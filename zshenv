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
# 全 shell が通るここに置く。global install の shim は $PNPM_HOME/bin に置かれる)
for _pnpm_home in "$HOME/Library/pnpm" "$HOME/.local/share/pnpm"; do
  [[ -d "$_pnpm_home" ]] || continue
  export PNPM_HOME="$_pnpm_home"
  case ":$PATH:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) export PATH="$PNPM_HOME/bin:$PATH" ;;
  esac
  break
done
unset _pnpm_home
