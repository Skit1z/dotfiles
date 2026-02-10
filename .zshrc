# THEME
ZSH_THEME=robbyrussell

# 优化 compinit - 每天只编译一次
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# source antidote
if [[ -f /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
    source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
elif [[ -f /usr/local/opt/antidote/share/antidote/antidote.zsh ]]; then
    source /usr/local/opt/antidote/share/antidote/antidote.zsh
fi

# 初始化插件和主题（带兜底）
export ZSH="${HOME}/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh"
if command -v antidote &>/dev/null; then
    export ZSH="$(antidote home)/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh"
    if ! antidote load; then
        [ -f "$ZDOTDIR/.zsh_plugins.zsh" ] && source "$ZDOTDIR/.zsh_plugins.zsh"
    fi
elif [[ -f "$ZDOTDIR/.zsh_plugins.zsh" ]]; then
    source "$ZDOTDIR/.zsh_plugins.zsh"
fi

# 主题兜底：插件链路异常时避免回落到默认 % 提示符
if [[ -d "$ZSH" ]] && [[ -z "$PROMPT" || "$PROMPT" == '%m%# ' || "$PROMPT" == *"%n@%m %1~ %#"* ]]; then
    [ -f "$ZSH/lib/git.zsh" ] && source "$ZSH/lib/git.zsh"
    [ -f "$ZSH/lib/prompt_info_functions.zsh" ] && source "$ZSH/lib/prompt_info_functions.zsh"
    [ -f "$ZSH/lib/theme-and-appearance.zsh" ] && source "$ZSH/lib/theme-and-appearance.zsh"
    [ -f "$ZSH/themes/${ZSH_THEME}.zsh-theme" ] && source "$ZSH/themes/${ZSH_THEME}.zsh-theme"
fi

# 加载 shell 配置
[ -f "$ZDOTDIR/shell/export" ] && source "$ZDOTDIR/shell/export"
[ -f "$ZDOTDIR/shell/alias" ] && source "$ZDOTDIR/shell/alias"
[ -f "$ZDOTDIR/shell/functions.sh" ] && source "$ZDOTDIR/shell/functions.sh"
[ -f "$ZDOTDIR/shell/welcome.sh" ] && source "$ZDOTDIR/shell/welcome.sh"
[ -f "$ZDOTDIR/.zsh_zoxide" ] && source "$ZDOTDIR/.zsh_zoxide"

# thefuck - 延迟加载（只在首次使用时初始化）
fuck() {
    unfunction fuck
    eval "$(thefuck --alias)"
    fuck "$@"
}

ZSH_COLORIZE_STYLE="colorful"
ZSH_COLORIZE_CHROMA_FORMATTER=terminal256

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

# iTerm2 shell integration (仅在 iTerm2 中加载)
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# zoxide 初始化
eval "$(zoxide init zsh)"

# Atuin - 仅作为历史后端，完全禁用键绑定
export ATUIN_NOBIND=true
command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# fzf 配置
if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
    source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
    source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

# 使用 fzf + atuin 搜索历史 (Ctrl+R)
if command -v atuin &>/dev/null && command -v fzf &>/dev/null; then
    _fzf_atuin_history() {
        local selected
        selected=$(atuin history list --format '{time}\t{command}' | \
            fzf --tac --no-sort --height=40% --layout=reverse | \
            awk -F'\t' '{print $2}')
        if [[ -n "$selected" ]]; then
            LBUFFER="$selected"
        fi
        zle redisplay
    }
    zle -N _fzf_atuin_history
    bindkey '^R' _fzf_atuin_history
fi

# 禁用 VS Code shell integration（会干扰 zsh 主题）
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
    PROMPT_COMMAND=""
    unset __vsc_prompt_cmd_original
fi

# opencode
export PATH=/Users/skit1z/.opencode/bin:$PATH
