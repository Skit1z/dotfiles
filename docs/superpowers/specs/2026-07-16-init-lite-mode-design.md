# init.sh 轻量模式 (Lite Mode) 设计

> 日期: 2026-07-16
> 目标: 让 `init.sh` 支持在 Linux 服务器上做"轻量"安装,只铺基础配置,跳过增强工具、编辑器/终端插件、Homebrew 和交互提问。

## 背景与动机

当前 `init.sh` 面向工作站(macOS / Debian),会安装一整套增强工具(atuin 云同步、thefuck、eza、zoxide)、拉取 vim/tmux 插件、在 Linux 上按需安装 Linuxbrew,并有多处交互式提问。BOSS 有多台服务器,希望在这些机器上装得更轻:够用、无人值守、不拉大体积依赖。

## 触发方式

- 命令行参数 `--lite`(别名 `--server`)开启轻量模式。
- `--help` 打印用法。
- 无参数 = 完整模式,行为与现状**完全一致**(向后兼容)。
- 用全局变量 `LITE_MODE=0/1` 贯穿脚本。

### 平台约束

- **轻量模式仅支持 Linux**。若在 macOS 上传入 `--lite`,脚本 `die` 退出并提示"轻量模式仅支持 Linux 服务器"。
- 完整模式仍照常支持 macOS / Debian。

## 完整模式 vs 轻量模式 行为对照

| 组件 | 完整模式 | 轻量模式 (Linux) |
|------|---------|------------------|
| 基础工具 git / neovim / vim / fzf / tmux / zsh / build-essential | ✅ 装 (apt) | ✅ 装 (apt) |
| 增强工具 atuin / eza / thefuck / zoxide | ✅ 装 (curl/pip) | ❌ 跳过 |
| Linuxbrew | 按需 | ❌ 绝不安装,只走 apt |
| antidote (zsh 插件管理) | ✅ git clone | ✅ 保留 (体积小,保证 zsh prompt 可用) |
| vim-plug + `:PlugInstall` | ✅ | ❌ 跳过,vim 保持裸配置 |
| tmux TPM 子模块 + `~/.tmux` 软链接 | ✅ 初始化 | ❌ 跳过 |
| tmux.conf 软链接 | ✅ | ✅ 仍链接 |
| zsh / bash / vim / tmux / git 软链接 | ✅ | ✅ |
| 交互提问 (atuin 登录 / git 用户信息 / 默认 shell 切换) | 交互询问 | ❌ 跳过,改为打印一行提示 |

设计要点:

- `BREW_PACKAGES` / apt 包清单拆成 **BASE** 与 **EXTRA** 两组。轻量模式只装 BASE。
- Debian 的 `install_dependencies_debian` 中,增强工具安装块(zoxide / eza / atuin / thefuck)在轻量模式下整体跳过。
- **保留 antidote**:BOSS 服务器主 shell 是 zsh,去掉 antidote 后 prompt 退化成默认 `%`,不划算;antidote 本身只是小 git clone。

## 顺带修复的健壮性问题

这两处不修的话,轻量模式(工具/插件缺失)会在每次启动时报错。修复对完整模式同样有益,符合"跨机 + 跨系统同步"前提。

### 1. `.zshrc:60` zoxide 未加守卫

现状:
```zsh
# zoxide 初始化
eval "$(zoxide init zsh)"
```
改为:
```zsh
# zoxide 初始化
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
```
与文件中 atuin(line 64)、thefuck(line 46)一致的守卫风格。

### 2. `tmux.conf:188` TPM 加载行未判断存在性

现状:
```tmux
run '~/.tmux/plugins/tpm/tpm'
```
改为:
```tmux
# only load TPM if it's installed (skipped in lite/server installs)
# 仅当 TPM 已安装时加载(轻量/服务器安装会跳过)
if-shell "test -f ~/.tmux/plugins/tpm/tpm" "run '~/.tmux/plugins/tpm/tpm'"
```

## 交互提问在轻量模式下的处理

| 提问点 | 完整模式 | 轻量模式 |
|--------|---------|---------|
| Git 用户名/邮箱未配置 | 询问并写入 | 打印提示:未配置,请手动 `git config --global`;不阻塞 |
| 是否设 zsh 为默认 shell | 询问 `chsh` | 跳过;打印提示可手动 `chsh -s $(command -v zsh)` |
| Atuin 注册/登录 | 询问 | 天然跳过(轻量不装 atuin,`check_atuin_auth` 直接 return) |

## 输出与用户可见变化

- 开头 banner 增加一行显示当前模式:`模式: 轻量 (Linux server)` 或 `模式: 完整`。
- `--help` 输出:用法、`--lite`/`--server`/`--help` 说明、轻量模式跳过项摘要。
- 轻量模式结束时提示与完整模式一致(`exec zsh` 应用更改)。

## 实现落点(涉及文件)

- `init.sh`:参数解析、`LITE_MODE` 分支、BASE/EXTRA 包拆分、各 `setup_*` 与 `install_*` 的轻量分支、banner、`--help`、macOS+lite 的 `die`。
- `.zshrc`:zoxide 守卫(1 行)。
- `tmux.conf`:TPM 加载改 `if-shell`(1 行)。
- `CLAUDE.md`:在"常见操作速查"补一行 `bash init.sh --lite`(可选,实现阶段决定)。

## 非目标 (YAGNI)

- 不为 macOS 提供轻量模式。
- 不做"卸载/回滚"模式。
- 不引入配置文件(如 `.dotfilesrc`)来声明模式;命令行参数已足够。
- 不细分多档轻量级别(只有 完整 / 轻量 两档)。

## 测试方式

- 语法检查:`bash -n init.sh`。
- `bash init.sh --help` 输出正确。
- macOS 上 `bash init.sh --lite` 应 `die` 退出。
- Linux(或容器)上 `bash init.sh --lite`:确认不装 EXTRA 工具、不拉 Linuxbrew、不跑 PlugInstall、不初始化 TPM 子模块、无交互阻塞;软链接与 BASE 工具正常。
- 完整模式回归:`bash init.sh` 行为不变。
