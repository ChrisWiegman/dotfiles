# ---- Locale (must come first) ----
# Without a UTF-8 charset the prompt's `$'✖'` below dies with "character
# not in range", which aborts the rest of this file -- no aliases, no update
# functions, no rup. Terminal.app sets LANG; a bare `ssh` often does not.
export LANG="${LANG:-en_US.UTF-8}"

# ---- Homebrew first (so PATH/FPATH are set before completions load) ----
# Cache shellenv output — re-generate only when the brew binary changes
_brew_cache="${HOMEBREW_CACHE:-$HOME/Library/Caches/Homebrew}/brew_shellenv.sh"
if [ -s "/opt/homebrew/bin/brew" ]; then
    if [[ ! -f "$_brew_cache" || "/opt/homebrew/bin/brew" -nt "$_brew_cache" ]]; then
        mkdir -p "${_brew_cache:h}"
        /opt/homebrew/bin/brew shellenv >| "$_brew_cache"
    fi
    source "$_brew_cache"
fi
unset _brew_cache

# Hide extra homebrew hints
export HOMEBREW_NO_ENV_HINTS=1

# ---- Prompt: bold green path, blue parens, red branch, yellow dirty markers ----
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr $' \u2716'
zstyle ':vcs_info:git:*' stagedstr ' +'
zstyle ':vcs_info:git:*' formats ' %F{blue}(%f%F{red}%b%F{blue})%f%F{yellow}%u%c%f'
zstyle ':vcs_info:git:*' actionformats ' %F{blue}(%f%F{red}%b|%a%F{blue})%f%F{yellow}%u%c%f'
precmd() {
  vcs_info
  if [[ "$PWD" == "$HOME" ]]; then
    _pdir="~"
  elif [[ "$PWD" == "$HOME/"* ]]; then
    _pdir="${PWD#$HOME/}"
  else
    _pdir="$PWD"
  fi
}
setopt PROMPT_SUBST
PROMPT='%B%F{green}${_pdir}%f%b${vcs_info_msg_0_} '

# ---- Spell correction ----
setopt CORRECT

# ---- sudo escape (ESC ESC prepends sudo to current command) ----
_sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    [[ $BUFFER != sudo\ * ]] && BUFFER="sudo $BUFFER"
    zle end-of-line
}
zle -N _sudo-command-line
bindkey "\e\e" _sudo-command-line

# ---- sudo Touch ID focus (tmux detaches the auth prompt from Terminal, so
# Touch ID won't arm until Terminal is frontmost -- activate it first) ----
# Only inside a local tmux: anywhere else (VS Code's terminal, ssh) this would
# launch or steal focus to Terminal for no reason.
sudo() {
    if [[ "$TERM_PROGRAM" == tmux && -z "$SSH_CONNECTION" ]]; then
        osascript -e 'tell application "Terminal" to activate' >/dev/null 2>&1
    fi
    command sudo "$@"
}

# ---- SSH keys from the Keychain ----
# After a reboot the ssh-agent starts empty. Reload keys whose passphrases are
# saved in the Keychain (setup's sshkey.sh saves them there), so git commit
# signing works without prompting for a passphrase. Skipped on machines with no
# local key (work signs through 1Password's agent, so the system agent is always
# empty there and this would otherwise run on every new shell).
if [[ "$OSTYPE" == darwin* && -n "$SSH_AUTH_SOCK" && -f "$HOME/.ssh/id_ed25519" ]] && ! ssh-add -l >/dev/null 2>&1; then
    ssh-add -q --apple-load-keychain 2>/dev/null
fi

# ---- History (good shared defaults) ----
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
# SHARE_HISTORY already writes each command as it runs (no need for
# INC_APPEND_HISTORY); EXTENDED_HISTORY records when each command ran.
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_VERIFY
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Search history by the text already typed, like old OMZ behavior
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# ---- Completion niceties ----
# Do the full (slow) compinit at most once a day and trust the cached dump
# otherwise. The glob qualifier has to be in a real glob: inside [[ ]] it's a
# literal string (without EXTENDED_GLOB), which made every shell run the full
# compinit. Touch the dump afterwards, since compinit only rewrites it when the
# set of completion functions changes.
autoload -Uz compinit
_zcompdump_stale=( "$HOME"/.zcompdump(N.mh+24) )
if (( ${#_zcompdump_stale} )); then
    compinit && touch "$HOME/.zcompdump"
else
    compinit -C
fi
unset _zcompdump_stale
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ---- fzf: Ctrl-R fuzzy history, Ctrl-T file picker, Option-C cd ----
# After compinit, which fzf's ** completion hooks into.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# ---- Editor ----
export EDITOR="${EDITOR:-vim}"

# ---- ls colors ----
if ls --color=auto /dev/null &>/dev/null; then
  alias ls='ls --color=auto'
else
  export CLICOLOR=1
fi

# ---- Aliases ----
alias szh='echo "Reloading shell..."; source ~/.zshrc'

# Track, export, and apply this machine's macOS and app settings
# (see `macsettings --help`).
macsettings() { /usr/bin/python3 -I "$HOME/.dotfiles/shared/scripts/settings.py" "$@"; }

# ---- Pull and delete local branches whose upstream was deleted ----
# `function` keyword so a previously loaded `gup` alias doesn't expand here on reload.
function gup {
  git fetch --all --prune || return
  git pull --ff-only

  local current branch track
  current="$(git branch --show-current)"
  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads |
    while read -r branch track; do
      [[ "$track" == "[gone]" && "$branch" != "$current" ]] && git branch -D "$branch"
    done
}


# ---- Update Homebrew packages and casks ----
update_homebrew() {
  command brew update --quiet
  command brew upgrade -y --quiet
  command brew upgrade -y --cask --greedy --quiet
  bundle_homebrew
  command brew cleanup --prune=all --quiet
}

# ---- Install new Brewfile entries ----
# Setup installs the shared and machine Brewfiles, but an entry added since
# (say, from another machine) would otherwise wait for the next setup run.
# The machine is whichever one ~/.zshrc links to, as in r_mise.
bundle_homebrew() {
  local zshrc brewfile
  zshrc="$(readlink "$HOME/.zshrc" 2>/dev/null)" || return 0
  for brewfile in "$HOME/.dotfiles/shared/Brewfile" "${zshrc:h:h}/Brewfile"; do
    [[ -f "$brewfile" ]] || continue
    command brew bundle check --no-upgrade --quiet --file="$brewfile" >/dev/null 2>&1 && continue
    echo "Installing new entries from ${brewfile#$HOME/.dotfiles/}"
    command brew bundle install --no-upgrade --quiet --file="$brewfile" ||
      echo "Some entries in $brewfile failed to install (App Store apps need you signed in)"
    rm -f "$brewfile.lock.json"
  done
}

# ---- Update Mac App Store apps ----
update_app_store() {
  [[ "$OSTYPE" == darwin* ]] || return 0

  if ! command -v mas >/dev/null 2>&1; then
    echo "mas not installed. Skipping Mac App Store updates."
    return 0
  fi

  echo "Updating Mac App Store apps"
  command mas upgrade --accurate || echo "Mac App Store update failed (check App Store sign-in)"
}

# ---- Update repos in ~/Code (depth 2, real) ----
update_repos() {
  setopt localoptions nomonitor nobgnice
  echo "Updating code repositories"
  local CODE_DIR="$HOME/Code"
  [[ -d "$CODE_DIR" ]] || { echo "$CODE_DIR does not exist. Skipping repo update."; return 0; }

  local gitdirs
  gitdirs=("${(@f)$(find "$CODE_DIR" -maxdepth 2 -type d -name ".git" 2>/dev/null)}")
  [[ ${#gitdirs[@]} -gt 0 ]] || { echo "No git repositories found in $CODE_DIR. Skipping repo update."; return 0; }

  local repo repodir pid
  local -i max_jobs="${UPDATE_REPOS_JOBS:-12}"
  local -a pids=()
  (( max_jobs > 0 )) || max_jobs=1

  for repo in "${gitdirs[@]}"; do
    repodir="${repo:h}"

    (
      local current_repo="$repodir"
      local result before after
      local -i changed

      # Skip dirty working trees
      if ! git -C "$current_repo" diff --quiet 2>/dev/null || \
         ! git -C "$current_repo" diff --cached --quiet 2>/dev/null; then
        result="skipped (uncommitted changes)"
      # Fetch with prune — bail gracefully if offline or unreachable
      elif ! git -C "$current_repo" fetch --all --prune --quiet 2>/dev/null; then
        result="%F{red}error updating repo%f"
      # Only pull if an upstream branch is configured
      elif ! git -C "$current_repo" rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
        result="skipped (no upstream configured)"
      else
        before="$(git -C "$current_repo" rev-parse HEAD 2>/dev/null)"
        if git -C "$current_repo" pull --ff-only --quiet 2>/dev/null; then
          after="$(git -C "$current_repo" rev-parse HEAD 2>/dev/null)"
          if [[ "$before" == "$after" ]]; then
            result="%F{yellow}No changes detected%f"
          else
            changed=$(git -C "$current_repo" diff --name-only "$before" "$after" 2>/dev/null | wc -l)
            result="%F{green}[${changed}] files updated%f"
          fi
        else
          result="%F{red}Error updating repo%f"
        fi
      fi

      print -P -- "  -> ${current_repo:t} -- $result"
    ) &
    pids+=($!)

    # Wait after each batch to keep network and process usage bounded.
    if (( ${#pids[@]} >= max_jobs )); then
      for pid in "${pids[@]}"; do
        wait "$pid"
      done
      pids=()
    fi
  done

  for pid in "${pids[@]}"; do
    wait "$pid"
  done
}

# ---- Update dotfiles ----
update_dotfiles() {
  echo "Updating dotfiles"
  local DOT="$HOME/.dotfiles"
  [[ -d "$DOT/.git" ]] || { echo "$DOT is not a git repo. Skipping."; return 0; }

  pushd "$DOT" > /dev/null || return 0
  gup
  popd > /dev/null

  szh
}

# ---- Local overrides ----
[ -f ~/.local.zsh ] && source ~/.local.zsh

# ---- Daily runner (runs once per day) ----
rup() {
  [[ $(typeset -f update_repos)    ]] && update_repos
  [[ $(typeset -f update_dotfiles) ]] && update_dotfiles

  local stamp="${XDG_CACHE_HOME:-$HOME}/.rup.last"
  mkdir -p "${stamp:h}"

  local today="$(date +%Y-%m-%d)"
  if [[ -f "$stamp" ]] && [[ "$(cat "$stamp")" == "$today" ]]; then
    return 0
  fi
  print -r -- "$today" >| "$stamp"

  [[ $(typeset -f update_app_store) ]] && update_app_store
  [[ $(typeset -f update_homebrew) ]] && update_homebrew
  [[ $(typeset -f r_mise)           ]] && r_mise
  [[ $(typeset -f u_mise)           ]] && u_mise
}
