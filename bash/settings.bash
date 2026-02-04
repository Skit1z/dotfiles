HISTSIZE=1048576
HISTFILE="$HOME/.bash_history"
SAVEHIST=$HISTSIZE
shopt -s histappend # append to history file
eval "$(/opt/homebrew/bin/brew shellenv)"

export EDITOR=vim
