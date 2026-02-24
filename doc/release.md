# 版本升级与发布指南

本文档描述发布新版本的完整流程，供 AI 执行时参考。

---

## 版本号规则

格式：`vMAJOR.MINOR.PATCH`

| 变更类型 | 升级位 | 示例 |
|---------|-------|------|
| 新增功能 | MINOR | v1.3.10 → v1.3.11 |
| Bug 修复 | PATCH | v1.3.10 → v1.3.10（视严重程度，可升 PATCH） |
| 破坏性变更 | MAJOR | v1.3.x → v2.0.0 |

---

## 发布步骤

### 第 1 步：确认待发布的改动

```bash
git log --oneline $(git describe --tags --abbrev=0)..HEAD
```

整理本次版本的变更内容，用于后续写 CHANGELOG。

### 第 2 步：更新版本号

编辑 `cmd/main.go`，修改 `Version` 变量：

```go
var Version = "v1.3.11"   // 改为新版本号
```

> 注意：GoReleaser 通过 `-X main.Version={{.Version}}` 从 git tag 注入版本号，
> 因此发布产物中的版本来自 tag 而非此变量。但仍需保持源码同步，
> 以确保本地 `go run` 时版本正确。

### 第 3 步：更新 README.md 变更日志

在 `README.md` 的 `## 变更日志` 章节顶部插入新版本条目：

```markdown
### v1.3.11

- 新增 download 命令支持目录递归下载，含断点续传（跳过大小一致的文件）
```

### 第 4 步：更新 skill 捆绑的二进制

`skill/bin/` 中存放了随 skill 安装包分发的预编译二进制，需先本地构建再更新：

```bash
bash build.sh

cp dist/kuake-v1.3.11-linux-amd64       skill/bin/kuake-linux-amd64
cp dist/kuake-v1.3.11-darwin-amd64      skill/bin/kuake-darwin-amd64
cp dist/kuake-v1.3.11-windows-amd64.exe skill/bin/kuake-windows-amd64.exe
chmod +x skill/bin/kuake-linux-amd64 skill/bin/kuake-darwin-amd64
```

### 第 5 步：提交所有变更

```bash
git add cmd/main.go README.md skill/bin/
git commit -m "chore: bump version to v1.3.11"
```

### 第 6 步：打 tag 并推送

```bash
git tag v1.3.11
git push origin main
git push origin v1.3.11
```

推送 tag 后，GitHub Actions（`.github/workflows/release.yml`）会自动触发 GoReleaser，
完成三平台二进制构建并创建 GitHub Release，无需手动操作。

---

## 关键文件清单

| 文件 | 作用 |
|------|------|
| `cmd/main.go` 第 22 行 | `Version` 变量（本地运行时显示） |
| `README.md` `## 变更日志` 章节 | 用户可见的变更记录 |
| `skill/bin/` | skill 安装包捆绑的预编译二进制（需手动同步） |
| `.goreleaser.yaml` | GoReleaser 构建配置，tag 推送后自动执行 |
| `.github/workflows/release.yml` | 触发 GoReleaser 的 Actions 工作流 |
