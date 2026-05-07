#
# Function definitions only. No side effects on load.
# Wiring (zle -N, bindkey, hooks) lives in 40-wiring.zsh.
#

# Ctrl-R: fuzzy history search with deletion support.
# Inside fzf, Ctrl-D removes the highlighted entry from $HISTFILE on disk
# and reloads the list. Note: zsh's in-memory history (used by up-arrow)
# is NOT cleared in the current session — the deleted entry will reappear
# until you start a new shell. `exec zsh` for a clean state.
fzf-select-history() {
  local lib="${ZSH_ENV_DIR:-$HOME/.zsh-env}/lib"
  local selected
  selected=$("$lib/zsh-env-history-list" | fzf \
    --height 40% --reverse --border \
    --prompt='history> ' \
    --query "${LBUFFER}" \
    --header 'Ctrl-D: 履歴から削除  /  Enter: 選択  /  Esc: キャンセル' \
    --bind "ctrl-d:execute-silent($lib/zsh-env-history-delete {})+reload($lib/zsh-env-history-list)")
  [[ -n $selected ]] || return
  BUFFER=$selected
  CURSOR=${#BUFFER}
  zle reset-prompt
}

# Ctrl-Q: jump to a recent directory via cdr
fzf-cdr() {
  local selected_dir=$(cdr -l | awk '{ print $2 }' | fzf --reverse)
  if [[ -n "$selected_dir" ]]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}

# ssh wrapper: switch iTerm profile around the connection
ssh() {
  echo -e "\033]50;SetProfile=$1\a"
  command ssh "$@"
  echo -e "\033]50;SetProfile=Default\a"
}

setup-node-with-fnm() {
  eval "$(fnm env --use-on-cd)"
}

setup-node-with-nvm() {
  source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
  nvm use default >/dev/null 2>&1

  # Mimic fnm's --use-on-cd: switch Node when entering a dir with .nvmrc
  autoload -U add-zsh-hook
  load-nvmrc() {
    local nvmrc_path="$(nvm_find_nvmrc)"
    [[ -z "$nvmrc_path" ]] && return
    local target_version=$(nvm version "$(cat "$nvmrc_path")")
    if [[ "$target_version" == "N/A" ]]; then
      nvm install
    elif [[ "$target_version" != "$(nvm version)" ]]; then
      nvm use
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
}
