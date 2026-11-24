#!/usr/bin/python3 -I
"""Track, export, and apply macOS settings for a dotfiles machine.

Settings are stored as one XML plist per preferences domain, holding only the
keys being tracked (not the whole domain, which is full of window positions,
timestamps, and account-specific IDs). Settings for the -currentHost (ByHost)
variant of a domain go in a currentHost/ subfolder. They're kept in layers,
which `apply` merges in this order, so a later layer wins:

  shared/settings/            every machine (--machine shared)
  profiles/<name>/settings/   machines that list <name> in machines/<m>/Profiles
                              (--profile <name>)
  machines/<m>/settings/      that machine alone (the default)

`track`, `untrack`, `watch`, and `export` work on one layer: the machine's own,
unless --machine shared or --profile <name> picks another. For a machine,
`apply` and `list` cover all of its layers.

For a machine, `export` captures everything it can in one go: every key that
looks like a setting in System Settings, Apple's apps, and third-party apps
(not Apple's background services, whose preferences are bookkeeping). It
leaves out app state, anything that looks personal (this repo is public),
keys a shared or profile layer already tracks, and whatever `untrack` told it
to leave out (kept in the layer's settings/_ignore.plist).

Commands (run from Terminal, which has Full Disk Access; without it macOS
hides sandboxed apps' settings such as Mail, Safari, and Notes):

  watch [domain ...]     Snapshot settings, wait while you change things in
                         System Settings or an app, then list what changed
                         and choose which keys to track.
  track <domain> [key ...]
                         Track keys at their current values. With no keys,
                         list the domain's keys to choose from.
  untrack <domain> [key ...]
                         Stop tracking keys (all of the domain's keys if none
                         are given). For a machine, export also stops
                         capturing them; `track` brings them back.
  export                 Refresh every tracked key from this Mac's current
                         values and, for a machine, capture every new setting.
                         Run after changing settings, review with git diff,
                         then commit. For a machine, also points out keys from
                         its shared and profile layers that differ on this Mac.
  apply                  Write the tracked settings to this Mac (setup runs
                         this).
  list                   Show the tracked settings.

Domains are names like com.apple.dock or NSGlobalDomain; prefix one with
currentHost/ for its ByHost variant (e.g. currentHost/com.apple.screensaver).
The machine defaults to whichever one ~/.zshrc is linked from; pass
--machine <name> to choose another.
"""

import argparse
import collections
import concurrent.futures
import datetime
import functools
import os
import plistlib
import re
import subprocess
import sys
import time

DOTFILES = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HOME = os.path.expanduser("~")
CURRENT_HOST = "currentHost/"
SHARED = "shared"  # --machine name for shared/settings, applied on every machine

# Keys that are app state rather than preferences. They're hidden from `watch`
# and `track` listings (pass --all to see them) but can still be tracked by name.
NOISE = re.compile(
    r"^(NSWindow Frame|NSSplitView|NSToolbar|NSNavPanel|NSNavLast|NSTableView|"
    r"NSOutlineView|NSStatusItem|NSOSPLast|NSColorPanel|FXRecent|FXDesktopVolume|"
    r"_MPC|JetEngine|PPr4:|rprf:|devp:|gnot:)"
    r"|[Ll]ast|[Dd]ate$|[Tt]ime$|[Tt]imestamp|[Ss]tamp|[Ss]ession|[Hh]eartbeat"
    r"|UUID|[Uu]uid|GUID|Identifier$|ID$|IDs$|[Cc]ache|[Aa]nalytics|[Mm]igrat"
    r"|[Bb]ookmark|-url$|[Rr]ecent|[Ss]eed$|[Tt]oken|[Cc]ount$|[Vv]ersion"
    r"|Window(H|V)?(Pos|Size)|[Rr]ects?$|Frame|[Ss]croll[Pp]osition|[Ss]elected"
    # Onboarding and "already did that" flags, migrations, logging, capability
    # caches, and similar bookkeeping.
    r"|^_|[Uu]pgrade|[Hh]as(Shown|Seen|Displayed|Been|Launched|Set|Started|Finished"
    r"|Performed)|[Dd]id[A-Z]|^did|^[Hh]ave[A-Z]|[Ff]irst(Launch|Run|Login)"
    r"|[Oo]nboarding|[Ww]hatsNew|[Ww]elcome|FTE|[Rr]ecen|[Dd]ebug|[Ll]ogging|[Ll]og[A-Z]"
    r"|[Rr]eason|[Aa]ttempt|[Pp]ending|Requested|[Cc]ompleted?($|[A-Z])|Performed"
    r"|Eligib|[Nn]eeds[A-Z]|[Ss]upport(s|ed)?[A-Z]|^store[A-Z]|[Ii]mported|[Bb]adge"
    r"|[Ii][Cc]loud|Window[\w.]*Location|SyncState|^AutoUnlock|^com\.apple\.gms\."
    r"|[Uu]pdateLevel|[Uu]tterance|[Dd]isclosure|Greetings?|Snapshot|Sent$|OneTime"
    r"|[Ss]yncing|Ever[A-Z]|SyncExtensions|Upsell|[Ii]ntroduction|NotFirst|MiniBuddy"
    r"|SplitView|Connected$|^trash-full$|[Ss]egment$"
)

# Real settings whose names look like app state to NOISE: 24-hour time ends in
# "Time", the screen saver's delay is idleTime, the Dock's show-recents says
# "recent", menu bar item visibility and toolbar layouts share prefixes with
# window state, and Safari's restore-windows options say "Session".
SETTING = re.compile(
    r"^(AppleICUForce(12|24)HourTime$|idleTime$|show-recents$|NSRecentDocumentsLimit$"
    r"|NSStatusItem Visible |NSToolbar Configuration )"
    r"|Restor(e|ing)Session"
)

# What export captures on its own for a machine. Any key anywhere can still be
# tracked by name with `track`.
#
# Apple's settings live in the domains for System Settings and Apple's apps.
# The few hundred other Apple domains belong to background services, and hold
# their bookkeeping (sync flags, counters, account IDs) rather than settings;
# replaying some of it on a new Mac would even do harm, like telling Messages
# its first sync already happened.
APPLE_SETTINGS = re.compile(
    r"^(NSGlobalDomain|pbs|com\.apple\.("
    # System Settings and the desktop
    r"dock|finder|WindowManager|controlcenter|menuextra\..*|systemuiserver|Spotlight"
    r"|screencapture|screensaver|loginwindow|desktopservices|sharingd|universalcontrol"
    r"|LaunchServices/com\.apple\.launchservices\.secure|ExtensionsPreferences\..*"
    r"|scriptmenu|FolderActionsDispatcher|batteryui\..*|AppStore|TelephonyUtilities"
    r"|Siri|assistant\.support|assistant\.backedup|AdLib"
    r"|universalaccess|Accessibility|mediaaccessibility.*|ComfortSounds|CoreGraphics"
    r"|HIToolbox|symbolichotkeys|TextInputMenu|keyboard\.preferences|inputmethod\..*"
    r"|AppleMultitouch.*|driver\.Apple(BluetoothMultitouch|HIDMouse).*"
    # Apple's apps
    r"|Safari|mail|Notes|iCal|reminders|Music|Music\.eq|podcasts|TV|Photos"
    r"|photos\.shareddefaults|Preview|TextEdit|Terminal|ActivityMonitor|Console"
    r"|DiskUtility|QuickTimePlayerX|Maps|weather|stocks|news|FaceTime|MobileSMS"
    r"|keychainaccess|ScriptEditor2|Automator|iWork\..*|freeform|iBooksX|dt\.Xcode"
    r"|FontBook|calculator|Dictionary|VoiceMemos|screensharing"
    r"))$"
)
# Third-party apps are named like com.company.App. Their updaters, helpers,
# and crash reporters are bookkeeping too.
THIRD_PARTY = re.compile(r"^(?!com\.apple\.|systemgroup\.|group\.)[\w-]+(\.[\w-]+)+$")
THIRD_PARTY_SKIP = re.compile(
    r"keystone|autoupdate|updater?$|crashpad|crash.?report|helper|agent$|daemon"
    r"|launcher|analytics|telemetry", re.IGNORECASE)

# Since this repo is public, export also leaves out anything that looks
# personal or tied to this Mac. Keys whose names say they hold something
# private:
PRIVATE_KEY = re.compile(
    r"passw(or)?d|secret|token|credential|licen[cs]e|serial|registration|e-?mail"
    r"|account|cookie|api.?key|auth|salt|birth|dsid|apns|nickname|identifier|identit|apple.?id"
    r"|persistent.?id|signature|(^|[^a-z])id([^a-z]|$)", re.IGNORECASE)
# Text in a key or value: email addresses, paths in a home folder, IDs and
# MAC addresses, hashes, and phone numbers.
PRIVATE_TEXT = re.compile(
    r"[\w.+-]+@[\w-]+\.[\w.-]+"
    r"|/Users/|file://"
    r"|[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"
    r"|\b[0-9A-Fa-f]{2}([:-])[0-9A-Fa-f]{2}(\1[0-9A-Fa-f]{2}){4}\b"
    r"|[0-9A-Fa-f]{32,}|\+\d{10,15}\b|tel:", re.ASCII)
# Text in a value (key names run long, so not those): tokens, and URLs with a
# query string, which tends to carry IDs.
TOKEN_TEXT = re.compile(
    r"[A-Za-z0-9+/_-]{40,}|\b(?=[A-Za-z+/_-]*\d)[A-Za-z0-9+/_-]{24,}|https?://\S*\?", re.ASCII)
# Text that marks a value as app state: dates, and window positions.
STATE_TEXT = re.compile(r"\b\d{4}-\d{2}-\d{2}\b|^\{\{?-?\d+(\.\d+)?, -?\d+", re.ASCII)
# Values bigger than this are caches or history, not settings.
MAX_CAPTURE_BYTES = 64 * 1024

# Restart these after applying so the changes show up without logging out.
# A currentHost/ domain uses the entry for its plain name.
RESTART = {
    "com.apple.dock": ["Dock"],
    "com.apple.finder": ["Finder"],
    "NSGlobalDomain": ["SystemUIServer"],
    "com.apple.controlcenter": ["ControlCenter"],
    "com.apple.menuextra.clock": ["ControlCenter"],
    "com.apple.systemuiserver": ["SystemUIServer"],
    "com.apple.screencapture": ["SystemUIServer"],
    "com.apple.WindowManager": ["WindowManager"],
    "com.apple.Spotlight": ["Spotlight"],
    "com.apple.TextInputMenu": ["TextInputMenuAgent"],
}

# Keyboard, keyboard-shortcut, trackpad, and mouse settings are read at login.
# Apple's activateSettings reloads them for the current session instead.
ACTIVATE_SETTINGS = ("/System/Library/PrivateFrameworks/SystemAdministration.framework/"
                     "Resources/activateSettings")
RELOAD = {
    "NSGlobalDomain",
    "com.apple.symbolichotkeys",
    "com.apple.HIToolbox",
    "com.apple.AppleMultitouchTrackpad",
    "com.apple.driver.AppleBluetoothMultitouch.trackpad",
    "com.apple.AppleMultitouchMouse",
    "com.apple.driver.AppleBluetoothMultitouch.mouse",
}

# One layer of tracked settings. `flag` is the macsettings option that picks it,
# for hints; `kind` is shared, profile, or machine.
Layer = collections.namedtuple("Layer", "label sdir flag kind")

# Reserved file name in a layer's settings/ folder for what export never
# captures: {domain: True} for a whole domain, {domain: [key, ...]} for keys.
IGNORE = "_ignore"


class NoAccess(Exception):
    pass


def is_noise(key):
    return bool(NOISE.search(key)) and not SETTING.search(key)


def base_domain(domain):
    return domain[len(CURRENT_HOST):] if domain.startswith(CURRENT_HOST) else domain


def capturable(domain):
    """Whether export captures new keys in this domain on its own."""
    name = base_domain(domain)
    return bool(APPLE_SETTINGS.search(name)
                or (THIRD_PARTY.search(name) and not THIRD_PARTY_SKIP.search(name)))


@functools.lru_cache(maxsize=None)
def personal_text():
    """Your name (from git), your login, and this Mac's names, which turn up in
    settings like a shared music library's name."""
    words, names = {os.path.basename(HOME)}, set()
    for cmd, split in ((["git", "config", "--get", "user.name"], True),
                       (["scutil", "--get", "ComputerName"], False),
                       (["scutil", "--get", "LocalHostName"], False)):
        try:
            out = subprocess.run(cmd, capture_output=True, text=True).stdout.strip()
        except OSError:
            continue
        (words.update(out.split()) if split else names.add(out))
    parts = [rf"\b{re.escape(w)}\b" for w in words | names if len(w) >= 3]
    return re.compile("|".join(parts), re.IGNORECASE) if parts else None


def strings_in(value):
    """Every string in a value, its dictionary keys included. Data is read as
    ASCII and as UTF-16, the two ways property lists store text in it."""
    if isinstance(value, dict):
        for k, v in value.items():
            yield k
            yield from strings_in(v)
    elif isinstance(value, list):
        for v in value:
            yield from strings_in(v)
    elif isinstance(value, bytes):
        yield value.decode("latin-1")
        yield value.decode("utf-16-be", "ignore")
    elif isinstance(value, str):
        yield value


def has_date(value):
    if isinstance(value, datetime.datetime):
        return True
    if isinstance(value, dict):
        return any(has_date(v) for v in value.values())
    if isinstance(value, list):
        return any(has_date(v) for v in value)
    return False


def worth_capturing(key, value):
    """Whether export should start tracking a key it found: a setting rather
    than app state, and nothing personal."""
    if is_noise(key) or PRIVATE_KEY.search(key) or has_date(value):
        return False
    if len(plistlib.dumps(value)) > MAX_CAPTURE_BYTES:
        return False
    # Bookmark and alias data are file references into someone's folders.
    if isinstance(value, bytes) and value[:4] in (b"book", b"alis"):
        return False
    personal = personal_text()
    values = list(strings_in(value))
    for text in [key, *values]:
        if PRIVATE_TEXT.search(text) or STATE_TEXT.search(text):
            return False
        if personal and personal.search(text):
            return False
    return not any(TOKEN_TEXT.search(text) for text in values)


# ---------------------------------------------------------------- layers

def detect_machine():
    target = os.path.realpath(os.path.join(HOME, ".zshrc"))
    parts = target.split(os.sep)
    if "machines" in parts:
        i = parts.index("machines")
        if i + 1 < len(parts):
            return parts[i + 1]
    sys.exit("Couldn't tell which machine this is from ~/.zshrc; pass --machine <name>.")


def machine_dir(machine):
    mdir = os.path.join(DOTFILES, "machines", machine)
    if not os.path.isdir(mdir):
        sys.exit(f"No machine named '{machine}' in {os.path.join(DOTFILES, 'machines')}.")
    return mdir


def machine_profiles(machine):
    """Profiles listed in machines/<machine>/Profiles, one per line, in order."""
    path = os.path.join(machine_dir(machine), "Profiles")
    if not os.path.exists(path):
        return []
    with open(path) as f:
        names = [line.split("#", 1)[0].strip() for line in f]
    return [n for n in names if n]


def known_profiles():
    machines = os.path.join(DOTFILES, "machines")
    return {p for m in os.listdir(machines) if os.path.isdir(os.path.join(machines, m))
            for p in machine_profiles(m)}


def shared_layer():
    return Layer(SHARED, os.path.join(DOTFILES, "shared", "settings"), "--machine shared",
                 "shared")


def profile_layer(name):
    return Layer(f"profile {name}", os.path.join(DOTFILES, "profiles", name, "settings"),
                 f"--profile {name}", "profile")


def machine_layer(machine):
    return Layer(machine, os.path.join(machine_dir(machine), "settings"), f"--machine {machine}",
                 "machine")


def target_layers(args):
    """The layers a command covers, lowest first. The last one is where
    track, untrack, watch, and export write."""
    if args.profile:
        if args.profile not in known_profiles():
            sys.exit(f"No machine uses a profile named '{args.profile}'. "
                     "List it in machines/<machine>/Profiles first.")
        return [profile_layer(args.profile)]
    if args.machine == SHARED:
        return [shared_layer()]
    return ([shared_layer()]
            + [profile_layer(p) for p in machine_profiles(args.machine)]
            + [machine_layer(args.machine)])


def domain_file(sdir, domain):
    if domain.startswith(CURRENT_HOST):
        return os.path.join(sdir, "currentHost", domain[len(CURRENT_HOST):] + ".plist")
    return os.path.join(sdir, domain + ".plist")


def tracked_domains(sdir):
    found = []
    for sub, prefix in (("", ""), ("currentHost", CURRENT_HOST)):
        d = os.path.join(sdir, sub)
        if os.path.isdir(d):
            for name in sorted(os.listdir(d)):
                if name.endswith(".plist") and not name.startswith("_"):
                    found.append(prefix + name[: -len(".plist")])
    return found


def load_tracked(sdir, domain):
    path = domain_file(sdir, domain)
    if not os.path.exists(path):
        return {}
    with open(path, "rb") as f:
        return plistlib.load(f)


def save_tracked(sdir, domain, values):
    path = domain_file(sdir, domain)
    if not values:
        if os.path.exists(path):
            os.remove(path)
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        plistlib.dump(values, f, sort_keys=True)


def tracked_below(layers, domain):
    """Keys of a domain tracked in the layers under the target one."""
    keys = set()
    for layer in layers[:-1]:
        keys.update(load_tracked(layer.sdir, domain))
    return keys


def unignore(layer, domain, keys):
    """Let export capture these keys again, now that they're tracked by hand."""
    ignore = load_tracked(layer.sdir, IGNORE)
    entry = ignore.get(domain)
    if isinstance(entry, list) and set(keys) & set(entry):
        ignore[domain] = [k for k in entry if k not in keys]
        if not ignore[domain]:
            del ignore[domain]
        save_tracked(layer.sdir, IGNORE, ignore)


# ---------------------------------------------------------------- defaults

def container_plist(name):
    return os.path.join(HOME, "Library", "Containers", name, "Data", "Library",
                        "Preferences", name + ".plist")


def defaults_args(domain):
    """The `defaults` arguments that address a domain.

    Sandboxed apps (Mail, Safari, Notes, ...) keep their settings in their
    container. Address those by path so reads and writes can't silently land
    in an empty ~/Library/Preferences copy instead.
    """
    if domain.startswith(CURRENT_HOST):
        return ["-currentHost", domain[len(CURRENT_HOST):]]
    cpath = container_plist(domain)
    if os.path.exists(cpath):
        return [cpath[: -len(".plist")]]
    return [domain]


def check_access(domain):
    """Raise NoAccess if macOS is hiding the domain's settings file from us,
    rather than let `defaults` read it as empty."""
    if domain.startswith(CURRENT_HOST):
        return
    for path in (container_plist(domain),
                 os.path.join(HOME, "Library", "Preferences", domain + ".plist")):
        if os.path.exists(path):
            try:
                with open(path, "rb"):
                    pass
            except PermissionError:
                raise NoAccess(
                    f"macOS is blocking access to {domain}'s settings. Run this from "
                    "Terminal, and give Terminal Full Disk Access in System Settings > "
                    "Privacy & Security.")
            return


def read_domain(domain):
    check_access(domain)
    out = subprocess.run(["defaults", *defaults_args(domain)[:-1], "export",
                          defaults_args(domain)[-1], "-"],
                         capture_output=True)
    if out.returncode != 0 or not out.stdout.strip():
        return {}
    try:
        return plistlib.loads(out.stdout)
    except Exception:
        return {}


def write_key(domain, key, value):
    args = defaults_args(domain)
    xml = plistlib.dumps(value).decode()
    subprocess.run(["defaults", *args[:-1], "write", args[-1], key, xml], check=True)


def app_is_sandboxed(bundle_id):
    """Path of the app with this bundle ID if it's sandboxed, else None."""
    out = subprocess.run(
        ["osascript", "-e", f'POSIX path of (path to application id "{bundle_id}")'],
        capture_output=True, text=True)
    app = out.stdout.strip()
    if out.returncode != 0 or not app:
        return None
    ent = subprocess.run(["codesign", "-d", "--entitlements", "-", "--xml", app],
                         capture_output=True)
    return app if b"com.apple.security.app-sandbox" in ent.stdout else None


def ensure_container(domain):
    """A sandboxed app's container only exists after its first launch, and
    settings written before then don't reach the app. Launch it hidden once
    so the container exists, then quit it. (Check for the container folder,
    not the plist: some sandboxed apps, like Calendar, keep their settings
    in ~/Library/Preferences anyway.)"""
    container = os.path.join(HOME, "Library", "Containers", domain)
    if domain.startswith(CURRENT_HOST) or os.path.isdir(container):
        return
    if not app_is_sandboxed(domain):
        return
    print(f"  launching {domain} once so it sets up its settings")
    subprocess.run(["open", "-g", "-j", "-b", domain], capture_output=True)
    for _ in range(30):
        if os.path.isdir(container):
            break
        time.sleep(1)
    time.sleep(2)
    subprocess.run(["osascript", "-e", f'tell application id "{domain}" to quit'],
                   capture_output=True)
    time.sleep(1)


# ---------------------------------------------------------------- display

def short(value, width=70):
    if isinstance(value, bytes):
        text = f"<{len(value)} bytes of data>"
    elif isinstance(value, (list, dict)):
        text = re.sub(r"\s+", " ", plistlib.dumps(value).decode()
                      .split("<plist version=\"1.0\">", 1)[-1]
                      .rsplit("</plist>", 1)[0]).strip()
    else:
        text = repr(value)
    return text if len(text) <= width else text[: width - 1] + "…"


def mark(key, here, below):
    return "*" if key in here else "+" if key in below else " "


def print_legend(layers):
    print("      (* already tracked"
          + (", + tracked in a shared or profile layer)" if len(layers) > 1 else ")"))


def parse_selection(answer, count):
    answer = answer.strip().lower()
    if answer in ("a", "all"):
        return list(range(count))
    picked = []
    for part in re.split(r"[,\s]+", answer):
        if not part:
            continue
        if "-" in part:
            lo, hi = part.split("-", 1)
            picked.extend(range(int(lo) - 1, int(hi)))
        else:
            picked.append(int(part) - 1)
    return [i for i in picked if 0 <= i < count]


def ask_selection(count):
    """Ask which of the numbered items to track. Asks again after a typo
    instead of crashing, which would throw away a `watch` session."""
    while True:
        try:
            answer = input("Track which? (e.g. 1 3 5-7, a for all, Enter for none): ")
        except EOFError:
            return []
        try:
            return parse_selection(answer, count)
        except ValueError:
            print("  Didn't understand that. Use numbers and ranges like 1 3 5-7, "
                  "a for all, or Enter for none.")


# ---------------------------------------------------------------- commands

def cmd_list(args, layers):
    for layer in layers:
        domains = tracked_domains(layer.sdir)
        if len(layers) > 1:
            print(f"--- {layer.label}" + ("" if domains else " (nothing tracked)"))
        elif not domains:
            print(f"No settings tracked for '{layer.label}' yet. "
                  f"Start with: macsettings {layer.flag} watch")
        for domain in domains:
            print(domain)
            for key, value in sorted(load_tracked(layer.sdir, domain).items()):
                print(f"    {key} = {short(value)}")
        ignore = load_tracked(layer.sdir, IGNORE)
        if ignore:
            print("export leaves out: " + ", ".join(
                d if v is True else f"{d} ({', '.join(v)})" for d, v in sorted(ignore.items())))


def cmd_track(args, layers):
    sdir = layers[-1].sdir
    live = read_domain(args.domain)
    if not args.keys:
        keys = sorted(k for k in live if args.all or not is_noise(k))
        hidden = len(live) - len(keys)
        if not keys:
            print(f"{args.domain} has no settings to show"
                  + (f" ({hidden} hidden as app state; add --all)" if hidden else "."))
            return
        here, below = load_tracked(sdir, args.domain), tracked_below(layers, args.domain)
        for i, key in enumerate(keys, 1):
            print(f"{i:4}{mark(key, here, below)} {key} = {short(live[key])}")
        if hidden:
            print(f"      ({hidden} more hidden as app state; add --all to show them)")
        print_legend(layers)
        args.keys = [keys[i] for i in ask_selection(len(keys))]
        if not args.keys:
            return
    tracked = load_tracked(sdir, args.domain)
    for key in args.keys:
        if key not in live:
            print(f"  {key} isn't set on this Mac; skipped")
            continue
        tracked[key] = live[key]
        print(f"  tracking {args.domain} {key} = {short(live[key])}")
    save_tracked(sdir, args.domain, tracked)
    if layers[-1].kind == "machine":
        unignore(layers[-1], args.domain, args.keys)


def cmd_untrack(args, layers):
    target = layers[-1]
    tracked = load_tracked(target.sdir, args.domain)
    if not tracked and target.kind != "machine":
        print(f"Nothing tracked for {args.domain}.")
        return
    for key in args.keys or list(tracked):
        if tracked.pop(key, None) is not None:
            print(f"  untracked {args.domain} {key}")
    save_tracked(target.sdir, args.domain, tracked)
    if target.kind != "machine":
        return
    # Export captures a machine's settings on its own, so remember to leave
    # these out, or they'd be back on the next export.
    ignore = load_tracked(target.sdir, IGNORE)
    if args.keys:
        if ignore.get(args.domain) is not True:
            ignore[args.domain] = sorted(set(ignore.get(args.domain) or []) | set(args.keys))
        print("  export will leave those keys out from now on (track them to bring them back)")
    else:
        ignore[args.domain] = True
        print(f"  export will leave {args.domain} out from now on "
              "(track keys in it to bring them back)")
    save_tracked(target.sdir, IGNORE, ignore)


def cmd_export(args, layers):
    target = layers[-1]
    capture = target.kind == "machine"
    ignore = load_tracked(target.sdir, IGNORE) if capture else {}
    domains = set(tracked_domains(target.sdir))
    if capture:
        domains.update(d for d in snapshot_domains(None)
                       if capturable(d) and ignore.get(d) is not True)
    print(f"Reading {len(domains)} settings domains…")
    live_all = snapshot(sorted(domains))

    changed = removed = added = 0
    added_in = set()
    skipped, blocked = [], []
    for domain in sorted(domains):
        tracked = load_tracked(target.sdir, domain)
        before = dict(tracked)
        live = live_all.get(domain)
        if live is None:
            if tracked:
                skipped.append(f"{domain}: macOS blocked reading it, so it was left as is. "
                               "Run this from Terminal with Full Disk Access.")
            else:
                blocked.append(domain)
            continue
        if tracked and not live:
            # A tracked domain that reads back empty is far more likely hidden
            # from us than reset to defaults in full. Untracking every key on
            # that guess would lose them, so leave it for a person to decide.
            skipped.append(f"{domain} read back empty, so it was left as is. If every key "
                           f"really is back to its default, run: "
                           f"macsettings {target.flag} untrack {domain}")
            continue
        for key in list(tracked):
            if key not in live:
                # Unset on this Mac means it's back to the default; stop tracking it.
                del tracked[key]
                removed += 1
                print(f"  {domain} {key}: no longer set here, untracked")
            elif live[key] != tracked[key]:
                print(f"  {domain} {key}: {short(tracked[key], 30)} -> {short(live[key], 30)}")
                tracked[key] = live[key]
                changed += 1
        entry = ignore.get(domain)
        if capture and entry is not True and capturable(domain):
            leave_out = tracked_below(layers, domain) | set(entry or [])
            for key in sorted(live):
                if key not in tracked and key not in leave_out and worth_capturing(key, live[key]):
                    tracked[key] = live[key]
                    added += 1
                    added_in.add(domain)
        if tracked != before:
            save_tracked(target.sdir, domain, tracked)

    summary = []
    if added:
        summary.append(f"{added} new setting(s) in {len(added_in)} domain(s)")
    if changed:
        summary.append(f"{changed} changed")
    if removed:
        summary.append(f"{removed} no longer set")
    print(f"Exported settings for '{target.label}': "
          + (", ".join(summary) + ". Review with git diff before committing (this repo is public)."
             if summary else "already up to date."))
    if blocked:
        print(f"  Couldn't read {len(blocked)} protected domain(s) (like {blocked[0]}), so "
              "nothing in them was captured. Run this from Terminal with Full Disk Access "
              "to include them.")
    if len(layers) > 1:
        report_drift(layers)
    if skipped:
        for line in skipped:
            print(f"  skipped: {line}", file=sys.stderr)
        sys.exit(1)


def report_drift(layers):
    """List keys from the layers under this machine's own (shared, profiles)
    that differ on this Mac. Export leaves those layers alone because other
    machines get them too, and the next apply would put the tracked value back."""
    drift = []
    overridden = collections.defaultdict(set)  # keys a higher layer tracks
    for i, layer in reversed(list(enumerate(layers))):
        for domain in tracked_domains(layer.sdir):
            tracked = load_tracked(layer.sdir, domain)
            if i < len(layers) - 1:
                try:
                    live = read_domain(domain)
                except NoAccess:
                    live = {}
                for key, value in sorted(tracked.items()):
                    if live and key not in overridden[domain] and live.get(key, "<unset>") != value:
                        drift.append((layer, domain, key, value, live.get(key, "<unset>")))
            overridden[domain].update(tracked)
    if not drift:
        return
    print("These come from other layers and differ on this Mac. The next apply puts the "
          "tracked value back:")
    for layer, domain, key, old, new in drift:
        print(f"  {layer.label}: {domain} {key}: {short(old, 30)} -> {short(new, 30)}")
    flags = sorted({layer.flag for layer, *_ in drift})
    print("  To keep this Mac's values, export that layer (macsettings "
          + " export, or macsettings ".join(flags)
          + " export), or track the key on this machine alone to override it.")


def cmd_apply(args, layers):
    # Merge the layers first, so a key tracked in more than one is written
    # once, with the value from the highest layer.
    wanted = {}
    for layer in layers:
        for domain in tracked_domains(layer.sdir):
            wanted.setdefault(domain, {}).update(load_tracked(layer.sdir, domain))

    restart = set()
    reload = False
    changed = 0
    failed = []
    for domain, values in wanted.items():
        try:
            ensure_container(domain)
            live = read_domain(domain)
            for key, value in sorted(values.items()):
                if live.get(key) != value:
                    write_key(domain, key, value)
                    changed += 1
                    restart.update(RESTART.get(base_domain(domain), []))
                    reload = reload or base_domain(domain) in RELOAD
        except (NoAccess, subprocess.CalledProcessError) as err:
            failed.append(f"{domain}: {err}")
    if reload and os.path.exists(ACTIVATE_SETTINGS):
        subprocess.run([ACTIVATE_SETTINGS, "-u"], capture_output=True)
    for app in sorted(restart):
        subprocess.run(["killall", app], capture_output=True)
    print(f"Applied settings ({', '.join(layer.label for layer in layers)}): "
          + (f"{changed} change(s)." if changed else "already up to date."))
    if changed:
        print("  A few changes (like input sources) only take effect after a log out and"
              " back in, and open apps need a restart.")
    if failed:
        for line in failed:
            print(f"  failed: {line}", file=sys.stderr)
        sys.exit(1)


def snapshot_domains(explicit):
    if explicit:
        return explicit
    names = subprocess.run(["defaults", "domains"], capture_output=True, text=True).stdout
    domains = {d.strip() for d in names.split(",") if d.strip()}
    domains.add("NSGlobalDomain")
    containers = os.path.join(HOME, "Library", "Containers")
    if os.path.isdir(containers):
        for name in os.listdir(containers):
            if os.path.exists(container_plist(name)):
                domains.add(name)
    host = subprocess.run(["defaults", "-currentHost", "domains"],
                          capture_output=True, text=True).stdout
    domains.update(CURRENT_HOST + d.strip() for d in host.split(",") if d.strip())
    domains.add(CURRENT_HOST + "NSGlobalDomain")
    return sorted(domains)


def snapshot(domains):
    def grab(domain):
        try:
            return domain, read_domain(domain)
        except NoAccess:
            return domain, None
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as pool:
        return dict(pool.map(grab, domains))


def cmd_watch(args, layers):
    sdir = layers[-1].sdir
    domains = snapshot_domains(args.domains)
    print(f"Snapshotting {len(domains)} settings domains…")
    before = snapshot(domains)
    blocked = sorted(d for d, v in before.items() if v is None)
    if blocked:
        print(f"  Can't read {len(blocked)} protected domain(s) (e.g. {blocked[0]}). Run this "
              "from Terminal with Full Disk Access to include them.")
    try:
        input("Now change the settings you want to capture, then press Enter here… ")
    except EOFError:
        return
    after = snapshot(domains)

    changes = []
    hidden = 0
    for domain in domains:
        old, new = before.get(domain) or {}, after.get(domain) or {}
        for key in sorted(set(old) | set(new)):
            if old.get(key) == new.get(key):
                continue
            if key not in new:
                continue  # removed: reset to default; nothing to track
            if not args.all and is_noise(key):
                hidden += 1
                continue
            changes.append((domain, key, old.get(key, "<unset>"), new[key]))

    if not changes:
        print("No setting changes found"
              + (f" ({hidden} app-state changes hidden; add --all)." if hidden else "."))
        return
    tracked = {d: load_tracked(sdir, d) for d in {c[0] for c in changes}}
    below = {d: tracked_below(layers, d) for d in tracked}
    for i, (domain, key, old, new) in enumerate(changes, 1):
        print(f"{i:4}{mark(key, tracked[domain], below[domain])} {domain} {key}: "
              f"{short(old, 25)} -> {short(new, 40)}")
    if hidden:
        print(f"      ({hidden} app-state changes hidden; add --all to show them)")
    print_legend(layers)
    picked = ask_selection(len(changes))
    if not picked:
        return
    for i in picked:
        domain, key, _, new = changes[i]
        tracked[domain][key] = new
        print(f"  tracking {domain} {key}")
    for domain, values in tracked.items():
        save_tracked(sdir, domain, values)
        if layers[-1].kind == "machine":
            unignore(layers[-1], domain, list(values))


def main():
    parser = argparse.ArgumentParser(
        prog="macsettings", description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    target = parser.add_mutually_exclusive_group()
    target.add_argument("--machine", help="machine to use (default: from ~/.zshrc), "
                        "or 'shared' for the settings every machine gets")
    target.add_argument("--profile", help="profile to use (see machines/<m>/Profiles)")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("list")
    sub.add_parser("export")
    sub.add_parser("apply")
    p = sub.add_parser("track")
    p.add_argument("domain")
    p.add_argument("keys", nargs="*")
    p.add_argument("--all", action="store_true", help="include app-state keys")
    p = sub.add_parser("untrack")
    p.add_argument("domain")
    p.add_argument("keys", nargs="*")
    p = sub.add_parser("watch")
    p.add_argument("domains", nargs="*")
    p.add_argument("--all", action="store_true", help="include app-state changes")
    args = parser.parse_args()

    if not args.profile:
        args.machine = args.machine or detect_machine()
    layers = target_layers(args)
    try:
        {"list": cmd_list, "track": cmd_track, "untrack": cmd_untrack,
         "export": cmd_export, "apply": cmd_apply, "watch": cmd_watch}[args.command](args, layers)
    except NoAccess as err:
        sys.exit(str(err))
    except KeyboardInterrupt:
        sys.exit(130)


if __name__ == "__main__":
    main()
