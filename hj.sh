#!/bin/bash

HISTORY_FILE="$HOME/.hj_history"

# 履歴保存フック関数
hj_add_to_history() {
    local current_dir="$(pwd)"
    
    # 履歴ファイルが存在しない場合は作成
    [ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
    
    # 現在のディレクトリが既に履歴にある場合は削除（重複を避けるため）
    if [ -f "$HISTORY_FILE" ]; then
        grep -v "^$current_dir$" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" 2>/dev/null || true
        mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
    fi
    
    # 現在のディレクトリを履歴の末尾に追加
    echo "$current_dir" >> "$HISTORY_FILE"
    
    # 履歴を最大1000行に制限
    tail -n 1000 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
}

# hjコマンド本体
hj() {
    case "$1" in
        --help|-h)
            cat << 'EOF'
hj - History Jump Tool

Usage:
  hj           Jump by selecting from history with fzf
  hj --list    Show history list
  hj --help    Show this help
EOF
            return 0
            ;;
        --list|-l)
            if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
                echo "History is empty"
                return 0
            fi
            # 履歴を逆順（最新が上）で表示
            if command -v tac >/dev/null 2>&1; then
                tac "$HISTORY_FILE"
            elif command -v tail >/dev/null 2>&1 && tail -r /dev/null >/dev/null 2>&1; then
                tail -r "$HISTORY_FILE"
            else
                cat "$HISTORY_FILE"
            fi
            return 0
            ;;
        "")
            # fzfを使用したインタラクティブ選択
            if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
                echo "History is empty"
                return 1
            fi
            
            # fzfがインストールされているかチェック
            if ! command -v fzf >/dev/null 2>&1; then
                echo "Error: fzf is not installed"
                echo "Please install fzf and try again"
                echo ""
                echo "Installation:"
                echo "  macOS: brew install fzf"
                echo "  Ubuntu/Debian: sudo apt install fzf"
                echo "  Other: https://github.com/junegunn/fzf#installation"
                return 1
            fi
            
            # 履歴を逆順で取得してfzfに渡す
            local selected_dir
            if command -v tac >/dev/null 2>&1; then
                selected_dir=$(tac "$HISTORY_FILE" | fzf --prompt="Select from history: " --height=40% --reverse)
            elif command -v tail >/dev/null 2>&1 && tail -r /dev/null >/dev/null 2>&1; then
                selected_dir=$(tail -r "$HISTORY_FILE" | fzf --prompt="Select from history: " --height=40% --reverse)
            else
                selected_dir=$(cat "$HISTORY_FILE" | fzf --prompt="Select from history: " --height=40% --reverse)
            fi
            
            # fzfでキャンセルされた場合
            if [ -z "$selected_dir" ]; then
                echo "Cancelled"
                return 0
            fi
            
            # ディレクトリが存在するかチェック
            if [ ! -d "$selected_dir" ]; then
                echo "Directory does not exist: $selected_dir"
                # 履歴から存在しないディレクトリを削除
                grep -v "^$selected_dir$" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" 2>/dev/null || true
                mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
                return 1
            fi
            
            # ディレクトリに移動
            cd "$selected_dir"
            return 0
            ;;
        *)
            echo "Unknown option: $1"
            hj --help
            return 1
            ;;
    esac
}

# cdコマンドをオーバーライド
cd() {
    builtin cd "$@" && hj_add_to_history
}