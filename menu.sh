#!/usr/bin/env bash

###############################################
# SillyTavern Termux 管理脚本
###############################################

# 使用更稳妥的 shell 行为：
# - pipefail: 管道中任意命令失败会导致整个管道失败，便于准确判断错误
# 不启用 set -e 以避免交互式流程在函数返回非零时被提前中断
set -o pipefail
# nullglob: 通配符未匹配时展开为空，而不是留下字面字符（对查找最新备份很有用）
shopt -s nullglob

###############################################
# 彩色输出定义（仅用于美化输出）
###############################################
# 说明：颜色代码是 ANSI 转义序列，变量名是只读（-r）以防误改
declare -r YELLOW='\033[1;33m'
declare -r GREEN='\033[38;5;40m'
declare -r BLUE='\033[38;5;33m'
declare -r MAGENTA='\033[38;5;129m'
declare -r CYAN='\033[38;5;44m'
declare -r BRIGHT_CYAN='\033[38;5;51m'
declare -r BRIGHT_GREEN='\033[38;5;46m'
declare -r BRIGHT_RED='\033[38;5;196m'
declare -r TEAL='\033[38;5;36m'
declare -r ORANGE='\033[38;5;208m'
declare -r PURPLE='\033[38;5;93m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m'

###############################################
# 全局配置（根据需要可修改）
###############################################
declare -r REPO_URL="https://github.com/SillyTavern/SillyTavern"  # 仓库地址
declare -r REPO_BRANCH="release"                                  # 要克隆的分支
declare -r SILLYTAVERN_DIR="$HOME/SillyTavern"                    # 项目根目录
declare -r START_SCRIPT="$SILLYTAVERN_DIR/start.sh"               # 启动脚本路径
declare -r BACKUP_SCRIPT="$HOME/backup_sillytavern.sh"            # 自动创建的备份脚本
# 必需工具（nodejs-lts 实际检查 node 命令）
declare -ar REQUIRED_TOOLS=(git nodejs-lts zip unzip)
declare -r FONT_URL="https://raw.githubusercontent.com/wuchen0309/Termux-SillyTavern/main/font.ttf"  # 字体下载地址
declare -r FONT_PATH="$HOME/.termux/font.ttf"                    # Termux 字体路径
declare -r BACKUP_DIR="$HOME/storage/shared/MySillyTavernBackups" # 备份保存目录（共享存储）
declare -r TMP_RESTORE_DIR="$HOME/tmp_sillytavern_restore"        # 临时恢复目录
declare -r DATA_DIR="$SILLYTAVERN_DIR/data"                       # 项目数据目录

###############################################
# 日志 / 输出工具（统一风格）
###############################################
# 说明：使用 printf 而不是 echo -e 更稳妥；\n 手动换行可控
print_section() { printf "%b\n" "${CYAN}${BOLD}==== $1 ====${NC}"; }           # 显示分节标题
log_success()   { printf "%b\n" "${GREEN}$1${NC}"; }                           # 成功信息
log_notice()    { printf "%b\n" "${YELLOW}$1${NC}"; }                          # 提示信息
log_warn()      { printf "%b\n" "${YELLOW}${BOLD}$1${NC}"; }                   # 警告信息
log_error()     { printf "%b\n" "${BRIGHT_RED}${BOLD}$1${NC}"; }               # 错误信息
log_hint()      { printf "%b\n" "${CYAN}$1${NC}"; }                            # 温馨小提示
log_prompt()    { printf "%b" "${BRIGHT_CYAN}${BOLD}$1${NC}"; }                # 输入提示（不换行）

###############################################
# 基础交互函数
###############################################
# confirm_choice: 循环询问 y/n；返回 0 表示“是”，1 表示“否”
confirm_choice() {
    # $1 为提示语；input 用于接收用户输入
    local prompt="$1" input
    while true; do
        log_prompt "$prompt"
        read -r input
        case "${input,,}" in            # 将输入转为小写，便于判断
            y|yes) return 0 ;;          # y/yes 表示确认
            n|no)  return 1 ;;          # n/no 表示否定
            *)     log_warn "请输入 y/yes 或 n/no！" ;;  # 其他内容继续循环
        esac
    done
}

# press_any_key: 等待用户按任意键继续
press_any_key() { 
    log_notice "按任意键返回菜单..."
    # -s: 静默（不回显）；-n1: 读取单个字符
    read -rsn1
}

# run: 执行给定命令，结束后回到菜单
run() { 
    "$@"
    press_any_key
}

###############################################
# 环境准备函数
###############################################
# ensure_termux_font: 检查字体文件，若不存在则下载并尝试应用
ensure_termux_font() {
    # 若字体已存在，直接返回
    [[ -f "$FONT_PATH" ]] && { log_success "字体文件已存在，跳过下载"; return 0; }
    print_section "检查并下载字体文件"
    log_notice "字体文件不存在，正在下载..."
    # 确保字体目录存在（dirname 取上级目录）
    mkdir -p -- "$(dirname -- "$FONT_PATH")"
    # 使用 curl 下载字体；-L 跟随重定向；--progress-bar 美化进度条；-o 指定输出文件
    if curl -L --progress-bar -o "$FONT_PATH" "$FONT_URL"; then
        log_success "字体文件下载完成！"
        # 判断 termux-reload-settings 是否可用，若可用则调用以刷新字体
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

# ensure_termux_storage: 检测共享存储链接是否存在，不存在则执行授权
ensure_termux_storage() {
    # Termux 授权后会在 $HOME/storage/shared 出现映射目录
    [[ -d "$HOME/storage/shared" ]] && return 0
    log_warn "检测到共享存储目录不存在，正在设置存储权限..."
    termux-setup-storage
    log_hint "请在弹窗中授权存储权限，授权完成后按回车继续..."
    read -r  # 暂停等待用户按回车
    # 授权失败时给出错误提示并退出
    [[ -d "$HOME/storage/shared" ]] || { log_error "错误：共享存储目录创建失败！请检查存储权限。"; exit 1; }
    log_success "共享存储目录设置完成！"
}

# ensure_backup_script: 首次使用时自动写入一个备份脚本并赋予可执行权限
ensure_backup_script() {
    # 若备份脚本已存在则跳过
    [[ -f "$BACKUP_SCRIPT" ]] && return 0
    log_notice "首次使用：正在创建备份脚本..."
    # 通过 heredoc 写入独立的备份脚本（带详细注释）
    cat >"$BACKUP_SCRIPT"<<'EOF'
#!/usr/bin/env bash

###############################################
# SillyTavern 数据备份工具（自动生成）
###############################################

# 源数据目录（SillyTavern 的 data 目录）
src_dir="$HOME/SillyTavern/data/"
# 临时拷贝目录（用于打包前的准备）
tmp_dir="$HOME/tmp_sillytavern_backup_copy"
# 备份输出目录（位于共享存储）
backup_dir="$HOME/storage/shared/MySillyTavernBackups"
# 生成时间戳（用于区分不同备份）
timestamp=$(date +%Y%m%d_%H%M%S)
# 备份文件名与完整路径
backup_name="sillytavern_backup_$timestamp.zip"
backup_path="$backup_dir/$backup_name"

###############################################
# 清理函数与中断处理
###############################################
cleanup() {
    echo "正在清理临时文件..."
    [[ -d "$tmp_dir" ]] && rm -rf "$tmp_dir" && echo "✓ 临时目录已清理"
    # 如压缩失败且生成了空文件，也一并清理
    [[ -f "$backup_path" ]] && [[ ! -s "$backup_path" ]] && rm -f "$backup_path" && echo "✓ 未完成的备份文件已清理"
}

# 捕获中断信号 (Ctrl+C) 或终止信号，执行清理并友好退出
trap 'echo -e "\n❌ 检测到中断信号！"; cleanup; echo "== 备份已取消 =="; exit 130' INT TERM

###############################################
# 脚本主程序
###############################################
echo "====================================="
echo "  SillyTavern 数据备份工具"
echo "====================================="
echo "源目录: $src_dir"
echo "备份目标: $backup_path"
echo ""

# --- 环境检查 ---
[[ -d "$src_dir" ]] || { echo "❌ 错误：源目录 '$src_dir' 不存在！"; exit 1; }
[[ -d "$HOME/storage/shared" ]] || { echo "❌ 错误：Termux 存储链接目录不存在。"; echo "提示：请先运行 termux-setup-storage 授权存储权限"; exit 1; }
mkdir -p "$backup_dir" || { echo "❌ 错误：无法创建备份目标目录！"; exit 1; }

# --- 步骤 1: 准备临时目录 ---
echo "[1/4] 准备临时目录..."
rm -rf "$tmp_dir"
mkdir -p "$tmp_dir" || { echo "❌ 错误：无法创建临时目录！"; exit 1; }
echo "✓ 临时目录准备完成"

# --- 步骤 2: 拷贝数据 ---
echo "[2/4] 正在拷贝数据到临时目录..."
if ! cp -r "$src_dir" "$tmp_dir/data"; then
    echo "❌ 拷贝失败！"
    cleanup
    exit 1
fi
echo "✓ 数据拷贝完成"

# 进入临时目录，为压缩做准备
cd "$tmp_dir" || { echo "❌ 无法进入临时目录！"; cleanup; exit 1; }

# --- 步骤 3: 压缩文件 ---
echo "[3/4] 正在压缩备份文件..."
if zip -r "$backup_path" "data" >/dev/null 2>&1; then
    echo "✓ 压缩完成"
else
    echo "❌ 压缩失败！"
    cleanup
    exit 1
fi

# --- 步骤 4: 清理临时文件 ---
echo "[4/4] 正在清理临时目录..."
cd "$HOME"
rm -rf "$tmp_dir"
echo "✓ 清理完成"

# --- 完成信息 ---
echo ""
echo "====================================="
echo "✅ 备份成功完成！"
echo "====================================="
echo "备份文件: $backup_name"
echo "保存位置: $backup_dir"
echo "文件大小: $(du -h "$backup_path" | cut -f1)"
echo "====================================="

# 任务完成，清除信号捕获
trap - INT TERM
EOF
    # 给备份脚本赋予可执行权限
    chmod +x "$BACKUP_SCRIPT"
    log_success "备份脚本初始化完成！"
}

# check_tools: 检查并安装缺失的依赖工具
check_tools() {
    print_section "检查必要工具"
    # 用数组保存缺失的工具以一次性安装
    local missing_tools=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        # nodejs-lts 实际检查 node 命令是否存在
        local cmd="$tool"; [[ "$tool" == "nodejs-lts" ]] && cmd="node"
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "✓ ${tool} 已安装"
        else
            log_warn    "⚠ ${tool} 未安装，准备安装..."
            missing_tools+=("$tool")
        fi
    done

    # 如有缺失，一次性安装；失败则返回 1
    ((${#missing_tools[@]})) || { log_success "工具检查完成！已安装: ${#REQUIRED_TOOLS[@]} 个"; return 0; }
    log_notice "正在安装缺失的工具..."
    pkg install -y "${missing_tools[@]}" || { log_error "✗ 工具安装失败"; return 1; }
    log_success "工具检查完成！已安装: ${#REQUIRED_TOOLS[@]} 个"
}

# check_tools_manual: 可选先更新系统包，再检查工具
check_tools_manual() {
    print_section "工具检测"
    # 询问是否先更新系统包
    if confirm_choice "检测前是否更新系统包? (y/n): "; then
        print_section "更新系统包"
        log_notice "正在更新系统包，请稍候..."
        # 使用括号创建子shell；失败时提示是否继续
        (pkg update -y && pkg upgrade -y) || {
            log_error "❌ 系统包更新失败！"
            confirm_choice "是否继续工具检测? (y/n): " || { log_notice "取消工具检测，���回主菜单"; return 0; }
        }
    else
        log_notice "跳过系统包更新"
    fi
    check_tools
}

###############################################
# 核心操作函数
###############################################
# deploy_sillytavern: 部署（克隆）项目
deploy_sillytavern() {
    print_section "部署酒馆"

    # 若目录已存在，询问是否重新部署（会删除旧目录）
    if [[ -d "$SILLYTAVERN_DIR" ]]; then
        log_warn "检测到已有 SillyTavern 目录"
        confirm_choice "重新部署? (y/n): " || { log_notice "取消部署"; return 0; }
        log_notice "清理旧目录..."
        rm -rf -- "$SILLYTAVERN_DIR"
    fi

    # 可选：部署前更新系统包
    if confirm_choice "部署前是否更新系统包? (y/n): "; then
        print_section "更新系统包"
        log_notice "正在更新系统包，请稍候..."
        (pkg update -y && pkg upgrade -y) || {
            log_error "❌ 系统包更新失败！"
            confirm_choice "是否继续部署? (y/n): " || { log_notice "取消部署，返回主菜单"; return 1; }
        }
    else
        log_notice "跳过系统包更新"
    fi

    # 可选：克隆前检测工具
    if confirm_choice "克隆前是否检测工具是否安装? (y/n): "; then
        check_tools || { log_error "工具安装失败，部署取消！"; return 1; }
    else
        log_notice "跳过工具检测"
    fi

    # 克隆仓库
    log_notice "准备克隆仓库..."
    log_hint "提示：按 CTRL+C 可中断克隆过程"
    if git clone "$REPO_URL" -b "$REPO_BRANCH" "$SILLYTAVERN_DIR"; then
        log_success "✅ 酒馆部署完成！"
    else
        log_error "❌ 酒馆克隆失败！"
    fi
}

# start_sillytavern: 启动项目
start_sillytavern() {
    print_section "启动酒馆"
    # 目录或启动脚本不存在时直接报错返回
    [[ -d "$SILLYTAVERN_DIR" ]] || { log_error "酒馆目录不存在，无法启动。"; return 1; }
    [[ -f "$START_SCRIPT"     ]] || { log_error "start.sh 不存在，无法启动。"; return 1; }
    # 调用项目自带的启动脚本
    bash "$START_SCRIPT"
}

# update_sillytavern: 拉取最新更改
update_sillytavern() {
    print_section "更新酒馆"
    [[ -d "$SILLYTAVERN_DIR"        ]] || { log_error "酒馆目录不存在，无法更新。"; return 1; }
    [[ -d "$SILLYTAVERN_DIR/.git"   ]] || { log_error "检测到目录 $SILLYTAVERN_DIR 不是 Git 仓库，无法执行更新。"; return 1; }
    git -C "$SILLYTAVERN_DIR" pull --rebase --autostash && \
        log_success "酒馆更新完成！" || log_error "酒馆更新失败！"
}

# delete_sillytavern: 删除整个项目目录（危险操作）
delete_sillytavern() {
    print_section "删除酒馆"
    # 若目录不存在，提示并返回
    [[ -d "$SILLYTAVERN_DIR" ]] || { log_notice "酒馆目录不存在，无需删除。"; return 0; }
    log_warn "警告：此操作将永久删除 SillyTavern 目录及其所有内容！"
    # 二次确认，确认后执行删除
    if confirm_choice "确认删除? (y/n): "; then
        rm -rf -- "$SILLYTAVERN_DIR" && log_success "酒馆删除完成！" || log_error "酒馆删除失败！"
    else
        log_notice "取消删除"
    fi
}

# backup_sillytavern: 运行自动生成的备份脚本
backup_sillytavern() {
    print_section "备份酒馆"
    [[ -f "$BACKUP_SCRIPT" ]] || { log_error "备份脚本不存在，无法备份。"; return 1; }
    bash "$BACKUP_SCRIPT"
}

# restore_sillytavern: 从最新备份恢复 data 目录
restore_sillytavern() {
    print_section "恢复酒馆"

    # 捕获 Ctrl+C，清理临时目录后友好退出；RETURN 用于函数返回时卸载 trap
    trap 'log_error "\n检测到中断信号！正在清理临时目录..."; rm -rf -- "$TMP_RESTORE_DIR"; exit 1' INT
    trap 'trap - INT' RETURN

    # 环境与路径检查
    [[ -d "$SILLYTAVERN_DIR" ]] || { log_error "SillyTavern目录不存在，请先部署SillyTavern！"; return 1; }
    [[ -d "$DATA_DIR"        ]] || { log_warn "data目录不存在，将自动创建"; mkdir -p -- "$DATA_DIR"; }

    log_warn "警告：此操作将永久删除当前的data目录并恢复备份！"
    confirm_choice "确定要继续恢复备份吗？(y/n): " || { log_notice "已取消恢复操作，请返回主菜单"; return 0; }

    # 确认备份目录存在
    [[ -d "$BACKUP_DIR" ]] || { log_error "备份目录不存在: $BACKUP_DIR"; log_hint "请先创建备份后再尝试恢复"; return 1; }

    # 使用 nullglob + 按时间排序查找最新备份，更兼容（避免 find 的 -printf 兼容性问题）
    local backups=( "$BACKUP_DIR"/sillytavern_backup_*.zip )
    # 若数组为空，说明没有任何备份文件
    ((${#backups[@]})) || { log_error "未找到任何备份文件！"; return 1; }
    # 使用 ls -t 按时间排序并取最新一个
    local latest_backup
    latest_backup=$(ls -t "$BACKUP_DIR"/sillytavern_backup_*.zip 2>/dev/null | head -n1)
    [[ -n "$latest_backup" ]] || { log_error "未找到任何备份文件！"; return 1; }

    log_success "找到最新备份: $(basename -- "$latest_backup")"

    # 删除旧 data 目录
    log_notice "正在删除当前data目录..."
    rm -rf -- "$DATA_DIR"

    # 准备临时目录
    rm -rf -- "$TMP_RESTORE_DIR"; mkdir -p -- "$TMP_RESTORE_DIR"

    # 解压到临时目录
    log_notice "正在解压备份文件..."
    unzip -q "$latest_backup" -d "$TMP_RESTORE_DIR" || { log_error "解压备份文件失败！"; rm -rf -- "$TMP_RESTORE_DIR"; return 1; }

    # 检查解压结构
    local extracted_data="$TMP_RESTORE_DIR/data"
    [[ -d "$extracted_data" ]] || { log_error "备份文件格式错误：未找到data目录！"; rm -rf -- "$TMP_RESTORE_DIR"; return 1; }

    # 将解压得到的 data 移动回项目目录
    log_notice "正在恢复数据..."
    if mv -- "$extracted_data" "$DATA_DIR"; then
        log_success "✅ 备份恢复成功！"
        rm -rf -- "$TMP_RESTORE_DIR"
        log_hint "恢复完成！您可以启动SillyTavern查看恢复的数据"
    else
        log_error "❌ 数据恢复失败！"
        rm -rf -- "$TMP_RESTORE_DIR"
        return 1
    fi
}

# rollback_sillytavern: 切换到指定版本或分支（例如输入 release 切到稳定分支）
rollback_sillytavern() {
    print_section "回退酒馆"
    [[ -d "$SILLYTAVERN_DIR"      ]] || { log_error "酒馆目录不存在，无法回退版本。"; return 1; }
    [[ -d "$SILLYTAVERN_DIR/.git" ]] || { log_error "检测到目录 $SILLYTAVERN_DIR 不是 Git 仓库，无法执行版本回退。"; return 1; }

    # 获取当前版本（优先 tag，失败则取短 hash）
    local current_version
    current_version=$(git -C "$SILLYTAVERN_DIR" describe --tags --abbrev=0 2>/dev/null || git -C "$SILLYTAVERN_DIR" rev-parse --short HEAD)
    log_notice "当前版本: $current_version"

    log_warn "版本切换前建议备份重要数据！"
    confirm_choice "是否继续回退版本？(y/n): " || { log_notice "取消版本回退"; return 0; }

    # 输入目标版本/分支/tag
    log_hint "提示："
    log_hint "  - 输入具体的版本号（如 1.13.4）"
    log_hint "  - 输入 commit hash（如 a1b2c3d）"
    log_hint "  - 输入 release 回到最新稳定版"
    log_prompt "请输入要回退到的版本: "
    local target_version
    read -r target_version
    [[ -n "$target_version" ]] || { log_error "版本号不能为空！"; return 1; }

    # 切换版本
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
# show_menu: 清屏并打印菜单
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

# main: 初始化环境并进入主循环
main() {
    clear
    # 准备环境：字体、共享存储、备份脚本
    ensure_termux_font
    ensure_termux_storage
    ensure_backup_script

    # 无限循环，直到用户选择退出
    while true; do
        show_menu
        # 读取用户选择
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

# 调用主函数
main