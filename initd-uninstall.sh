#!/bin/bash

# T2D Init.d 反安装器
# 清除 T2D Init.d 安装器部署的所有文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量 (与安装脚本保持一致)
INSTALL_PATH="/bin/t2d"
CONFIG_DIR="/etc/t2d"
SERVICE_FILE="/etc/init.d/t2d"
PID_DIR="/var/run/t2d"
LOG_DIR="/var/log/t2d"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检测系统类型 (用于卸载时的服务移除命令)
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
    else
        log_warning "无法检测操作系统类型，可能需要手动移除服务注册"
        OS="unknown"
    fi
}

# Function to get the PID file path for a given instance
get_pid_file_path() {
    local instance="$1"
    echo "${PID_DIR}/${SERVICE_FILE##*/}-${instance}.pid"
}

# 停止并禁用T2D服务
stop_and_disable_service() {
    log_info "尝试停止并禁用所有T2D服务..."
    
    # Iterate through PID files to stop running instances
    if [[ -d "$PID_DIR" ]]; then
        for pid_file in "$PID_DIR"/*.pid;
        do
            if [[ -f "$pid_file" ]]; then
                local instance=$(basename "$pid_file" .pid)
                instance="${instance#${SERVICE_FILE##*/}-}" # Extract instance name
                
                log_info "停止服务实例: ${instance}"
                # Attempt to stop via init.d script first
                if [[ -x "$SERVICE_FILE" ]]; then
                    "$SERVICE_FILE" stop "${instance}" || log_warning "使用 init.d 脚本停止 ${instance} 失败"
                else
                    local pid=$(cat "$pid_file" 2>/dev/null)
                    if [[ -n "$pid" ]] && ps -p "$pid" > /dev/null; then
                        log_warning "init.d 脚本不存在或不可执行，直接终止进程 PID: ${pid}"
                        kill "$pid" || log_warning "终止进程 ${pid} 失败"
                        sleep 1
                        if ps -p "$pid" > /dev/null; then
                            kill -9 "$pid" || log_error "强制终止进程 ${pid} 失败"
                        fi
                    fi
                fi
                rm -f "$pid_file" # Always remove pid file after attempt to stop
            fi
        done
    fi

    # Remove init.d service from startup
    if [[ -f "$SERVICE_FILE" ]]; then
        log_info "从开机启动中移除 ${SERVICE_FILE##*/} 服务..."
        case $OS in
            "ubuntu"|"debian")
                update-rc.d "$(basename "$SERVICE_FILE")" remove || log_warning "从开机启动中移除服务失败"
                ;;
            "centos"|"rhel"|"fedora")
                chkconfig --del "$(basename "$SERVICE_FILE")" || log_warning "从开机启动中移除服务失败"
                ;;
            *)
                log_warning "未知的操作系统，请手动从开机启动中移除服务"
                ;;
        esac
        
        log_info "移除init.d服务文件 $SERVICE_FILE..."
        rm -f "$SERVICE_FILE"
        log_success "init.d服务文件移除完成"
    else
        log_warning "init.d服务文件 $SERVICE_FILE 不存在"
    fi
}

# 移除二进制文件
remove_binary() {
    log_info "移除T2D二进制文件..."
    if [[ -f "$INSTALL_PATH" ]]; then
        rm -f "$INSTALL_PATH"
        log_success "T2D二进制文件 $INSTALL_PATH 移除完成"
    else
        log_warning "T2D二进制文件 $INSTALL_PATH 不存在"
    fi
}

# 移除配置目录
remove_config_dir() {
    log_info "移除T2D配置目录..."
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        log_success "T2D配置目录 $CONFIG_DIR 移除完成"
    else
        log_warning "T2D配置目录 $CONFIG_DIR 不存在"
    fi
}

# 移除 PID 和日志目录
remove_pid_log_dirs() {
    log_info "移除T2D PID 和日志文件..."
    if [[ -d "$PID_DIR" ]]; then
        rm -rf "$PID_DIR"
        log_success "PID目录 $PID_DIR 移除完成"
    else
        log_warning "PID目录 $PID_DIR 不存在"
    fi
    
    if [[ -d "$LOG_DIR" ]]; then
        rm -rf "$LOG_DIR"
        log_success "日志目录 $LOG_DIR 移除完成"
    else
        log_warning "日志目录 $LOG_DIR 不存在"
    fi
}

# 主函数
main() {
    echo -e "${RED}"
    echo "=================================="
    echo "      T2D Init.d 反安装器"
    echo "=================================="
    echo -e "${NC}"
    
    check_root
    detect_os
    stop_and_disable_service
    remove_binary
    remove_config_dir
    remove_pid_log_dirs
    
    log_success "T2D Init.d 反安装完成！"
}

# 运行主函数
main "$@" 