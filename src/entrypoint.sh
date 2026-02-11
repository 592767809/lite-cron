#!/bin/bash
#
# LiteCron 容器入口脚本
#

# 设置日志目录
mkdir -p /app/logs

# 引入统一日志管理
source /app/logger.sh

log_info "🚀 启动LiteCron"
log_info "时间: $(date) 默认时区: ${TIMEZONE:-UTC}"

# ============ 信号处理 ============
shutdown() {
    log_info "收到停止信号，正在关闭..."
    
    # 停止 cron 服务
    service cron stop 2>/dev/null || true
    
    # 停止 WebUI
    if [ -n "${WEBUI_PID:-}" ] && kill -0 $WEBUI_PID 2>/dev/null; then
        kill $WEBUI_PID 2>/dev/null || true
    fi
    
    log_info "已关闭所有服务"
    exit 0
}

# 捕获 SIGTERM 和 SIGINT 信号
trap shutdown SIGTERM SIGINT

# ============ 启动逻辑 ============

# 设置时区（如果提供）
if [ -n "$TIMEZONE" ]; then
    log_info "设置时区为: $TIMEZONE"
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    echo $TIMEZONE > /etc/timezone
fi

# 检查配置文件是否存在
if [ ! -f "config.yml" ]; then
    log_error "未找到 config.yml 配置文件"
    exit 1
fi

# ============ 导出任务环境变量 ============

# 生成环境变量文件
if [ -f "/app/make_env.py" ]; then
    python3 /app/make_env.py
    if [ $? -ne 0 ]; then
        log_error "生成环境变量文件失败"
        exit 1
    fi
else
    log_warning "未找到 make_env.py，跳过环境变量导出"
fi

# 加载环境变量
if [ -f "/app/.env" ]; then
    source /app/.env
    log_success "环境变量加载完成"
fi

# 检查 notify.py 是否存在
if [ ! -f "notify.py" ]; then
    log_warning "未找到 notify.py，任务失败时将无法发送通知"
fi

# 检查 task_wrapper 是否存在
if [ ! -f "task_wrapper.py" ]; then
    log_warning "未找到 task_wrapper.py"
fi

# 创建crontab文件
CRON_FILE="/tmp/crontab"
echo "# 自动生成的crontab - $(date)" > $CRON_FILE
echo "# 不要手动编辑此文件" >> $CRON_FILE
echo "" >> $CRON_FILE
echo "# 禁用邮件通知，避免输出被邮件系统捕获" >> $CRON_FILE
echo "MAILTO=\"\"" >> $CRON_FILE
echo "" >> $CRON_FILE

# 设置环境变量
if [ -f "config.yml" ]; then
    echo "# 全局环境变量" >> $CRON_FILE
    echo "APP_ENV=${APP_ENV:-production}" >> $CRON_FILE
    echo "LOG_LEVEL=${LOG_LEVEL:-INFO}" >> $CRON_FILE
    echo "PYTHONPATH=/app" >> $CRON_FILE
    echo "" >> $CRON_FILE
    echo "PATH=/usr/local/bin:/usr/bin:/bin" >> $CRON_FILE
    echo "" >> $CRON_FILE
fi

# 生成cron任务
log_info "生成cron任务..."
python3 /app/make_cron.py

if [ $? -ne 0 ]; then
    log_error "生成 cron 任务失败"
    exit 1
fi

log_info "生成的crontab路径: /tmp/crontab"

# 加载并启动 cron
log_info "加载并启动 cron 服务..."
crontab /tmp/crontab
service cron start

# 启动 WebUI（可选）
if [ "${WEBUI:-false}" = "true" ]; then
    log_info "WebUI 已启用"
    
    if [ -f "/app/webapp.py" ]; then
        WEBUI_PORT=${WEBUI_PORT:-5000}
        mkdir -p /app/ui
        
        # 在后台启动 Flask 服务
        cd /app && python3 /app/webapp.py &
        WEBUI_PID=$!
        
        # 快速检查是否启动成功
        sleep 0.5
        
        if kill -0 $WEBUI_PID 2>/dev/null; then
            log_success "✅ WebUI 启动成功 (PID: $WEBUI_PID) 访问地址: http://localhost:${WEBUI_PORT}"
        else
            log_warning "WebUI 启动失败"
        fi
    else
        log_warning "未找到 webapp.py"
    fi
else
    log_info "WebUI 未启用"
fi

log_success "✅ 容器启动完成"

# ============ 保持运行（等待信号） ============
# 使用 wait 等待后台进程，可以正确响应 SIGTERM/SIGINT 信号
sleep infinity &
wait $!
