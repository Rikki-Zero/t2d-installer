#!/bin/bash

# T2D 安装器
# 支持 CentOS、Debian、Ubuntu 系统
# 自动从 GitHub 获取最新版本并安装

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量
REPO_URL="https://api.github.com/repos/Neet-NXO/T2D/releases/latest"
BINARY_NAME="t2d"
INSTALL_PATH="/bin/t2d"
CONFIG_DIR="/etc/t2d"
SERVICE_FILE="/etc/systemd/system/t2d@.service"
COMPLETION_FILE="/etc/bash_completion.d/t2d"

# 模板文件URL
SERVICE_FILE_URL="https://raw.githubusercontent.com/Rikka-Sei/t2d-installer/refs/heads/Stable/t2d%40.service"
CLIENT_EXAMPLE_URL="https://raw.githubusercontent.com/Rikka-Sei/t2d-installer/refs/heads/Stable/template/client.example"
SERVER_EXAMPLE_URL="https://raw.githubusercontent.com/Rikka-Sei/t2d-installer/refs/heads/Stable/template/server.example"

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

# 检测系统类型
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
        log_error "无法检测操作系统类型"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS"
}

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            ARCH="amd64"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        armv6l)
            ARCH="armv6"
            ;;
        armv5l)
            ARCH="armv5"
            ;;
        arm*)
            ARCH="arm"
            ;;
        mips64)
            ARCH="mips64"
            ;;
        mips64el)
            ARCH="mips64le"
            ;;
        mips)
            ARCH="mips"
            ;;
        mipsel)
            ARCH="mipsle"
            ;;
        ppc64)
            ARCH="ppc64"
            ;;
        ppc64le)
            ARCH="ppc64le"
            ;;
        riscv64)
            ARCH="riscv64"
            ;;
        s390x)
            ARCH="s390x"
            ;;
        *)
            log_error "不支持的架构: $arch"
            exit 1
            ;;
    esac
    
    log_info "检测到系统架构: $ARCH"
}

# 安装依赖
install_dependencies() {
    log_info "安装依赖包..."
    
    case $OS in
        "ubuntu"|"debian")
            apt-get update
            apt-get install -y curl jq tar systemd bash-completion
            ;;
        "centos"|"rhel"|"fedora")
            if command -v dnf &> /dev/null; then
                dnf install -y curl jq tar systemd bash-completion
            else
                yum install -y curl jq tar systemd bash-completion
            fi
            ;;
        *)
            log_warning "未知的操作系统，请手动安装 curl, jq, tar, systemd, bash-completion"
            ;;
    esac
}

# 获取最新版本信息
get_latest_version() {
    log_info "获取最新版本信息..."
    
    local response=$(curl -s "$REPO_URL")
    if [[ $? -ne 0 ]]; then
        log_error "无法获取版本信息"
        exit 1
    fi
    
    VERSION=$(echo "$response" | jq -r '.tag_name')
    DOWNLOAD_URL=$(echo "$response" | jq -r ".assets[] | select(.name == \"T2D-linux-${ARCH}.tar.gz\") | .browser_download_url")
    
    if [[ "$VERSION" == "null" ]] || [[ "$DOWNLOAD_URL" == "null" ]]; then
        log_error "无法找到适合的版本或下载链接"
        exit 1
    fi
    
    log_success "找到最新版本: $VERSION"
    log_info "下载链接: $DOWNLOAD_URL"
}

# 下载并安装二进制文件
install_binary() {
    log_info "下载T2D二进制文件..."
    
    local temp_dir=$(mktemp -d)
    local tar_file="$temp_dir/T2D-linux-${ARCH}.tar.gz"
    
    # 下载文件
    if ! curl -L -o "$tar_file" "$DOWNLOAD_URL"; then
        log_error "下载失败"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 解压文件
    log_info "解压文件..."
    cd "$temp_dir"
    tar -xzf "T2D-linux-${ARCH}.tar.gz"
    
    # 找到二进制文件
    local binary_file="T2D-linux-${ARCH}"
    if [[ ! -f "$binary_file" ]]; then
        log_error "未找到二进制文件: $binary_file"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # 复制到系统目录
    log_info "安装二进制文件到 $INSTALL_PATH..."
    cp "$binary_file" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    log_success "二进制文件安装完成"
}

# 创建systemd服务文件
create_service() {
    log_info "创建systemd服务文件..."
    
    if ! curl -L -o "$SERVICE_FILE" "$SERVICE_FILE_URL"; then
        log_error "下载t2d@.service失败"
        exit 1
    fi
    
    log_success "systemd服务文件创建完成"
}

# 创建配置目录和模板文件
create_config() {
    log_info "创建配置目录和模板文件..."
    
    # 创建配置目录
    mkdir -p "$CONFIG_DIR"
    
    # 下载客户端配置模板
    log_info "下载客户端配置模板..."
    if ! curl -L -o "$CONFIG_DIR/client.example" "$CLIENT_EXAMPLE_URL"; then
        log_error "下载client.example失败"
        exit 1
    fi
    
    # 下载服务器配置模板
    log_info "下载服务器配置模板..."
    if ! curl -L -o "$CONFIG_DIR/server.example" "$SERVER_EXAMPLE_URL"; then
        log_error "下载server.example失败"
        exit 1
    fi
    
    log_success "配置模板创建完成"
}

# 创建bash补全脚本
create_completion() {
    log_info "创建bash补全脚本..."

    mkdir -p "/etc/bash_completion.d"
    
    cat > "$COMPLETION_FILE" << 'EOF'
# T2D systemctl completion for t2d@ services

_t2d_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 检查是否是 systemctl 命令的 t2d@ 服务补全
    if [[ ${COMP_WORDS[1]} == "start" || ${COMP_WORDS[1]} == "stop" || ${COMP_WORDS[1]} == "restart" || ${COMP_WORDS[1]} == "status" || ${COMP_WORDS[1]} == "enable" || ${COMP_WORDS[1]} == "disable" ]]; then
        if [[ ${cur} == t2d@* ]]; then
            local configs=$(ls /etc/t2d/*.json 2>/dev/null | sed 's|/etc/t2d/||g' | sed 's|\.json$||g' | sed 's|^|t2d@|g' | sed 's|$|.service|g')
            COMPREPLY=( $(compgen -W "${configs}" -- ${cur}) )
            return 0
        fi
    fi
}

# 为systemctl命令注册补全
complete -F _t2d_completion systemctl

# 扩展现有的systemctl补全
_systemctl_completion_extension() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    
    if [[ ${cur} == t2d@* ]]; then
        local configs=$(ls /etc/t2d/*.json 2>/dev/null | sed 's|/etc/t2d/||g' | sed 's|\.json$||g' | sed 's|^|t2d@|g' | sed 's|$|.service|g')
        COMPREPLY=( $(compgen -W "${configs}" -- ${cur}) )
        return 0
    fi
}

# 如果systemctl已有补全函数，则扩展它
if declare -F _systemctl > /dev/null; then
    eval "$(declare -f _systemctl | sed '1s/.*/_original_systemctl()/')"
    _systemctl() {
        _systemctl_completion_extension
        if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
            _original_systemctl "$@"
        fi
    }
fi
EOF
    
    chmod +x "$COMPLETION_FILE"
    
    log_success "bash补全脚本创建完成"
}

# 重新加载systemd
reload_systemd() {
    log_info "重新加载systemd..."
    systemctl daemon-reload
    log_success "systemd重新加载完成"
}

# 显示安装后信息
show_post_install_info() {
    log_success "T2D安装完成！"
    echo
    echo -e "${GREEN}安装信息:${NC}"
    echo "  - 二进制文件: $INSTALL_PATH"
    echo "  - 配置目录: $CONFIG_DIR"
    echo "  - 服务文件: $SERVICE_FILE"
    echo "  - 补全脚本: $COMPLETION_FILE"
    echo
    echo -e "${GREEN}使用方法:${NC}"
    echo "  1. 复制配置模板:"
    echo "     cp $CONFIG_DIR/client.example $CONFIG_DIR/my-client.json"
    echo "     cp $CONFIG_DIR/server.example $CONFIG_DIR/my-server.json"
    echo
    echo "  2. 编辑配置文件:"
    echo "     nano $CONFIG_DIR/my-client.json"
    echo
    echo "  3. 启动服务:"
    echo "     systemctl start t2d@my-client"
    echo "     systemctl enable t2d@my-client"
    echo
    echo "  4. 查看状态:"
    echo "     systemctl status t2d@my-client"
    echo
    echo -e "${GREEN}自动补全:${NC}"
    echo "  重新登录或运行 'source /etc/bash_completion.d/t2d' 启用补全功能"
    echo "  之后可以使用 Tab 键补全服务名称"
    echo
    echo -e "${YELLOW}注意: 请根据实际需求修改配置文件中的服务器地址和密码${NC}"
}

# 主函数
main() {
    echo -e "${BLUE}"
    echo "=================================="
    echo "      T2D 自动安装器"
    echo "=================================="
    echo -e "${NC}"
    
    check_root
    detect_os
    detect_arch
    install_dependencies
    get_latest_version
    install_binary
    create_service
    create_config
    create_completion
    reload_systemd
    show_post_install_info
}

# 运行主函数
main "$@" 