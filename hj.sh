#!/bin/bash

HISTORY_FILE="$HOME/.hj_history"

# frecencyスコアを計算してソート
hj_calculate_frecency_and_sort() {
    if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
        return
    fi
    
    local current_time=$(/bin/date +%s)
    local temp_file="${HISTORY_FILE}.frecency"
    
    while IFS='|' read -r path rank timestamp; do
        # 空行やフィールドが不完全な行をスキップ
        if [ -z "$path" ] || [ -z "$rank" ] || [ -z "$timestamp" ]; then
            continue
        fi
        
        # ディレクトリが存在するかチェック
        if [ ! -d "$path" ]; then
            continue
        fi
        
        # 時間による減衰係数を計算（最近ほど高いスコア）
        local time_diff=$((current_time - timestamp))
        local time_factor=1
        
        if [ $time_diff -lt 3600 ]; then
            # 1時間以内は最高係数
            time_factor=4
        elif [ $time_diff -lt 86400 ]; then
            # 1日以内
            time_factor=2
        elif [ $time_diff -lt 604800 ]; then
            # 1週間以内
            time_factor=1
        else
            # それ以上古い
            time_factor=0.5
        fi
        
        # frecencyスコア = ランク × 時間係数
        local frecency_score=$(/usr/bin/awk "BEGIN {print $rank * $time_factor}")
        echo "$frecency_score|$path|$rank|$timestamp" >> "$temp_file"
    done < "$HISTORY_FILE"
    
    # スコア順でソート（降順）
    if [ -f "$temp_file" ]; then
        /usr/bin/sort -t'|' -k1,1nr "$temp_file"
        /bin/rm "$temp_file"
    fi
}

# 簡略化されたエイジング処理
hj_age_history() {
    if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
        return
    fi
    
    # 行数でエイジングを判定（1000行を超えた場合）
    local line_count=$(/usr/bin/wc -l < "$HISTORY_FILE" 2>/dev/null || echo "0")
    
    if [ "$line_count" -gt 1000 ]; then
        local temp_file="${HISTORY_FILE}.aging"
        
        # 全ランクを0.99倍して減衰
        while IFS='|' read -r path rank timestamp; do
            if [ -n "$path" ] && [ -n "$rank" ] && [ -n "$timestamp" ]; then
                local new_rank=$(/usr/bin/awk "BEGIN {printf \"%.2f\", $rank * 0.99}")
                # ランクが1以上の場合のみ保持
                if /usr/bin/awk "BEGIN {exit !($new_rank >= 1)}"; then
                    echo "$path|$new_rank|$timestamp" >> "$temp_file"
                fi
            fi
        done < "$HISTORY_FILE"
        
        if [ -f "$temp_file" ]; then
            /bin/mv "$temp_file" "$HISTORY_FILE"
        fi
    fi
}

# 履歴保存フック関数
hj_add_to_history() {
    local current_dir="$(pwd)"
    local current_time=$(date +%s)
    
    # 履歴ファイルが存在しない場合は作成
    [ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
    
    local temp_file="${HISTORY_FILE}.tmp"
    local found=0
    local new_rank=1.0
    
    # 既存のエントリを探して更新、または新規追加
    if [ -f "$HISTORY_FILE" ]; then
        while IFS='|' read -r path rank timestamp; do
            if [ "$path" = "$current_dir" ]; then
                # 既存エントリの場合はランクを増加
                new_rank=$(/usr/bin/awk "BEGIN {print $rank + 1}")
                echo "$current_dir|$new_rank|$current_time" >> "$temp_file"
                found=1
            elif [ -n "$path" ] && [ -d "$path" ]; then
                # 他の有効なエントリはそのまま保持
                echo "$path|$rank|$timestamp" >> "$temp_file"
            fi
        done < "$HISTORY_FILE"
        
        # 新規エントリの場合
        if [ $found -eq 0 ]; then
            echo "$current_dir|1.0|$current_time" >> "$temp_file"
        fi
        
        /bin/mv "$temp_file" "$HISTORY_FILE"
    else
        # 履歴ファイルが空の場合
        echo "$current_dir|1.0|$current_time" > "$HISTORY_FILE"
    fi
    
    # エイジング処理
    hj_age_history
    
    # 履歴を最大1000行に制限
    /usr/bin/tail -n 1000 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && /bin/mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
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
            # frecencyスコア順で表示（スコアの高い順）
            hj_calculate_frecency_and_sort | while IFS='|' read -r score path rank timestamp; do
                echo "$path"
            done
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
            
            # frecencyスコア順でfzfに渡す
            local selected_dir
            selected_dir=$(hj_calculate_frecency_and_sort | while IFS='|' read -r score path rank timestamp; do
                echo "$path"
            done | fzf --prompt="Select from history: " --height=40% --reverse)
            
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

# 簡略化したFrecency履歴保存
hj_add_to_history_simple() {
    local current_dir="$(pwd)"
    local current_time=$(/bin/date +%s)
    
    # 履歴ファイルが存在しない場合は作成
    [ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
    
    local temp_file="${HISTORY_FILE}.tmp"
    local found=0
    local new_rank=1.0
    
    # 既存のエントリを探して更新、または新規追加
    if [ -s "$HISTORY_FILE" ]; then
        while IFS='|' read -r path rank timestamp; do
            if [ "$path" = "$current_dir" ]; then
                # 既存エントリの場合はランクを増加
                new_rank=$(/usr/bin/awk "BEGIN {print $rank + 1}")
                echo "$current_dir|$new_rank|$current_time" >> "$temp_file"
                found=1
            elif [ -n "$path" ] && [ -d "$path" ]; then
                # 他の有効なエントリはそのまま保持
                echo "$path|$rank|$timestamp" >> "$temp_file"
            fi
        done < "$HISTORY_FILE"
        
        # 新規エントリの場合
        if [ $found -eq 0 ]; then
            echo "$current_dir|1.0|$current_time" >> "$temp_file"
        fi
        
        /bin/mv "$temp_file" "$HISTORY_FILE"
    else
        # 履歴ファイルが空の場合
        echo "$current_dir|1.0|$current_time" > "$HISTORY_FILE"
    fi
    
    # 履歴を最大1000行に制限
    /usr/bin/tail -n 1000 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && /bin/mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
}

# cdコマンドをオーバーライド
cd() {
    if builtin cd "$@"; then
        local current_dir="$(pwd)"
        local current_time=$(/bin/date +%s)
        [ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
        
        local new_rank=1.0
        
        # 既存エントリがあるかチェックしてランクを取得
        if [ -s "$HISTORY_FILE" ]; then
            local existing_line=$(/usr/bin/grep "^${current_dir}|" "$HISTORY_FILE" | head -n 1)
            if [ -n "$existing_line" ]; then
                local old_rank=$(echo "$existing_line" | cut -d'|' -f2)
                new_rank=$(/usr/bin/awk "BEGIN {print $old_rank + 1}")
            fi
            
            # 既存エントリを削除
            /usr/bin/grep -v "^${current_dir}|" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" 2>/dev/null || cp "$HISTORY_FILE" "${HISTORY_FILE}.tmp"
            /bin/mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
        fi
        
        # 新しいエントリを追加
        echo "$current_dir|$new_rank|$current_time" >> "$HISTORY_FILE"
        
        # エイジング処理（1000行を超えた場合に減衰）
        hj_age_history 2>/dev/null || true
        
        # 履歴を最大1000行に制限
        /usr/bin/tail -n 1000 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && /bin/mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
        
        return 0
    else
        return $?
    fi
}