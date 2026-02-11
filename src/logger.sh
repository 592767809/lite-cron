#!/bin/bash
#
# 统一日志管理脚本
# 功能：将日志同时输出到文件和控制台（stdout）
#
# 使用方法：
#   source /app/logger.sh    # 在其他脚本中引入
#   log "消息内容"            # 普通日志
#   log_info "消息内容"       # info 级别
#   log_success "消息内容"    # 成功
#   log_error "消息内容"      # 错误
#   log_warning "消息内容"    # 警告
#

# ============ 配置 ============
LOG_DIR="${LOG_DIR:-/app/logs}"
LOG_DATE="$(date '+%Y%m%d')"
LOG_FILE="${LOG_DIR}/${LOG_DATE}.log"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# ============ 核心日志函数 ============

# 通用日志函数
# 参数: $1=消息 $2=级别(INFO/SUCCESS/ERROR/WARNING/DEBUG)
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')

    local formatted="${timestamp} [${level}] ${message}"

    # 同时输出到文件和控制台
    echo "$formatted" | tee -a "$LOG_FILE"
}

# INFO 级别
log_info() {
    log "$1" "INF"
}

# SUCCESS 级别
log_success() {
    log "$1" "INF"
}

# ERROR 级别
log_error() {
    log "$1" "ERR"
}

# WARNING 级别
log_warning() {
    log "$1" "WAR"
}

# DEBUG 级别（仅当 DEBUG=true 时输出）
log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        log "$1" "DBG"
    fi
}

# ============ 辅助函数 ============

# 重置/清空日志文件
log_reset() {
    : > "$LOG_FILE"
}

# 获取日志文件路径
log_path() {
    echo "$LOG_FILE"
}

# 获取日志文件大小
log_size() {
    if [ -f "$LOG_FILE" ]; then
        stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# 导出供子进程使用
export LOG_FILE LOG_DIR LOG_DATE
