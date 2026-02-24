---
name: kuake-cli
description: 当用户需要操作夸克网盘文件时使用此 skill，包括文件上传下载、目录管理、分享链接创建和转存等操作。
---

# Kuake CLI

## Overview

此 skill 提供夸克网盘 CLI 工具（kuake）的调用指南，用于管理夸克网盘文件。支持文件上传下载、目录管理、文件移动复制重命名删除、分享链接创建删除和转存等操作。

skill 已捆绑各平台二进制文件，安装后无需额外步骤即可使用。

## 前置准备

每次执行命令前，先设置以下变量：

```bash
SKILL_DIR="$HOME/.claude/skills/kuake-cli"

# 二进制：使用 skill 目录捆绑的版本
case "$(uname -s)" in
    Linux*)             KUAKE="$SKILL_DIR/bin/kuake-linux-amd64" ;;
    Darwin*)            KUAKE="$SKILL_DIR/bin/kuake-darwin-amd64" ;;
    CYGWIN*|MINGW*|MSYS*) KUAKE="$SKILL_DIR/bin/kuake-windows-amd64.exe" ;;
esac
chmod +x "$KUAKE" 2>/dev/null || true

# 配置：使用 skill 目录的 config.json
KUAKE_CONFIG="$SKILL_DIR/config.json"
```

所有命令均通过 `-c` 显式传入配置路径：
```bash
$KUAKE -c "$KUAKE_CONFIG" <command>
```

### 配置文件

kuake 需要 `config.json`，包含 access_token，位于 `$SKILL_DIR/config.json`。

**配置文件格式：**
```json
{
  "Quark": {
    "access_tokens": ["__pus=your_pus_value_here;"]
  }
}
```

**获取 access_token：**
1. 登录夸克网盘网页版
2. 打开开发者工具（F12）
3. 在 Application/Storage → Cookies 中找到 `__pus` 的值（格式为 `__pus=xxx;`）

**初始配置（首次使用）：**
```bash
# 交互式生成配置文件
python3 "$SKILL_DIR/scripts/init_config.py"

# 或直接登录（交互式填入 token）
$KUAKE -c "$KUAKE_CONFIG" login
```

## 命令列表

### 基础命令

| 命令 | 说明 |
|------|------|
| `version` | 显示版本信息 |
| `user` | 获取当前用户信息 |
| `help` | 显示帮助信息 |

### 文件管理

| 命令 | 说明 | 示例 |
|------|------|------|
| `list [path]` | 列出目录内容 | `$KUAKE -c "$KUAKE_CONFIG" list "/"` |
| `info <path>` | 获取文件/文件夹信息 | `$KUAKE -c "$KUAKE_CONFIG" info "/file.txt"` |
| `download <path> [dest]` | 下载文件 | `$KUAKE -c "$KUAKE_CONFIG" download "/file.txt"` 或 `$KUAKE -c "$KUAKE_CONFIG" download "/file.txt" ./local.zip` |
| `upload <file> <dest>` | 上传文件 | `$KUAKE -c "$KUAKE_CONFIG" upload "file.txt" "/folder/file.txt"` |

### 目录管理

| 命令 | 说明 | 示例 |
|------|------|------|
| `create <name> <pdir>` | 创建文件夹 | `$KUAKE -c "$KUAKE_CONFIG" create "folder" "/"` |

### 文件操作

| 命令 | 说明 | 示例 |
|------|------|------|
| `move <src> <dest>` | 移动文件/文件夹 | `$KUAKE -c "$KUAKE_CONFIG" move "/file.txt" "/folder/"` |
| `copy <src> <dest>` | 复制文件/文件夹 | `$KUAKE -c "$KUAKE_CONFIG" copy "/file.txt" "/backup/"` |
| `rename <path> <newName>` | 重命名文件/文件夹 | `$KUAKE -c "$KUAKE_CONFIG" rename "/file.txt" "new_name.txt"` |
| `delete <path>` | 删除文件/文件夹 | `$KUAKE -c "$KUAKE_CONFIG" delete "/file.txt"` |

### 分享功能

| 命令 | 说明 | 示例 |
|------|------|------|
| `share <path> <days> <passcode>` | 创建分享链接 | `$KUAKE -c "$KUAKE_CONFIG" share "/file.txt" 7 "false"` |
| `share-delete <share_id_or_path>` | 删除分享 | `$KUAKE -c "$KUAKE_CONFIG" share-delete "share_id"` 或 `$KUAKE -c "$KUAKE_CONFIG" share-delete "/file.txt"` |
| `share-list [page] [size]` | 获取分享列表 | `$KUAKE -c "$KUAKE_CONFIG" share-list` |
| `share-save <share_link> [passcode]` | 转存分享文件 | `$KUAKE -c "$KUAKE_CONFIG" share-save "https://pan.quark.cn/s/xxx" "1234"` |

### 命令详细说明

#### version
```bash
$KUAKE -c "$KUAKE_CONFIG" version
```
显示当前 CLI 工具的版本号。

#### user
```bash
$KUAKE -c "$KUAKE_CONFIG" user
```
获取当前登录用户的信息，包括用户名、容量等。

#### list
```bash
$KUAKE -c "$KUAKE_CONFIG" list [path]
```
列出指定目录的内容。
- `path`：目录路径，默认为根目录 `/`
- 返回：目录下的文件和文件夹列表

#### info
```bash
$KUAKE -c "$KUAKE_CONFIG" info <path>
```
获取指定文件或文件夹的详细信息。
- `path`：文件或文件夹路径
- 返回：文件大小、创建时间、修改时间、FID 等信息

#### download
```bash
$KUAKE -c "$KUAKE_CONFIG" download <path> [dest]
```
下载文件或获取下载链接。
- `path`：云盘文件路径
- `dest`（可选）：本地保存路径
  - 不指定：仅返回下载链接 JSON
  - 指定：下载文件到本地

#### upload
```bash
$KUAKE -c "$KUAKE_CONFIG" upload <file> <dest> [--max_upload_parallel N]
```
上传本地文件到云盘。
- `file`：本地文件路径
- `dest`：云盘目标路径
- `--max_upload_parallel N`：上传并发数（1-16），可通过环境变量 `KUAKE_UPLOAD_PARALLEL` 设置

#### create
```bash
$KUAKE -c "$KUAKE_CONFIG" create <name> <pdir>
```
创建新文件夹。
- `name`：新文件夹名称
- `pdir`：父目录路径（使用 `/` 表示根目录）

#### move
```bash
$KUAKE -c "$KUAKE_CONFIG" move <src> <dest>
```
移动文件或文件夹到目标位置。

#### copy
```bash
$KUAKE -c "$KUAKE_CONFIG" copy <src> <dest>
```
复制文件或文件夹到目标位置。

#### rename
```bash
$KUAKE -c "$KUAKE_CONFIG" rename <path> <newName>
```
重命名文件或文件夹。

#### delete
```bash
$KUAKE -c "$KUAKE_CONFIG" delete <path>
```
删除文件或文件夹（移到回收站）。

#### share
```bash
$KUAKE -c "$KUAKE_CONFIG" share <path> <days> <passcode>
```
创建分享链接。
- `days`：有效期天数（0=永久，1/7/30 等）
- `passcode`：是否需要提取码（`"true"` 或 `"false"`）

#### share-delete
```bash
$KUAKE -c "$KUAKE_CONFIG" share-delete <share_id_or_path>...
```
删除分享链接。支持 share_id 或文件路径，可一次删除多个。

#### share-list
```bash
$KUAKE -c "$KUAKE_CONFIG" share-list [page] [size] [orderField] [orderType]
```
获取分享列表。默认按 `created_at` 降序，每页 50 条。

#### share-save
```bash
$KUAKE -c "$KUAKE_CONFIG" share-save <share_link> [passcode] [dest_dir]
```
转存分享文件到自己的云盘。`dest_dir` 默认为 `/`。

## 输出格式

所有命令输出 JSON 格式：

```json
{
  "success": true,
  "code": "OK",
  "message": "操作成功",
  "data": {}
}
```

## 使用示例

### 查看目录结构
```bash
$KUAKE -c "$KUAKE_CONFIG" list "/"
$KUAKE -c "$KUAKE_CONFIG" list "/电影"
```

### 上传文件
```bash
$KUAKE -c "$KUAKE_CONFIG" upload "document.pdf" "/documents/document.pdf"
$KUAKE -c "$KUAKE_CONFIG" upload "video.mp4" "/videos/video.mp4" --max_upload_parallel 8
```

### 下载文件
```bash
$KUAKE -c "$KUAKE_CONFIG" download "/file.txt"
$KUAKE -c "$KUAKE_CONFIG" download "/file.txt" "./downloads/file.txt"
```

### 创建分享
```bash
$KUAKE -c "$KUAKE_CONFIG" share "/file.txt" 7 "false"
$KUAKE -c "$KUAKE_CONFIG" share "/folder" 0 "true"
```

### 转存分享
```bash
$KUAKE -c "$KUAKE_CONFIG" share-save "https://pan.quark.cn/s/xxx"
$KUAKE -c "$KUAKE_CONFIG" share-save "https://pan.quark.cn/s/xxx" "1234" "/backup"
```

## 维护

### 更新二进制（不影响配置文件）

```bash
bash ~/.claude/skills/kuake-cli/scripts/update.sh
```

脚本会自动检测平台，下载最新版本二进制，替换 `bin/` 目录中对应文件，`config.json` 保持不变。

## Resources

### scripts/

- `init_config.py`：交互式生成 `config.json`
- `update.sh`：更新二进制到最新版本（不影响配置）

### bin/

捆绑的预编译二进制：
- `kuake-linux-amd64`
- `kuake-darwin-amd64`
- `kuake-windows-amd64.exe`
