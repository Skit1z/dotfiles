# Zsh 环境配置 - 由 dotfiles 管理

# 初始化 Homebrew/Linuxbrew PATH
# Initialize Homebrew/Linuxbrew PATH
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# 设置 ZDOTDIR
export ZDOTDIR="$HOME/.config/zsh"
