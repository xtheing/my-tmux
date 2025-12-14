#!/bin/bash

# ============================================================================
# Tmux 持久化环境自动安装脚本
# 适用于 Arch Linux，也可以适配其他发行版
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

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "检测到 root 用户，建议使用普通用户安装"
        # 检查是否在交互式环境中
        if [ -t 0 ]; then
            read -p "是否继续？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            print_info "非交互式环境，自动继续安装"
        fi
    fi
}

# 检测发行版并安装依赖
install_dependencies() {
    print_info "检测系统发行版并安装依赖..."

    if command -v pacman &> /dev/null; then
        # Arch Linux
        print_info "检测到 Arch Linux 系统"
        sudo pacman -S --needed --noconfirm tmux git curl
    elif command -v dnf &> /dev/null; then
        # Fedora
        print_info "检测到 Fedora 系统"
        sudo dnf install -y tmux git curl
    elif command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        print_info "检测到 Debian/Ubuntu 系统"
        sudo apt-get update
        sudo apt-get install -y tmux git curl
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        print_info "检测到 CentOS/RHEL 系统"
        sudo yum install -y tmux git curl
    else
        print_error "不支持的发行版，请手动安装 tmux、git、curl"
        exit 1
    fi

    print_success "依赖安装完成"
}

# 创建 tmux 配置目录
create_config_dirs() {
    print_info "创建配置目录..."
    mkdir -p ~/.tmux/plugins
    mkdir -p ~/.tmux/resurrect
    print_success "配置目录创建完成"
}

# 安装 TPM
install_tpm() {
    print_info "安装 Tmux Plugin Manager (TPM)..."
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        print_success "TPM 安装完成"
    else
        print_warning "TPM 已经存在，跳过安装"
    fi
}

# 备份现有配置
backup_config() {
    if [ -f ~/.tmux.conf ]; then
        print_info "备份现有配置文件..."
        cp ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)
        print_success "配置已备份"
    fi
}

# 创建 tmux 配置文件
create_config() {
    print_info "创建 tmux 配置文件..."

    cat > ~/.tmux.conf << 'EOF'
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

# 主题设置
set -g status-style 'bg=black,fg=white'
set -g window-status-current-style 'bg=white,fg=black,bold'
set -g status-interval 60
set -g status-left-length 30
set -g status-left '#[fg=green](#S) #(whoami)@#H#[default]'
set -g status-right '#[fg=yellow]#(cut -d " " -f 1-3 /proc/loadavg)#[default] #[fg=cyan]%H:%M#[default]'

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
if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm'"

# 初始化 TPM (必须放在配置文件底部)
run '~/.tmux/plugins/tpm/tpm'
EOF

    print_success "tmux 配置文件创建完成"
}

# 安装插件
install_plugins() {
    print_info "安装 tmux 插件..."

    # 清理可能存在的临时会话
    tmux kill-session -t temp_install 2>/dev/null || true

    # 创建临时会话来安装插件
    tmux new-session -d -s temp_install

    # 安装插件
    tmux run-shell ~/.tmux/plugins/tpm/bin/install_plugins

    # 清理临时会话
    tmux kill-session -t temp_install 2>/dev/null || true

    print_success "插件安装完成"
}

# 创建启动脚本
create_startup_script() {
    print_info "创建自动启动脚本..."

    cat > ~/.tmux_startup.sh << 'EOF'
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
EOF

    chmod +x ~/.tmux_startup.sh
    print_success "启动脚本创建完成"
}

# 配置自动启动
configure_autostart() {
    print_info "配置自动启动..."

    # 添加到 bashrc
    if ! grep -q "tmux_startup.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# 自动启动 tmux (如果存在)" >> ~/.bashrc
        echo 'if [ -f ~/.tmux_startup.sh ]; then' >> ~/.bashrc
        echo '    ~/.tmux_startup.sh' >> ~/.bashrc
        echo 'fi' >> ~/.bashrc
        print_success "已添加到 ~/.bashrc"
    else
        print_warning "自动启动配置已存在"
    fi
}

# 显示完成信息
show_completion() {
    print_success "Tmux 持久化环境安装完成！"
    echo
    echo "=== 快捷键说明 ==="
    echo "Ctrl-b \"      - 垂直分割窗口"
    echo "Ctrl-b %      - 水平分割窗口"
    echo "Ctrl-b 方向键 - 窗格导航"
    echo "Ctrl-b o      - 在窗格间循环切换"
    echo "Ctrl-b Ctrl-s - 手动保存会话"
    echo "Ctrl-b Ctrl-r - 手动恢复会话"
    echo
    echo "=== 功能特性 ==="
    echo "✓ 每15分钟自动保存会话"
    echo "✓ 保存窗口和窗格布局"
    echo "✓ 保存窗格内容和 bash 历史"
    echo "✓ 启动时自动恢复会话"
    echo "✓ 支持 vim/nvim 会话恢复"
    echo
    echo "=== 下一步 ==="
    echo "1. 重新登录或运行: source ~/.bashrc"
    echo "2. 或者手动运行: ~/.tmux_startup.sh"
    echo "3. 开始使用 tmux！"
    echo
    print_info "如需卸载，请运行: bash uninstall_tmux_persistent.sh"
}

# 主函数
main() {
    echo "=================================================="
    echo "    Tmux 持久化环境自动安装脚本"
    echo "=================================================="
    echo

    check_root
    install_dependencies
    create_config_dirs
    backup_config
    create_config
    install_tpm
    install_plugins
    create_startup_script
    configure_autostart
    show_completion
}

# 运行主函数
main "$@"
