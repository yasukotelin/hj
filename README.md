# HJ - 履歴ジャンプツール

z jumpライクな履歴ジャンプ機能を提供するシェルスクリプトです。fzfを使用したインタラクティブな選択でディレクトリに素早く移動できます。

## 機能

- **自動履歴保存**: `cd`コマンドでディレクトリを移動すると自動的に履歴を保存
- **fzfによるインタラクティブ選択**: ファジーファインダーで履歴から素早く検索・選択
- **履歴管理**: 重複排除、最大1000行制限、存在しないディレクトリの自動削除

## 必要条件

- **fzf**: インタラクティブ選択に使用
  - macOS: `brew install fzf`
  - Ubuntu/Debian: `sudo apt install fzf`
  - その他: https://github.com/junegunn/fzf#installation

## インストール

1. `hj.sh`をダウンロード
2. シェル設定ファイル（`.bashrc`, `.zshrc`等）に以下を追加:

```bash
source /path/to/hj.sh
```

3. シェルを再起動またはsource実行

## 使用方法

### 基本コマンド

```bash
# 履歴からインタラクティブに選択してジャンプ
hj

# 履歴一覧を表示
hj --list
hj -l

# ヘルプを表示
hj --help
hj -h
```

### 履歴の自動保存

`cd`コマンドを使用すると自動的に履歴が保存されます：

```bash
cd /path/to/project
cd ~/Documents
cd /var/log
# これらのパスが ~/.hj_history に保存される
```

### fzfによる選択

`hj`コマンドを実行すると、fzfが起動して履歴から選択できます：

- **検索**: 文字を入力してディレクトリをフィルタリング
- **選択**: 矢印キーまたは`Ctrl+J/K`で移動、Enterで選択
- **キャンセル**: `Esc`または`Ctrl+C`

## 履歴ファイル

履歴は`~/.hj_history`に保存されます。このファイルは：

- 最新の訪問ディレクトリが末尾に追加
- 重複するパスは自動的に削除
- 最大1000行に制限
- 存在しないディレクトリは自動的に削除

## 例

```bash
# プロジェクトディレクトリに移動
cd ~/projects/myapp
cd ~/projects/webapp
cd /etc/nginx

# 履歴から選択してジャンプ
hj
# fzfが起動し、"proj"と入力すると
# ~/projects/myapp と ~/projects/webapp がフィルタリングされる

# 履歴一覧を確認
hj --list
```

## ライセンス

MIT License