# Bash 配置文件 - 由 dotfiles 管理

# ================================
# Homebrew PATH 初始化
# ================================
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ================================
# Shell 配置目录
# ================================
SHELL_CONFIG_DIR="${HOME}/.config/zsh/shell"

# ================================
# 加载 shell 配置
# ================================
[ -f "$SHELL_CONFIG_DIR/export" ] && source "$SHELL_CONFIG_DIR/export"
[ -f "$SHELL_CONFIG_DIR/alias" ] && source "$SHELL_CONFIG_DIR/alias"
[ -f "$SHELL_CONFIG_DIR/functions.sh" ] && source "$SHELL_CONFIG_DIR/functions.sh"
[ -f "$SHELL_CONFIG_DIR/welcome.sh" ] && source "$SHELL_CONFIG_DIR/welcome.sh"

# ================================
# 工具初始化
# ================================
# zoxide
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

# fzf
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
    
    # 使用 fzf + atuin 搜索历史
    if command -v atuin &>/dev/null; then
        _fzf_atuin_history() {
            local selected
            selected=$(atuin history list --format '{time}\t{command}' | \
                fzf --tac --no-sort --height=40% --layout=reverse \
                    --preview 'echo {}' --preview-window=down:3:wrap | \
                awk -F'\t' '{print $2}')
            if [[ -n "$selected" ]]; then
                READLINE_LINE="$selected"
                READLINE_POINT=${#selected}
            fi
        }
        bind -x '"\C-r": _fzf_atuin_history'
    fi
fi

# Atuin (仅作为历史后端，完全禁用键绑定)
export ATUIN_NOBIND=true
command -v atuin &>/dev/null && eval "$(atuin init bash --disable-up-arrow)"

# thefuck
command -v thefuck &>/dev/null && eval "$(thefuck --alias)"

# ================================
# 允许本地自定义
# ================================
[ -f ~/.bashrc_local ] && source ~/.bashrc_local
