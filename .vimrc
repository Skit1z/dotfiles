" =============================================================================
"  Vim (no plugins) - readable, beautiful, easy (2-space) for iTerm2 & VSCode
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

" --- 外观/信息 ---
set number
set relativenumber
set cursorline
set ruler
set laststatus=2
set showcmd
set showmode
set signcolumn=yes
set scrolloff=4
set sidescrolloff=6
set cmdheight=1

" 真彩：iTerm2 & VSCode 终端一般都支持
if has('termguicolors')
  set termguicolors
endif

set background=dark
silent! colorscheme desert

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
" netrw (内置文件浏览器)：尽量接近“现代文件树”体验
" =============================================================================
let g:netrw_banner=0
let g:netrw_liststyle=3      " tree
let g:netrw_browse_split=4   " open in prior window
let g:netrw_altv=1
let g:netrw_winsize=25
nnoremap <leader>e :Lexplore<CR>

" =============================================================================
" Statusline (纯内置：够用且清晰)
" =============================================================================
set statusline=
set statusline+=\ %f
set statusline+=%m%r%h%w
set statusline+=%=
set statusline+=%{&filetype}\ \|\ %{&fileencoding}\ \|\ %{&fileformat}
set statusline+=\ \|\ %l:%c\ (%p%%)

" =============================================================================
" End
" =============================================================================
