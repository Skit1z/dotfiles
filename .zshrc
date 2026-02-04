# THEME
ZSH_THEME="philips" # set by `omz`

# source antidote
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

# 加载 shell 配置
[ -f "$ZDOTDIR/shell/export" ] && source "$ZDOTDIR/shell/export"
[ -f "$ZDOTDIR/shell/alias" ] && source "$ZDOTDIR/shell/alias"
[ -f "$ZDOTDIR/shell/functions.sh" ] && source "$ZDOTDIR/shell/functions.sh"
[ -f "$ZDOTDIR/shell/welcome.sh" ] && source "$ZDOTDIR/shell/welcome.sh"
[ -f "$ZDOTDIR/.zsh_zoxide" ] && source "$ZDOTDIR/.zsh_zoxide"

ZSH_COLORIZE_STYLE="colorful"
ZSH_COLORIZE_CHROMA_FORMATTER=terminal256

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

eval "$(zoxide init zsh)"

# Atuin - 仅作为历史后端，完全禁用键绑定
export ATUIN_NOBIND=true
command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# fzf 配置
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
    
    # 使用 fzf + atuin 搜索历史 (Ctrl+R)
    if command -v atuin &>/dev/null; then
        _fzf_atuin_history() {
            local selected
            selected=$(atuin history list --format '{time}\t{command}' | \
                fzf --tac --no-sort --height=40% --layout=reverse \
                    --preview 'echo {}' --preview-window=down:3:wrap \
                    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)' | \
                awk -F'\t' '{print $2}')
            if [[ -n "$selected" ]]; then
                LBUFFER="$selected"
            fi
            zle redisplay
        }
        zle -N _fzf_atuin_history
        bindkey '^R' _fzf_atuin_history
    fi
fi
