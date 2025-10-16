#!/bin/bash

###############################################
# SillyTavern Termux 管理脚本
###############################################

# ==== 彩色输出定义 ====
YELLOW='\033[1;33m'
GREEN='\033[38;5;40m'
BLUE='\033[38;5;33m'
MAGENTA='\033[38;5;129m'
CYAN='\033[38;5;44m'
BRIGHT_CYAN='\033[38;5;51m'
BRIGHT_GREEN='\033[38;5;46m'
BRIGHT_RED='\033[38;5;196m'
BOLD='\033[1m'
NC='\033[0m'

# ==== 全局配置 ====
REPO_URL="https://github.com/SillyTavern/SillyTavern"
REPO_BRANCH="release"
SILLYTAVERN_DIR="$HOME/SillyTavern"
START_SCRIPT="$SILLYTAVERN_DIR/start.sh"
BACKUP_SCRIPT="$HOME/backup_sillytavern.sh"
FONT_URL="https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/main/font.ttf"
FONT_PATH="$HOME/.termux/font.ttf"
REQUIRED_TOOLS=(git nodejs-lts zip)

# ==== 日志 / 输出工具 ====
print_section()  { echo -e "${CYAN}${BOLD}==== $1 ====${NC}"; }
log_success()    { echo -e "${GREEN}$1${NC}"; }
log_notice()     { echo -e "${YELLOW}$1${NC}"; }
log_warn()       { echo -e "${YELLOW}${BOLD}$1${NC}"; }
log_error()      { echo -e "${BRIGHT_RED}${BOLD}$1${NC}"; }
log_hint()       { echo -e "${CYAN}$1${NC}"; }
log_prompt()     { echo -ne "${BRIGHT_CYAN}${BOLD}$1${NC}"; }

# ==== 基础交互函数 ====
confirm_choice() {
    local prompt="$1" input
    while true; do
        log_prompt "$prompt"
        read -r input
        input=$(echo "$input" | tr '[:upper:]' '[:lower:]' | xargs)
        case "$input" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     log_warn "请输入 y/yes 或 n/no！" ;;
        esac
    done
}

press_any_key() {
    log_notice "按任意键返回菜单..."
    read -n1 -s
}

# ==== 环境准备函数 ====
ensure_termux_font() {
    if [ -f "$FONT_PATH" ]; then
        log_success "字体文件已存在，跳过下载"
        return 0
    fi

    print_section "检查并下载字体文件"
    log_notice "字体文件不存在，正在下载..."

    # 确保目录存在
    mkdir -p "$(dirname "$FONT_PATH")"

    if curl -L --progress-bar -o "$FONT_PATH" "$FONT_URL"; then
        log_success "字体文件下载完成！"
        
        # 尝试重新加载 Termux 设置以立即应用字体
        if command -v termux-reload-settings >/dev/null 2>&1; then
            log_notice "正在应用新字体..."
            termux-reload-settings
            log_success "新字体已应用！"
        else
            log_warn "termux-reload-settings 命令不可用，请重启 Termux 以应用新字体。"
        fi
    else
        log_error "字体文件下载失败！"
        return 1
    fi
}

ensure_termux_storage() {
    local shared_dir="$HOME/storage/shared"
    if [ -d "$shared_dir" ]; then
        return 0
    fi

    log_warn "检测到共享存储目录不存在，正在设置存储权限..."
    termux-setup-storage
    log_hint "请在弹窗中授权存储权限，授权完成后按 Enter 继续..."
    read -r

    if [ ! -d "$shared_dir" ]; then
        log_error "错误：共享存储目录创建失败！请检查存储权限。"
        exit 1
    fi

    log_success "共享存储目录设置完成！"
}

ensure_backup_script() {
    if [ -f "$BACKUP_SCRIPT" ]; then
        return 0
    fi

    log_notice "首次使用：正在创建备份脚本..."
    cat >"$BACKUP_SCRIPT"<<'EOF'
#!/bin/bash
src_dir="$HOME/SillyTavern/data/default-user/"
tmp_dir="$HOME/tmp_sillytavern_backup_copy"
backup_dir_base="$HOME/storage/shared/"
backup_dir_name="MySillyTavernBackups"
folder_name_in_zip="default-user"
backup_dir="${backup_dir_base}${backup_dir_name}"
timestamp=$(date +%Y%m%d_%H%M%S)
backup_name="sillytavern_backup_$timestamp.zip"

echo "== 开始备份 SillyTavern 数据 =="
echo "源目录: $src_dir"
echo "备份目标目录: $backup_dir"

[ ! -d "$src_dir" ]       && { echo "❌ 错误：源目录 '$src_dir' 不存在！"; exit 1; }
[ ! -d "$backup_dir_base" ] && { echo "❌ 错误：Termux 存储链接目录 '$backup_dir_base' 不存在。"; exit 1; }

mkdir -p "$backup_dir" || { echo "❌ 错误：无法创建备份目标目录 '$backup_dir'！"; exit 1; }
rm -rf "$tmp_dir"
mkdir -p "$tmp_dir" || { echo "❌ 错误：无法创建临时目录 '$tmp_dir'！"; exit 1; }

echo "正在拷贝数据到临时目录..."
cp -r "$src_dir" "$tmp_dir/$folder_name_in_zip" || { echo "❌ 拷贝失败！"; rm -rf "$tmp_dir"; exit 1; }

cd "$tmp_dir" || { echo "❌ 无法进入临时目录 '$tmp_dir'！"; rm -rf "$tmp_dir"; exit 1; }

echo "正在压缩备份文件..."
if zip -r "$backup_dir/$backup_name" "$folder_name_in_zip"; then
    echo "✅ 备份成功完成！备份文件保存至: $backup_dir/$backup_name"
else
    echo "❌ 压缩失败！"
fi

cd "$HOME"
rm -rf "$tmp_dir"
echo "== 备份流程结束 =="
EOF

    log_success "备份脚本初始化完成！"
}

check_tools() {
    print_section "检查必要工具"
    declare -A tool_status
    declare -A tool_commands=(
        ["git"]="git"
        ["nodejs-lts"]="nodejs-lts"
        ["zip"]="zip"
    )
    local missing_tools=()

    for tool in "${REQUIRED_TOOLS[@]}"; do
        local cmd="${tool_commands[$tool]}"
        local detected=0

        if [ -n "$cmd" ] && command -v "$cmd" >/dev/null 2>&1; then
            detected=1
        fi

        if [ "$tool" = "nodejs-lts" ] && command -v node >/dev/null 2>&1; then
            detected=1
        fi

        if [ $detected -eq 1 ]; then
            log_success "✓ ${tool} 已安装"
            tool_status["$tool"]="installed"
        else
            log_warn "⚠ ${tool} 未安装，准备安装..."
            tool_status["$tool"]="pending"
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_notice "正在安装缺失的工具..."
        if ! pkg install -y "${missing_tools[@]}"; then
            log_error "✗ 工具安装失败"
            return 1
        fi
        for tool in "${missing_tools[@]}"; do
            tool_status["$tool"]="installed"
        done
    fi

    local installed=0
    for status in "${tool_status[@]}"; do
        [[ "$status" == "installed" ]] && ((installed++))
    done
    log_success "工具检查完成！已安装: ${installed} 个"
    return 0
}

###############################################
# 核心操作函数
###############################################

deploy_sillytavern() {
    print_section "部署酒馆"

    if [ -d "$SILLYTAVERN_DIR" ]; then
        log_warn "检测到已有 SillyTavern 目录"
        if ! confirm_choice "重新部署? (y/n): "; then
            log_notice "取消部署"
            return 0
        fi
        log_notice "清理旧目录..."
        rm -rf "$SILLYTAVERN_DIR"
    fi

    if confirm_choice "部署前是否更新系统包? (y/n): "; then
        print_section "更新系统包"
        log_notice "正在更新系统包，请稍候..."
        if ! (pkg update -y && pkg upgrade -y); then
            log_error "❌ 系统包更新失败！"
            if ! confirm_choice "是否继续部署? (y/N): "; then
                log_notice "取消部署，返回主菜单"
                return 1
            fi
        fi
    else
        log_notice "跳过系统包更新"
    fi

    if confirm_choice "克隆前是否检测工具是否安装? (y/n): "; then
        if ! check_tools; then
            log_error "工具安装失败，部署取消！"
            return 1
        fi
    else
        log_notice "跳过工具检测"
    fi

    log_notice "准备克隆仓库..."
    log_hint "提示：按 CTRL+C 可中断克隆过程"

    local clone_aborted=0
    trap 'clone_aborted=1; log_error "\n检测到中断信号！已取消克隆。"' INT

    if git clone "$REPO_URL" -b "$REPO_BRANCH" "$SILLYTAVERN_DIR"; then
        trap - INT
        if [ $clone_aborted -eq 1 ]; then
            return 1
        fi
        log_success "✅ 酒馆部署完成！"
    else
        trap - INT
        if [ $clone_aborted -eq 1 ]; then
            return 1
        fi
        log_error "❌ 酒馆克隆失败！"
        return 1
    fi
}

start_sillytavern() {
    print_section "启动酒馆"

    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        log_error "酒馆目录不存在，无法启动。"
        return 1
    fi

    if [ ! -f "$START_SCRIPT" ]; then
        log_error "start.sh 不存在，无法启动。"
        return 1
    fi

    bash "$START_SCRIPT"
}

update_sillytavern() {
    print_section "更新酒馆"

    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        log_error "酒馆目录不存在，无法更新。"
        return 1
    fi

    if [ ! -d "$SILLYTAVERN_DIR/.git" ]; then
        log_error "检测到目录 $SILLYTAVERN_DIR 不是 Git 仓库，无法执行更新。"
        return 1
    fi

    if git -C "$SILLYTAVERN_DIR" pull --rebase --autostash; then
        log_success "酒馆更新完成！"
    else
        log_error "酒馆更新失败！"
    fi
}

delete_sillytavern() {
    print_section "删除酒馆"

    if [ ! -d "$SILLYTAVERN_DIR" ]; then
        log_notice "酒馆目录不存在，无需删除。"
        return 0
    fi

    log_warn "警告：此操作将永久删除 SillyTavern 目录及其所有内容！"
    if confirm_choice "确认删除? (y/N): "; then
        if rm -rf "$SILLYTAVERN_DIR"; then
            log_success "酒馆删除完成！"
        else
            log_error "酒馆删除失败！"
        fi
    else
        log_notice "取消删除"
    fi
}

backup_sillytavern() {
    print_section "备份酒馆"

    if [ ! -f "$BACKUP_SCRIPT" ]; then
        log_error "备份脚本不存在，无法备份。"
        return 1
    fi

    bash "$BACKUP_SCRIPT"
}

###############################################
# 菜单与主循环
###############################################

show_menu() {
    clear
    echo -e "${CYAN}${BOLD}==== SillyTavern 一键管理菜单 ====${NC}"
    echo -e "${YELLOW}${BOLD}0. 退出脚本${NC}"
    echo -e "${GREEN}${BOLD}1. 部署酒馆${NC}"
    echo -e "${BLUE}${BOLD}2. 启动酒馆${NC}"
    echo -e "${MAGENTA}${BOLD}3. 更新酒馆${NC}"
    echo -e "${BRIGHT_RED}${BOLD}4. 删除酒馆${NC}"
    echo -e "${BRIGHT_CYAN}${BOLD}5. 备份酒馆${NC}"
    echo -e "${CYAN}${BOLD}==================================${NC}"
    log_prompt "请选择操作 (0-5): "
}

main() {
    clear
    ensure_termux_font
    ensure_termux_storage
    ensure_backup_script

    while true; do
        show_menu
        read -r choice
        case "$choice" in
            0) clear; exit 0 ;;
            1) deploy_sillytavern;   press_any_key ;;
            2) start_sillytavern;    press_any_key ;;
            3) update_sillytavern;   press_any_key ;;
            4) delete_sillytavern;   press_any_key ;;
            5) backup_sillytavern;   press_any_key ;;
            *) log_error "无效选择，请重新输入！"; sleep 1 ;;
        esac
    done
}

main
