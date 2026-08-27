#
# zsh-env: pre-load env hook
# Sourced by all zsh shells (interactive, login, scripts).
# Keep this file minimal — heavy logic belongs in zshrc.
#

# Per-machine pre-load overrides (env vars that tools read at init).
# Example use: NVM_DIR override, POWERLEVEL9K_INSTANT_PROMPT setting,
# SKIP_* flags, ZDOTDIR — anything that must be set before zshrc runs.
[[ -r "${HOME}/.zshenv.local" ]] && source "${HOME}/.zshenv.local"

# ssh-agent (conf.d は対話 shell 専用で zsh -c や ssh 越しの実行に効かないため、
# 全 shell が通るここに置く。ssh-add の終了値は 0=鍵あり / 1=agent 生存で鍵なし / 2 以上=接続不可)
ssh-add -l >/dev/null 2>&1
if (( $? > 1 )); then
  # 掴める agent が無いときだけ固定 socket に切り替える。既に生きている
  # agent を継承している shell の設定は奪わない。
  export SSH_AUTH_SOCK="${HOME}/.ssh/ssh-agent.sock"
  ssh-add -l >/dev/null 2>&1
  if (( $? > 1 )); then
    command rm -f "${SSH_AUTH_SOCK}"
    ssh-agent -a "${SSH_AUTH_SOCK}" >/dev/null 2>&1
  fi
fi

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
