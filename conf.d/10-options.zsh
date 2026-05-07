#
# Shell options, completion paths, fzf integration.
#

setopt noflowcontrol         # Disable Ctrl-S/Ctrl-Q flow control
setopt HIST_IGNORE_ALL_DUPS

[[ -d ~/.zsh/completion ]] && fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
