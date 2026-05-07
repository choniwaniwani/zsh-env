#!/usr/bin/env bash
#
# zsh-env bootstrap: install missing prerequisites and set up symlinks.
# Required tools that are missing will be installed via the detected package
# manager. If installation cannot proceed, the script exits with an error.
#

set -euo pipefail

# --- Resolve repo root ---
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PREZTO_DIR="${HOME}/.zprezto"
PREZTO_REPO="https://github.com/sorin-ionescu/prezto.git"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# --- Output helpers ---
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
blue()   { printf '\033[34m%s\033[0m\n' "$*"; }
section() { echo; blue "── $* ──"; }

OS_KIND="$(uname -s)"

# --- Package install ---
attempt_install_pkg() {
  local pkg="$1"
  case "$OS_KIND" in
    Darwin)
      command -v brew >/dev/null 2>&1 || {
        echo "    Homebrew not found. Install from https://brew.sh first." >&2
        return 1
      }
      brew install "$pkg" ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y "$pkg"
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$pkg"
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm "$pkg"
      else
        echo "    No supported package manager (apt-get / dnf / pacman) found." >&2
        return 1
      fi ;;
    *)
      echo "    Unsupported OS: $OS_KIND" >&2
      return 1 ;;
  esac
}

# --- Nerd Font ---
# Font rendering happens on the machine running the terminal application,
# which may differ from where this script runs (e.g. SSH). The only reliable
# check is visual: print glyphs and ask the user.

visual_nerd_font_check() {
  echo
  echo "  Sample glyphs (Powerline + Nerd):"
  printf "           \n"
  echo "  These should render as solid arrows and recognizable icons,"
  echo "  not as boxes or tofu (□)."
  echo

  if [[ "${ASSUME_NERD_FONT:-0}" == "1" ]]; then
    green "  ✓ assumed via ASSUME_NERD_FONT=1"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    yellow "  ! non-interactive run — cannot ask visually."
    yellow "    Set ASSUME_NERD_FONT=1 to skip this check."
    return 1
  fi

  local ans
  read -r -p "  Do they render correctly? [y/N] " ans
  [[ "$ans" =~ ^[Yy] ]]
}

attempt_install_nerd_font() {
  case "$OS_KIND" in
    Darwin)
      command -v brew >/dev/null 2>&1 || {
        echo "    Homebrew not found. Install from https://brew.sh first." >&2
        return 1
      }
      brew install --cask font-meslo-lg-nerd-font ;;
    Linux)
      local font_dir="$HOME/.local/share/fonts"
      mkdir -p "$font_dir"
      local base="https://github.com/romkatv/powerlevel10k-media/raw/master"
      local files=(
        "MesloLGS%20NF%20Regular.ttf"
        "MesloLGS%20NF%20Bold.ttf"
        "MesloLGS%20NF%20Italic.ttf"
        "MesloLGS%20NF%20Bold%20Italic.ttf"
      )
      for f in "${files[@]}"; do
        local out="$font_dir/$(echo "$f" | sed 's/%20/ /g')"
        echo "    Downloading $(basename "$out")..."
        curl -fsSL "$base/$f" -o "$out" || return 1
      done
      command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null 2>&1 || true
      ;;
    *)
      echo "    Unsupported OS: $OS_KIND" >&2
      return 1 ;;
  esac
}

# --- Prerequisite check ---
section "Prerequisite check"

REQUIRED=(zsh git curl fzf bat)
unresolved_required=()

for cmd in "${REQUIRED[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    green "  ✓ $cmd"
    continue
  fi
  yellow "  ○ $cmd missing — installing..."
  if attempt_install_pkg "$cmd" && command -v "$cmd" >/dev/null 2>&1; then
    green "  ✓ $cmd installed"
  else
    red   "  ✗ $cmd installation failed"
    unresolved_required+=("$cmd")
  fi
done

# Nerd Font (visual check — see comment block above visual_nerd_font_check)
section "Nerd Font check"
if visual_nerd_font_check; then
  green "  ✓ Nerd Font OK"
else
  echo
  yellow "  Nerd Font does not render. The font lives on the machine running"
  yellow "  your terminal application — not necessarily where this script runs."
  echo
  if [[ -t 0 ]]; then
    read -r -p "  Install MesloLGS NF on THIS machine now? [y/N] " ans
    if [[ "$ans" =~ ^[Yy] ]]; then
      if attempt_install_nerd_font; then
        echo
        green "  ✓ Font files installed."
        echo "  Configure your terminal application to use 'MesloLGS NF',"
        echo "  then re-run: $0"
        exit 0
      else
        red "  ✗ Install failed."
      fi
    fi
  fi
  cat <<'EOF'

  Manual setup:
    macOS:   brew install --cask font-meslo-lg-nerd-font
    Linux:   download MesloLGS NF (4 files: Regular / Bold / Italic / Bold Italic)
             from https://github.com/romkatv/powerlevel10k-media
             into ~/.local/share/fonts/  and run 'fc-cache -f'
  Then set 'MesloLGS NF' as the font in your terminal application,
  and re-run this script.
EOF
  exit 1
fi

# Optional tools: report only
echo
for cmd in fnm nvm pyenv; do
  if command -v "$cmd" >/dev/null 2>&1; then
    green "  ✓ $cmd (optional)"
  fi
done
if ! command -v fnm >/dev/null 2>&1 && ! command -v nvm >/dev/null 2>&1; then
  yellow "  ○ fnm or nvm  (optional, Node version manager)"
fi
if ! command -v pyenv >/dev/null 2>&1; then
  yellow "  ○ pyenv  (optional, Python version manager)"
fi

if (( ${#unresolved_required[@]} > 0 )); then
  echo
  red "Cannot proceed — the following required prerequisites could not be installed:"
  for item in "${unresolved_required[@]}"; do
    red "  - $item"
  done
  echo "Install them manually and re-run this script."
  exit 1
fi

# --- prezto framework ---
section "prezto framework (~/.zprezto)"

if [[ -d "$PREZTO_DIR/.git" ]]; then
  prezto_origin="$(git -C "$PREZTO_DIR" config --get remote.origin.url 2>/dev/null || echo unknown)"
  if [[ "$prezto_origin" == *"sorin-ionescu/prezto"* ]]; then
    green "  ✓ already cloned ($prezto_origin)"
  else
    yellow "  ! origin is not sorin-ionescu/prezto: $prezto_origin"
    yellow "    Backing up the existing directory and cloning the expected repo."
    backup="${PREZTO_DIR}.backup-${TIMESTAMP}"
    echo "  Renaming $PREZTO_DIR → $backup"
    mv "$PREZTO_DIR" "$backup"
    echo "  Cloning $PREZTO_REPO ..."
    git clone --recursive "$PREZTO_REPO" "$PREZTO_DIR"
    green "  ✓ prezto cloned"
  fi
elif [[ -e "$PREZTO_DIR" ]]; then
  red "  ✗ $PREZTO_DIR exists but is not a git repo. Aborting."
  exit 1
else
  echo "  Cloning $PREZTO_REPO ..."
  git clone --recursive "$PREZTO_REPO" "$PREZTO_DIR"
  green "  ✓ prezto cloned"
fi

# --- Symlink helpers ---
backup_and_link() {
  local target="$1"
  local link="$2"
  if [[ -L "$link" ]]; then
    local current; current="$(readlink "$link")"
    if [[ "$current" == "$target" ]]; then
      green "  ✓ $link → $target  (already linked)"
      return
    fi
    yellow "  ! $link is a symlink to $current — replacing"
    rm "$link"
  elif [[ -e "$link" ]]; then
    local backup="${link}.backup-${TIMESTAMP}"
    yellow "  ! $link exists — backing up to $backup"
    mv "$link" "$backup"
  fi
  ln -s "$target" "$link"
  green "  ✓ $link → $target"
}

section "Symlinks managed by zsh-env"
backup_and_link "$REPO_ROOT/zshenv"    "$HOME/.zshenv"
backup_and_link "$REPO_ROOT/zshrc"     "$HOME/.zshrc"
backup_and_link "$REPO_ROOT/zpreztorc" "$HOME/.zpreztorc"
backup_and_link "$REPO_ROOT/p10k.zsh"  "$HOME/.p10k.zsh"

section "Symlinks to prezto runcoms"
backup_and_link "$PREZTO_DIR/runcoms/zprofile" "$HOME/.zprofile"
backup_and_link "$PREZTO_DIR/runcoms/zlogin"   "$HOME/.zlogin"
backup_and_link "$PREZTO_DIR/runcoms/zlogout"  "$HOME/.zlogout"

section "Done"
green "Setup complete."
echo
echo "Next steps:"
echo "  1. Open a new shell:           exec zsh"
echo "  2. Configure your terminal app to use 'MesloLGS NF' as its font"
echo "  3. (Optional) per-machine env: edit ~/.zshenv.local"
echo "  4. (Optional) per-machine rc:  edit ~/.zshrc.local"
echo "  5. (Optional) re-tune prompt:  p10k configure"
echo
echo "Layers:"
echo "  framework  : ~/.zprezto                          (don't edit)"
echo "  common     : ~/.zsh-env                          (this repo)"
echo "  per-machine: ~/.zshrc.local, ~/.zshenv.local     (gitignored)"
