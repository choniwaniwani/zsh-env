#!/usr/bin/env bash
#
# zsh-env bootstrap: check prerequisites and set up symlinks.
# Does NOT install software automatically — only checks and reports.
#

set -euo pipefail

# --- Resolve repo root (works even via curl|bash if invoked locally) ---
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

# --- OS detection (for install hints only) ---
detect_pkg_install_hint() {
  case "$(uname -s)" in
    Darwin) echo "brew install" ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then echo "sudo apt install"
      elif command -v dnf  >/dev/null 2>&1; then echo "sudo dnf install"
      elif command -v pacman >/dev/null 2>&1; then echo "sudo pacman -S"
      else echo "<your package manager>"
      fi ;;
    *) echo "<your package manager>" ;;
  esac
}
PKG_HINT="$(detect_pkg_install_hint)"

# --- Prerequisite check ---
section "Prerequisite check"

REQUIRED=(zsh git curl)
RECOMMENDED=(fzf bat)
OPTIONAL=(fnm nvm pyenv)

missing_required=()
missing_recommended=()
missing_optional=()

for cmd in "${REQUIRED[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    green "  ✓ $cmd"
  else
    red   "  ✗ $cmd  (required)"
    missing_required+=("$cmd")
  fi
done

for cmd in "${RECOMMENDED[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    green "  ✓ $cmd"
  else
    yellow "  ○ $cmd  (recommended)"
    missing_recommended+=("$cmd")
  fi
done

for cmd in "${OPTIONAL[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    green "  ✓ $cmd"
  fi
done
# Optional tools: only warn if NEITHER fnm nor nvm exists.
if ! command -v fnm >/dev/null 2>&1 && ! command -v nvm >/dev/null 2>&1; then
  missing_optional+=("fnm or nvm (Node version manager)")
fi
if ! command -v pyenv >/dev/null 2>&1; then
  missing_optional+=("pyenv (Python version manager)")
fi

if (( ${#missing_required[@]} > 0 )); then
  echo
  red "Required tools are missing: ${missing_required[*]}"
  echo "Install with:  $PKG_HINT ${missing_required[*]}"
  echo "Then re-run this script."
  exit 1
fi

if (( ${#missing_recommended[@]} > 0 )); then
  echo
  yellow "Recommended tools missing: ${missing_recommended[*]}"
  echo "  Install hint:  $PKG_HINT ${missing_recommended[*]}"
  echo "  (Setup will continue, but fzf widgets / fzfv alias won't work without these.)"
fi

if (( ${#missing_optional[@]} > 0 )); then
  echo
  yellow "Optional tools not detected: ${missing_optional[*]}"
  echo "  These are loaded conditionally — setup will continue."
fi

# --- Upstream prezto ---
section "Upstream prezto (~/.zprezto)"

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

# --- zsh-env managed symlinks ---
section "Symlinks managed by zsh-env"
backup_and_link "$REPO_ROOT/zshenv"    "$HOME/.zshenv"
backup_and_link "$REPO_ROOT/zshrc"     "$HOME/.zshrc"
backup_and_link "$REPO_ROOT/zpreztorc" "$HOME/.zpreztorc"
backup_and_link "$REPO_ROOT/p10k.zsh"  "$HOME/.p10k.zsh"

# --- prezto runcoms (zprofile/zlogin/zlogout are templates) ---
section "Symlinks to prezto runcoms"
backup_and_link "$PREZTO_DIR/runcoms/zprofile" "$HOME/.zprofile"
backup_and_link "$PREZTO_DIR/runcoms/zlogin"   "$HOME/.zlogin"
backup_and_link "$PREZTO_DIR/runcoms/zlogout"  "$HOME/.zlogout"

# --- Done ---
section "Done"
green "Setup complete."
echo
echo "Next steps:"
echo "  1. Open a new shell:           exec zsh"
echo "  2. (Optional) per-machine env: edit ~/.zshenv.local"
echo "  3. (Optional) per-machine rc:  edit ~/.zshrc.local"
echo "  4. (Optional) re-tune prompt:  p10k configure"
echo
echo "Layers:"
echo "  framework  : ~/.zprezto                          (don't edit)"
echo "  common     : ~/.zsh-env                          (this repo)"
echo "  per-machine: ~/.zshrc.local, ~/.zshenv.local     (gitignored)"
