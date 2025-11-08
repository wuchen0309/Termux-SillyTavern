<div align="center">

# Termux-SillyTavern

**一个专为 Termux 设计的 SillyTavern 一键式管理脚本，让部署、管理和维护你的酒馆变得前所未有的简单。**

[![GitHub Stars](https://img.shields.io/github/stars/wuchen0309/Termux-SillyTavern.svg?style=for-the-badge&logo=github)](https://github.com/wuchen0309/Termux-SillyTavern)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-blue.svg?style=for-the-badge)](https://github.com/wuchen0309/Termux-SillyTavern/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-2025.11.9-brightgreen.svg?style=for-the-badge)](https://github.com/wuchen0309/Termux-SillyTavern/blob/main/menu.sh)
[![Platform](https://img.shields.io/badge/Platform-Termux%20(Android)-orange.svg?style=for-the-badge&logo=android)](https://termux.dev/cn/index.html)

</div>

---

## ✨ 项目特性

- 🚀 **一键部署**：自动克隆 SillyTavern 仓库，配置环境。
- 📋 **交互式菜单**：直观的文本菜单，操作一目了然。
- 🔧 **智能依赖管理**：自动检测并安装`git`, `nodejs-lts`, `zip`, `unzip`等必要工具。
- 💾 **内置数据备份**：一键备份你的酒馆数据，无需手动操作。
- 🔄 **智能备份恢复**：自动识别最新备份文件，一键恢复到备份时的完整状态。
- 🎨 **终端美化**：首次运行自动下载并应用更美观的等宽字体。
- 🧹 **无路径依赖**：所有操作均使用绝对路径，无需关心当前目录。
- 🛡️ **安全机制**：操作中断时自动清理临时文件，防止残留垃圾。

## 📝 适宜人群

本项目主要面向以下用户：

- **熟悉 Termux 环境**：你对在 Termux 中执行命令、管理文件和理解基本概念有一定经验。
- **具备自主解决问题的能力**：当遇到网络问题、依赖冲突或特定设备兼容性问题时，你愿意并能够通过**询问 AI** 或其他方式来定位并解决问题。

> **重要提示**：
> 本脚本致力于提供一个功能强大且实用的管理工具，而非一个"零基础保姆式"教程。脚本自身会针对一些基础错误给出提示，但如果问题出在 `git`、`pkg` 或 `npm` 等具体命令的执行上，则需要你自行解决。

## 🚀 快速开始

只需一行命令，即可在 Termux 中完成脚本的下载、授权与运行。

复制以下命令到 Termux 中执行即可：

```bash
curl -o $HOME/menu.sh "https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/refs/heads/main/menu.sh" && chmod +x $HOME/menu.sh && $HOME/menu.sh
```

脚本会自动完成环境检测、字体下载等初始化操作，然后你就能看到主菜单了！

## ⚙️ 启动脚本

### 🔑 开机自启

如果你希望每次打开 Termux 都自动运行此脚本，可以进行如下设置：

1.  执行以下命令，将启动命令写入 `$HOME/.bashrc` 文件：
    ```bash
    echo '$HOME/menu.sh' > $HOME/.bashrc
    ```
2.  完成后，**完全关闭** Termux 应用（从后台划掉），然后重新打开。

之后每次新打开 Termux 都会自动运行脚本。

### 🗝️ 手动启动

如果你没有设置自启动，或者临时需要手动运行，只需在 Termux 中执行以下命令即可：

```bash
$HOME/menu.sh
```

>**⚠️注意事项**：如果你通过编辑器手动修改了 `menu.sh` 文件，其执行权限会丢失。此时直接运行会报错：`Permission denied`。
>必须先使用以下命令重新赋予其执行权限，然后再运行：
>`chmod +x $HOME/menu.sh`

## ⚡ 更新脚本

脚本版本更新时，只需重新执行一遍上面的**安装命令**即可。它会自动覆盖旧版本，无需手动卸载。

## 📖 脚本功能

脚本提供了完整的管理功能，通过数字键选择：

- **部署酒馆**
  - 检测本地是否已安装 SillyTavern。
  - 如果已存在，会询问是否**重新部署**（将删除旧目录并重新克隆）。
  - 可选更新系统包。
  - 可选检查并安装依赖工具。
  - 从 GitHub 克隆最新的 SillyTavern `release` 分支。
  - 支持 Ctrl+C 中断克隆过程。

- **启动酒馆**
  - 直接执行`$HOME/SillyTavern/start.sh`，无需切换目录。

- **更新酒馆**
  - 使用`git pull --rebase --autostash`更新本地 SillyTavern 仓库到最新版。

- **删除酒馆**
  - 安全删除整个 SillyTavern 目录，删除前会二次确认。

- **备份酒馆**
  - 将`$HOME/SillyTavern/data/`完整目录打包成带时间戳的 zip 文件。
  - 备份文件自动保存到手机内部存储的`MySillyTavernBackups`文件夹中。
  - 备份文件命名格式：`sillytavern_backup_YYYYMMDD_HHMMSS.zip`
  - 支持所有用户数据、角色卡片、聊天记录等完整备份。

- **恢复酒馆**
  - 自动检测并选择最新的备份文件进行恢复。
  - 恢复前会警告用户此操作将**永久删除当前数据目录**。
  - 临时目录解压完成后再进行替换，确保操作安全。
  - 支持 Ctrl+C 中断恢复过程，自动清理临时文件。
  - 一键恢复到备份时的完整状态，包括所有角色、聊天记录等。

- **回退酒馆**
  - **回退SillyTavern程序版本**，当新版本出现问题时，可用于切换回旧的稳定版本。
  - 显示当前 SillyTavern 版本信息。
  - 支持输入具体版本号（如 `1.13.4`）、commit hash（如 `a1b2c3d`）或标签。
  - 输入 `release` 可快速回到最新稳定版。
  - 切换前提醒用户备份重要数据。
  - 使用绝对路径操作，不依赖当前工作目录。

- **工具检测**
  - 一个独立的工具检测与安装功能。
  - 可选在检测前更新系统包。
  - 用于修复或验证 `git`, `nodejs-lts`, `zip`, `unzip` 等核心依赖。

## ⚠️ 重要提示

### 备份目录配置

脚本默认将备份保存在手机存储的 `MySillyTavernBackups` 目录中。如果需要修改备份目录名称，请确保同时修改以下位置：

**主菜单脚本**（`$HOME/menu.sh`）中的全局变量：
```bash
BACKUP_DIR="$HOME/storage/shared/MySillyTavernBackups"
```

**备份脚本**（`$HOME/backup_sillytavern.sh`）中的配置：
```bash
backup_dir="$HOME/storage/shared/MySillyTavernBackups"
```

两个脚本中的目录路径必须完全一致，否则恢复备份功能将无法找到备份文件。

### 中断安全

- **部署酒馆**和**恢复酒馆**过程中支持 Ctrl+C 中断操作。
- 中断后脚本会自动清理临时文件和目录，避免残留垃圾数据。

## 🎯 使用建议

1. **定期备份**：在进行更新、回退等操作前，建议先执行备份操作。
2. **版本管理**：使用回退功能时，建议记录当前版本号，以便需要时恢复。
3. **存储空间**：备份文件会占用手机存储空间，建议定期清理旧备份。
4. **网络环境**：部署和更新操作需要稳定的网络连接，建议在 WiFi 环境下进行。

## 📄 许可证

本项目采用 [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！**

</div>