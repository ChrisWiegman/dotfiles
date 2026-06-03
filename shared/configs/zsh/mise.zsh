# ~/.zprofile
eval "$(mise activate zsh --shims)"

# Update all mise-managed tools (go, node, npm, etc.) to the latest
# versions allowed by the mise config, then remove the old installs.
function u_mise() {
  mise upgrade
  mise prune --yes
}