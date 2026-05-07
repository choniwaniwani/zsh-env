# zsh-env

choniwaniwani 用の zsh 環境。

## レイヤ構造

3 つのレイヤを明確に分離し、それぞれの所有者・更新方法を分けて管理する。

| 層 | 場所 | 役割 | 更新方法 |
|---|---|---|---|
| Framework | `~/.zprezto` | sorin-ionescu/prezto をそのまま clone した zsh フレームワーク | `git pull` で追従 |
| Personal common | `~/.zsh-env` (このリポジトリ) | 自分のすべてのマシンで共有する設定 | このリポジトリに commit |
| Per-machine | `~/.zshrc.local` / `~/.zshenv.local` | マシン固有の差分 | gitignore 済み、各マシンで手書き |

設計方針:

- prezto 本体は一切編集しない。改造したくなったら個人設定側 (`~/.zsh-env`) で上書きする。
- マシン固有のものは絶対に Personal common に混ぜない。`*.local` ファイルへ。

## 前提条件

### 必須

| ツール | 用途 | 確認 |
|---|---|---|
| `zsh` | シェル本体 | `zsh --version` |
| `git` | clone と更新 | `git --version` |
| `curl` | 各種DL | `curl --version` |

### 推奨（無くても動くが一部機能が無効）

| ツール | 何が使えなくなるか |
|---|---|
| `fzf` | Ctrl-R の履歴検索、Ctrl-Q の cdr ジャンプ、`fzfv` alias |
| `bat` | `fzfv` のシンタックスハイライト付きプレビュー |

### オプション（環境に応じて）

| ツール | 用途 |
|---|---|
| `fnm` | Node version manager（推奨。`.nvmrc` 自動切替が組み込み） |
| `nvm` | fnm が無い場合の fallback |
| `pyenv` | Python version manager |
| Nerd Font | powerlevel10k のグリフ表示用。ターミナル側でフォント設定が必要 |

## インストール

```bash
git clone https://github.com/choniwaniwani/zsh-env.git ~/.zsh-env
~/.zsh-env/bootstrap.sh
exec zsh
```

`bootstrap.sh` がやること:

1. 前提条件をチェック（必須が無ければ OS 別のインストールコマンドを表示して終了）
2. `sorin-ionescu/prezto` を `~/.zprezto` に `git clone --recursive`（存在しない場合のみ）
3. 既存の dotfile があればタイムスタンプ付きで backup
4. シンボリックリンクを張る:
   - `~/.zshenv`     → `~/.zsh-env/zshenv`
   - `~/.zshrc`      → `~/.zsh-env/zshrc`
   - `~/.zpreztorc`  → `~/.zsh-env/zpreztorc`
   - `~/.p10k.zsh`   → `~/.zsh-env/p10k.zsh`
   - `~/.zprofile`   → `~/.zprezto/runcoms/zprofile`
   - `~/.zlogin`     → `~/.zprezto/runcoms/zlogin`
   - `~/.zlogout`    → `~/.zprezto/runcoms/zlogout`

ソフトウェアの自動インストールはしない（OS 別の差を吸収しない方針）。

## ファイル構成

```
zsh-env/
├── README.md
├── LICENSE
├── bootstrap.sh         # 前提チェック + symlink セットアップ
├── zshenv               # ~/.zshenv 用。.zshenv.local を source する
├── zshrc                # ~/.zshrc 用。prezto + conf.d + .zshrc.local を順に load
├── zpreztorc            # ~/.zpreztorc 用。prezto モジュール構成
├── p10k.zsh             # ~/.p10k.zsh 用。powerlevel10k テーマ設定
└── conf.d/              # zshrc から lexical 順に source される
    ├── 00-env.zsh       # PATH, env vars, prompt
    ├── 10-options.zsh   # setopt, fpath, compinit, fzf
    ├── 20-aliases.zsh   # alias 群
    ├── 30-functions.zsh # 関数定義（副作用なし）
    └── 40-wiring.zsh    # zle/bindkey/hook/init（30 の関数を使う）
```

## ロード順

```
~/.zshenv  ──→ ~/.zshenv.local            (全シェル共通の env)
                  │
~/.zshrc   ──→ ~/.zprezto/init.zsh        (prezto 本体)
            ──→ conf.d/*.zsh (lexical)    (個人共通)
            ──→ ~/.zshrc.local            (マシン固有、最後に勝つ)
```

## マシンごとに違う設定をしたい時

### 環境変数の上書き / 読み込み前 hook

`~/.zshenv.local` に書く。`zshenv` の末尾で source される。

```zsh
# ~/.zshenv.local の例
export NVM_DIR="/custom/path/to/nvm"
export POWERLEVEL9K_INSTANT_PROMPT=quiet
SKIP_PYENV=1
```

### alias / 関数 / bindkey などの上書き

`~/.zshrc.local` に書く。`zshrc` の末尾で source されるので、ここに書いた定義はすべての個人共通設定に勝つ。

```zsh
# ~/.zshrc.local の例
alias work-vpn='sudo openconnect ...'
alias deploy='cd ~/work/foo && ./deploy.sh'
```

両ファイルは `.gitignore` で除外済みなので commit されない。

## アップデート

```bash
# 個人共通設定の更新
cd ~/.zsh-env && git pull

# zsh フレームワーク (prezto) の更新
cd ~/.zprezto && git pull && git submodule update --init --recursive
```

## 既存の dotfile が衝突した場合

`bootstrap.sh` は既存の `~/.zshrc` などを `${HOME}/.zshrc.backup-YYYYMMDD-HHMMSS` の形式で退避してから symlink を張る。`~/.zprezto` が `sorin-ionescu/prezto` 以外の origin を持っていた場合も同様にディレクトリごと退避される。

退避ファイルは bootstrap が生成する。残しておくか削除するかは利用者の判断。

## License

MIT
