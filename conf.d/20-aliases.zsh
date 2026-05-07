#
# Aliases.
#

alias "?s"="gh copilot suggest"
alias "?e"="gh copilot explain"
alias fzfv='fzf --preview "bat  --color=always --style=header,grid --line-range :100 {}"'

# Block accidental npm in pnpm-managed projects.
npm() {
  echo "pnpmを使ってください"
  return 1
}
