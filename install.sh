#!/bin/bash
set -e

# 安装脚本 - 自动检测平台并从 GitHub Releases 安装 kuake

REPO="CoderDKai/kuake_cli"
BINARY_NAME="kuake"

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "darwin"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

# 检测架构
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "amd64"
            ;;
    esac
}

# 获取最新版本
get_latest_version() {
    curl -s "https://api.github.com/repos/${REPO}/releases/latest" | \
        grep '"tag_name"' | \
        sed -E 's/.*"v?([^"]+)".*/\1/'
}

# 获取下载 URL
get_download_url() {
    local version=$1
    local os=$2
    local arch=$3

    local response
    response=$(curl -s "https://api.github.com/repos/${REPO}/releases/tags/v${version}")

    # 根据平台构建文件名: kuake_{version}_{os}_amd64.tar.gz
    local filename
    filename="${BINARY_NAME}_${version}_${os}_${arch}.tar.gz"

    # 从响应中查找对应的下载 URL
    echo "$response" | \
        grep -o "\"browser_download_url\":.*${filename}\"" | \
        sed -E 's/.*"(https[^"]+)".*/\1/'
}

# 写入默认配置文件
write_default_config() {
    local config_path=$1
    cat > "$config_path" << 'EOF'
{
  "quark": {
    "access_tokens": []
  }
}
EOF
}

# 主函数
main() {
    echo "检测平台..."
    OS=$(detect_os)
    ARCH=$(detect_arch)

    if [ "$OS" = "unsupported" ]; then
        echo "错误: 不支持的操作系统"
        exit 1
    fi

    echo "平台: $OS, 架构: $ARCH"

    echo "获取最新版本..."
    VERSION=$(get_latest_version)
    echo "最新版本: v$VERSION"

    echo "获取下载链接..."
    DOWNLOAD_URL=$(get_download_url "$VERSION" "$OS" "$ARCH")

    if [ -z "$DOWNLOAD_URL" ]; then
        echo "错误: 找不到适合您平台的安装包"
        exit 1
    fi

    echo "下载: $DOWNLOAD_URL"

    # 创建临时目录
    TEMP_DIR=$(mktemp -d)

    # 下载并解压
    echo "下载并解压..."
    curl -sL "$DOWNLOAD_URL" -o "${TEMP_DIR}/kuake.tar.gz"
    tar -xzf "${TEMP_DIR}/kuake.tar.gz" -C "$TEMP_DIR"

    # 查找二进制文件
    BINARY_PATH=$(find "$TEMP_DIR" -type f -name "$BINARY_NAME" -executable | head -n 1)

    if [ -z "$BINARY_PATH" ] && [ "$OS" = "windows" ]; then
        BINARY_PATH=$(find "$TEMP_DIR" -type f -name "${BINARY_NAME}.exe" | head -n 1)
    fi

    if [ -z "$BINARY_PATH" ]; then
        echo "错误: 解压后未找到二进制文件"
        exit 1
    fi

    echo "安装二进制文件..."

    if [ "$OS" = "windows" ]; then
        BIN_NAME="${BINARY_NAME}.exe"
    else
        BIN_NAME="$BINARY_NAME"
    fi

    # 尝试系统级安装（需要 sudo）
    if sudo cp "$BINARY_PATH" "/usr/local/bin/${BIN_NAME}" 2>/dev/null && \
       sudo chmod +x "/usr/local/bin/${BIN_NAME}" 2>/dev/null; then

        FINAL_BIN="/usr/local/bin/${BIN_NAME}"
        SYSTEM_INSTALL=true
    else
        # 用户级安装（无需 sudo）
        mkdir -p "$HOME/.local/bin"
        cp "$BINARY_PATH" "$HOME/.local/bin/${BIN_NAME}"
        chmod +x "$HOME/.local/bin/${BIN_NAME}"
        FINAL_BIN="$HOME/.local/bin/${BIN_NAME}"
        SYSTEM_INSTALL=false
    fi

    # 配置文件统一写到 ~/.config/kuake/config.json
    echo "创建默认配置文件..."
    mkdir -p "$HOME/.config/kuake"
    write_default_config "$HOME/.config/kuake/config.json"

    # 清理临时目录
    rm -rf "$TEMP_DIR"

    # 验证安装
    echo ""
    echo "=========================================="
    echo "验证安装..."
    echo "=========================================="

    if "$FINAL_BIN" version >/dev/null 2>&1; then
        echo "安装成功!"
    else
        echo "错误: 二进制无法运行，详情: $("$FINAL_BIN" version 2>&1 || true)"
        exit 1
    fi

    echo ""
    echo "可执行文件: $FINAL_BIN"
    echo "配置文件: $HOME/.config/kuake/config.json"

    if [ "$SYSTEM_INSTALL" = false ]; then
        echo ""
        echo "注意: 安装到用户目录，请确保 $HOME/.local/bin 在 PATH 中"
    fi

    # 交互式登录
    echo ""
    echo "=========================================="
    echo "登录夸克网盘"
    echo "=========================================="
    if "$FINAL_BIN" login; then
        echo ""
        echo "登录成功！现在可以使用 kuake 命令操作夸克网盘。"
    else
        echo ""
        echo "未完成登录，可通过以下命令手动登录:"
        echo "  kuake login"
        echo "  kuake login -t YOUR_TOKEN"
    fi

    echo ""
    echo "安装完成!"
}

main "$@"
