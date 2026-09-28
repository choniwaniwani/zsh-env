#
# シェルオプション、補完パス、fzf 連携。
#

setopt noflowcontrol         # Ctrl-S / Ctrl-Q のフロー制御を無効化
setopt HIST_IGNORE_ALL_DUPS  # 履歴中の重複を全削除

# agent（Claude Code / Codex）は非対話の login shell から zshrc を source して、
# option を shell snapshot に写す。その shell では clobber を許し、`>` が弾かれて
# command ごと走らない事故を無くす。人間の対話 shell は prezto の既定（noclobber）のまま。
[[ -o interactive ]] || setopt clobber

[[ -d ~/.zsh/completion ]] && fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
