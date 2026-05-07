# zsh-env

choniwaniwani 用の zsh 環境。

## レイヤ構造

| 層 | 場所 | 触る人 |
|---|---|---|
| **Upstream** | `~/.zprezto` (sorin-ionescu/prezto を pristine clone) | 本家のみ。`git pull` で更新 |
| **Personal common** | `~/.zsh-env` (このリポジトリ) | 自分。複数マシンで共有 |
| **Per-machine** | `~/.zshrc.local` / `~/.zshenv.local` | 自分。マシンごとに gitignore |

> **prezto は本家 repo を直接使う**（fork 経由しない）。個人設定は全部このリポジトリに分離してあるので、本家 prezto をそのまま `git pull` するだけで追従できる。

## 前提条件

### 必須

| ツール | 用途 | 確認 |
|---|---|---|
| `zsh` | シェル本体 | `zsh --version` |
| `git` | prezto clone | `git --version` |
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
| `powerlevel10k` フォント | 美麗プロンプト用（手動でターミナルにフォント設定） |

## インストール

```bash
git clone https://github.com/choniwaniwani/zsh-env.git ~/.zsh-env
~/.zsh-env/bootstrap.sh
exec zsh
```

`bootstrap.sh` がやること:

1. 前提条件をチェック（必須が無ければ OS 別のインストールコマンドを表示して終了）
2. 本家 prezto を `~/.zprezto` に `git clone --recursive`（既に存在する場合はスキップ）
3. 既存の `~/.zshrc` 等があればタイムスタンプ付きで backup
4. シンボリックリンク作成:
   - `~/.zshenv` → `~/.zsh-env/zshenv`
   - `~/.zshrc` → `~/.zsh-env/zshrc`
   - `~/.zpreztorc` → `~/.zsh-env/zpreztorc`
   - `~/.p10k.zsh` → `~/.zsh-env/p10k.zsh`
   - `~/.zprofile` / `~/.zlogin` / `~/.zlogout` → `~/.zprezto/runcoms/*`（本家のテンプレ）

ソフトウェアの自動インストールはしない（OS 別の差を吸収しない方針）。

## ファイル構成

```
zsh-env/
├── README.md
├── LICENSE
├── bootstrap.sh        # 前提チェック + symlink セットアップ
├── zshenv              # ~/.zshenv 用。.zshenv.local を source するだけ
├── zshrc               # ~/.zshrc 用。prezto + conf.d + .zshrc.local を順に load
├── zpreztorc           # ~/.zpreztorc 用。prezto モジュール構成
├── p10k.zsh            # ~/.p10k.zsh 用。powerlevel10k テーマ設定
└── conf.d/             # zshrc から lexical 順に source される
    ├── 00-env.zsh      # PATH, env vars, prompt
    ├── 10-options.zsh  # setopt, fpath, compinit, fzf
    ├── 20-aliases.zsh  # alias 群
    ├── 30-functions.zsh # 関数定義（副作用なし）
    └── 40-wiring.zsh    # zle/bindkey/hook/init（30の関数を使う）
```

## マシンごとに違う設定をしたい時

### 環境変数の上書き / 読み込み前 hook

`~/.zshenv.local` に書く。zshenv の最後に `source` される。

```zsh
# ~/.zshenv.local の例
export NVM_DIR="/custom/path/to/nvm"
export POWERLEVEL9K_INSTANT_PROMPT=quiet
SKIP_PYENV=1
```

### alias / 関数 / bindkey などの上書き

`~/.zshrc.local` に書く。zshrc の最後に `source` される。

```zsh
# ~/.zshrc.local の例
alias work-vpn='sudo openconnect ...'
alias deploy='cd ~/work/foo && ./deploy.sh'
```

両ファイルは `.gitignore` で除外済みなので commit されない。

## アップデート

```bash
# 個人設定をアップデート
cd ~/.zsh-env && git pull

# 本家 prezto をアップデート
cd ~/.zprezto && git pull && git submodule update --init --recursive
```

## 既存環境（prezto fork）からの移行

旧来 `choniwaniwani/prezto` fork を使っていたマシンの場合:

```bash
# 1. 旧 ~/.zprezto を退避
mv ~/.zprezto ~/.zprezto.fork-backup-$(date +%Y%m%d)

# 2. 古い symlink を一旦削除
rm -f ~/.zshenv ~/.zshrc ~/.zpreztorc ~/.p10k.zsh ~/.zprofile ~/.zlogin ~/.zlogout

# 3. このリポジトリを clone & bootstrap
git clone https://github.com/choniwaniwani/zsh-env.git ~/.zsh-env
~/.zsh-env/bootstrap.sh

# 4. 新シェルへ
exec zsh
```

## License

MIT
