# Zsh 环境配置 - 由 dotfiles 管理

# 初始化 Homebrew PATH (Apple Silicon / Intel Mac)
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# 设置 ZDOTDIR
export ZDOTDIR="$HOME/.config/zsh"
