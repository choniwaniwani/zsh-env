#
# zsh-env: pre-load env hook
# Sourced by all zsh shells (interactive, login, scripts).
# Keep this file minimal — heavy logic belongs in zshrc.
#

# Per-machine pre-load overrides (env vars that tools read at init).
# Example use: NVM_DIR override, POWERLEVEL9K_INSTANT_PROMPT setting,
# SKIP_* flags, ZDOTDIR — anything that must be set before zshrc runs.
[[ -r "${HOME}/.zshenv.local" ]] && source "${HOME}/.zshenv.local"

# pnpm (zshrc は対話 shell 専用で non-interactive な zsh -c 呼び出しに効かないため、
# 全 shell が通るここに置く。PNPM_HOME 未設置の環境では export するだけで無害)
if [[ -d "$HOME/.local/share/pnpm" ]]; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) export PATH="$PNPM_HOME/bin:$PATH" ;;
  esac
fi
