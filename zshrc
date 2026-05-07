#
# zsh-env: main interactive shell configuration
#
# Layout:
#   1. Bootstrap upstream prezto (no-touch, lives at ~/.zprezto)
#   2. Load conf.d/*.zsh in lexical order
#   3. Source ~/.zshrc.local (machine-specific, gitignored)
#

ZSH_ENV_DIR="${ZSH_ENV_DIR:-$HOME/.zsh-env}"

# 1. Upstream prezto. Init script handles modules/options/aliases/prompt.
if [[ -s "${HOME}/.zprezto/init.zsh" ]]; then
  source "${HOME}/.zprezto/init.zsh"
fi

# 2. Personal common configs, split by purpose under conf.d/.
for _zshenv_conf in "${ZSH_ENV_DIR}/conf.d"/*.zsh(N); do
  source "$_zshenv_conf"
done
unset _zshenv_conf

# 3. Per-machine post-load override.
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
