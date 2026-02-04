#!/bin/bash
# Shell 欢迎信息脚本

# 颜色定义
_WELCOME_BLUE='\033[0;34m'
_WELCOME_GREEN='\033[0;32m'
_WELCOME_CYAN='\033[0;36m'
_WELCOME_NC='\033[0m'

_show_welcome() {
    local user="${USER:-$(whoami)}"
    local date_str=$(date "+%Y-%m-%d %H:%M")
    local local_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "N/A")
    
    echo -e "${_WELCOME_GREEN}👋 ${user}${_WELCOME_NC} | ${_WELCOME_BLUE}📅 ${date_str}${_WELCOME_NC} | ${_WELCOME_CYAN}🌐 ${local_ip}${_WELCOME_NC}"
}

# 只在交互式 shell 中显示
[[ $- == *i* ]] && _show_welcome
