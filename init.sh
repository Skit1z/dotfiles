#!/bin/bash
#
# dotfiles 安装脚本 (macOS / Debian)
# 用途: 将 dotfiles 链接到正确位置并安装必要依赖
#
# 用法:
#   bash init.sh          完整模式（向后兼容）
#   bash init.sh --lite   轻量模式（Linux 服务器，跳过增强工具/编辑器插件/TPM）
#   bash init.sh --server 同 --lite
#   bash init.sh --help   打印帮助信息
#

set -euo pipefail  # 启用严格模式: 遇错退出、未定义变量报错、管道错误传递

# ================================
# 颜色定义
# ================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ================================
# 配置变量
# ================================
readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ZDOTDIR_TARGET="${HOME}/.config/zsh"
readonly ZSHRC_SOURCE="${DOTFILES_DIR}/.zshrc"
readonly BASHRC_SOURCE="${DOTFILES_DIR}/bashrc"
readonly VIMRC_SOURCE="${DOTFILES_DIR}/.vimrc"
readonly GITCONFIG_SOURCE="${DOTFILES_DIR}/gitconfig"
readonly TMUX_SOURCE="${DOTFILES_DIR}/tmux.conf"
readonly ZSH_CONFIG_DIR="${DOTFILES_DIR}/zsh"
readonly SHELL_CONFIG_DIR="${DOTFILES_DIR}/shell"

# OS detection result (set by detect_os)
# 操作系统检测结果（由 detect_os 设置）
OS_TYPE=""

# Lite mode flag (0=full, 1=lite server install)
# 轻量模式标志（0=完整, 1=轻量服务器安装）
LITE_MODE=0

# Homebrew packages (macOS full-mode install; lite mode is Linux-only)
# Homebrew 包（macOS 完整模式安装；轻量模式仅限 Linux）
readonly BREW_PACKAGES=(git nvim vim uv atuin eza fzf thefuck tmux zoxide)

# ================================
# 工具函数
# ================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

die() {
    log_error "$1"
    exit 1
}

# ================================
# 参数解析
# ================================
print_help() {
    echo ""
    echo "Dotfiles 安装脚本"
    echo ""
    echo "用法:"
    echo "  bash init.sh              完整模式（macOS / Debian 工作站）"
    echo "  bash init.sh --lite        轻量模式（Linux 服务器，无人值守）"
    echo "  bash init.sh --server      同 --lite"
    echo "  bash init.sh --help        打印此帮助信息"
    echo ""
    echo "轻量模式跳过项:"
    echo "  - 增强工具 (atuin / eza / thefuck / zoxide)"
    echo "  - Linuxbrew / Homebrew"
    echo "  - vim-plug 及插件安装"
    echo "  - tmux TPM 插件管理器"
    echo "  - 所有交互式提问（无人值守运行）"
    echo "  - 仅支持 Linux；macOS 上使用 --lite 会退出"
    echo ""
}

parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            --lite|--server)
                LITE_MODE=1
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                die "未知参数: ${arg}（使用 --help 查看用法）"
                ;;
        esac
    done
}

# ================================
# 检查函数
# ================================
detect_os() {
    local kernel
    kernel="$(uname -s)"
    case "${kernel}" in
        Darwin)
            OS_TYPE="macos"
            log_info "系统检查通过: macOS"
            ;;
        Linux)
            if [[ -f /etc/debian_version ]]; then
                OS_TYPE="debian"
                log_info "系统检查通过: Debian/Ubuntu ($(cat /etc/debian_version))"
            else
                die "不支持的 Linux 发行版（目前仅支持 Debian/Ubuntu）"
            fi
            ;;
        *)
            die "不支持的操作系统: ${kernel}"
            ;;
    esac
}

check_homebrew() {
    # 先尝试初始化 Homebrew/Linuxbrew PATH
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    if ! command -v brew &>/dev/null; then
        log_warn "未检测到 Homebrew，正在安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "Homebrew 安装失败"
        # 安装后再次初始化 PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        elif [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
        log_success "Homebrew 安装完成"
    else
        log_info "Homebrew 已安装"
    fi
}

check_source_files() {
    local missing_files=()

    [[ -f "${ZSHRC_SOURCE}" ]] || missing_files+=(".zshrc")
    [[ -d "${ZSH_CONFIG_DIR}" ]] || missing_files+=("zsh/")
    [[ -f "${ZSH_CONFIG_DIR}/.zshenv" ]] || missing_files+=("zsh/.zshenv")
    [[ -d "${SHELL_CONFIG_DIR}" ]] || missing_files+=("shell/")

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        die "缺少必要文件: ${missing_files[*]}"
    fi
    log_info "源文件检查通过"
}

# ================================
# 安装函数
# ================================

# macOS: 使用 Homebrew 安装依赖
install_dependencies_macos() {
    log_info "安装依赖 (Homebrew)..."

    # 安装 antidote (zsh 插件管理器)
    if ! brew list antidote &>/dev/null; then
        brew install antidote || die "antidote 安装失败"
        log_success "antidote 安装完成"
    else
        log_info "antidote 已安装"
    fi

    # 安装其他必要工具
    local packages_to_install=()
    for pkg in "${BREW_PACKAGES[@]}"; do
        if ! brew list "${pkg}" &>/dev/null; then
            packages_to_install+=("${pkg}")
        fi
    done

    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        log_info "安装: ${packages_to_install[*]}"
        brew install "${packages_to_install[@]}" || log_warn "部分包安装失败"
    else
        log_info "所有依赖已安装"
    fi
}

# Debian/Ubuntu: 使用 apt 安装依赖
install_dependencies_debian() {
    log_info "安装依赖 (apt)..."

    # 更新包索引
    sudo apt-get update -qq || log_warn "apt-get update 失败"

    # 安装基础工具（apt 中可用的包）
    local apt_install=()
    local apt_base=(git neovim vim curl zsh fzf tmux build-essential)
    for pkg in "${apt_base[@]}"; do
        if ! dpkg -l "${pkg}" 2>/dev/null | grep -q '^ii'; then
            apt_install+=("${pkg}")
        fi
    done

    if [[ ${#apt_install[@]} -gt 0 ]]; then
        log_info "安装 (apt): ${apt_install[*]}"
        sudo apt-get install -y "${apt_install[@]}" || log_warn "部分包安装失败"
    fi

    # 增强工具（仅完整模式安装）
    # Enhanced tools (full mode only)
    if [[ "${LITE_MODE}" -eq 0 ]]; then

    # zoxide — 可能不在旧版 apt 中，尝试安装或用 cargo/curl
    if ! command -v zoxide &>/dev/null; then
        if apt-cache show zoxide &>/dev/null 2>&1; then
            sudo apt-get install -y zoxide || true
        else
            log_info "通过官方脚本安装 zoxide..."
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh \
                && log_success "zoxide 安装完成" \
                || log_warn "zoxide 安装失败，请手动安装: https://github.com/ajeetdsouza/zoxide"
        fi
    fi

    # eza — 可能不在旧版 apt 中
    if ! command -v eza &>/dev/null; then
        if apt-cache show eza &>/dev/null 2>&1; then
            sudo apt-get install -y eza || true
        else
            log_warn "eza 未在 apt 中找到，ls 将回退到系统 ls（可手动安装: https://github.com/eza-community/eza）"
        fi
    fi

    # atuin — 通常不在 apt 中
    if ! command -v atuin &>/dev/null; then
        log_info "通过官方脚本安装 atuin..."
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) 2>/dev/null \
            && log_success "atuin 安装完成" \
            || log_warn "atuin 安装失败，请手动安装: https://github.com/atuinsh/atuin"
    fi

    # thefuck — pip 安装
    if ! command -v thefuck &>/dev/null; then
        if command -v pip3 &>/dev/null; then
            pip3 install --user thefuck \
                && log_success "thefuck 安装完成" \
                || log_warn "thefuck 安装失败"
        else
            log_warn "thefuck 需要 pip3，请先安装 python3-pip"
        fi
    fi

    else
        log_info "轻量模式: 跳过增强工具 (atuin / eza / thefuck / zoxide)"
    fi

    # antidote — git clone 安装
    install_antidote_git
}

# 通过 git clone 安装 antidote（Debian 用）
install_antidote_git() {
    local antidote_dir="${HOME}/.antidote"
    if [[ -d "${antidote_dir}" ]]; then
        log_info "antidote 已安装 (${antidote_dir})"
        return 0
    fi
    # Homebrew 中的 antidote 也算已安装
    if command -v antidote &>/dev/null; then
        log_info "antidote 已安装 (Homebrew)"
        return 0
    fi

    log_info "通过 git clone 安装 antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote.git "${antidote_dir}" \
        && log_success "antidote 安装完成" \
        || log_warn "antidote 安装失败"
}

install_dependencies() {
    if [[ "${OS_TYPE}" == "macos" ]]; then
        install_dependencies_macos
    elif [[ "${OS_TYPE}" == "debian" ]]; then
        install_dependencies_debian
    fi
}

backup_existing() {
    local target="$1"
    if [[ -e "${target}" && ! -L "${target}" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        log_warn "备份已存在的文件: ${target} -> ${backup}"
        mv "${target}" "${backup}" || die "备份失败: ${target}"
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"

    # 备份已存在的文件/目录（非符号链接）
    backup_existing "${target}"

    # 删除已存在的符号链接（强制重建）
    [[ -L "${target}" ]] && rm "${target}"

    # 创建符号链接
    ln -s "${source}" "${target}" || die "创建符号链接失败: ${source} -> ${target}"
    log_success "创建符号链接: ${target} -> ${source}"
}

cleanup_old_symlinks() {
    log_info "清理旧的符号链接..."

    # 清理 ~/.zshenv
    if [[ -L "${HOME}/.zshenv" ]]; then
        rm "${HOME}/.zshenv"
        log_info "已移除: ~/.zshenv"
    fi

    # 清理 ZDOTDIR 目录中的所有符号链接
    if [[ -d "${ZDOTDIR_TARGET}" ]]; then
        find "${ZDOTDIR_TARGET}" -maxdepth 1 -type l -delete 2>/dev/null || true
        log_info "已清理: ${ZDOTDIR_TARGET} 中的符号链接"
    fi

    # 如果 ZDOTDIR 本身是符号链接，移除它
    if [[ -L "${ZDOTDIR_TARGET}" ]]; then
        rm "${ZDOTDIR_TARGET}"
        log_info "已移除符号链接目录: ${ZDOTDIR_TARGET}"
    fi

    log_success "旧链接清理完成"
}

setup_zsh_config() {
    log_info "配置 zsh..."

    # Debian: 确保 zsh 已安装
    if [[ "${OS_TYPE}" == "debian" ]] && ! command -v zsh &>/dev/null; then
        log_warn "zsh 未安装，跳过 zsh 配置"
        return 0
    fi

    # 先清理旧的符号链接
    cleanup_old_symlinks

    # 创建 ZDOTDIR 目录（包括父目录）
    mkdir -p "${ZDOTDIR_TARGET}" || die "创建目录失败: ${ZDOTDIR_TARGET}"

    # 链接 .zshrc 到 ZDOTDIR
    create_symlink "${ZSHRC_SOURCE}" "${ZDOTDIR_TARGET}/.zshrc"

    # 链接 zsh/ 目录下的配置文件 (.zshenv, .zsh_plugins.txt 等)
    for config_file in "${ZSH_CONFIG_DIR}"/.zsh*; do
        if [[ -f "${config_file}" ]]; then
            local filename
            filename="$(basename "${config_file}")"
            create_symlink "${config_file}" "${ZDOTDIR_TARGET}/${filename}"
        fi
    done

    # 链接 shell/ 目录到 ZDOTDIR
    create_symlink "${SHELL_CONFIG_DIR}" "${ZDOTDIR_TARGET}/shell"

    # 设置 ZDOTDIR 环境变量 (在 ~/.zshenv 中)
    setup_zdotdir

    # Debian: 提示设置 zsh 为默认 shell（轻量模式跳过交互）
    if [[ "${OS_TYPE}" == "debian" ]]; then
        local current_shell
        current_shell="$(getent passwd "${USER}" | cut -d: -f7)"
        if [[ "${current_shell}" != *"zsh"* ]]; then
            if [[ "${LITE_MODE}" -eq 1 ]]; then
                log_info "轻量模式: 跳过 chsh，可手动运行 chsh -s $(command -v zsh) 切换默认 shell"
            else
                echo ""
                read -rp "是否将 zsh 设为默认 shell? (y/n): " set_zsh
                if [[ "${set_zsh}" =~ ^[Yy]$ ]]; then
                    chsh -s "$(command -v zsh)" \
                        && log_success "默认 shell 已设为 zsh" \
                        || log_warn "设置默认 shell 失败，请手动运行: chsh -s $(command -v zsh)"
                fi
            fi
        fi
    fi
}

setup_zdotdir() {
    local zshenv_file="${HOME}/.zshenv"

    # 将 ~/.zshenv 软链接到 dotfiles/zsh/.zshenv
    create_symlink "${ZSH_CONFIG_DIR}/.zshenv" "${zshenv_file}"
}

setup_bash_config() {
    log_info "配置 bash..."

    # 链接 ~/.bashrc
    if [[ -f "${BASHRC_SOURCE}" ]]; then
        create_symlink "${BASHRC_SOURCE}" "${HOME}/.bashrc"
    else
        log_warn "bashrc 文件不存在，跳过 bash 配置"
    fi
}

setup_vim_config() {
    log_info "配置 vim/nvim..."
    
    # 链接 ~/.vimrc
    if [[ -f "${VIMRC_SOURCE}" ]]; then
        create_symlink "${VIMRC_SOURCE}" "${HOME}/.vimrc"
        
        # nvim 也使用相同配置
        local nvim_config_dir="${HOME}/.config/nvim"
        mkdir -p "${nvim_config_dir}"
        create_symlink "${VIMRC_SOURCE}" "${nvim_config_dir}/init.vim"
    else
        log_warn ".vimrc 文件不存在，跳过 vim 配置"
    fi

    # vim-plug 和插件安装（仅完整模式）
    # vim-plug and plugin install (full mode only)
    if [[ "${LITE_MODE}" -eq 1 ]]; then
        log_info "轻量模式: 跳过 vim-plug 和插件安装（vim 保持裸配置）"
        return 0
    fi

    # Install vim-plug for Vim
    # 为 Vim 安装 vim-plug
    local vim_plug_path="${HOME}/.vim/autoload/plug.vim"
    if [[ ! -f "${vim_plug_path}" ]]; then
        log_info "安装 vim-plug (Vim)..."
        curl -fLo "${vim_plug_path}" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
            && log_success "vim-plug (Vim) 安装完成" \
            || log_warn "vim-plug (Vim) 安装失败，首次启动 Vim 时会自动重试"
    else
        log_info "vim-plug (Vim) 已安装"
    fi

    # Install vim-plug for Neovim
    # 为 Neovim 安装 vim-plug
    local nvim_plug_path="${HOME}/.local/share/nvim/site/autoload/plug.vim"
    if [[ ! -f "${nvim_plug_path}" ]]; then
        log_info "安装 vim-plug (Neovim)..."
        curl -fLo "${nvim_plug_path}" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
            && log_success "vim-plug (Neovim) 安装完成" \
            || log_warn "vim-plug (Neovim) 安装失败，首次启动 Neovim 时会自动重试"
    else
        log_info "vim-plug (Neovim) 已安装"
    fi

    # Install plugins
    # 安装 Vim 插件
    if command -v vim &>/dev/null && [[ -f "${vim_plug_path}" ]]; then
        log_info "安装 Vim 插件..."
        vim +PlugInstall +qall 2>/dev/null \
            && log_success "Vim 插件安装完成" \
            || log_warn "Vim 插件安装失败，可稍后在 Vim 中运行 :PlugInstall"
    fi
}

setup_tmux_config() {
    log_info "配置 tmux..."
    
    # 链接 ~/.tmux.conf
    if [[ -f "${TMUX_SOURCE}" ]]; then
        create_symlink "${TMUX_SOURCE}" "${HOME}/.tmux.conf"
    else
        log_warn "tmux.conf 文件不存在，跳过 tmux 配置"
    fi

    # 链接 ~/.tmux -> dotfiles/tmux（TPM 插件目录）
    local tmux_dir="${DOTFILES_DIR}/tmux"
    if [[ -d "${tmux_dir}" ]]; then
        create_symlink "${tmux_dir}" "${HOME}/.tmux"
        # 初始化子模块（确保 tpm 已拉取）—— 轻量模式跳过
        if [[ "${LITE_MODE}" -eq 1 ]]; then
            log_info "轻量模式: 跳过 TPM 子模块初始化"
        else
            (cd "${DOTFILES_DIR}" && git submodule update --init --recursive) || log_warn "子模块初始化失败"
        fi
    fi
}

setup_git_config() {
    log_info "配置 git..."

    # 链接 ~/.gitconfig
    if [[ -f "${GITCONFIG_SOURCE}" ]]; then
        create_symlink "${GITCONFIG_SOURCE}" "${HOME}/.gitconfig"
    else
        log_warn "gitconfig 文件不存在，跳过 git 配置"
    fi

    # 设置 OS 特定的 credential helper (写入 ~/.gitconfig_local)
    setup_git_credential

    # 检查 git 用户名和邮箱是否配置
    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -z "${git_name}" || -z "${git_email}" ]]; then
        if [[ "${LITE_MODE}" -eq 1 ]]; then
            log_info "轻量模式: Git 用户信息未配置，请手动 git config --global user.name / user.email"
        else
            log_warn "Git 用户信息未配置"
            echo ""
            read -rp "是否现在配置 Git 用户信息? (y/n): " do_config
            if [[ "${do_config}" =~ ^[Yy]$ ]]; then
                if [[ -z "${git_name}" ]]; then
                    read -rp "请输入你的 Git 用户名: " git_name
                    git config --global user.name "${git_name}" || die "设置 Git 用户名失败"
                fi
                if [[ -z "${git_email}" ]]; then
                    read -rp "请输入你的 Git 邮箱: " git_email
                    git config --global user.email "${git_email}" || die "设置 Git 邮箱失败"
                fi
                log_success "Git 用户信息配置完成"
            else
                log_info "跳过 Git 用户信息配置"
            fi
        fi
    else
        log_info "Git 用户: ${git_name} <${git_email}>"
    fi
}

# 设置 OS 特定的 git credential helper
setup_git_credential() {
    local local_gitconfig="${HOME}/.gitconfig_local"

    # 如果已存在且包含 credential，不覆盖
    if [[ -f "${local_gitconfig}" ]] && grep -q '\[credential\]' "${local_gitconfig}" 2>/dev/null; then
        log_info "~/.gitconfig_local 已包含 credential 配置"
        return 0
    fi

    local helper=""
    if [[ "${OS_TYPE}" == "macos" ]]; then
        helper="osxkeychain"
    elif [[ "${OS_TYPE}" == "debian" ]]; then
        helper="cache --timeout=86400"
    fi

    if [[ -n "${helper}" ]]; then
        # 追加到 local gitconfig（不覆盖已有内容）
        {
            echo ""
            echo "[credential]"
            echo "	helper = ${helper}"
        } >> "${local_gitconfig}"
        log_success "Git credential helper 已设置: ${helper} (→ ~/.gitconfig_local)"
    fi
}

check_atuin_auth() {
    log_info "检查 Atuin 配置状态..."
    
    if ! command -v atuin &>/dev/null; then
        log_warn "Atuin 未安装，跳过配置"
        return 0
    fi
    
    # 检查是否已登录（检查 key 文件是否存在）
    if [[ -f "${HOME}/.local/share/atuin/key" ]]; then
        log_success "Atuin 已配置"
    else
        log_warn "Atuin 未配置同步"
        echo ""
        echo -e "${YELLOW}Atuin 可以同步你的命令历史记录到云端${NC}"
        echo "  - 注册新账号: atuin register"
        echo "  - 登录已有账号: atuin login"
        echo ""
        read -rp "是否现在配置 Atuin? (r=注册/l=登录/n=跳过): " atuin_choice
        case "${atuin_choice}" in
            [Rr])
                atuin register || log_warn "Atuin 注册失败，可稍后运行 'atuin register'"
                ;;
            [Ll])
                atuin login || log_warn "Atuin 登录失败，可稍后运行 'atuin login'"
                ;;
            *)
                log_info "跳过 Atuin 配置，可稍后运行 'atuin register' 或 'atuin login'"
                ;;
        esac
    fi
}

# ================================
# 主函数
# ================================
main() {
    # 解析命令行参数
    parse_args "$@"

    # 轻量模式仅支持 Linux
    if [[ "${LITE_MODE}" -eq 1 && "$(uname -s)" == "Darwin" ]]; then
        die "轻量模式仅支持 Linux 服务器（macOS 请使用完整模式: bash init.sh）"
    fi

    local mode_label
    if [[ "${LITE_MODE}" -eq 1 ]]; then
        mode_label="轻量 (Linux server)"
    else
        mode_label="完整"
    fi

    echo ""
    echo "======================================="
    echo "   Dotfiles 安装脚本 (macOS / Debian)"
    echo "   模式: ${mode_label}"
    echo "======================================="
    echo ""

    # 前置检查
    detect_os
    check_source_files

    # macOS: Homebrew 必需；Debian: 可选
    if [[ "${OS_TYPE}" == "macos" ]]; then
        check_homebrew
    fi

    # 安装依赖
    install_dependencies

    # 配置 zsh
    setup_zsh_config

    # 配置 bash
    setup_bash_config

    # 配置 vim/nvim
    setup_vim_config

    # 配置 tmux
    setup_tmux_config

    # 配置 git
    setup_git_config

    # 检查 Atuin 配置
    check_atuin_auth

    echo ""
    log_success "安装完成！"
    if command -v zsh &>/dev/null; then
        log_info "请重新启动终端或运行 'exec zsh' 以应用更改"
    else
        log_info "请重新启动终端或运行 'source ~/.bashrc' 以应用更改"
    fi
    echo ""
}

# 执行主函数
main "$@"