#
# Wiring: register widgets / hooks / inits that depend on functions above.
#

# Custom widgets
zle -N fzf-select-history
bindkey '^r' fzf-select-history
zle -N fzf-cdr
bindkey '^q' fzf-cdr

# cdr: recent-directory tracking
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ':completion:*' recent-dirs-insert both
  zstyle ':chpwd:*' recent-dirs-default true
  zstyle ':chpwd:*' recent-dirs-max 1000
fi

# Node version manager: prefer fnm, fall back to nvm
if command -v fnm >/dev/null 2>&1; then
  setup-node-with-fnm
elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
  setup-node-with-nvm
fi

# ssh-agent
if ! pgrep -x "ssh-agent" >/dev/null; then
  eval "$(ssh-agent -s)"
fi
export SSH_AUTH_SOCK=$(find /tmp/ -type s -name 'agent.*' 2>/dev/null | head -n 1)

# Pyenv
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# VSCode shell integration
if [[ "${TERM_PROGRAM:-}" == "vscode" ]] && command -v code >/dev/null 2>&1; then
  VSCODE_ZSH_INTEGRATION="$(code --locate-shell-integration-path zsh 2>/dev/null || true)"
  if [[ -n "$VSCODE_ZSH_INTEGRATION" && -r "$VSCODE_ZSH_INTEGRATION" ]]; then
    source "$VSCODE_ZSH_INTEGRATION"
  fi
fi
