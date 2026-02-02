#!/bin/bash

# Tmux 启动脚本 - 自动恢复最后一个会话
# 这个脚本会在登录时自动运行，恢复保存的 tmux 会话

# 检查是否已经在 tmux 会话中
if [ -z "$TMUX" ]; then
    # 检查是否有保存的会话
    if [ -f ~/.tmux/resurrect/last ]; then
        # 恢复最后一个会话
        tmux new-session -d -s restored
        tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
        echo "Tmux 会话已恢复"
    else
        # 如果没有保存的会话，创建一个新的默认会话
        tmux new-session -d -s main
        tmux send-keys -t main "echo '欢迎使用 tmux！使用 Ctrl-b + % 水平分割，Ctrl-b + \" 垂直分割'" C-m
        echo "创建了新的 tmux 会话 'main'"
    fi

    # 附加到会话（如果当前是交互式登录）
    if [ "$-" = "*i*" ] || [ -t 1 ]; then
        # 获取第一个活动的会话名称
        SESSION=$(tmux list-sessions | grep -o '^[[:alnum:]_-]*' | head -1)
        tmux attach-session -t "$SESSION"
    fi
fi
