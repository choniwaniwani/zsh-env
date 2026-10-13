#
# エイリアス。
#

alias "?s"="gh copilot suggest"
alias "?e"="gh copilot explain"
alias fzfv='fzf --preview "bat  --color=always --style=header,grid --line-range :100 {}"'

# pnpm 管理のプロジェクトで誤って npm を叩かないようにブロックする。
# npm 管理のプロジェクトでは ALLOW_NPM を立てて素通しする（direnv で worktree ごとに制御可能）。
npm() {
  if [[ -n "$ALLOW_NPM" ]]; then
    command npm "$@"
    return
  fi
  echo "pnpmを使ってください (npm プロジェクトなら ALLOW_NPM=1)"
  return 1
}
