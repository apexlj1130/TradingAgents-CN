#!/bin/bash

# =============================================================================
# 上游代码同步脚本 (TradingAgents-CN)
# 作者: 江哥的毒舌AI助手
# 功能: 自动从上游仓库同步最新代码到本地并推送到origin
# =============================================================================

set -euo pipefail  # 严格模式：遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在git仓库中
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是Git仓库！"
        exit 1
    fi
}

# 检查工作区是否干净
check_clean_workspace() {
    if [[ -n $(git status --porcelain) ]]; then
        log_warning "工作区有未提交的更改："
        git status --short
        echo
        read -p "是否继续同步？这可能导致合并冲突 (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi
}

# 检查远程仓库配置
check_remotes() {
    local has_origin=false
    local has_upstream=false
    
    if git remote | grep -q "^origin$"; then
        has_origin=true
        log_info "检测到 origin: $(git remote get-url origin)"
    fi
    
    if git remote | grep -q "^upstream$"; then
        has_upstream=true
        log_info "检测到 upstream: $(git remote get-url upstream)"
    else
        log_error "未配置上游仓库 'upstream'！"
        log_info "请先执行: git remote add upstream https://github.com/hsliuping/TradingAgents-CN.git"
        exit 1
    fi
}

# 显示当前分支状态
show_current_status() {
    local current_branch=$(git branch --show-current)
    local current_commit=$(git rev-parse --short HEAD)
    
    log_info "当前分支: ${current_branch}"
    log_info "当前提交: ${current_commit}"
    
    echo
    log_info "最近5次提交:"
    git log --oneline --graph --decorate -5
    echo
}

# 获取远程更新
fetch_updates() {
    log_info "获取远程仓库更新..."
    
    log_info "从 upstream 获取更新..."
    if ! git fetch upstream; then
        log_error "从 upstream 获取更新失败！"
        exit 1
    fi
    
    log_info "从 origin 获取更新..."
    if ! git fetch origin; then
        log_error "从 origin 获取更新失败！"
        exit 1
    fi
    
    log_success "远程更新获取完成"
}

# 检查是否有新的提交
check_new_commits() {
    local current_branch=$(git branch --show-current)
    local upstream_commits=$(git rev-list --count HEAD..upstream/${current_branch} 2>/dev/null || echo "0")
    
    if [[ $upstream_commits -eq 0 ]]; then
        log_success "没有新的上游提交，代码已是最新！"
        return 1
    else
        log_info "发现 ${upstream_commits} 个新的上游提交"
        echo
        log_info "上游新提交预览:"
        git log --oneline --graph --decorate HEAD..upstream/${current_branch}
        echo
        return 0
    fi
}

# 执行合并
perform_merge() {
    local current_branch=$(git branch --show-current)
    
    log_info "正在合并 upstream/${current_branch}..."
    
    if git merge upstream/${current_branch}; then
        log_success "合并完成！"
        
        # 显示合并统计
        echo
        log_info "合并统计:"
        git diff --stat HEAD~1
        echo
    else
        log_error "合并失败，可能存在冲突！"
        log_info "请手动解决冲突后运行: git add . && git commit"
        exit 1
    fi
}

# 推送到origin
push_to_origin() {
    local current_branch=$(git branch --show-current)
    
    read -p "是否推送合并结果到 origin/${current_branch}？ (Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "跳过推送到 origin"
        return 0
    fi
    
    log_info "推送到 origin/${current_branch}..."
    
    if git push origin ${current_branch}; then
        log_success "推送完成！"
    else
        log_error "推送失败！"
        exit 1
    fi
}

# 显示最终状态
show_final_status() {
    echo
    log_success "🎉 同步完成！"
    echo
    log_info "最终状态:"
    git status
    echo
    log_info "最新提交历史:"
    git log --oneline --graph --decorate -5
}

# 主函数
main() {
    echo "================================================================"
    echo "             TradingAgents-CN 上游代码同步脚本"
    echo "================================================================"
    echo
    
    # 执行检查
    check_git_repo
    check_remotes
    check_clean_workspace
    
    # 显示当前状态
    show_current_status
    
    # 获取更新
    fetch_updates
    
    # 检查新提交
    if ! check_new_commits; then
        exit 0
    fi
    
    # 确认是否继续
    read -p "是否继续合并上游代码？ (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
    
    # 执行合并和推送
    perform_merge
    push_to_origin
    show_final_status
    
    echo
    log_success "所有操作完成！代码已成功同步。"
}

# 错误处理
trap 'log_error "脚本执行过程中发生错误！"; exit 1' ERR

# 执行主函数
main "$@"