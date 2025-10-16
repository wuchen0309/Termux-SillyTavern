<div align="center">

# Termux-SillyTavern

**一个专为 Termux 设计的 SillyTavern 一键式管理脚本，让部署、管理和维护你的酒馆变得前所未有的简单。**

[![GitHub Stars](https://img.shields.io/github/stars/wuchen0309/Termux-SillyTavern.svg?style=for-the-badge&logo=github)](https://github.com/wuchen0309/Termux-SillyTavern)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-blue.svg?style=for-the-badge)](https://github.com/wuchen0309/Termux-SillyTavern/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-2025.10.16-brightgreen.svg?style=for-the-badge)](https://github.com/wuchen0309/Termux-SillyTavern/blob/main/menu.sh)
[![Platform](https://img.shields.io/badge/Platform-Termux%20(Android)-orange.svg?style=for-the-badge&logo=android)](https://termux.dev/cn/index.html)

</div>

---

## ✨ 项目特性

- 🚀 **一键部署**：自动克隆 SillyTavern 仓库，配置环境。
- 📋 **交互式菜单**：直观的文本菜单，操作一目了然。
- 🔧 **智能依赖管理**：自动检测并安装`git`, `nodejs-lts`, `zip`等必要工具。
- 💾 **内置数据备份**：一键备份你的酒馆数据，无需手动操作。
- 🎨 **终端美化**：首次运行自动下载并应用更美观的等宽字体。
- 🧹 **无路径依赖**：所有操作均使用绝对路径，无需关心当前目录。

## 📝 适宜人群

本项目主要面向以下用户：

- **熟悉 Termux 环境**：你对在 Termux 中执行命令、管理文件和理解基本概念有一定经验。
- **具备自主解决问题的能力**：当遇到网络问题、依赖冲突或特定设备兼容性问题时，你愿意并能够通过**询问 AI** 或其他方式来定位并解决问题。

> **重要提示**：
> 本脚本致力于提供一个功能强大且实用的管理工具，而非一个“零基础保姆式”教程。脚本自身会针对一些基础错误给出提示，但如果问题出在 `git`、`pkg` 或 `npm` 等具体命令的执行上，则需要你自行解决。
>
> 因此，我**不提供答疑服务**。如果你希望所有问题都能直接得到解答，那么这个项目可能不适合你。我相信，赋予你强大的工具，比为你解决每一个小问题更有价值。

## 🚀 快速开始

只需一行命令，即可在 Termux 中完成脚本的下载、授权与运行。

复制以下命令到 Termux 中执行即可：

```
curl -o $HOME/menu.sh "https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/refs/heads/main/menu.sh" && chmod +x $HOME/menu.sh && bash $HOME/menu.sh
```

脚本会自动完成环境检测、字体下载等初始化操作，然后你就能看到主菜单了！

## ⚙️ 启动脚本

### 开机自启动（可选）

如果你希望每次打开 Termux 都自动运行此脚本，可以进行如下设置：

1.  执行以下命令，将启动命令写入 `$HOME/.bashrc` 文件：
    ```
    echo 'bash $HOME/menu.sh' > $HOME/.bashrc
    ```
2.  完成后，**完全关闭** Termux 应用（从后台划掉），然后重新打开。

之后每次新打开 Termux 都会自动运行脚本。

### 手动启动

如果你没有设置自启动，或者临时需要手动运行，只需在 Termux 中执行以下命令即可：

```
bash $HOME/menu.sh
```

2.  完成后，**完全关闭** Termux 应用（从后台划掉），然后重新打开。

之后每次新打开 Termux 都会自动运行脚本。

## ⚡ 更新脚本

脚本版本更新时，只需重新执行一遍上面的**安装命令**即可。它会自动覆盖旧版本，无需手动卸载。

## 📖 脚本功能

脚本提供了完整的管理功能，通过数字键选择：

- **部署酒馆**
  - 检测本地是否已安装 SillyTavern。
  - 如果已存在，会询问是否**重新部署**（将删除旧目录并重新克隆）。
  - 可选更新系统包。
  - 可选检查并安装依赖工具。
  - 从 GitHub 克隆最新的SillyTavern `release`分支。

- **启动酒馆**
  - 直接执行`$HOME/SillyTavern/start.sh`，无需切换目录。

- **更新酒馆**
  - 使用`git pull`更新本地 SillyTavern 仓库到最新版。

- **删除酒馆**
  - 安全删除整个SillyTavern目录，删除前会二次确认。

- **备份酒馆**
  - 将`$HOME/SillyTavern/data/default-user/`目录打包成带时间戳的 zip 文件，并保存到手机内部存储的`MySillyTavernBackups`文件夹中。

---

**好好享受你的酒馆之旅吧！ 🎉**
