#!/bin/bash
#
# dotfiles 安装脚本 (macOS)
# 用途: 将 dotfiles 链接到正确位置并安装必要依赖
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
readonly ZSH_CONFIG_DIR="${DOTFILES_DIR}/zsh"
readonly SHELL_CONFIG_DIR="${DOTFILES_DIR}/shell"

# 需要安装的 brew 包
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
# 检查函数
# ================================
check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        die "此脚本仅支持 macOS 系统"
    fi
    log_info "系统检查通过: macOS"
}

check_homebrew() {
    # 先尝试初始化 Homebrew PATH
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    if ! command -v brew &>/dev/null; then
        log_warn "未检测到 Homebrew，正在安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "Homebrew 安装失败"
        # 安装后再次初始化 PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
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
install_dependencies() {
    log_info "安装依赖..."
    
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
    
    # 如果目标已经是正确的符号链接，跳过
    if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
        log_info "符号链接已存在: ${target}"
        return 0
    fi
    
    # 备份已存在的文件/目录
    backup_existing "${target}"
    
    # 删除已存在的符号链接
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
    
    # 先清理旧的符号链接
    cleanup_old_symlinks
    
    # 创建 ZDOTDIR 目录（包括父目录）
    mkdir -p "${ZDOTDIR_TARGET}" || die "创建目录失败: ${ZDOTDIR_TARGET}"
    
    # 链接 .zshrc 到 ZDOTDIR
    create_symlink "${ZSHRC_SOURCE}" "${ZDOTDIR_TARGET}/.zshrc"
    
    # 链接 zsh/ 目录下的配置文件 (.zshenv, .zsh_plugins.txt, .zsh_zoxide 等)
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
}

setup_git_config() {
    log_info "配置 git..."
    
    # 链接 ~/.gitconfig
    if [[ -f "${GITCONFIG_SOURCE}" ]]; then
        create_symlink "${GITCONFIG_SOURCE}" "${HOME}/.gitconfig"
    else
        log_warn "gitconfig 文件不存在，跳过 git 配置"
    fi
    
    # 检查 git 用户名和邮箱是否配置
    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [[ -z "${git_name}" || -z "${git_email}" ]]; then
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
    else
        log_info "Git 用户: ${git_name} <${git_email}>"
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
    echo ""
    echo "================================"
    echo "   Dotfiles 安装脚本 (macOS)"
    echo "================================"
    echo ""
    

    # 前置检查
    check_macos
    check_source_files
    check_homebrew
    
    # 安装依赖
    install_dependencies
    
    # 配置 zsh
    setup_zsh_config
    
    # 配置 bash
    setup_bash_config
    
    # 配置 vim/nvim
    setup_vim_config
    
    # 配置 git
    setup_git_config
    
    # 检查 Atuin 配置
    check_atuin_auth
    
    echo ""
    log_success "安装完成！"
    log_info "请重新启动终端或运行 'exec zsh' 以应用更改"
    echo ""
}

# 执行主函数
main "$@"