#
# 関数定義のみ。ロード時に副作用は出さない。
# 配線 (zle -N、bindkey、hook など) は 40-wiring.zsh で行う。
#

# Ctrl-R: fzf による履歴検索 + 削除機能つき。
# fzf の TUI 上でエントリを選んで Ctrl-D を押すと、$HISTFILE 上のその
# エントリを削除してリストも reload する。
# 注意: zsh の in-memory history (上矢印で辿るやつ) は API の制約で
# 一括 reload できないため、現セッション内では削除済みエントリも
# 上矢印で見える。完全に消したい場合は `exec zsh` で新シェルへ。
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

# Ctrl-Q: cdr 経由で最近の directory にジャンプする
fzf-cdr() {
  local selected_dir=$(cdr -l | awk '{ print $2 }' | fzf --reverse)
  if [[ -n "$selected_dir" ]]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}

# ssh ラッパー: 接続前後で iTerm のプロファイルを切り替える
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

  # fnm の --use-on-cd を擬似実装: .nvmrc のあるディレクトリに cd したら
  # Node のバージョンを自動切替する
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
