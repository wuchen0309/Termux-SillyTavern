# Termux-SillyTavern

一个专为 Termux 设计的 SillyTavern 一键式管理脚本，让部署、管理和维护你的酒馆变得前所未有的简单。

## ✨ 特性

- 🚀 **一键部署**：自动克隆 SillyTavern 仓库，配置环境。
- 📋 **交互式菜单**：直观的文本菜单，操作一目了然。
- 🔧 **智能依赖管理**：自动检测并安装 `git`, `nodejs-lts`, `zip` 等必要工具。
- 💾 **内置数据备份**：一键备份你的酒馆数据，无需手动操作。
- 🎨 **终端美化**：首次运行自动下载并应用更美观的等宽字体。
- 🧹 **无路径依赖**：所有操作均使用绝对路径，无需关心当前目录。

## 🚀 快速开始

只需一行命令，即可在 Termux 中完成脚本的下载、授权与运行。

复制以下命令到 Termux 中执行即可：

```
curl -o $HOME/menu.sh "https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/refs/heads/main/menu.sh" && chmod +x $HOME/menu.sh && bash $HOME/menu.sh
```

脚本会自动完成环境检测、字体下载等初始化操作，然后你就能看到主菜单了！

## ⚙️ 开机自启动（可选）

如果你希望每次打开 Termux 都自动运行此脚本，可以进行如下设置：

1.  执行以下命令，将启动命令写入 `$HOME/.bashrc` 文件：

    ```
    echo 'bash $HOME/menu.sh' > $HOME/.bashrc
    ```

2.  完成后，**完全关闭** Termux 应用（从后台划掉），然后重新打开。

之后每次新打开 Termux 都会自动运行脚本。

## 🔄 更新脚本

脚本版本更新时，只需重新执行一遍上面的**安装命令**即可。它会自动覆盖旧版本，无需手动卸载。

## 📖 脚本功能详解

脚本提供了完整的管理功能，通过数字键选择：

- **部署酒馆**
  - 检测本地是否已安装 SillyTavern。
  - 如果已存在，会询问是否**重新部署**（将删除旧目录并重新克隆）。
  - 可选更新系统包。
  - 可选检查并安装依赖工具。
  - 从 GitHub 克隆最新的 SillyTavern `release` 分支。

- **启动酒馆**
  - 直接执行 `$HOME/SillyTavern/start.sh`，无需切换目录。

- **更新酒馆**
  - 使用 `git pull` 更新本地 SillyTavern 仓库到最新版。

- **删除酒馆**
  - 安全删除整个 SillyTavern 目录，删除前会二次确认。

- **备份酒馆**
  - 将 `$HOME/SillyTavern/data/default-user/` 目录打包成带时间戳的 zip 文件，并保存到手机内部存储的 `MySillyTavernBackups` 文件夹中。

---

**好好享受你的酒馆之旅吧！ 🎉**
