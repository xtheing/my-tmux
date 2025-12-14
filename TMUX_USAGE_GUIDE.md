# Tmux 持久化环境使用指南

## 📖 目录
- [快速开始](#快速开始)
- [基础概念](#基础概念)
- [核心快捷键](#核心快捷键)
- [会话管理](#会话管理)
- [窗口管理](#窗口管理)
- [窗格管理](#窗格管理)
- [持久化功能](#持久化功能)
- [高级技巧](#高级技巧)
- [故障排除](#故障排除)

## 🚀 快速开始

### 安装
```bash
# 下载并运行安装脚本
bash install_tmux_persistent.sh

# 重新登录或执行
source ~/.bashrc
```

### 首次使用
1. 安装完成后，tmux 会自动启动一个会话
2. 使用 `Ctrl-b %` 水平分割窗口
3. 使用 `Ctrl-b "` 垂直分割窗口
4. 使用 `Ctrl-b 方向键` 在窗格间导航

## 📚 基础概念

**会话 (Session)** - tmux 的最高级别容器，可以包含多个窗口
**窗口 (Window)** - 会话中的标签页，可以包含多个窗格
**窗格 (Pane)** - 窗口中的分割区域，每个窗格运行一个 shell

```
Session (会话)
├── Window 1 (窗口1)
│   ├── Pane 1 (窗格1)
│   ├── Pane 2 (窗格2)
│   └── Pane 3 (窗格3)
└── Window 2 (窗口2)
    ├── Pane 1 (窗格1)
    └── Pane 2 (窗格2)
```

## ⌨️ 核心快捷键

**前缀键**: `Ctrl-b` (可配置)

### 基础操作
| 快捷键 | 功能 |
|--------|------|
| `Ctrl-b ?` | 显示所有快捷键 |
| `Ctrl-b d` | 分离会话 (detach) |
| `Ctrl-b :` | 进入命令模式 |

### 会话管理
| 快捷键 | 功能 |
|--------|------|
| `Ctrl-b s` | 列出所有会话 |
| `Ctrl-b $` | 重命名当前会话 |
| `Ctrl-b new` | 创建新会话 (在命令模式) |

### 窗口管理
| 快捷键 | 功能 |
|--------|------|
| `Ctrl-b c` | 创建新窗口 |
| `Ctrl-b &` | 关闭当前窗口 |
| `Ctrl-b ,` | 重命名当前窗口 |
| `Ctrl-b w` | 列出所有窗口 |
| `Ctrl-b n` | 切换到下一个窗口 |
| `Ctrl-b p` | 切换到上一个窗口 |
| `Ctrl-b 0-9` | 切换到指定编号的窗口 |

### 窗格管理
| 快捷键 | 功能 |
|--------|------|
| `Ctrl-b %` | 水平分割窗格 |
| `Ctrl-b "` | 垂直分割窗格 |
| `Ctrl-b x` | 关闭当前窗格 |
| `Ctrl-b o` | 在窗格间循环切换 |
| `Ctrl-b 方向键` | 按方向切换窗格 |
| `Ctrl-b Ctrl-方向键` | 调整窗格大小 |
| `Ctrl-b {` | 交换当前窗格与前一个 |
| `Ctrl-b }` | 交换当前窗格与后一个 |
| `Ctrl-b !` | 将当前窗格转为新窗口 |
| `Ctrl-b z` | 最大化/恢复当前窗格 |

## 💾 会话管理

### 创建和连接会话
```bash
# 创建新会话
tmux new-session -s mysession

# 创建新会话并指定窗口名称
tmux new-session -s mysession -n mywindow

# 连接到现有会话
tmux attach-session -t mysession
tmux a -t mysession  # 简写

# 列出所有会话
tmux list-sessions
tmux ls  # 简写

# 杀死会话
tmux kill-session -t mysession
```

### 会话操作
```bash
# 重命名会话
tmux rename-session -t oldname newname

# 在后台创建会话
tmux new-session -d -s background_session

# 在现有会话中创建新窗口
tmux new-window -t mysession

# 发送命令到指定会话的窗口
tmux send-keys -t mysession:1 "ls -la" C-m
```

## 🪟 窗口管理

### 窗口操作
```bash
# 在指定会话中创建新窗口
tmux new-window -t mysession -n "New Window"

# 重命名窗口
tmux rename-window -t mysession:1 "Development"

# 关闭窗口
tmux kill-window -t mysession:2

# 选择窗口
tmux select-window -t mysession:3
```

## 🔲 窗格管理

### 窗格操作
```bash
# 水平分割窗格
tmux split-window -h -t mysession:1

# 垂直分割窗格
tmux split-window -v -t mysession:1

# 选择窗格
tmux select-pane -t mysession:1.2

# 发送命令到窗格
tmux send-keys -t mysession:1.1 "cd /path/to/project" C-m

# 关闭窗格
tmux kill-pane -t mysession:1.2
```

## 🔄 持久化功能

### 自动保存和恢复
- **自动保存**: 每15分钟自动保存会话状态
- **自动恢复**: 启动时自动恢复最后一个会话
- **保存内容**: 窗口布局、窗格内容、bash历史

### 手动控制
| 快捷键 | 功能 |
|--------|------|
| `Ctrl-b Ctrl-s` | 手动保存当前会话 |
| `Ctrl-b Ctrl-r` | 手动恢复保存的会话 |

### 恢复文件位置
保存的会话文件位于: `~/.tmux/resurrect/last`

### 支持的应用
- **终端会话**: 完全支持
- **Bash 历史**: 自动保存和恢复
- **Vim**: 会话恢复需要配置 `.vimrc`
- **Neovim**: 会话恢复需要配置 `init.vim`

## 🎯 高级技巧

### 自定义配置
编辑 `~/.tmux.conf` 文件来自定义设置：

```bash
# 修改前缀键
set -g prefix C-space
bind C-space send-prefix

# 自定义状态栏
set -g status-left '#[fg=green]#S #[fg=yellow]#I:#P'
set -g status-right '#[fg=cyan]%Y-%m-%d %H:%M'

# 启用活动窗口监控
setw -g monitor-activity on
set -g visual-activity on
```

### 脚本化操作
```bash
#!/bin/bash
# 创建开发环境的 tmux 会话

SESSION_NAME="dev"

# 检查会话是否已存在
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "会话 $SESSION_NAME 已存在"
    tmux attach-session -t $SESSION_NAME
else
    # 创建新会话
    tmux new-session -d -s $SESSION_NAME

    # 创建多个窗口
    tmux new-window -t $SESSION_NAME:1 -n "Editor"
    tmux send-keys -t $SESSION_NAME:1 "vim" C-m

    tmux new-window -t $SESSION_NAME:2 -n "Terminal"
    tmux send-keys -t $SESSION_NAME:2 "cd ~/project" C-m

    tmux new-window -t $SESSION_NAME:3 -n "Server"
    tmux send-keys -t $SESSION_NAME:3 "npm start" C-m

    # 附加到会话
    tmux attach-session -t $SESSION_NAME:1
fi
```

### 团队协作
```bash
# 共享会话 (需要适当权限)
tmux new-session -s shared
# 其他用户:
tmux attach-session -t shared

# 只读连接
tmux attach-session -r -t shared
```

## 🔧 故障排除

### 常见问题

**Q: 快捷键不工作？**
A: 检查是否在正确的会话中，按 `Ctrl-b ?` 查看所有快捷键

**Q: 会话没有自动恢复？**
A: 检查 `~/.tmux/resurrect/last` 文件是否存在，手动运行 `~/.tmux_startup.sh`

**Q: 插件安装失败？**
A: 重新运行安装脚本或手动安装:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux run-shell ~/.tmux/plugins/tpm/bin/install_plugins
```

**Q: 配置文件语法错误？**
A: 检查 `~/.tmux.conf` 语法，特别是引号和分号的使用

**Q: 鼠标不工作？**
A: 确保 `set -g mouse on` 在配置文件中，并重新加载配置

### 调试命令
```bash
# 检查 tmux 版本
tmux -V

# 检查配置文件语法
tmux source-file ~/.tmux.conf

# 列出所有会话
tmux list-sessions

# 查看 tmux 进程
ps aux | grep tmux

# 杀死所有 tmux 会话
tmux kill-server
```

### 重置配置
如果遇到严重问题，可以重置配置：
```bash
# 备份现有配置
cp ~/.tmux.conf ~/.tmux.conf.backup

# 删除所有 tmux 相关文件
rm -rf ~/.tmux*

# 重新安装
bash install_tmux_persistent.sh
```

## 📋 参考配置

### 开发环境配置示例
```bash
# ~/.tmux.conf 额外配置

# 自定义窗口布局
bind D source-file ~/.tmux/dev-layout

# 项目快速启动
bind P command-prompt -p "Project name:" "new-session -s '%%'"

# 保存当前窗口布局
bind-key + command-prompt -p "layout name:" "save-buffer ~/.tmux/layouts/%%"

# 加载保存的布局
bind-key = choose-buffer -p "load layout:" "load-buffer %% ; source-buffer"
```

### 布局文件示例
```bash
# ~/.tmux/dev-layout
neww -n "editor"
splitw -h -p 50
selectp -t 0
splitw -v -p 30
selectw -t 1
neww -n "server"
selectw -t 0
```

---

## 📞 获取帮助

- **官方文档**: https://github.com/tmux/tmux/wiki
- **快捷键参考**: 在 tmux 中按 `Ctrl-b ?`
- **配置重新加载**: 重启 tmux 或在命令模式执行 `source-file ~/.tmux.conf`

享受高效的终端工作环境！🎉