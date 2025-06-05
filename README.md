# hj

z jumpライクな履歴ジャンプ機能を提供するシェルスクリプトです。fzfを使用したインタラクティブな選択でディレクトリに素早く移動できます。

## Requirements

- [fzf](https://github.com/junegunn/fzf)

## インストール

1. `hj.sh`をダウンロード
2. シェル設定ファイル（`.bashrc`, `.zshrc`等）に以下を追加:

```bash
source /path/to/hj.sh
```

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

### 履歴から選択してジャンプ

```bash
hj
```

fzfが起動し選択したディレクトリに `cd` します。

### 履歴の自動保存

`cd`コマンドを使用すると自動的に履歴が保存されます：

```bash
cd /path/to/project
cd ~/Documents
cd /var/log
# これらのパスが ~/.hj_history に保存される
```

## 履歴ファイル

履歴は`~/.hj_history`に保存されます。このファイルは：

- 最新の訪問ディレクトリが末尾に追加
- 重複するパスは自動的に削除
- 最大1000行に制限
- 存在しないディレクトリは自動的に削除

## 使用例

```bash
# プロジェクトディレクトリに移動
cd ~/projects/myapp
cd ~/projects/webapp
cd /etc/nginx

# 履歴一覧を確認
hj --list
```

## ライセンス

MIT License
