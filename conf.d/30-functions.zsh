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
  # list は "<物理行番号>\t<表示>" を出す。番号列 (1列目) は表示から隠し、
  # Ctrl-D には {1} (番号) を渡して確実に削除する。
  # --nth で検索列を絞ると、fzf が --with-nth 変換後の列を見て 0 件になる。
  # 検索は全体に効かせる (番号は数字なのでコマンド検索に実害はない)。
  selected=$("$lib/zsh-env-history-list" | fzf \
    --height 40% --reverse --border \
    --delimiter='\t' --with-nth='2..' \
    --prompt='history> ' \
    --query "${LBUFFER}" \
    --header 'Ctrl-D: 履歴から削除  /  Enter: 選択  /  Esc: キャンセル' \
    --bind "ctrl-d:execute-silent($lib/zsh-env-history-delete {1})+reload($lib/zsh-env-history-list)")
  # 選択時のみ BUFFER を差し替える。キャンセル (Esc) でも reset-prompt は
  # 必ず通す — 通さないと fzf 描画後にプロンプトが再描画されず記号が消える。
  if [[ -n $selected ]]; then
    BUFFER=${selected#*$'\t'}   # 番号列を落としてコマンド部分だけ採用
    CURSOR=${#BUFFER}
  fi
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

# macOS のみ: claude / codex を必ず tmux 内で起動する。
# handoff (/clear → 復帰) は pane をプロセスごと張り替える respawn 方式のため、
# agent が tmux 外に居ると復帰できない。起動時点で pane を持たせておく。
# Linux 側の agent は role-boot が pane 内で起こすので、この包みは要らない。
#
# 関数なので対話シェルからの起動だけに効く。script や絶対パス経由の起動は
# 素通りするので、既存の自動起動経路 (role-boot、restart worker 等) は変わらない。
#
# 注意: 既存 tmux server があると、新しい session はその server の環境を継ぐ。
# 起動するバイナリ自体は下で絶対パスに解決してから渡すため PATH の古さに
# 影響されないが、子プロセスが見る環境は server 側のものになる。
if [[ $(uname) == 'Darwin' ]]; then
  _run-in-tmux() {
    local bin=${commands[$1]}
    [[ -n $bin ]] || { print -u2 "$1: command not found"; return 127 }
    shift
    if [[ -z $TMUX ]] && (( $+commands[tmux] )); then
      # 起動時の argv を session 環境に残す。handoff の respawn はこれを使う。
      # 走っているプロセスの argv は client 自身が足す --resume を含んでおり、
      # そのまま復元すると捨てたはずの文脈を読み直してしまう。
      local -a launch_argv=("$bin" "$@")
      tmux new-session -c "$PWD" -e "AGENT_LAUNCH_ARGV=${(j: :)${(@q)launch_argv}}" -- "$bin" "$@"
    else
      "$bin" "$@"
    fi
  }

  claude() { _run-in-tmux claude "$@" }
  codex()  { _run-in-tmux codex "$@" }
fi
