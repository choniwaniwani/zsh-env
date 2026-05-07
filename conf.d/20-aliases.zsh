#
# エイリアス。
#

alias "?s"="gh copilot suggest"
alias "?e"="gh copilot explain"
alias fzfv='fzf --preview "bat  --color=always --style=header,grid --line-range :100 {}"'

# pnpm 管理のプロジェクトで誤って npm を叩かないようにブロックする。
npm() {
  echo "pnpmを使ってください"
  return 1
}
