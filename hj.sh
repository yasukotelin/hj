#!/bin/bash

# HJ - z jumpライクな履歴ジャンプツール
# 使用方法: このファイルをパスの通った場所に置いて、シェル設定ファイルに以下を追加
# source /path/to/hj.sh

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
HJ - 履歴ジャンプツール

使用法:
  hj           履歴から選択してジャンプ
  hj --list    履歴一覧を表示
  hj --help    このヘルプを表示
EOF
            return 0
            ;;
        --list|-l)
            if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
                echo "履歴が空です"
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
            # インタラクティブ選択
            if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
                echo "履歴が空です"
                return 1
            fi
            
            # 履歴を配列に読み込み（最新順）
            local dirs=""
            local temp_file
            temp_file=$(mktemp)
            
            # 履歴を逆順で取得
            if command -v tac >/dev/null 2>&1; then
                tac "$HISTORY_FILE" > "$temp_file"
            elif command -v tail >/dev/null 2>&1 && tail -r /dev/null >/dev/null 2>&1; then
                tail -r "$HISTORY_FILE" > "$temp_file"
            else
                cat "$HISTORY_FILE" > "$temp_file"
            fi
            
            # 配列に読み込み
            local i=0
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    eval "dir_$i=\"\$line\""
                    i=$((i + 1))
                fi
            done < "$temp_file"
            rm -f "$temp_file"
            
            if [ $i -eq 0 ]; then
                echo "履歴が空です"
                return 1
            fi
            
            echo "履歴から選択してください:"
            echo
            
            # 選択肢を表示
            local j=0
            while [ $j -lt $i ]; do
                eval "current_dir=\$dir_$j"
                printf "%2d) %s\n" $((j + 1)) "$current_dir"
                j=$((j + 1))
            done
            
            # ユーザーの選択を待つ
            printf "\n選択してください (1-%d, Enterでキャンセル): " $i
            read -r selection
            
            # 空入力の場合はキャンセル
            if [ -z "$selection" ]; then
                echo "キャンセルしました"
                return 0
            fi
            
            # 入力検証（数値チェック）
            case "$selection" in
                ''|*[!0-9]*)
                    echo "無効な選択です"
                    return 1
                    ;;
            esac
            
            if [ "$selection" -lt 1 ] || [ "$selection" -gt $i ]; then
                echo "無効な選択です"
                return 1
            fi
            
            # 選択されたディレクトリを取得
            eval "selected_dir=\$dir_$((selection - 1))"
            
            # ディレクトリが存在するかチェック
            if [ ! -d "$selected_dir" ]; then
                echo "ディレクトリが存在しません: $selected_dir"
                # 履歴から存在しないディレクトリを削除
                grep -v "^$selected_dir$" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" 2>/dev/null || true
                mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
                return 1
            fi
            
            # ディレクトリに移動
            echo "移動中: $selected_dir"
            cd "$selected_dir"
            return 0
            ;;
        *)
            echo "不明なオプション: $1"
            hj --help
            return 1
            ;;
    esac
}

# cdコマンドをオーバーライド
cd() {
    builtin cd "$@" && hj_add_to_history
}