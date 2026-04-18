# 🐳 TradingAgents-CN Docker 快速指南

## 🚀 一键启动

```bash
./quick-start.sh
```

这将自动：
- ✅ 检查Docker环境
- 🚀 构建并启动当前新版服务
- 🏥 等待前后端与数据库健康检查通过
- 👤 自动创建默认管理员账号
- 🔐 验证前端登录链路
- 🌐 输出最终访问地址

## 🛑 一键停止

```bash
./quick-stop.sh
```

提供3种停止选项：
1. **停止服务** - 保留所有数据
2. **删除容器** - 保留数据卷
3. **完全清理** - 删除所有数据

## 📱 访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| **主应用** | http://localhost:3000 | Vue 前端界面 |
| **后端 API** | http://localhost:8000 | FastAPI 服务 |
| **Redis管理** | http://localhost:8081 | Redis Commander |

## 💾 数据库信息

```bash
# MongoDB
mongodb://admin:tradingagents123@localhost:27017/tradingagents?authSource=admin

# Redis
redis://:tradingagents123@localhost:6379
```

## 🔐 默认登录信息

脚本会自动创建或修复默认管理员账号：

```text
用户名: admin
密码: admin123
```

如需自定义，可以在执行前设置环境变量：

```bash
ADMIN_USERNAME=myadmin ADMIN_PASSWORD='your-password' ./quick-start.sh
```

## 🔧 常用命令

### 基本操作
```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart frontend backend

# 进入容器
docker exec -it tradingagents-backend bash
```

### 数据管理
```bash
# 备份MongoDB数据
docker exec tradingagents-mongodb mongodump --out /backup

# 清理Redis缓存
docker exec tradingagents-redis redis-cli -a tradingagents123 flushall

# 查看Redis内存使用
docker exec tradingagents-redis redis-cli -a tradingagents123 info memory
```

### 故障排除
```bash
# 重建镜像
docker-compose build --no-cache

# 查看详细日志
docker-compose logs --tail 100 web

# 重置所有数据
docker-compose down -v && docker volume prune -f
```

## 📂 目录结构

```
TradingAgents-CN/
├── quick-start.sh          # 🚀 快速启动脚本
├── quick-stop.sh           # 🛑 快速停止脚本
├── docker-compose.yml      # 🐳 Docker编排文件
├── Dockerfile              # 📦 镜像构建文件
├── .env                    # ⚙️ 环境变量配置
└── scripts/docker/         # 📁 其他Docker脚本
```

## ⚡ 性能优化

### 资源限制
编辑 `docker-compose.yml` 添加资源限制：
```yaml
services:
  web:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

### 缓存优化
```bash
# 调整Redis内存限制
docker exec tradingagents-redis redis-cli -a tradingagents123 config set maxmemory 512mb
```

## 🚨 常见问题

### 端口冲突
```bash
# 查看端口占用
lsof -i :8501

# 修改端口映射
# 编辑 docker-compose.yml 中的 ports 配置
```

### 内存不足
```bash
# 查看容器资源使用
docker stats

# 清理Docker缓存
docker system prune -a
```

### 权限问题
```bash
# macOS给脚本权限
chmod +x quick-start.sh quick-stop.sh

# Linux Docker权限
sudo usermod -aG docker $USER
```

## 📈 监控与日志

### 实时监控
```bash
# 查看容器资源使用
docker stats tradingagents-*

# 查看服务健康状态
docker-compose ps
```

### 日志管理
```bash
# 查看最新日志
docker-compose logs --tail 50 -f

# 按服务查看日志
docker-compose logs web
docker-compose logs mongodb
docker-compose logs redis
```

## 🔄 更新与维护

### 更新应用
```bash
# 拉取最新代码
git pull

# 重建并启动
docker-compose up -d --build
```

### 数据库维护
```bash
# MongoDB备份
docker exec tradingagents-mongodb mongodump --out /backup

# Redis内存清理
docker exec tradingagents-redis redis-cli -a tradingagents123 memory purge
```

---

**💡 提示**: 首次启动会构建镜像并等待服务健康检查，请耐心等待。  

**🔥 快速访问**: 启动完成后直接访问 http://localhost:3000 开始使用！ 
