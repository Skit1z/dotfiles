# Dotfiles 开发规范与维护指南

> 本文档是 Claude AI 协助维护此仓库时的标准参考。同时也作为人类开发者的 dotfiles 维护手册。

## 项目概览

```
dotfiles/
├── init.sh              # 安装脚本（macOS）- 创建软链接、安装依赖
├── .zshrc               # Zsh 主配置（antidote 插件管理、工具初始化）
├── bashrc               # Bash 主配置
├── bash_profile         # Bash 登录 shell 入口（仅 source bashrc）
├── tmux.conf            # Tmux 配置（prefix: C-a, 主题: tmux2k duo）
├── gitconfig            # Git 全局配置
├── README.md            # 项目说明
├── zsh/                 # Zsh 特定配置
│   ├── .zshenv          # ZDOTDIR 设置、Homebrew PATH
│   ├── .zsh_plugins.txt # Antidote 插件清单
│   └── .zsh_zoxide      # Zoxide 初始化脚本
├── shell/               # Bash/Zsh 共享配置
│   ├── export           # 环境变量
│   ├── alias            # 命令别名
│   ├── functions.sh     # 自定义函数
│   └── welcome.sh       # 欢迎信息
├── bash/                # Bash 特定配置
│   ├── settings.bash    # 历史记录等设置
│   ├── prompt.bash      # 命令提示符
│   └── plugins.bash     # Bash 插件
└── tmux/                # Tmux 子模块
    └── plugins/tpm/     # TPM 插件管理器（git submodule）
```

### 软链接映射关系（由 init.sh 建立）

| 仓库文件 | 系统位置 |
|----------|----------|
| `.zshrc` | `~/.config/zsh/.zshrc` |
| `zsh/.zshenv` | `~/.zshenv` |
| `zsh/.zsh_*` | `~/.config/zsh/.zsh_*` |
| `shell/` | `~/.config/zsh/shell/` |
| `bashrc` | `~/.bashrc` |
| `tmux.conf` | `~/.tmux.conf` |
| `gitconfig` | `~/.gitconfig` |

## 代码规范

### 1. 文件职责分离

| 文件 | 只放什么 | 不要放什么 |
|------|----------|------------|
| `shell/export` | `export` 环境变量 | alias、函数、source 命令 |
| `shell/alias` | `alias` 命令别名 | export、函数定义 |
| `shell/functions.sh` | 函数定义 | export、alias |
| `shell/welcome.sh` | 交互式 shell 欢迎信息 | 配置逻辑 |
| `.zshrc` | Zsh 专有配置、插件加载 | 通用的 export/alias |
| `bashrc` | Bash 专有配置 | 通用的 export/alias |

### 2. Shell 脚本规范

```bash
# ✅ 正确的环境变量导出
export PATH="$PATH:$HOME/.local/bin"   # 用 $HOME，不硬编码用户名

# ❌ 错误
export PATH="$PATH:/Users/skit1z/.local/bin"   # 硬编码了用户名
JAVA_HOME='$(/usr/libexec/java_home -v 17'     # 缺少闭合括号，单引号阻止展开
```

**原则：**
- 路径中用 `$HOME` 代替 `/Users/skit1z`（便于多机共享）
- 环境变量必须 `export`（否则子进程无法继承）
- 命令替换用 `$()` + 双引号，不用反引号
- 条件判断使用 `[[ ]]`（比 `[ ]` 更安全）
- 在运行命令前用 `command -v xxx &>/dev/null` 检查是否存在
- 避免重复定义同一个变量（如两个不同的 `HOMEBREW_BOTTLE_DOMAIN`）

### 3. Tmux 配置规范

- **前缀键:** `C-a`（模仿 GNU screen）
- **TPM 路径:** `run 'tmux/plugins/tpm/tpm'`（相对于仓库目录，需确保 tmux 的工作目录正确）
- **TPM 初始化必须在文件最后一行**
- 插件通过 `set -g @plugin '...'` 声明，放在文件顶部
- 主题配置（tmux2k）集中在 `# theme configuration` 区块
- tmux 选项的空字符串 `""` 可能被插件当作"未设置"而回退默认值，必要时用 `" "`（空格）

### 4. Git 配置规范

- `gitconfig` 不包含机器特定的凭证信息
- 使用 `user.useConfigOnly = true` 强制每个仓库显式配置用户信息
- 别名保持简短且有记忆性（如 `st` = status, `br` = branch）

### 5. 注释规范

- 所有注释使用**英文原文 + 中文翻译**双行格式：
  ```bash
  # enable mouse control
  # 启用鼠标控制
  set -g mouse on
  ```
- 配置区块之间用空行分隔
- 被注释掉的示例配置用 `# set -g ...` 格式，保留一行即可

## 多机差异处理

### 原则
- 通用配置放在共享文件中
- 机器特定配置通过 `hostname` 条件判断：
  ```bash
  if [[ "$(hostname)" == "Skit1zdeMacBook-Air.local" ]]; then
      # 此机器特有配置
  fi
  ```
- 或通过"本地覆盖"文件（不纳入 git）：
  - `~/.tmux_local.conf`
  - `~/.bashrc_local`

## 新增配置的工作流

1. **确定放置位置** — 按文件职责分离表选择正确文件
2. **添加英文 + 中文双语注释**
3. **测试** — 新开终端 / `source` / `tmux source-file` 验证
4. **提交** — 使用有意义的 commit message：
   ```
   feat: add proxy toggle functions
   fix: correct JAVA_HOME syntax in export
   refactor: move python alias to alias file
   ```

## 常见操作速查

| 操作 | 命令 |
|------|------|
| 安装 dotfiles | `bash init.sh` |
| 重载 zsh 配置 | `exec zsh` |
| 重载 tmux 配置 | `C-a R`（prefix + Shift+r） |
| 安装 tmux 插件 | `C-a I`（prefix + Shift+i） |
| 更新 tmux 插件 | `C-a U`（prefix + Shift+u） |
| 开启终端代理 | `proxy_on [port]`（默认 7890） |
| 关闭终端代理 | `proxy_off` |
| 查看代理状态 | `proxy_status` |

## 已知问题与注意事项

1. **`escape-time` 设为 10ms** — 为了支持 iTerm2 的 Option+方向键切换面板。设为 0 会导致转义序列被截断。
2. **iTerm2 必须将 Option 键设为 `Esc+`** — Settings → Profiles → Keys → General → Left/Right Option key = Esc+
3. **`bash/plugins.bash`** 中引用了 `~/.shell/plugins/dircolors-solarized/` 目录，但该目录可能不存在。
4. **`bash/settings.bash`** 硬编码了 `/opt/homebrew/bin/brew`，应使用与 `.zshenv`/`bashrc` 一致的条件判断。
5. **`tmux.conf` 中 `bind @` 命令** 使用了 `"pane -s ':%%'"`，`pane` 不是 tmux 命令，应为 `join-pane`。
6. **TPM 路径** `run 'tmux/plugins/tpm/tpm'` 是相对路径，如果 tmux 的工作目录不在 dotfiles 根目录则会失败。可改为绝对路径 `run '~/Workspace/dotfiles/tmux/plugins/tpm/tpm'` 或创建 `~/.tmux -> ~/Workspace/dotfiles/tmux` 软链接后使用 `run '~/.tmux/plugins/tpm/tpm'`。
6. **更改任何文件的时候，总是考虑多机同步这个前提**
