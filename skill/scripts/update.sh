#!/bin/bash
# 更新 kuake-cli 二进制文件（不影响配置文件）

set -e

REPO="CoderDKai/kuake_cli"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="$SKILL_DIR/bin"

detect_platform() {
    local os arch
    case "$(uname -s)" in
        Linux*)             os="linux" ;;
        Darwin*)            os="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *) echo "错误: 不支持的操作系统" >&2; exit 1 ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64" ;;
        aarch64|arm64)  arch="arm64" ;;
        *)              arch="amd64" ;;
    esac
    echo "${os} ${arch}"
}

get_latest_version() {
    curl -s "https://api.github.com/repos/${REPO}/releases/latest" | \
        grep '"tag_name"' | \
        sed -E 's/.*"v?([^"]+)".*/\1/'
}

get_download_url() {
    local version=$1 os=$2 arch=$3
    local filename="kuake_${version}_${os}_${arch}.tar.gz"
    curl -s "https://api.github.com/repos/${REPO}/releases/tags/v${version}" | \
        grep -o "\"browser_download_url\":.*${filename}\"" | \
        sed -E 's/.*"(https[^"]+)".*/\1/'
}

main() {
    read -r OS ARCH <<< "$(detect_platform)"
    echo "平台: $OS/$ARCH"

    echo "获取最新版本..."
    VERSION=$(get_latest_version)
    if [ -z "$VERSION" ]; then
        echo "错误: 无法获取最新版本" >&2
        exit 1
    fi
    echo "最新版本: v$VERSION"

    DOWNLOAD_URL=$(get_download_url "$VERSION" "$OS" "$ARCH")
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "错误: 找不到适合 $OS/$ARCH 的安装包" >&2
        exit 1
    fi

    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo "下载: $DOWNLOAD_URL"
    curl -sL "$DOWNLOAD_URL" -o "$TEMP_DIR/kuake.tar.gz"
    tar -xzf "$TEMP_DIR/kuake.tar.gz" -C "$TEMP_DIR"

    local BINARY_NAME="kuake"
    [ "$OS" = "windows" ] && BINARY_NAME="kuake.exe"
    BINARY_PATH=$(find "$TEMP_DIR" -type f -name "$BINARY_NAME" | head -n 1)

    if [ -z "$BINARY_PATH" ]; then
        echo "错误: 解压后未找到二进制文件" >&2
        exit 1
    fi

    mkdir -p "$BIN_DIR"
    DEST_NAME="kuake-${OS}-${ARCH}"
    [ "$OS" = "windows" ] && DEST_NAME="${DEST_NAME}.exe"

    cp "$BINARY_PATH" "$BIN_DIR/$DEST_NAME"
    [ "$OS" != "windows" ] && chmod +x "$BIN_DIR/$DEST_NAME"

    echo "更新成功: $BIN_DIR/$DEST_NAME"
    "$BIN_DIR/$DEST_NAME" version
}

main "$@"
