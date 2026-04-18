#!/bin/bash

# TradingAgents-CN Docker 一键部署脚本
# 适用于 Linux Docker 环境
# 功能：
# 1. 启动/重建 Docker 服务
# 2. 等待 MongoDB、Redis、Backend、Frontend 就绪
# 3. 自动创建默认管理员用户
# 4. 验证前端登录链路

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"
ADMIN_EMAIL="${ADMIN_EMAIL:-${ADMIN_USERNAME}@tradingagents.cn}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
BACKEND_URL="${BACKEND_URL:-http://localhost:8000}"

MONGODB_CONTAINER="tradingagents-mongodb"
REDIS_CONTAINER="tradingagents-redis"
BACKEND_CONTAINER="tradingagents-backend"
FRONTEND_CONTAINER="tradingagents-frontend"

print_banner() {
    echo "========================================"
    echo "🚀 TradingAgents-CN Docker 一键部署"
    echo "========================================"
    echo ""
}

print_step() {
    echo -e "${BLUE}$1${NC}"
}

print_ok() {
    echo -e "${GREEN}$1${NC}"
}

print_warn() {
    echo -e "${YELLOW}$1${NC}"
}

print_err() {
    echo -e "${RED}$1${NC}"
}

detect_compose() {
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD=(docker compose)
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD=(docker-compose)
    else
        print_err "❌ 未找到 docker compose / docker-compose"
        exit 1
    fi
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_err "❌ 缺少命令: $cmd"
        exit 1
    fi
}

check_environment() {
    print_step "🔍 检查运行环境..."

    require_cmd docker
    require_cmd curl

    if ! docker version >/dev/null 2>&1; then
        print_err "❌ Docker 未运行或未安装"
        exit 1
    fi

    if [ ! -f "docker-compose.yml" ]; then
        print_err "❌ 未找到 docker-compose.yml，请在项目根目录运行"
        exit 1
    fi

    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        cp .env.example .env
        print_warn "⚠️ 未找到 .env，已从 .env.example 复制生成"
    fi

    print_ok "✅ 环境检查通过"
    echo ""
}

start_services() {
    print_step "🐳 启动 Docker 服务..."
    "${COMPOSE_CMD[@]}" up -d --build
    print_ok "✅ Docker 服务已启动"
    echo ""
}

wait_for_container_health() {
    local container="$1"
    local timeout="${2:-180}"
    local elapsed=0

    while [ "$elapsed" -lt "$timeout" ]; do
        local status
        status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || true)"

        if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
            print_ok "✅ $container 已就绪 ($status)"
            return 0
        fi

        sleep 3
        elapsed=$((elapsed + 3))
    done

    print_err "❌ $container 在 ${timeout}s 内未就绪"
    docker logs --tail 80 "$container" 2>/dev/null || true
    return 1
}

wait_for_http() {
    local url="$1"
    local name="$2"
    local timeout="${3:-180}"
    local elapsed=0

    while [ "$elapsed" -lt "$timeout" ]; do
        if curl -fsS "$url" >/dev/null 2>&1; then
            print_ok "✅ $name 可访问: $url"
            return 0
        fi

        sleep 3
        elapsed=$((elapsed + 3))
    done

    print_err "❌ $name 在 ${timeout}s 内未响应: $url"
    return 1
}

wait_for_services() {
    print_step "⏳ 等待容器健康检查通过..."
    wait_for_container_health "$MONGODB_CONTAINER"
    wait_for_container_health "$REDIS_CONTAINER"
    wait_for_container_health "$BACKEND_CONTAINER"
    print_warn "⚠️ 跳过 frontend 容器 healthcheck 阻塞，改用 HTTP 可达性验证"
    echo ""

    print_step "🌐 等待 HTTP 服务可访问..."
    wait_for_http "$BACKEND_URL/api/health" "后端健康接口"
    wait_for_http "$FRONTEND_URL/health" "前端健康接口"
    echo ""
}

ensure_admin_user() {
    print_step "👤 创建或修复默认管理员账户..."

    docker exec -i \
        -e ADMIN_USERNAME="$ADMIN_USERNAME" \
        -e ADMIN_PASSWORD="$ADMIN_PASSWORD" \
        -e ADMIN_EMAIL="$ADMIN_EMAIL" \
        "$BACKEND_CONTAINER" \
        python - <<'PY'
import hashlib
import os
from datetime import datetime

from pymongo import MongoClient

from app.core.config import settings

username = os.environ["ADMIN_USERNAME"]
password = os.environ["ADMIN_PASSWORD"]
email = os.environ["ADMIN_EMAIL"]

client = MongoClient(settings.MONGO_URI)
db = client[settings.MONGO_DB]

db.users.update_one(
    {"username": username},
    {
        "$set": {
            "username": username,
            "email": email,
            "hashed_password": hashlib.sha256(password.encode()).hexdigest(),
            "is_active": True,
            "is_verified": True,
            "is_admin": True,
            "updated_at": datetime.utcnow(),
            "last_login": None,
            "preferences": {
                "default_market": "A股",
                "default_depth": "深度",
                "ui_theme": "light",
                "language": "zh-CN",
                "notifications_enabled": True,
                "email_notifications": False,
            },
            "daily_quota": 10000,
            "concurrent_limit": 10,
            "total_analyses": 0,
            "successful_analyses": 0,
            "failed_analyses": 0,
            "favorite_stocks": [],
        },
        "$setOnInsert": {
            "created_at": datetime.utcnow(),
        },
    },
    upsert=True,
)

print(f"ensured admin user in db={settings.MONGO_DB}, username={username}")
PY

    print_ok "✅ 默认管理员账户已准备完成"
    echo ""
}

verify_login() {
    print_step "🔐 验证登录链路..."

    local response_file
    response_file="$(mktemp)"
    local status
    status="$(
        curl -sS \
            -o "$response_file" \
            -w '%{http_code}' \
            -X POST "$FRONTEND_URL/api/auth/login" \
            -H 'Content-Type: application/json' \
            -d "{\"username\":\"$ADMIN_USERNAME\",\"password\":\"$ADMIN_PASSWORD\"}"
    )"

    if [ "$status" != "200" ]; then
        print_err "❌ 登录验证失败，HTTP 状态码: $status"
        cat "$response_file"
        rm -f "$response_file"
        exit 1
    fi

    rm -f "$response_file"
    print_ok "✅ 前端登录链路验证成功"
    echo ""
}

show_summary() {
    print_step "📊 当前服务状态:"
    "${COMPOSE_CMD[@]}" ps
    echo ""

    echo "========================================"
    echo -e "${GREEN}🎉 部署完成${NC}"
    echo "========================================"
    echo ""
    echo -e "${CYAN}访问地址:${NC}"
    echo "  前端: $FRONTEND_URL"
    echo "  后端 API: $BACKEND_URL"
    echo "  API 文档: $BACKEND_URL/docs"
    echo ""
    echo -e "${CYAN}默认管理员:${NC}"
    echo "  用户名: $ADMIN_USERNAME"
    echo "  密码: $ADMIN_PASSWORD"
    echo ""
    echo -e "${CYAN}常用命令:${NC}"
    echo "  查看日志: ${COMPOSE_CMD[*]} logs -f"
    echo "  查看状态: ${COMPOSE_CMD[*]} ps"
    echo "  停止服务: ${COMPOSE_CMD[*]} down"
    echo ""
}

main() {
    print_banner
    detect_compose
    check_environment
    start_services
    wait_for_services
    ensure_admin_user
    verify_login
    show_summary
}

main "$@"
