path_remove() {
    PATH=$(echo -n "$PATH" | awk -v RS=: -v ORS=: "\$0 != \"$1\"" | sed 's/:$//')
}

path_append() {
    path_remove "$1"
    PATH="${PATH:+"$PATH:"}$1"
}

path_dedup() {
    PATH=$(printf '%s' "$PATH" | awk -v RS=: '!seen[$0]++ && length($0)>0 { paths = paths (paths ? ":" : "") $0 } END { print paths }')
    export PATH
}

path_prepend() {
    path_remove "$1"
    PATH="$1${PATH:+":$PATH"}"
}

here() {
    local loc
    if [ "$#" -eq 1 ]; then
        loc=$(realpath "$1")
    else
        loc=$(realpath ".")
    fi
    ln -sfn "${loc}" "$HOME/.shell.here"
    echo "here -> $(readlink $HOME/.shell.here)"
}

there="$HOME/.shell.here"

there() {
    cd "$(readlink "${there}")"
}

# 代理开关（默认关闭，输入 proxy_on 开启，proxy_off 关闭）
proxy_on() {
    local port="${1:-1082}"
    export http_proxy="http://127.0.0.1:${port}"
    export https_proxy="http://127.0.0.1:${port}"
    export all_proxy="socks5://127.0.0.1:${port}"
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export ALL_PROXY="$all_proxy"
    echo "✅ 代理已开启 → 127.0.0.1:${port}"
}

proxy_off() {
    unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
    echo "❌ 代理已关闭"
}

proxy_status() {
    if [ -n "$http_proxy" ]; then
        echo "✅ 代理: $http_proxy"
    else
        echo "❌ 代理未开启"
    fi
}

# Create a directory and cd into it
# 创建目录并进入
mcd() {
    mkdir "${1}" && cd "${1}"
}

# Jump to directory containing file
# 跳转到包含文件的目录
jump() {
    cd "$(dirname "${1}")"
}

# cd replacement for screen to track cwd (like tmux)
# screen 中的 cd 替换，用于追踪工作目录
scr_cd() {
    builtin cd "$1"
    screen -X chdir "$PWD"
}

if [[ -n $STY ]]; then
    alias cd=scr_cd
fi

# Go up [n] directories
# 向上跳转 [n] 级目录
up() {
    local cdir="$(pwd)"
    if [[ "${1}" == "" ]]; then
        cdir="$(dirname "${cdir}")"
    elif ! [[ "${1}" =~ ^[0-9]+$ ]]; then
        echo "Error: argument must be a number"
    elif ! [[ "${1}" -gt "0" ]]; then
        echo "Error: argument must be positive"
    else
        for ((i=0; i<${1}; i++)); do
            local ncdir="$(dirname "${cdir}")"
            if [[ "${cdir}" == "${ncdir}" ]]; then
                break
            else
                cdir="${ncdir}"
            fi
        done
    fi
    cd "${cdir}"
}

# Execute a command in a specific directory
# 在指定目录中执行命令
xin() {
    (
        cd "${1}" && shift && "${@}"
    )
}

# Check if a file contains non-ascii characters
# 检查文件是否包含非 ASCII 字符
nonascii() {
    LC_ALL=C grep -n '[^[:print:][:space:]]' "${@}"
}

# Fetch pull request from GitHub
# 从 GitHub 拉取 pull request
fpr() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "error: fpr must be executed from within a git repository"
        return 1
    fi
    (
        cd "$(git rev-parse --show-toplevel)"
        if [ "$#" -eq 1 ]; then
            local repo="${PWD##*/}"
            local user="${1%%:*}"
            local branch="${1#*:}"
        elif [ "$#" -eq 2 ]; then
            local repo="${PWD##*/}"
            local user="${1}"
            local branch="${2}"
        elif [ "$#" -eq 3 ]; then
            local repo="${1}"
            local user="${2}"
            local branch="${3}"
        else
            echo "Usage: fpr [repo] username branch"
            return 1
        fi

        git fetch "git@github.com:${user}/${repo}" "${branch}:${user}/${branch}"
    )
}

# Java helpers (macOS)
# Java 版本管理辅助函数（macOS）
jdk() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        echo "jdk: this function currently supports macOS only"
        return 1
    fi

    case "${1:-}" in
        ""|"current")
            echo "JAVA_HOME=${JAVA_HOME:-<unset>}"
            java -version 2>&1 | head -n 1
            ;;
        "list")
            /usr/libexec/java_home -V 2>&1
            ;;
        "use")
            if [[ -z "${2:-}" ]]; then
                echo "Usage: jdk use <version>"
                echo "Example: jdk use 17 | jdk use 1.8"
                return 1
            fi

            local target_home
            target_home="$(/usr/libexec/java_home -v "${2}" 2>/dev/null)"
            if [[ -z "${target_home}" ]]; then
                echo "❌ JDK version not found: ${2}"
                echo "Run 'jdk list' to see installed versions."
                return 1
            fi

            export JAVA_HOME="${target_home}"
            export PATH="${JAVA_HOME}/bin:${PATH}"
            hash -r 2>/dev/null || true

            echo "✅ Switched to JDK ${2}"
            echo "JAVA_HOME=${JAVA_HOME}"
            java -version 2>&1 | head -n 1
            ;;
        *)
            echo "Usage: jdk [current|list|use <version>]"
            return 1
            ;;
    esac
}
