#
# zsh-env: main interactive shell configuration
#
# Layout:
#   1. Load prezto (the zsh framework at ~/.zprezto)
#   2. Source conf.d/*.zsh in lexical order (personal common config)
#   3. Source ~/.zshrc.local (per-machine, gitignored)
#

ZSH_ENV_DIR="${ZSH_ENV_DIR:-$HOME/.zsh-env}"

# 1. prezto framework. init.zsh activates modules per ~/.zpreztorc.
if [[ -s "${HOME}/.zprezto/init.zsh" ]]; then
  source "${HOME}/.zprezto/init.zsh"
fi

# 2. Personal common config, split by purpose under conf.d/.
for _zshenv_conf in "${ZSH_ENV_DIR}/conf.d"/*.zsh(N); do
  source "$_zshenv_conf"
done
unset _zshenv_conf

# 3. Per-machine override.
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
