#!/usr/bin/env bash
#
# zsh-env bootstrap: 必須ツールのインストールと symlink 展開を行う。
# 必須ツールが不足していれば自動インストールを試み、失敗時は exit する。
#

set -euo pipefail

# Ensure ~/.local/bin is on PATH for symlinks we may create during install fixups.
export PATH="$HOME/.local/bin:$PATH"

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

# --- Session detection ---
# このスクリプトを実行している場所が「ターミナルアプリが動いているマシン」と
# 同じか、それとも SSH 接続先のサーバ側か、を判別する。フォントの扱いが分岐する。
is_ssh_session() {
  [[ -n "${SSH_CLIENT:-}" ]] || [[ -n "${SSH_CONNECTION:-}" ]] || [[ -n "${SSH_TTY:-}" ]]
}

# --- Package install ---
attempt_install_pkg() {
  local pkg="$1"
  case "$OS_KIND" in
    Darwin)
      command -v brew >/dev/null 2>&1 || {
        echo "    Homebrew が見つかりません。https://brew.sh からインストールしてください。" >&2
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
        echo "    対応するパッケージマネージャ (apt-get / dnf / pacman) が見つかりません。" >&2
        return 1
      fi ;;
    *)
      echo "    未対応の OS: $OS_KIND" >&2
      return 1 ;;
  esac
}

# 一部のディストリではパッケージ名と実バイナリ名が違う。例えば Debian/Ubuntu
# では 'bat' パッケージは 'batcat' バイナリをインストールする。導入されている
# かのチェックでは別名も許容する。命名を統一するシム作成は conf.d 側で実施。
verify_installed() {
  local cmd="$1"
  case "$cmd" in
    bat) command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1 ;;
    *)   command -v "$cmd" >/dev/null 2>&1 ;;
  esac
}

# --- Nerd Font ---
# フォントレンダリングは「ターミナルアプリが動いているマシン」のフォント設定で
# 決まるため、シェル側からは判定不能。サンプル glyph を表示して目視確認する。

visual_nerd_font_check() {
  echo
  echo "  サンプル glyph:"
  # Powerline arrows: U+E0B0/E0B2/E0B4/E0B6
  printf '    Powerline:  %s\n' $'      '
  # Nerd Font icons: GitHub / Ubuntu / Apple / JS / Snowflake / Folder
  printf '    Nerd Font:  %s\n' $'          '
  echo "  矢印とアイコンが正しく表示されているはずです (豆腐 □ ではなく)。"
  echo

  if [[ "${ASSUME_NERD_FONT:-0}" == "1" ]]; then
    green "  ✓ ASSUME_NERD_FONT=1 によりスキップ"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    yellow "  ! 非対話実行のため目視確認できません。"
    yellow "    ASSUME_NERD_FONT=1 を設定するとスキップ可能です。"
    return 1
  fi

  local ans
  read -r -p "  正しく表示されていますか？ [y/N] " ans
  [[ "$ans" =~ ^[Yy] ]]
}

attempt_install_nerd_font() {
  case "$OS_KIND" in
    Darwin)
      command -v brew >/dev/null 2>&1 || {
        echo "    Homebrew が見つかりません。https://brew.sh からインストールしてください。" >&2
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
        echo "    ダウンロード中: $(basename "$out")"
        curl -fsSL "$base/$f" -o "$out" || return 1
      done
      command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null 2>&1 || true
      ;;
    *)
      echo "    未対応の OS: $OS_KIND" >&2
      return 1 ;;
  esac
}

# --- Prerequisite check ---
section "前提条件チェック"

REQUIRED=(zsh git curl fzf bat)
unresolved_required=()

for cmd in "${REQUIRED[@]}"; do
  if verify_installed "$cmd"; then
    green "  ✓ $cmd"
    continue
  fi
  yellow "  ○ $cmd が見つかりません — インストール中..."
  if attempt_install_pkg "$cmd" && verify_installed "$cmd"; then
    green "  ✓ $cmd をインストールしました"
  else
    red   "  ✗ $cmd のインストールに失敗"
    unresolved_required+=("$cmd")
  fi
done

# --- Nerd Font check ---
section "Nerd Font チェック"
if visual_nerd_font_check; then
  green "  ✓ Nerd Font OK"
else
  echo
  if is_ssh_session; then
    # SSH 接続先で実行中: フォントは接続元 (ローカル) にインストールが必要
    yellow "  Nerd Font が表示されていません。"
    echo
    cat <<'EOF'
  このセッションは SSH 経由なので、フォントは「接続元のマシン
  (= 今あなたが操作中のマシン)」にインストールしてください。

  接続元マシンで以下を実行:
    macOS:   brew install --cask font-meslo-lg-nerd-font
    Linux:   https://github.com/romkatv/powerlevel10k-media から
             MesloLGS NF (Regular / Bold / Italic / Bold Italic の 4 ファイル) を
             ~/.local/share/fonts/ に置き、fc-cache -f を実行

  続いて、接続元のターミナルアプリの font 設定で 'MesloLGS NF' を選択し、
  改めて SSH 接続してこのスクリプトを再実行してください。
EOF
    exit 1
  else
    # ローカルで実行中: このマシンに font を入れれば直る可能性が高い
    yellow "  Nerd Font が表示されていません。"
    yellow "  このマシンでターミナルアプリが動いているなら、フォントを入れて"
    yellow "  ターミナル設定で選択することで解決します。"
    echo
    if [[ -t 0 ]]; then
      read -r -p "  このマシンに MesloLGS NF をインストールしますか？ [y/N] " ans
      if [[ "$ans" =~ ^[Yy] ]]; then
        if attempt_install_nerd_font; then
          echo
          green "  ✓ フォントファイルをインストールしました。"
          echo "  次にターミナルアプリの font 設定で 'MesloLGS NF' を選択し、"
          echo "  このスクリプトを再実行してください: $0"
          exit 0
        else
          red "  ✗ インストールに失敗しました。"
        fi
      fi
    fi
    cat <<'EOF'

  手動セットアップ:
    macOS:   brew install --cask font-meslo-lg-nerd-font
    Linux:   https://github.com/romkatv/powerlevel10k-media から MesloLGS NF
             (Regular / Bold / Italic / Bold Italic の 4 ファイル) を
             ~/.local/share/fonts/ に置き、fc-cache -f を実行
  そのうえでターミナルアプリの font 設定で 'MesloLGS NF' を選択し、
  このスクリプトを再実行してください。
EOF
    exit 1
  fi
fi

# --- Optional tools (report only) ---
echo
for cmd in fnm nvm pyenv; do
  if command -v "$cmd" >/dev/null 2>&1; then
    green "  ✓ $cmd (オプション)"
  fi
done
if ! command -v fnm >/dev/null 2>&1 && ! command -v nvm >/dev/null 2>&1; then
  yellow "  ○ fnm または nvm  (オプション、Node version manager)"
fi
if ! command -v pyenv >/dev/null 2>&1; then
  yellow "  ○ pyenv  (オプション、Python version manager)"
fi

if (( ${#unresolved_required[@]} > 0 )); then
  echo
  red "続行できません — 以下の必須ツールをインストールできませんでした:"
  for item in "${unresolved_required[@]}"; do
    red "  - $item"
  done
  echo "手動でインストールしてからこのスクリプトを再実行してください。"
  exit 1
fi

# --- prezto framework ---
section "prezto フレームワーク (~/.zprezto)"

if [[ -d "$PREZTO_DIR/.git" ]]; then
  prezto_origin="$(git -C "$PREZTO_DIR" config --get remote.origin.url 2>/dev/null || echo unknown)"
  if [[ "$prezto_origin" == *"sorin-ionescu/prezto"* ]]; then
    green "  ✓ 既に clone 済み ($prezto_origin)"
  else
    yellow "  ! origin が sorin-ionescu/prezto ではありません: $prezto_origin"
    yellow "    既存ディレクトリを backup してから期待される repo を clone します。"
    backup="${PREZTO_DIR}.backup-${TIMESTAMP}"
    echo "  リネーム: $PREZTO_DIR → $backup"
    mv "$PREZTO_DIR" "$backup"
    echo "  $PREZTO_REPO を clone 中..."
    git clone --recursive "$PREZTO_REPO" "$PREZTO_DIR"
    green "  ✓ prezto を clone しました"
  fi
elif [[ -e "$PREZTO_DIR" ]]; then
  red "  ✗ $PREZTO_DIR は存在しますが git repo ではありません。中止します。"
  exit 1
else
  echo "  $PREZTO_REPO を clone 中..."
  git clone --recursive "$PREZTO_REPO" "$PREZTO_DIR"
  green "  ✓ prezto を clone しました"
fi

# --- Symlink helpers ---
backup_and_link() {
  local target="$1"
  local link="$2"
  if [[ -L "$link" ]]; then
    local current; current="$(readlink "$link")"
    if [[ "$current" == "$target" ]]; then
      green "  ✓ $link → $target  (既にリンク済み)"
      return
    fi
    yellow "  ! $link は $current への symlink — 張り替えます"
    rm "$link"
  elif [[ -e "$link" ]]; then
    local backup="${link}.backup-${TIMESTAMP}"
    yellow "  ! $link が既に存在 — $backup へ退避"
    mv "$link" "$backup"
  fi
  ln -s "$target" "$link"
  green "  ✓ $link → $target"
}

section "zsh-env が管理する symlink"
backup_and_link "$REPO_ROOT/zshenv"    "$HOME/.zshenv"
backup_and_link "$REPO_ROOT/zshrc"     "$HOME/.zshrc"
backup_and_link "$REPO_ROOT/zpreztorc" "$HOME/.zpreztorc"
backup_and_link "$REPO_ROOT/p10k.zsh"  "$HOME/.p10k.zsh"

section "prezto runcoms への symlink"
backup_and_link "$PREZTO_DIR/runcoms/zprofile" "$HOME/.zprofile"
backup_and_link "$PREZTO_DIR/runcoms/zlogin"   "$HOME/.zlogin"
backup_and_link "$PREZTO_DIR/runcoms/zlogout"  "$HOME/.zlogout"

section "完了"
green "セットアップが完了しました。"
echo
echo "次のステップ:"
echo "  1. 新しいシェルを起動:                    exec zsh"
echo "  2. ターミナルアプリの font 設定で 'MesloLGS NF' を選択"
echo "  3. (オプション) マシン固有 env:           edit ~/.zshenv.local"
echo "  4. (オプション) マシン固有 zshrc:         edit ~/.zshrc.local"
echo "  5. (オプション) prompt の再調整:          p10k configure"
echo
echo "レイヤ構造:"
echo "  framework   : ~/.zprezto                          (編集しない)"
echo "  common      : ~/.zsh-env                          (このリポジトリ)"
echo "  per-machine : ~/.zshrc.local, ~/.zshenv.local     (gitignore 済み)"
