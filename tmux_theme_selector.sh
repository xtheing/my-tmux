#!/bin/bash

# ============================================================================
# Tmux TokyoNight 主题选择器
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# 显示主题选择菜单
show_theme_menu() {
    echo
    print_header "TokyoNight 主题选择器"
    echo
    echo "请选择你喜欢的 TokyoNight 主题变体："
    echo
    echo "1) Night  - 深色主题 (默认推荐)"
    echo "2) Storm  - 深蓝灰色主题"
    echo "3) Moon   - 浅色主题"
    echo "4) Day    - 明亮浅色主题"
    echo "5) 退出"
    echo
}

# 备份当前配置
backup_config() {
    if [ -f ~/.tmux.conf ]; then
        cp ~/.tmux.conf ~/.tmux.conf.backup_theme_switch_$(date +%Y%m%d_%H%M%S)
        print_info "已备份当前配置"
    fi
}

# 应用主题
apply_theme() {
    local theme_name=$1
    local theme_file="/root/.local/share/nvim/lazy/tokyonight.nvim/extras/tmux/tokyonight_${theme_name}.tmux"

    if [ ! -f "$theme_file" ]; then
        print_error "主题文件不存在: $theme_file"
        return 1
    fi

    backup_config

    # 读取主题文件内容
    local theme_content=$(cat "$theme_file")

    # 创建新配置，保持插件和其他设置不变
    cat > ~/.tmux.conf << EOF
# 基础设置
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# 使用默认的 Ctrl-b 作为前缀快捷键
# 如果想改为 Ctrl-a，可以取消下面的注释
# unbind C-b
# set -g prefix C-a
# bind C-a send-prefix

# 重新加载配置文件的快捷键 (可选)
# bind r source-file ~/.tmux.conf \; display "配置已重新加载!"

# 使用 tmux 默认快捷键:
# Ctrl-b "        - 垂直分割窗口
# Ctrl-b %        - 水平分割窗口
# Ctrl-b 方向键  - 窗格导航
# Ctrl-b o        - 在窗格间循环切换

# TokyoNight ${theme_name} 主题配置
$theme_content

# 自定义状态栏 - 完整信息显示
set -g status-right "#[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]#[fg=#7aa2f7,bg=#16161e] #{prefix_highlight} #[fg=#3b4261,bg=#16161e,nobold,nounderscore,noitalics]#[fg=#7aa2f7,bg=#3b4261] #(cut -d ' ' -f 1-3 /proc/loadavg)  %Y-%m-%d  %H:%M #[fg=#7aa2f7,bg=#3b4261,nobold,nounderscore,noitalics]#[fg=#15161e,bg=#7aa2f7,bold] #(whoami)@#H "

# 启用鼠标支持
set -g mouse on

# 窗口索引从1开始
set -g base-index 1
setw -g pane-base-index 1

# 自动重编号窗口
set -g renumber-windows on

# 更长的历史记录
set -g history-limit 10000

# 降低延迟
set -sg escape-time 1

# 插件列表
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# tmux-resurrect 配置
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-save-bash-history 'on'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'

# tmux-continuum 配置 (自动保存)
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# 安装插件管理器 TPM
if "test ! -d ~/.tmux/plugins/tpm" \\
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm'"

# 初始化 TPM (必须放在配置文件底部)
run '~/.tmux/plugins/tpm/tpm'
EOF

    print_success "已应用 TokyoNight ${theme_name} 主题"
}

# 重载配置
reload_config() {
    print_info "重载 tmux 配置..."

    # 如果有 tmux 会话在运行，重载配置
    if tmux list-sessions &>/dev/null; then
        tmux source-file ~/.tmux.conf
        print_success "配置已重载到运行中的会话"
    else
        print_info "没有运行中的 tmux 会话"
    fi
}

# 主循环
main() {
    while true; do
        show_theme_menu
        read -p "请输入选择 (1-5): " choice
        echo

        case $choice in
            1)
                apply_theme "night"
                reload_config
                break
                ;;
            2)
                apply_theme "storm"
                reload_config
                break
                ;;
            3)
                apply_theme "moon"
                reload_config
                break
                ;;
            4)
                apply_theme "day"
                reload_config
                break
                ;;
            5)
                print_info "退出主题选择器"
                exit 0
                ;;
            *)
                print_warning "无效选择，请输入 1-5"
                echo
                ;;
        esac
    done

    echo
    print_success "主题切换完成！"
    echo
    print_info "使用提示："
    echo "• 重新启动 tmux 或运行 'tmux source-file ~/.tmux.conf' 查看效果"
    echo "• 如需切换其他主题，重新运行此脚本"
    echo "• 备份文件保存在 ~/.tmux.conf.backup_*"
}

# 检查依赖
check_dependencies() {
    if [ ! -d "/root/.local/share/nvim/lazy/tokyonight.nvim/extras/tmux" ]; then
        print_error "未找到 TokyoNight 主题文件"
        print_info "请确保已安装 tokyonight.nvim"
        exit 1
    fi
}

# 运行主函数
check_dependencies
main "$@"