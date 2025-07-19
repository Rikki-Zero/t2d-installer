#!/bin/bash

# T2D 反安装器
# 清除 T2D 安装器部署的所有文件

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
SERVICE_FILE="/etc/systemd/system/t2d@.service"
COMPLETION_FILE="/etc/bash_completion.d/t2d"

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

# 停止并禁用T2D服务
stop_and_disable_service() {
    log_info "尝试停止并禁用所有T2D服务..."
    local services=$(systemctl list-units --type=service --state=running | grep "t2d@" | awk '{print $1}')
    for service in $services;
    do
        log_info "停止服务: $service"
        systemctl stop "$service" || log_warning "停止 $service 失败或已停止"
        log_info "禁用服务: $service"
        systemctl disable "$service" || log_warning "禁用 $service 失败或已禁用"
    done

    if [[ -f "$SERVICE_FILE" ]]; then
        log_info "移除systemd服务文件 $SERVICE_FILE..."
        rm -f "$SERVICE_FILE"
        log_success "systemd服务文件移除完成"
    else
        log_warning "systemd服务文件 $SERVICE_FILE 不存在"
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

# 移除bash补全脚本
remove_completion() {
    log_info "移除bash补全脚本..."
    if [[ -f "$COMPLETION_FILE" ]]; then
        rm -f "$COMPLETION_FILE"
        log_success "bash补全脚本 $COMPLETION_FILE 移除完成"
        log_info "请重新登录或运行 'rm $COMPLETION_FILE' 并 'exec bash' 或 'source /etc/bash_completion.d/t2d' 刷新"
    else
        log_warning "bash补全脚本 $COMPLETION_FILE 不存在"
    fi
}

# 重新加载systemd
reload_systemd() {
    log_info "重新加载systemd..."
    systemctl daemon-reload
    log_success "systemd重新加载完成"
}

# 主函数
main() {
    echo -e "${RED}"
    echo "=================================="
    echo "      T2D 反安装器"
    echo "=================================="
    echo -e "${NC}"
    
    check_root
    stop_and_disable_service
    remove_binary
    remove_config_dir
    remove_completion
    reload_systemd
    
    log_success "T2D反安装完成！"
    echo -e "${YELLOW}如果需要彻底清除bash补全效果，请手动移除 $COMPLETION_FILE 并重新登录您的shell。${NC}"
}

# 运行主函数
main "$@" 