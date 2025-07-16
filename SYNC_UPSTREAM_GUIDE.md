# 🔄 上游仓库同步指南

## 📋 **仓库配置说明**

当前仓库配置：
- **origin**: https://github.com/apexlj1130/TradingAgents-CN.git (您的fork)
- **upstream**: https://github.com/hsliuping/TradingAgents-CN.git (原始仓库)

## 🔄 **定期同步上游更新**

### 1. 获取上游最新代码
```bash
# 获取上游所有分支的最新提交
git fetch upstream

# 查看上游有哪些新的更新
git log HEAD..upstream/main --oneline
```

### 2. 合并上游更新
```bash
# 切换到main分支
git checkout main

# 合并上游main分支的更新
git merge upstream/main

# 或者使用rebase方式(保持历史整洁)
git rebase upstream/main
```

### 3. 解决冲突(如果有)
```bash
# 如果有冲突，编辑冲突文件后
git add .
git commit -m "resolve merge conflicts"

# 或者在rebase过程中
git add .
git rebase --continue
```

### 4. 推送到您的fork
```bash
git push origin main
```

## 🛡️ **保护您的自定义修改**

### 重要文件列表（需要保护）
- `.env` - 环境变量配置
- `quick-start.sh` - 快速启动脚本
- `quick-stop.sh` - 快速停止脚本
- `DOCKER_QUICK_GUIDE.md` - Docker使用指南
- `SYNC_UPSTREAM_GUIDE.md` - 本文件

### 备份策略
```bash
# 每次同步前备份重要文件
cp .env ~/backup_tradingagents_config/.env.$(date +%Y%m%d)
cp quick-start.sh ~/backup_tradingagents_config/
cp quick-stop.sh ~/backup_tradingagents_config/
```

### 创建保护分支
```bash
# 创建一个包含您自定义内容的分支
git checkout -b custom-features
git add .env quick-start.sh quick-stop.sh DOCKER_QUICK_GUIDE.md
git commit -m "保存自定义配置和脚本"
git push origin custom-features
```

## 🚀 **推荐的同步工作流**

### 方法1: 安全同步流程
```bash
# 1. 备份当前重要文件
./backup_custom_files.sh  # (如果您创建了备份脚本)

# 2. 获取上游更新
git fetch upstream

# 3. 创建临时分支进行合并测试
git checkout -b temp-sync upstream/main
git cherry-pick 1722fde  # (您的自定义commit)

# 4. 测试无问题后合并到main
git checkout main
git merge temp-sync

# 5. 清理临时分支
git branch -d temp-sync

# 6. 推送更新
git push origin main
```

### 方法2: 使用stash保护修改
```bash
# 1. 暂存当前更改
git stash push -m "保存自定义配置"

# 2. 同步上游
git fetch upstream
git rebase upstream/main

# 3. 恢复自定义更改
git stash pop

# 4. 处理冲突并提交
git add .
git commit -m "恢复自定义配置"
git push origin main
```

## 📅 **建议的同步频率**

- **每周**: 检查上游是否有重要更新
- **每月**: 进行一次完整同步
- **重大版本发布时**: 立即同步并测试

## 🔍 **同步前检查清单**

- [ ] 备份`.env`文件
- [ ] 备份自定义脚本
- [ ] 确认当前环境正常运行
- [ ] 查看上游更新日志
- [ ] 测试同步后的功能

## 🆘 **紧急恢复**

如果同步后出现问题：

```bash
# 回退到上一个版本
git reset --hard HEAD~1

# 或者回退到特定commit
git reset --hard 1722fde

# 强制推送(谨慎使用)
git push origin main --force
```

## 📞 **获取帮助**

- 查看同步状态: `git status`
- 查看提交历史: `git log --oneline --graph`
- 查看远程仓库: `git remote -v`
- 比较差异: `git diff upstream/main`

---

**💡 提示**: 建议在同步前先在测试环境验证，确保不影响生产使用。 