# 上游代码同步脚本使用指南

## 📋 概述

这是 TradingAgents-CN 项目的上游代码同步脚本，用于自动从上游仓库同步最新代码到本地并推送到你的远程仓库。

## 🚀 快速使用

### Linux/macOS 用户

```bash
# 给脚本执行权限（首次使用）
chmod +x sync_upstream.sh

# 运行同步脚本
./sync_upstream.sh
```

### Windows 用户

```powershell
# 在 PowerShell 中运行
.\sync_upstream.ps1
```

## 📁 文件说明

- `sync_upstream.sh` - Linux/macOS 版本的同步脚本
- `sync_upstream.ps1` - Windows PowerShell 版本的同步脚本
- `SYNC_UPSTREAM_GUIDE.md` - 本使用指南

## ⚙️ 前置条件

1. **配置上游仓库**（如果还没有配置）：
   ```bash
   git remote add upstream https://github.com/hsliuping/TradingAgents-CN.git
   ```

2. **确保工作区干净**：
   - 提交或储存所有未提交的更改
   - 脚本会检查并提示，但建议提前处理

## 🎯 脚本功能

### 自动化流程
1. ✅ **环境检查** - 验证Git仓库和远程配置
2. ✅ **工作区检查** - 确保没有未提交的更改
3. ✅ **获取更新** - 从upstream和origin获取最新代码
4. ✅ **新提交检测** - 智能检测是否有新的上游提交
5. ✅ **预览更改** - 显示将要合并的提交
6. ✅ **安全合并** - 自动合并上游代码
7. ✅ **推送确认** - 询问是否推送到你的远程仓库
8. ✅ **状态展示** - 显示最终的合并结果

### 安全特性
- 🛡️ **严格模式** - 遇到错误立即停止
- 🛡️ **冲突检测** - 自动检测并提示合并冲突
- 🛡️ **交互确认** - 关键操作需要用户确认
- 🛡️ **状态备份** - 操作前显示当前状态
- 🛡️ **彩色日志** - 不同级别的信息用不同颜色标识

## 🎨 输出示例

```bash
================================================================
             TradingAgents-CN 上游代码同步脚本
================================================================

[INFO] 检测到 origin: https://github.com/你的用户名/TradingAgents-CN.git
[INFO] 检测到 upstream: https://github.com/hsliuping/TradingAgents-CN.git
[INFO] 当前分支: main
[INFO] 当前提交: 1621984

[INFO] 最近5次提交:
*   1621984 (HEAD -> main, origin/main) Merge remote-tracking branch 'upstream/main'
...

[SUCCESS] 远程更新获取完成
[INFO] 发现 3 个新的上游提交

[INFO] 上游新提交预览:
* abc1234 修复重要Bug
* def5678 新增功能X
* ghi9012 性能优化

是否继续合并上游代码？ (Y/n): Y

[SUCCESS] 合并完成！
[INFO] 合并统计:
 docs/README.md           |  25 +++++
 src/new_feature.py       |  87 ++++++++++++++++
 2 files changed, 112 insertions(+)

是否推送合并结果到 origin/main？ (Y/n): Y

[SUCCESS] 推送完成！
[SUCCESS] 🎉 同步完成！
```

## 🚨 故障排除

### 常见问题

1. **上游仓库未配置**
   ```bash
   [ERROR] 未配置上游仓库 'upstream'！
   请先执行: git remote add upstream https://github.com/hsliuping/TradingAgents-CN.git
   ```

2. **工作区有未提交更改**
   ```bash
   [WARNING] 工作区有未提交的更改：
   M  file1.py
   ?? file2.py
   是否继续同步？这可能导致合并冲突 (y/N):
   ```

3. **合并冲突**
   ```bash
   [ERROR] 合并失败，可能存在冲突！
   请手动解决冲突后运行: git add . && git commit
   ```

### 解决方案

1. **配置上游仓库**：
   ```bash
   git remote add upstream https://github.com/hsliuping/TradingAgents-CN.git
   ```

2. **处理未提交更改**：
   ```bash
   # 提交更改
   git add .
   git commit -m "提交描述"
   
   # 或储存更改
   git stash
   ```

3. **手动解决冲突**：
   ```bash
   # 查看冲突文件
   git status
   
   # 编辑冲突文件，解决冲突标记
   # 然后添加和提交
   git add .
   git commit -m "解决合并冲突"
   ```

## 📝 注意事项

1. **网络连接** - 确保能正常访问GitHub
2. **权限配置** - 确保有推送到origin的权限
3. **分支状态** - 建议在main分支执行同步
4. **备份习惯** - 重要更改建议先备份

## 🔄 手动同步（如果脚本出问题）

```bash
# 1. 获取上游更新
git fetch upstream
git fetch origin

# 2. 合并上游代码
git merge upstream/main

# 3. 推送到你的仓库
git push origin main
```

## 📞 支持

如果遇到问题：
1. 检查网络连接和Git配置
2. 查看错误信息并按提示操作
3. 必要时使用手动同步方法
4. 联系项目维护者

---

**作者**: 江哥的毒舌AI助手  
**版本**: v1.0  
**更新**: 2024年最新版