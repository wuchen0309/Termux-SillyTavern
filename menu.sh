#!/usr/bin/env bash

###############################################
# SillyTavern Termux 管理脚本
###############################################

set -o pipefail
shopt -s nullglob

###############################################
# 彩色输出定义
###############################################
declare -r YELLOW='\033[1;33m' GREEN='\033[38;5;40m' BLUE='\033[38;5;33m' MAGENTA='\033[38;5;129m' CYAN='\033[38;5;44m'
declare -r BRIGHT_CYAN='\033[38;5;51m' BRIGHT_GREEN='\033[38;5;46m' BRIGHT_RED='\033[38;5;196m' TEAL='\033[38;5;36m'
declare -r ORANGE='\033[38;5;208m' PURPLE='\033[38;5;93m' BOLD='\033[1m' NC='\033[0m'

###############################################
# 全局配置
###############################################
declare -r REPO_URL="https://github.com/SillyTavern/SillyTavern"
declare -r REPO_BRANCH="release"
declare -r SILLYTAVERN_DIR="$HOME/SillyTavern"
declare -r START_SCRIPT="$SILLYTAVERN_DIR/start.sh"
declare -r BACKUP_SCRIPT="$HOME/backup_sillytavern.sh"
declare -ar REQUIRED_TOOLS=(git nodejs-lts zip unzip)
declare -r FONT_URL="https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/main/font.ttf"
declare -r FONT_PATH="$HOME/.termux/font.ttf"
declare -r BACKUP_DIR="$HOME/storage/shared/MySillyTavernBackups"
declare -r TMP_RESTORE_DIR="$HOME/tmp_sillytavern_restore"
declare -r DATA_DIR="$SILLYTAVERN_DIR/data"

###############################################
# 日志 / 输出工具
###############################################
print_section() { printf "%b\n" "${CYAN}${BOLD}==== $1 ====${NC}"; }
log_success()   { printf "%b\n" "${GREEN}$1${NC}"; }
log_notice()    { printf "%b\n" "${YELLOW}$1${NC}"; }
log_warn()      { printf "%b\n" "${YELLOW}${BOLD}$1${NC}"; }
log_error()     { printf "%b\n" "${BRIGHT_RED}${BOLD}$1${NC}"; }
log_hint()      { printf "%b\n" "${CYAN}$1${NC}"; }
log_prompt()    { printf "%b" "${BRIGHT_CYAN}${BOLD}$1${NC}"; }

###############################################
# 基础交互函数
###############################################
confirm_choice() {
    local input
    while true; do
        log_prompt "$1"
        read -r input
        case "${input,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *)     log_warn "请输入 y/yes 或 n/no！" ;;
        esac
    done
}

press_any_key() { 
    log_notice "按任意键返回菜单..."
    # 重置终端并清理残留输入
    stty sane 2>/dev/null || true
    while read -r -t 0; do read -r; done 2>/dev/null || true
    read -rsn1 2>/dev/null || true
}

run() { 
    local exit_code=0
    
    # 捕获 INT 信号，防止脚本直接退出
    # 子进程仍可接收信号并正常终止
    trap ':' INT
    
    "$@" || exit_code=$?
    
    # 恢复默认信号处理
    trap - INT
    
    # 130 是 SIGINT 的标准退出码
    if (( exit_code == 130 )); then
        log_warn "操作被用户中断"
    fi
    
    press_any_key
}

###############################################
# 环境准备函数
###############################################
ensure_termux_font() {
    [[ -f "$FONT_PATH" ]] && { log_success "字体文件已存在，跳过下载"; return 0; }
    print_section "检查并下载字体文件"
    log_notice "字体文件不存在，正在下载..."
    mkdir -p -- "$(dirname -- "$FONT_PATH")"
    if curl -L --progress-bar -o "$FONT_PATH" "$FONT_URL"; then
        log_success "字体文件下载完成！"
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
    [[ -d "$HOME/storage/shared" ]] && return 0
    log_warn "检测到共享存储目录不存在，正在设置存储权限..."
    termux-setup-storage
    log_hint "请在弹窗中授权存储权限，授权完成后按回车继续..."
    read -r
    [[ -d "$HOME/storage/shared" ]] || { log_error "错误：共享存储目录创建失败！请检查存储权限。"; exit 1; }
    log_success "共享存储目录设置完成！"
}

ensure_backup_script() {
    [[ -f "$BACKUP_SCRIPT" ]] && return 0
    log_notice "首次使用：正在创建备份脚本..."
    cat >"$BACKUP_SCRIPT"<<'EOF'
#!/usr/bin/env bash
src_dir="$HOME/SillyTavern/data/"
tmp_dir="$HOME/tmp_sillytavern_backup_copy"
backup_dir="$HOME/storage/shared/MySillyTavernBackups"
timestamp=$(date +%Y%m%d_%H%M%S)
backup_name="sillytavern_backup_$timestamp.zip"
backup_path="$backup_dir/$backup_name"

cleanup() {
    [[ -d "$tmp_dir" ]] && rm -rf "$tmp_dir" && echo "✓ 临时目录已清理"
    [[ -f "$backup_path" ]] && [[ ! -s "$backup_path" ]] && rm -f "$backup_path" && echo "✓ 未完成的备份文件已清理"
}
trap 'echo -e "\n❌ 检测到中断信号！"; cleanup; echo "== 备份已取消 =="; exit 130' INT TERM

echo "====================================="
echo "  SillyTavern 数据备份工具"
echo "====================================="
echo "源目录: $src_dir"
echo "备份目标: $backup_path"
echo ""

[[ -d "$src_dir" ]] || { echo "❌ 错误：源目录 '$src_dir' 不存在！"; exit 1; }
[[ -d "$HOME/storage/shared" ]] || { echo "❌ 错误：Termux 存储链接目录不存在。"; echo "提示：请先运行 termux-setup-storage 授权存储权限"; exit 1; }
mkdir -p "$backup_dir" || { echo "❌ 错误：无法创建备份目标目录！"; exit 1; }

echo "[1/4] 准备临时目录..."
rm -rf "$tmp_dir"
mkdir -p "$tmp_dir" || { echo "❌ 错误：无法创建临时目录！"; exit 1; }
echo "✓ 临时目录准备完成"

echo "[2/4] 正在拷贝数据到临时目录..."
cp -r "$src_dir" "$tmp_dir/data" || { echo "❌ 拷贝失败！"; cleanup; exit 1; }
echo "✓ 数据拷贝完成"

cd "$tmp_dir" || { echo "❌ 无法进入临时目录！"; cleanup; exit 1; }

echo "[3/4] 正在压缩备份文件..."
zip -r "$backup_path" "data" >/dev/null 2>&1 || { echo "❌ 压缩失败！"; cleanup; exit 1; }
echo "✓ 压缩完成"

echo "[4/4] 正在清理临时目录..."
cd "$HOME"
rm -rf "$tmp_dir"
echo "✓ 清理完成"

echo ""
echo "====================================="
echo "✅ 备份成功完成！"
echo "====================================="
echo "备份文件: $backup_name"
echo "保存位置: $backup_dir"
echo "文件大小: $(du -h "$backup_path" | cut -f1)"
echo "====================================="

trap - INT TERM
EOF
    chmod +x "$BACKUP_SCRIPT"
    log_success "备份脚本初始化完成！"
}

update_system() {
    print_section "更新系统包"
    log_notice "正在更新系统包，请稍候..."
    (pkg update -y && pkg upgrade -y) || { log_error "❌ 系统包更新失败！"; return 1; }
    log_success "系统包更新完成！"
}

check_tools_impl() {
    local missing_tools=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        local cmd="$tool"; [[ "$tool" == "nodejs-lts" ]] && cmd="node"
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "✓ ${tool} 已安装"
        else
            log_warn "⚠ ${tool} 未安装，准备安装..."
            missing_tools+=("$tool")
        fi
    done

    if ((${#missing_tools[@]})); then
        log_notice "正在安装缺失的工具..."
        pkg install -y "${missing_tools[@]}" || { log_error "✗ 工具安装失败"; return 1; }
    fi
    log_success "工具检查完成！已安装: ${#REQUIRED_TOOLS[@]} 个"
}

check_tools() {
    print_section "检查必要工具"
    check_tools_impl
}

check_tools_manual() {
    print_section "工具检测"
    if confirm_choice "检测前是否更新系统包? (y/n): "; then
        update_system || {
            log_error "❌ 系统包更新失败！"
            confirm_choice "是否继续工具检测? (y/n): " || { log_notice "取消工具检测，返回主菜单"; return 0; }
        }
    else
        log_notice "跳过系统包更新"
    fi
    check_tools_impl
}

###############################################
# 核心操作函数
###############################################
deploy_sillytavern() {
    print_section "部署酒馆"
    
    if [[ -d "$SILLYTAVERN_DIR" ]]; then
        log_warn "检测到已有 SillyTavern 目录"
        confirm_choice "重新部署? (y/n): " || { log_notice "取消部署"; return 0; }
        log_notice "清理旧目录..."
        rm -rf -- "$SILLYTAVERN_DIR"
    fi

    if confirm_choice "部署前是否更新系统包? (y/n): "; then
        update_system || {
            confirm_choice "是否继续部署? (y/n): " || { log_notice "取消部署，返回主菜单"; return 1; }
        }
    else
        log_notice "跳过系统包更新"
    fi

    if confirm_choice "克隆前是否检测工具是否安装? (y/n): "; then
        check_tools || { log_error "工具安装失败，部署取消！"; return 1; }
    else
        log_notice "跳过工具检测"
    fi

    log_notice "准备克隆仓库..."
    log_hint "提示：按 CTRL+C 可中断克隆过程"
    if git clone "$REPO_URL" -b "$REPO_BRANCH" "$SILLYTAVERN_DIR"; then
        log_success "✅ 酒馆部署完成！"
    else
        log_error "❌ 酒馆克隆失败！"
    fi
}

start_sillytavern() {
    print_section "启动酒馆"
    [[ -d "$SILLYTAVERN_DIR" ]] || { log_error "酒馆目录不存在，无法启动。"; return 1; }
    [[ -f "$START_SCRIPT"    ]] || { log_error "start.sh 不存在，无法启动。"; return 1; }
    bash "$START_SCRIPT"
}

update_sillytavern() {
    print_section "更新酒馆"
    [[ -d "$SILLYTAVERN_DIR"      ]] || { log_error "酒馆目录不存在，无法更新。"; return 1; }
    [[ -d "$SILLYTAVERN_DIR/.git" ]] || { log_error "检测到目录 $SILLYTAVERN_DIR 不是 Git 仓库，无法执行更新。"; return 1; }
    git -C "$SILLYTAVERN_DIR" pull --rebase --autostash && \
        log_success "酒馆更新完成！" || log_error "酒馆更新失败！"
}

delete_sillytavern() {
    print_section "删除酒馆"
    [[ -d "$SILLYTAVERN_DIR" ]] || { log_notice "酒馆目录不存在，无需删除。"; return 0; }
    
    log_warn "警告：此操作将永久删除 SillyTavern 目录及其所有内容！"
    confirm_choice "确认删除? (y/n): " && {
        rm -rf -- "$SILLYTAVERN_DIR" && log_success "酒馆删除完成！" || log_error "酒馆删除失败！"
    } || log_notice "取消删除"
}

backup_sillytavern() {
    print_section "备份酒馆"
    [[ -f "$BACKUP_SCRIPT" ]] && { bash "$BACKUP_SCRIPT"; return $?; }
    log_error "备份脚本不存在，无法备份。"
    return 1
}

restore_sillytavern() {
    print_section "恢复酒馆"

    trap 'log_error "\n检测到中断信号！正在清理..."; rm -rf -- "$TMP_RESTORE_DIR"; exit 1' INT
    trap 'rm -rf -- "$TMP_RESTORE_DIR"' RETURN
    
    [[ -d "$SILLYTAVERN_DIR" ]] || { log_error "SillyTavern目录不存在，请先部署SillyTavern！"; return 1; }
    [[ -d "$BACKUP_DIR"      ]] || { log_error "备份目录不存在: $BACKUP_DIR"; log_hint "请先创建备份后再尝试恢复"; return 1; }
    
    [[ -d "$DATA_DIR" ]] || { log_warn "data目录不存在，将自动创建"; mkdir -p -- "$DATA_DIR"; }
    
    log_warn "警告：此操作将永久删除当前的data目录并恢复备份！"
    confirm_choice "确定要继续恢复备份吗？(y/n): " || { log_notice "已取消恢复操作，请返回主菜单"; return 0; }

    local backups=("$BACKUP_DIR"/sillytavern_backup_*.zip)
    ((${#backups[@]})) || { log_error "未找到任何备份文件！"; return 1; }
    
    local latest_backup
    latest_backup=$(ls -t "${backups[@]}" 2>/dev/null | head -n1)
    [[ -n "$latest_backup" ]] || { log_error "未找到任何备份文件！"; return 1; }
    
    log_success "找到最新备份: $(basename -- "$latest_backup")"

    log_notice "正在删除当前data目录..."
    rm -rf -- "$DATA_DIR"

    log_notice "正在解压备份文件..."
    mkdir -p -- "$TMP_RESTORE_DIR"
    unzip -q "$latest_backup" -d "$TMP_RESTORE_DIR" || { log_error "解压备份文件失败！"; return 1; }

    [[ -d "$TMP_RESTORE_DIR/data" ]] || { log_error "备份文件格式错误：未找到data目录！"; return 1; }

    log_notice "正在恢复数据..."
    mv -- "$TMP_RESTORE_DIR/data" "$DATA_DIR" && {
        log_success "✅ 备份恢复成功！"
        log_hint "恢复完成！您可以启动SillyTavern查看恢复的数据"
    } || log_error "❌ 数据恢复失败！"
}

rollback_sillytavern() {
    print_section "回退酒馆"
    [[ -d "$SILLYTAVERN_DIR"      ]] || { log_error "酒馆目录不存在，无法回退版本。"; return 1; }
    [[ -d "$SILLYTAVERN_DIR/.git" ]] || { log_error "检测到目录 $SILLYTAVERN_DIR 不是 Git 仓库，无法执行版本回退。"; return 1; }

    local current_version
    current_version=$(git -C "$SILLYTAVERN_DIR" describe --tags --abbrev=0 2>/dev/null || git -C "$SILLYTAVERN_DIR" rev-parse --short HEAD)
    log_notice "当前版本: $current_version"

    log_warn "版本切换前建议备份重要数据！"
    confirm_choice "是否继续回退版本？(y/n): " || { log_notice "取消版本回退"; return 0; }

    log_hint "提示："
    log_hint "  - 输入具体的版本号（如 1.13.4）"
    log_hint "  - 输入 commit hash（如 a1b2c3d）"
    log_hint "  - 输入 release 回到最新稳定版"
    log_prompt "请输入要回退到的版本: "
    
    local target_version
    read -r target_version
    [[ -n "$target_version" ]] || { log_error "版本号不能为空！"; return 1; }

    log_notice "正在切换到版本: $target_version"
    if git -C "$SILLYTAVERN_DIR" checkout "$target_version"; then
        local new_version
        new_version=$(git -C "$SILLYTAVERN_DIR" describe --tags --abbrev=0 2>/dev/null || git -C "$SILLYTAVERN_DIR" rev-parse --short HEAD)
        log_success "✅ 版本回退成功！"
        log_success "当前版本: $new_version"
    else
        log_error "❌ 版本回退失败！"
        log_error "请检查版本号是否正确，或网络连接是否正常。"
        return 1
    fi
}

###############################################
# 菜单与主循环
###############################################
show_menu() {
    clear
    printf "%b\n" "${CYAN}${BOLD}==== SillyTavern 一键管理菜单 ====${NC}"
    printf "%b\n" "${YELLOW}${BOLD}0. 退出脚本${NC}"
    printf "%b\n" "${GREEN}${BOLD}1. 部署酒馆${NC}"
    printf "%b\n" "${BLUE}${BOLD}2. 启动酒馆${NC}"
    printf "%b\n" "${MAGENTA}${BOLD}3. 更新酒馆${NC}"
    printf "%b\n" "${BRIGHT_RED}${BOLD}4. 删除酒馆${NC}"
    printf "%b\n" "${BRIGHT_CYAN}${BOLD}5. 备份酒馆${NC}"
    printf "%b\n" "${ORANGE}${BOLD}6. 恢复酒馆${NC}"
    printf "%b\n" "${TEAL}${BOLD}7. 回退酒馆${NC}"
    printf "%b\n" "${PURPLE}${BOLD}8. 工具检测${NC}"
    printf "%b\n" "${CYAN}${BOLD}==================================${NC}"
    log_prompt "请选择操作 (0-8): "
}

main() {
    clear
    ensure_termux_font
    ensure_termux_storage
    ensure_backup_script

    while true; do
        show_menu
        local choice
        read -r choice
        case "$choice" in
            0) clear; exit 0 ;;
            1) run deploy_sillytavern ;;
            2) run start_sillytavern ;;
            3) run update_sillytavern ;;
            4) run delete_sillytavern ;;
            5) run backup_sillytavern ;;
            6) run restore_sillytavern ;;
            7) run rollback_sillytavern ;;
            8) run check_tools_manual ;;
            *) log_error "无效选择，请重新输入！"; sleep 1 ;;
        esac
    done
}

main