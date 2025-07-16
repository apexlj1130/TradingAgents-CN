#!/bin/bash

# TradingAgents-CN Docker快速停止脚本
# 作者: TradingAgents-CN项目组
# 用途: 一键停止所有Docker服务

echo "========================================"
echo "🛑 TradingAgents-CN Docker快速停止"
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
    echo -e "${RED}❌ Docker未运行${NC}"
    exit 1
fi

# 显示当前运行的服务
echo -e "${BLUE}📊 当前运行的TradingAgents服务:${NC}"
docker ps --filter "name=tradingagents" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "未找到运行中的服务"
echo ""

# 询问停止方式
echo -e "${YELLOW}请选择停止方式:${NC}"
echo "1) 停止服务(保留数据)"
echo "2) 停止并删除容器(保留数据卷)"
echo "3) 完全清理(删除所有数据)"
echo ""
read -p "请选择 (1-3): " -n 1 -r
echo ""
echo ""

case $REPLY in
    1)
        echo -e "${BLUE}🛑 停止服务...${NC}"
        docker-compose stop
        echo -e "${GREEN}✅ 服务已停止，数据已保留${NC}"
        echo "使用 docker-compose start 可重新启动"
        ;;
    2)
        echo -e "${BLUE}🗑️ 停止并删除容器...${NC}"
        docker-compose down
        echo -e "${GREEN}✅ 容器已删除，数据卷已保留${NC}"
        echo "使用 ./quick-start.sh 可重新创建并启动"
        ;;
    3)
        echo -e "${RED}⚠️ 警告: 这将删除所有数据！${NC}"
        read -p "确认删除所有数据? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}🧹 完全清理...${NC}"
            docker-compose down -v
            docker volume prune -f 2>/dev/null || true
            echo -e "${GREEN}✅ 完全清理完成${NC}"
        else
            echo -e "${YELLOW}取消清理操作${NC}"
        fi
        ;;
    *)
        echo -e "${YELLOW}取消操作${NC}"
        exit 0
        ;;
esac

echo ""
echo -e "${BLUE}📊 停止后状态:${NC}"
docker ps --filter "name=tradingagents" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "所有TradingAgents服务已停止"
echo ""
echo -e "${GREEN}🎉 操作完成！${NC}" 