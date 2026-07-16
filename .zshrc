# THEME
ZSH_THEME=robbyrussell

# 优化 compinit - 每天只编译一次
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# source antidote (Homebrew / Linuxbrew / git clone)
# 加载 antidote（Homebrew / Linuxbrew / git clone）
if [[ -f "${HOMEBREW_PREFIX}/opt/antidote/share/antidote/antidote.zsh" ]]; then
    source "${HOMEBREW_PREFIX}/opt/antidote/share/antidote/antidote.zsh"
elif [[ -f "${HOME}/.antidote/antidote.zsh" ]]; then
    source "${HOME}/.antidote/antidote.zsh"
fi

# 初始化插件和主题（带兜底）
# In antidote v2, load() auto-generates and sources the static plugin file.
# antidote v2 中 load() 自动生成并加载静态插件文件。
if command -v antidote &>/dev/null; then
    export ZSH="$(antidote home)/github.com/ohmyzsh/ohmyzsh"
    antidote load "$ZDOTDIR/.zsh_plugins.txt" "$ZDOTDIR/.zsh_plugins.zsh"
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
[ -f "$ZDOTDIR/shell/functions.sh" ] && source "$ZDOTDIR/shell/functions.sh"
[ -f "$ZDOTDIR/shell/export" ] && source "$ZDOTDIR/shell/export"
[ -f "$ZDOTDIR/shell/alias" ] && source "$ZDOTDIR/shell/alias"
[ -f "$ZDOTDIR/shell/welcome.sh" ] && source "$ZDOTDIR/shell/welcome.sh"

# thefuck - lazy load (only initialize on first use)
# thefuck - 延迟加载（只在首次使用时初始化）
if command -v thefuck &>/dev/null; then
    fuck() {
        unfunction fuck
        eval "$(thefuck --alias)"
        fuck "$@"
    }
fi

# iTerm2 shell integration (仅在 iTerm2 中加载)
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
fi

# zoxide 初始化
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# Atuin - 仅作为历史后端，完全禁用键绑定
export ATUIN_NOBIND=true
command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# fzf 配置 (Homebrew / apt / git clone)
# Suppress "can't change option: zle" — macOS 27's zsh makes zle read-only,
# fzf's eval 'options=(... zle on ...)' can't toggle it (harmless, already on).
# 抑制 "can't change option: zle" — macOS 27 的 zsh 中 zle 变为只读选项，
# fzf 的 eval 'options=(... zle on ...)' 无法切换（无害，本身已是 on 状态）。
_fzf_source() { source "$1" 2> >(grep -v "can't change option: zle" >&2); }
if [[ -f "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh" ]]; then
    _fzf_source "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh"
    _fzf_source "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh"
elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    _fzf_source /usr/share/doc/fzf/examples/key-bindings.zsh
    [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && _fzf_source /usr/share/doc/fzf/examples/completion.zsh
elif [[ -f "${HOME}/.fzf.zsh" ]]; then
    _fzf_source "${HOME}/.fzf.zsh"
fi
unfunction _fzf_source

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

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun completions
# bun 补全
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
