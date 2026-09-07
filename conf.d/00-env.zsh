#
# 環境設定: PATH、環境変数、プラットフォーム別の初期化、プロンプト。
#

# プラットフォーム別
if [[ $(uname) == 'Darwin' ]]; then
  [[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"
  export PATH=/opt/homebrew/bin:$PATH
fi

# PATH (後に prepend したものが先頭になる)
export PATH="$HOME/.nodebrew/current/bin:$PATH"
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"            # Claude Code native binary
export PATH="${ZSH_ENV_DIR:-$HOME/.zsh-env}/lib:$PATH"  # zsh-env の helper scripts (editor 等)

# 各ツールのルート
export NVM_DIR="$HOME/.nvm"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# ツールのデフォルト
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
# Claude Code は起動中ターミナルのタイトル (tmux では pane title) を会話の要約に書き換える。
# タブ名は常にマシン名にしたいので止める (prezto の terminal module がマシン名を書く)
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1
# Claude Code は tmux の passthrough でターミナルのタブ名を直接書き換える。
# タブ名は常にマシン名にしたいので (prezto の tab-title / tmux の set-titles)、これを止める
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

# Debian/Ubuntu の 'bat' パッケージは 'batcat' という名前のバイナリを入れる。
# ~/.local/bin に 'bat' という名前の symlink を作って、サブプロセス
# (fzf の preview など) からも標準名で呼べるようにする。
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  hash -r 2>/dev/null
fi

# EDITOR / VISUAL: VSCode wrapper (lib/editor) を標準エディタにする。
# git commit / git rebase -i / crontab -e / Ctrl+x Ctrl+e から呼ばれた時に
# 起動中の VSCode で開く。VSCode が無ければ nano 等へ fallback する。
export EDITOR="${ZSH_ENV_DIR:-$HOME/.zsh-env}/lib/editor"
export VISUAL="$EDITOR"

# プロンプト: ~/.p10k.zsh を再生成したいときは `p10k configure`
if [[ "$TERM" == "linux" ]]; then
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '
else
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
fi
