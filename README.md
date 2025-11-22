<div align="center">

# Termux-SillyTavern

**一个专为 Termux 设计的 SillyTavern 一键式管理脚本，让部署、管理和维护你的酒馆变得前所未有的简单。**

[![GitHub Stars](https://img.shields.io/github/stars/wuchen0309/Termux-SillyTavern.svg?style=for-the-badge&logo=github)](https://github.com/wuchen0309/Termux-SillyTavern)
[![License](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-blue.svg?style=for-the-badge)](https://github.com/wuchen0309/Termux-SillyTavern/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/Version-2025.11.10-brightgreen.svg?style=for-the-badge)](https://github.com/wuchen0309/Termux-SillyTavern/blob/main/menu.sh)
[![Platform](https://img.shields.io/badge/Platform-Termux%20(Android)-orange.svg?style=for-the-badge&logo=android)](https://termux.dev/cn/index.html)

</div>

---

## ✨ 核心特性

- **一键部署** - 自动克隆仓库并配置环境，支持中断恢复
- **交互式菜单** - 彩色文本界面，操作直观清晰
- **智能依赖管理** - 自动检测并安装 git、nodejs-lts、zip、unzip
- **完整备份方案** - 一键备份/恢复所有数据，自动识别最新备份
- **版本回退** - 支持切换到任意历史版本或稳定版
- **终端美化** - 首次运行自动配置等宽字体
- **安全机制** - 操作中断时自动清理临时文件

## 🚀 快速开始

在 Termux 中执行以下命令即可完成安装：

```bash
curl -o $HOME/menu.sh "https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/refs/heads/main/menu.sh" && chmod +x $HOME/menu.sh && $HOME/menu.sh
```

脚本会自动完成初始化，然后显示主菜单。

## 🔧 启动方式

**开机自启**

将脚本设置为 Termux 启动时自动运行：

```bash
echo '$HOME/menu.sh' > $HOME/.bashrc
```

完成后重启 Termux 生效。

**手动启动**

随时执行以下命令启动脚本：

```bash
$HOME/menu.sh
```

> 如果提示权限错误，先执行 `chmod +x $HOME/menu.sh` 恢复执行权限。

## 📋 功能说明

**部署酒馆**
- 检测现有安装并提供重新部署选项
- 可选更新系统包和检测依赖工具
- 从 GitHub 克隆 release 分支
- 支持 Ctrl+C 中断

**启动酒馆**
- 直接运行 start.sh，无需切换目录

**更新酒馆**
- 使用 git pull 更新到最新版本

**删除酒馆**
- 安全删除整个目录，删除前二次确认

**备份酒馆**
- 完整备份 data 目录到手机存储
- 备份文件命名：`sillytavern_backup_YYYYMMDD_HHMMSS.zip`
- 保存位置：`手机存储/MySillyTavernBackups`

**恢复酒馆**
- 自动选择最新备份文件
- 恢复前警告并二次确认
- 支持中断操作并自动清理

**回退酒馆**
- 切换到指定版本号、commit hash 或标签
- 输入 `release` 回到最新稳定版
- 显示当前版本信息

**工具检测**
- 独立的依赖检测与安装功能
- 可选更新系统包

## ⚡ 更新脚本

重新执行安装命令即可覆盖旧版本：

```bash
curl -o $HOME/menu.sh "https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/refs/heads/main/menu.sh" && chmod +x $HOME/menu.sh
```

**中断安全**

部署和恢复操作支持 Ctrl+C 中断，脚本会自动清理临时文件。

## 💡 使用建议

- 重要操作前先执行备份
- 使用回退功能时记录当前版本号
- 定期清理旧备份释放存储空间

## 📄 许可证

本项目采用 [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

<div align="center">

**如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！**

</div>
