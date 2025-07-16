#!/bin/bash

# TradingAgents-CN Docker快速启动脚本
# 作者: TradingAgents-CN项目组
# 用途: 一键启动所有Docker服务

set -e  # 遇到错误立即退出

echo "========================================"
echo "🚀 TradingAgents-CN Docker快速启动"
echo "========================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查Docker是否运行
echo -e "${BLUE}🔍 检查Docker服务状态...${NC}"
if ! docker version >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker未运行或未安装${NC}"
    echo "请先启动Docker Desktop或安装Docker"
    exit 1
fi
echo -e "${GREEN}✅ Docker服务正常${NC}"
echo ""

# 检查docker-compose文件
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ 未找到docker-compose.yml文件${NC}"
    echo "请确保在项目根目录下运行此脚本"
    exit 1
fi

# 检查环境变量文件
echo -e "${BLUE}🔍 检查环境配置...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️ 未找到.env文件，将使用docker-compose默认配置${NC}"
else
    echo -e "${GREEN}✅ 找到.env配置文件${NC}"
fi
echo ""

# 清理可能的旧容器
echo -e "${BLUE}🧹 清理旧容器...${NC}"
docker-compose down >/dev/null 2>&1 || true
echo -e "${GREEN}✅ 清理完成${NC}"
echo ""

# 启动服务
echo -e "${BLUE}🚀 启动Docker服务...${NC}"
echo "正在启动以下服务："
echo "  📊 MongoDB (数据库)"
echo "  📦 Redis (缓存)"
echo "  🖥️ Redis Commander (管理界面)"
echo "  🌐 TradingAgents Web (主应用)"
echo ""

if docker-compose up -d; then
    echo -e "${GREEN}✅ 所有服务启动成功${NC}"
else
    echo -e "${RED}❌ 服务启动失败${NC}"
    echo "请检查日志: docker-compose logs"
    exit 1
fi
echo ""

# 等待服务启动
echo -e "${BLUE}⏳ 等待服务完全启动...${NC}"
for i in {1..20}; do
    echo -n "."
    sleep 1
done
echo ""
echo ""

# 检查服务状态
echo -e "${BLUE}📊 服务状态检查:${NC}"
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 健康检查
echo -e "${BLUE}🏥 健康检查...${NC}"

# 检查Web应用
if curl -s http://localhost:8501 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Web应用 (端口8501) - 正常${NC}"
else
    echo -e "${YELLOW}⚠️ Web应用 (端口8501) - 启动中...${NC}"
fi

# 检查Redis Commander
if curl -s http://localhost:8081 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Redis管理界面 (端口8081) - 正常${NC}"
else
    echo -e "${YELLOW}⚠️ Redis管理界面 (端口8081) - 启动中...${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}🎉 启动完成！${NC}"
echo "========================================"
echo ""
echo -e "${BLUE}📱 主要访问地址:${NC}"
echo "  🌐 TradingAgents Web应用: http://localhost:8501"
echo "  🔧 Redis管理界面:        http://localhost:8081"
echo ""
echo -e "${BLUE}📊 数据库连接信息:${NC}"
echo "  MongoDB: mongodb://admin:tradingagents123@localhost:27017/tradingagents"
echo "  Redis:   redis://:tradingagents123@localhost:6379"
echo ""
echo -e "${BLUE}💡 常用命令:${NC}"
echo "  查看日志: docker-compose logs -f"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart"
echo "  服务状态: docker-compose ps"
echo ""
echo -e "${YELLOW}🔥 现在可以在浏览器中访问: http://localhost:8501${NC}"
echo ""

# 可选：自动打开浏览器
read -p "是否自动打开浏览器? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🌐 正在打开浏览器...${NC}"
    if command -v open >/dev/null 2>&1; then
        # macOS
        open http://localhost:8501
    elif command -v xdg-open >/dev/null 2>&1; then
        # Linux
        xdg-open http://localhost:8501
    elif command -v start >/dev/null 2>&1; then
        # Windows (Git Bash)
        start http://localhost:8501
    else
        echo -e "${YELLOW}请手动访问: http://localhost:8501${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🚀 TradingAgents-CN 已准备就绪！${NC}" 