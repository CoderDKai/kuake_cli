# TODO 改进计划

本文件记录代码审查中发现的改进建议，按优先级排序。

## 已完成 ✅

- [x] **为 updateHashCtxFromHash 添加错误处理** (`sdk/file.go`)
  - 并行上传和串行上传逻辑中均已添加错误处理

- [x] **为断点续传状态保存添加 3 次重试机制** (`sdk/file.go`)
  - 并行上传和串行上传逻辑中均已添加重试机制

- [x] **简化常量定义** (`sdk/constants.go`)
  - 删除了重复的 FILE_DOWNLOAD_PC 常量

## 高优先级 (High)

- [x] **添加 version 命令** (`cmd/main.go`)
  - CLI 缺少版本查看命令，不方便用户验证安装
  - 已添加 `kuake version` 子命令，输出 Version 变量
  - 已更新 `install.sh` 中的验证指令：将 `$FINAL_BIN help` 改为 `$FINAL_BIN version`

- [x] **拆分 UploadFile 函数** (`sdk/file.go:765-1445`)
  - 当前函数超过 600 行，职责过多
  - 已拆分为：`openAndValidateFile`, `parseDestPath`, `ensureDirectoryExists`, `loadOrCreateUploadState`, `calculateFileHash`, `buildUploadStateFunc`, `saveUploadStateWithRetry`, `handleQuickUpload`, `commitUpload` 等小函数
  - ⚠️ **注意**: 拆分后未经过实际测试，可能存在 bug，建议进行测试验证

- [ ] **统一错误处理模式** (`sdk/file.go` 多处)
  - 当前存在两种错误返回模式混用
  - 建议统一使用一种模式

## 中优先级 (Medium)

- [ ] **HTTP 客户端复用** (`sdk/file.go:2708-2711`)
  - 每次下载文件都创建新的 HTTP 客户端
  - 建议复用 `qc.HttpClient`

- [ ] **进度保存优化** (`sdk/file.go:339`)
  - 每上传完成一个分片就保存一次状态
  - 建议改为每 N 个分片保存一次

- [ ] **添加请求重试机制**
  - 临时网络故障会导致上传失败
  - 建议实现带指数退避的重试

- [ ] **build.sh eval 使用** (`build.sh:56`)
  - 建议使用数组方式代替 eval

## 低优先级 (Low)

- [ ] **添加单元测试**
  - 当前项目缺少测试文件

- [ ] **配置文件示例优化** (`build.sh:89-97`)
  - 添加更清晰的注释
