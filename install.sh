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
    cd "$TEMP_DIR"

    # 下载并解压
    echo "下载并解压..."
    curl -sL "$DOWNLOAD_URL" -o "${TEMP_DIR}/kuake.tar.gz"
    tar -xzf "${TEMP_DIR}/kuake.tar.gz" -C "$TEMP_DIR"

    # 查找二进制文件
    BINARY_PATH=$(find "$TEMP_DIR" -type f -name "$BINARY_NAME*" -executable | head -n 1)

    if [ -z "$BINARY_PATH" ]; then
        # Windows 查找 .exe 文件
        BINARY_PATH=$(find "$TEMP_DIR" -type f -name "${BINARY_NAME}*.exe" | head -n 1)
    fi

    if [ -z "$BINARY_PATH" ]; then
        echo "错误: 解压后未找到二进制文件"
        exit 1
    fi

    echo "安装二进制文件..."
    # 安装二进制文件，优先使用 sudo，失败则安装到用户目录
    if [ "$OS" = "windows" ]; then
        TARGET_DIR="/usr/local/bin"
        if ! sudo cp "$BINARY_PATH" "${TARGET_DIR}/${BINARY_NAME}.exe" 2>/dev/null; then
            TARGET_DIR="$HOME/.local/bin"
            mkdir -p "$TARGET_DIR"
            cp "$BINARY_PATH" "${TARGET_DIR}/${BINARY_NAME}.exe"
        fi
        sudo chmod +x "${TARGET_DIR}/${BINARY_NAME}.exe" 2>/dev/null || chmod +x "${TARGET_DIR}/${BINARY_NAME}.exe"
        FINAL_BIN="${TARGET_DIR}/${BINARY_NAME}.exe"
    else
        TARGET_DIR="/usr/local/bin"
        if ! sudo cp "$BINARY_PATH" "${TARGET_DIR}/${BINARY_NAME}" 2>/dev/null; then
            TARGET_DIR="$HOME/.local/bin"
            mkdir -p "$TARGET_DIR"
            cp "$BINARY_PATH" "${TARGET_DIR}/${BINARY_NAME}"
        fi
        sudo chmod +x "${TARGET_DIR}/${BINARY_NAME}" 2>/dev/null || chmod +x "${TARGET_DIR}/${BINARY_NAME}"
        FINAL_BIN="${TARGET_DIR}/${BINARY_NAME}"
    fi

    # 创建默认配置文件
    echo "创建默认配置文件..."
    cat > "${TARGET_DIR}/config.json" << 'EOF'
{
  "quark": {
    "access_tokens": []
  }
}
EOF
    if [ "$OS" = "windows" ]; then
        sudo chmod +x "${TARGET_DIR}/config.json" 2>/dev/null || chmod +x "${TARGET_DIR}/config.json"
    else
        sudo chmod +x "${TARGET_DIR}/config.json" 2>/dev/null || chmod +x "${TARGET_DIR}/config.json"
    fi

    # 清理临时目录
    rm -rf "$TEMP_DIR"

    # 验证安装 - 使用 help 命令验证二进制可执行
    echo ""
    echo "=========================================="
    echo "验证安装..."
    echo "=========================================="
    $FINAL_BIN version >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "安装成功!"
        echo ""
        echo "kuake 已安装到: $FINAL_BIN"
        if [ "$TARGET_DIR" = "$HOME/.local/bin" ]; then
            echo ""
            echo "注意: 安装到用户目录，请确保 $HOME/.local/bin 在 PATH 中"
        fi
        echo ""
        echo "=========================================="
        echo "下一步: 请运行以下命令登录"
        echo "=========================================="
        echo "  kuake login"
        echo ""
        echo "或者通过命令行传入 token:"
        echo "  kuake login -t YOUR_TOKEN"
        echo ""
    else
        echo "警告: 安装验证失败，但文件已安装到 $FINAL_BIN"
    fi

    echo "安装完成!"
}

main "$@"
