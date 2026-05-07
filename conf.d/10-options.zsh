#
# シェルオプション、補完パス、fzf 連携。
#

setopt noflowcontrol         # Ctrl-S / Ctrl-Q のフロー制御を無効化
setopt HIST_IGNORE_ALL_DUPS  # 履歴中の重複を全削除

[[ -d ~/.zsh/completion ]] && fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
