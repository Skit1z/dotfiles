# dircolors (solarized, if available)
# dircolors 配色（solarized，如果存在）
if [[ "$(tput colors)" == "256" ]]; then
    local dircolors_file="$HOME/.shell/plugins/dircolors-solarized/dircolors.256dark"
    if [[ -f "$dircolors_file" ]]; then
        eval "$(dircolors "$dircolors_file")"
    fi
fi
