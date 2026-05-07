#
# Environment: PATH, env vars, platform-specific setup, prompt.
#

# Platform-specific
if [[ $(uname) == 'Darwin' ]]; then
  [[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"
  export PATH=/opt/homebrew/bin:$PATH
fi

# PATH (front-most prepended last)
export PATH="$HOME/.nodebrew/current/bin:$PATH"
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"            # Claude Code native binary

# Tool roots
export NVM_DIR="$HOME/.nvm"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Tool defaults
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Debian/Ubuntu installs the 'bat' package as 'batcat'. Provide a 'bat' shim in
# ~/.local/bin so subprocess uses (e.g. fzf preview) see the standard name.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  hash -r 2>/dev/null
fi

# Prompt: run `p10k configure` to regenerate ~/.p10k.zsh
if [[ "$TERM" == "linux" ]]; then
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f %# '
else
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
fi
