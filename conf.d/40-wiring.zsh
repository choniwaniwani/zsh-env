#
# 配線: 上で定義した関数を使う widget 登録 / hook / init をここに集める。
#

# カスタム widget
zle -N fzf-select-history
bindkey '^r' fzf-select-history
zle -N fzf-cdr
bindkey '^q' fzf-cdr

# cdr: 最近 cd した directory を記録
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ':completion:*' recent-dirs-insert both
  zstyle ':chpwd:*' recent-dirs-default true
  zstyle ':chpwd:*' recent-dirs-max 1000
fi

# Node version manager: fnm を優先、なければ nvm へ fallback
if command -v fnm >/dev/null 2>&1; then
  setup-node-with-fnm
elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
  setup-node-with-nvm
fi

# ssh-agent: 動いてなければ起動して、agent socket を環境変数に登録
if ! pgrep -x "ssh-agent" >/dev/null; then
  eval "$(ssh-agent -s)"
fi
if [[ ! -S ${SSH_AUTH_SOCK:-} ]]; then
  # socket は必ず ${TMPDIR}/ssh-XXXXXX/agent.<pid> の深さ 2 にある
  export SSH_AUTH_SOCK=$(find "${TMPDIR:-/tmp}" -maxdepth 2 -type s -name 'agent.*' -print -quit 2>/dev/null)
fi

# Pyenv
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# VSCode シェル統合 (コマンドの実行履歴・現在ディレクトリを VSCode 側に通知)
if [[ "${TERM_PROGRAM:-}" == "vscode" ]] && command -v code >/dev/null 2>&1; then
  VSCODE_ZSH_INTEGRATION="$(code --locate-shell-integration-path zsh 2>/dev/null || true)"
  if [[ -n "$VSCODE_ZSH_INTEGRATION" && -r "$VSCODE_ZSH_INTEGRATION" ]]; then
    source "$VSCODE_ZSH_INTEGRATION"
  fi
fi
