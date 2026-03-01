" =============================================================================
"  Vim/Neovim 配置 - 支持 vim-plug 插件管理
"  Works in: Terminal.app / iTerm2 / VSCode / Ghostty
" =============================================================================

" --- 基础 ---
set nocompatible
set encoding=utf-8
scriptencoding utf-8
set hidden
set autoread
set updatetime=300
set shortmess+=c
set history=2000

syntax on
filetype plugin indent on

" =============================================================================
" vim-plug 插件管理
" =============================================================================
" Auto-install vim-plug if not found
" 自动安装 vim-plug（如果不存在）
let s:data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(s:data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo ' . s:data_dir . '/autoload/plug.vim --create-dirs '
    \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

" Color scheme - works well in 256-color terminals
" 配色方案 - 在 256 色终端下也有良好表现
Plug 'joshdick/onedark.vim'
Plug 'morhetz/gruvbox'

" Status line - lightweight and informative
" 状态栏 - 轻量且信息丰富
Plug 'itchyny/lightline.vim'

" File explorer - better than netrw
" 文件浏览器 - 比 netrw 更好用
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

" Syntax highlighting enhancement
" 语法高亮增强
Plug 'sheerun/vim-polyglot'

" Git integration
" Git 集成
Plug 'airblade/vim-gitgutter'

" Auto pairs - brackets, quotes, etc.
" 自动配对 - 括号、引号等
Plug 'jiangmiao/auto-pairs'

" Comment toggle
" 注释切换
Plug 'tpope/vim-commentary'

" Surround - change surrounding chars
" 包围操作 - 修改包围字符
Plug 'tpope/vim-surround'

" LSP client - language server protocol support
" LSP 客户端 - 语言服务器协议支持
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'

" Async auto-completion - works with vim-lsp
" 异步自动补全 - 配合 vim-lsp 使用
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" Floating terminal - works in both Vim and Neovim
" 浮窗终端 - 支持 Vim 和 Neovim
Plug 'voldikss/vim-floaterm'

call plug#end()

" --- 外观/信息 ---
set number
set relativenumber
set cursorline
set ruler
set laststatus=2
set showcmd
set noshowmode        " lightline already shows mode
set signcolumn=yes
set scrolloff=4
set sidescrolloff=6
set cmdheight=1

" Terminal color detection
" 终端颜色检测：仅在支持的终端中启用真彩色
if has('termguicolors')
  " Terminal.app does NOT support truecolor; iTerm2 / Ghostty / VSCode do
  " macOS Terminal.app 不支持真彩色；iTerm2 / Ghostty / VSCode 支持
  if $TERM_PROGRAM ==# 'Apple_Terminal'
    set notermguicolors
  else
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
  endif
endif

" Ensure 256 colors in all terminals
" 确保所有终端至少使用 256 色
if &term =~# '256color' || $TERM_PROGRAM ==# 'Apple_Terminal'
  set t_Co=256
endif

set background=dark

" Color scheme with fallback
" 配色方案（带回退）
try
  let g:gruvbox_contrast_dark = 'medium'
  let g:gruvbox_italic = 1
  colorscheme gruvbox
catch
  try
    colorscheme onedark
  catch
    colorscheme desert
  endtry
endtry

" Lightline configuration
" Lightline 状态栏配置
let g:lightline = {
  \ 'colorscheme': 'gruvbox',
  \ 'active': {
  \   'left':  [['mode', 'paste'], ['readonly', 'filename', 'modified']],
  \   'right': [['lineinfo'], ['percent'], ['filetype', 'fileencoding', 'fileformat']]
  \ },
  \ }

" 搜索显示
set hlsearch
set incsearch
set ignorecase
set smartcase
nnoremap <leader>/ :nohlsearch<CR>

" --- 缩进：2空格 ---
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set smartindent
set shiftround

" --- 换行/可读性 ---
set wrap
set linebreak
set breakindent
set textwidth=0

" 显示不可见字符（更易读）
set list
set listchars=tab:▸\ ,trail:·,extends:»,precedes:«,nbsp:␣

" --- 命令行补全体验 ---
set wildmenu
set wildmode=longest:full,full
set completeopt=menuone,noselect

" --- 性能/大文件 ---
set lazyredraw
set synmaxcol=250

" --- 文件/撤销/备份：可靠 ---
set undofile
if has('persistent_undo')
  let s:undo_dir = expand('~/.vim/undo')
  if !isdirectory(s:undo_dir) | call mkdir(s:undo_dir, 'p') | endif
  execute 'set undodir=' . fnameescape(s:undo_dir)
endif

set backup
set writebackup
set swapfile

let s:backup_dir = expand('~/.vim/backup')
let s:swap_dir   = expand('~/.vim/swap')
if !isdirectory(s:backup_dir) | call mkdir(s:backup_dir, 'p') | endif
if !isdirectory(s:swap_dir)   | call mkdir(s:swap_dir, 'p')   | endif
execute 'set backupdir=' . fnameescape(s:backup_dir) . '//'
execute 'set directory=' . fnameescape(s:swap_dir)   . '//'

" --- 剪贴板：终端下能用就用（macOS 通常 OK） ---
if has('clipboard')
  set clipboard=unnamedplus
endif

" --- 更顺手的默认行为 ---
set backspace=indent,eol,start
set mouse=a
set whichwrap+=<,>,h,l
set splitright
set splitbelow

" 让 Y 像 D/C：复制到行尾
nnoremap Y y$

" =============================================================================
" Keymaps (少而关键)
" =============================================================================
let mapleader=" "

" 保存/退出
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>Q :quitall!<CR>

" 快速切换相对行号
nnoremap <leader>n :set relativenumber!<CR>

" 窗口移动（iTerm2/VSCode 都一致）
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" =============================================================================
" netrw (内置文件浏览器)：作为 NERDTree 的后备
" =============================================================================
let g:netrw_banner=0
let g:netrw_liststyle=3      " tree
let g:netrw_browse_split=4   " open in prior window
let g:netrw_altv=1
let g:netrw_winsize=25

" Use NERDTree if available, otherwise netrw
" 优先使用 NERDTree，否则使用 netrw
if exists(':NERDTreeToggle')
  nnoremap <leader>e :NERDTreeToggle<CR>
else
  nnoremap <leader>e :Lexplore<CR>
endif

" NERDTree settings
" NERDTree 配置
let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeWinSize = 30
" Close vim if NERDTree is the only window remaining
" 如果 NERDTree 是最后一个窗口则关闭 vim
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" =============================================================================
" LSP Configuration (vim-lsp)
" LSP 配置
" =============================================================================

" LSP diagnostics signs
" LSP 诊断标记
let g:lsp_diagnostics_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_float_cursor = 1
let g:lsp_diagnostics_signs_enabled = 1
let g:lsp_diagnostics_signs_error = {'text': '✗'}
let g:lsp_diagnostics_signs_warning = {'text': '▲'}
let g:lsp_diagnostics_signs_hint = {'text': '▸'}
let g:lsp_diagnostics_signs_information = {'text': 'ℹ'}

" Reduce diagnostic delay
" 减少诊断延迟
let g:lsp_diagnostics_echo_delay = 200

" Enable code actions sign
" 启用代码操作标记
let g:lsp_document_code_action_signs_enabled = 0

" Register clangd as LSP server for C/C++
" 注册 clangd 作为 C/C++ 的 LSP 服务器
if executable('clangd')
  augroup lsp_clangd
    autocmd!
    autocmd User lsp_setup call lsp#register_server({
      \ 'name': 'clangd',
      \ 'cmd': {server_info->['clangd', '--background-index', '--clang-tidy']},
      \ 'allowlist': ['c', 'cpp', 'objc', 'objcpp'],
      \ })
  augroup END
endif

" LSP keymaps - only active in buffers with LSP attached
" LSP 快捷键 - 仅在有 LSP 的缓冲区中生效
function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes

  " Go to definition
  " 跳转到定义
  nmap <buffer> gd <plug>(lsp-definition)

  " Go to declaration
  " 跳转到声明
  nmap <buffer> gD <plug>(lsp-declaration)

  " Go to implementation
  " 跳转到实现
  nmap <buffer> gi <plug>(lsp-implementation)

  " Go to type definition
  " 跳转到类型定义
  nmap <buffer> gt <plug>(lsp-type-definition)

  " Find references
  " 查找引用
  nmap <buffer> gr <plug>(lsp-references)

  " Hover documentation
  " 悬浮文档
  nmap <buffer> K <plug>(lsp-hover)

  " Rename symbol
  " 重命名符号
  nmap <buffer> <leader>rn <plug>(lsp-rename)

  " Code action
  " 代码操作
  nmap <buffer> <leader>ca <plug>(lsp-code-action)

  " Format document
  " 格式化文档
  nmap <buffer> <leader>f <plug>(lsp-document-format)

  " Diagnostics navigation
  " 诊断导航
  nmap <buffer> [d <plug>(lsp-previous-diagnostic)
  nmap <buffer> ]d <plug>(lsp-next-diagnostic)

  " Show document diagnostics
  " 显示文档诊断
  nmap <buffer> <leader>dd <plug>(lsp-document-diagnostics)
endfunction

augroup lsp_install
  autocmd!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" Asyncomplete settings
" 异步补全设置
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 0
set completeopt=menuone,noinsert,noselect,preview

" Auto-close preview window after completion
" 补全后自动关闭预览窗口
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" =============================================================================
" Terminal Configuration (vim-floaterm)
" 终端配置
" =============================================================================

" Floaterm settings
" 浮窗终端设置
let g:floaterm_position = 'bottomright'
let g:floaterm_width = 0.9
let g:floaterm_height = 0.4
let g:floaterm_borderchars = '─│─│╭╮╰╯'
let g:floaterm_title = 'Terminal'
let g:floaterm_titleposition = 'left'

" Toggle floating terminal
" 切换浮窗终端
nnoremap <leader>t :FloatermToggle<CR>
tnoremap <leader>t <C-\><C-n>:FloatermToggle<CR>

" Create new floating terminal
" 创建新终端
nnoremap <leader>T :FloatermNew<CR>

" Kill floating terminal
" 关闭浮窗终端
nnoremap <leader>tk :FloatermKill<CR>

" Switch to next/prev floating terminal
" 切换到下一个/上一个终端
nnoremap <leader>tn :FloatermNext<CR>
nnoremap <leader>tp :FloatermPrev<CR>

" =============================================================================
" Statusline fallback (used only if lightline is not loaded)
" 状态栏回退（仅在 lightline 未加载时使用）
" =============================================================================
if !exists('g:loaded_lightline')
  set statusline=
  set statusline+=\ %f
  set statusline+=%m%r%h%w
  set statusline+=%=
  set statusline+=%{&filetype}\ \|\ %{&fileencoding}\ \|\ %{&fileformat}
  set statusline+=\ \|\ %l:%c\ (%p%%)
endif

" =============================================================================
" End
" =============================================================================
