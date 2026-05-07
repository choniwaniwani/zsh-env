#
# zsh-env: pre-load env hook
# Sourced by all zsh shells (interactive, login, scripts).
# Keep this file minimal — heavy logic belongs in zshrc.
#

# Per-machine pre-load overrides (env vars that tools read at init).
# Example use: NVM_DIR override, POWERLEVEL9K_INSTANT_PROMPT setting,
# SKIP_* flags, ZDOTDIR — anything that must be set before zshrc runs.
[[ -r "${HOME}/.zshenv.local" ]] && source "${HOME}/.zshenv.local"
