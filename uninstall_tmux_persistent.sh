#!/bin/bash

# ============================================================================
# Tmux 持久化环境卸载脚本
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 确认卸载
confirm_uninstall() {
    echo "=================================================="
    echo "    Tmux 持久化环境卸载脚本"
    echo "=================================================="
    echo
    print_warning "这将删除以下内容："
    echo "  • ~/.tmux/ 目录 (包含所有插件和配置)"
    echo "  • ~/.tmux.conf 配置文件"
    echo "  • ~/.tmux_startup.sh 启动脚本"
    echo "  • ~/.bashrc 中的自动启动配置"
    echo "  • 所有保存的会话数据"
    echo
    read -p "确定要继续吗？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "取消卸载"
        exit 0
    fi
}

# 停止所有 tmux 会话
stop_tmux_sessions() {
    print_info "停止所有 tmux 会话..."

    if tmux list-sessions 2>/dev/null; then
        tmux kill-server 2>/dev/null || true
        print_success "所有 tmux 会话已停止"
    else
        print_info "没有运行的 tmux 会话"
    fi
}

# 备份配置 (可选)
backup_config() {
    if [ -f ~/.tmux.conf ] || [ -d ~/.tmux ]; then
        read -p "是否要备份当前配置？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR="$HOME/tmux_backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"

            [ -f ~/.tmux.conf ] && cp ~/.tmux.conf "$BACKUP_DIR/"
            [ -d ~/.tmux ] && cp -r ~/.tmux "$BACKUP_DIR/"

            print_success "配置已备份到: $BACKUP_DIR"
        fi
    fi
}

# 删除 tmux 配置和插件
remove_tmux_files() {
    print_info "删除 tmux 配置文件..."

    # 删除配置文件
    if [ -f ~/.tmux.conf ]; then
        rm -f ~/.tmux.conf
        print_success "已删除 ~/.tmux.conf"
    fi

    # 删除插件目录
    if [ -d ~/.tmux ]; then
        rm -rf ~/.tmux
        print_success "已删除 ~/.tmux/ 目录"
    fi

    # 删除启动脚本
    if [ -f ~/.tmux_startup.sh ]; then
        rm -f ~/.tmux_startup.sh
        print_success "已删除 ~/.tmux_startup.sh"
    fi

    # 删除其他可能的配置文件
    for file in ~/.tmux.conf.backup.*; do
        if [ -f "$file" ]; then
            rm -f "$file"
            print_success "已删除备份文件: $file"
        fi
    done
}

# 清理自动启动配置
cleanup_autostart() {
    print_info "清理自动启动配置..."

    # 备份 bashrc
    if [ -f ~/.bashrc ]; then
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

        # 删除 tmux 启动相关行
        sed -i '/# 自动启动 tmux/,/fi/d' ~/.bashrc

        # 清理空行
        sed -i '/^$/N;/^\n$/d' ~/.bashrc

        print_success "已从 ~/.bashrc 移除自动启动配置"
    fi
}

# 清理其他shell配置
cleanup_other_shells() {
    print_info "检查其他 shell 配置文件..."

    # 检查 zsh
    if [ -f ~/.zshrc ]; then
        if grep -q "tmux_startup" ~/.zshrc; then
            cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
            sed -i '/# 自动启动 tmux/,/fi/d' ~/.zshrc
            print_success "已从 ~/.zshrc 移除自动启动配置"
        fi
    fi

    # 检查 fish
    if [ -f ~/.config/fish/config.fish ]; then
        if grep -q "tmux_startup" ~/.config/fish/config.fish; then
            cp ~/.config/fish/config.fish ~/.config/fish/config.fish.backup.$(date +%Y%m%d_%H%M%S)
            sed -i '/# 自动启动 tmux/,/end/d' ~/.config/fish/config.fish
            print_success "已从 fish 配置移除自动启动配置"
        fi
    fi
}

# 检查残留文件
check_remaining_files() {
    print_info "检查残留文件..."

    local remaining_files=()

    # 检查可能的残留文件
    [ -f ~/.tmux.conf ] && remaining_files+=("~/.tmux.conf")
    [ -d ~/.tmux ] && remaining_files+=("~/.tmux/")
    [ -f ~/.tmux_startup.sh ] && remaining_files+=("~/.tmux_startup.sh")

    if [ ${#remaining_files[@]} -gt 0 ]; then
        print_warning "发现以下残留文件："
        for file in "${remaining_files[@]}"; do
            echo "  • $file"
        done
        print_info "你可以手动删除这些文件"
    else
        print_success "没有发现残留文件"
    fi
}

# 完全卸载选项
full_uninstall() {
    read -p "是否要完全卸载 tmux 程序本身？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "卸载 tmux 程序..."

        if command -v pacman &> /dev/null; then
            sudo pacman -R --noconfirm tmux
        elif command -v apt-get &> /dev/null; then
            sudo apt-get remove --purge -y tmux
        elif command -v dnf &> /dev/null; then
            sudo dnf remove -y tmux
        elif command -v yum &> /dev/null; then
            sudo yum remove -y tmux
        else
            print_warning "无法自动卸载 tmux，请手动卸载"
        fi

        print_success "tmux 程序卸载完成"
    fi
}

# 显示完成信息
show_completion() {
    print_success "Tmux 持久化环境卸载完成！"
    echo
    echo "=== 清理总结 ==="
    echo "✓ 停止了所有 tmux 会话"
    echo "✓ 删除了配置文件和插件"
    echo "✓ 清理了自动启动配置"
    echo "✓ 移除了启动脚本"
    echo
    print_info "如果你只是想重置配置，可以运行安装脚本重新安装"
    print_info "如需帮助，请查看使用指南文档"
}

# 主函数
main() {
    confirm_uninstall
    stop_tmux_sessions
    backup_config
    remove_tmux_files
    cleanup_autostart
    cleanup_other_shells
    check_remaining_files
    full_uninstall
    show_completion
}

# 运行主函数
main "$@"