#!/usr/bin/env python3
"""
统一日志管理模块（Python 版本）
功能：将日志同时输出到文件和控制台（stdout）

使用方法：
    from logger import log, log_info, log_success, log_error, log_warning
    
    log_info("消息内容")
    log_success("成功消息")
    log_error("错误消息")
"""
import os
import sys
from datetime import datetime
from pathlib import Path

# ============ 配置 ============
LOG_DIR = os.environ.get('LOG_DIR', '/app/logs')
LOG_DATE = datetime.now().strftime('%Y%m%d')
LOG_FILE = os.path.join(LOG_DIR, f"{LOG_DATE}.log")

# 确保日志目录存在
Path(LOG_DIR).mkdir(parents=True, exist_ok=True)


# ============ 核心日志函数 ============

def log(message: str, level: str = "INF") -> None:
    """
    通用日志函数
    
    Args:
        message: 日志消息
        level: 日志级别 (INFO/SUCCESS/ERROR/WARNING/DEBUG)
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
    formatted = f"{timestamp} [{level}] {message}"
    
    # 输出到控制台（flush=True 确保立即输出到 Docker logs）
    print(formatted, flush=True)
    
    # 输出到文件
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(formatted + '\n')
    except Exception as e:
        # 如果写入文件失败，至少打印到控制台
        print(f"[ERR] 无法写入日志文件: {e}")


def log_info(message: str) -> None:
    """INFO 级别日志"""
    log(message, "INF")


def log_success(message: str) -> None:
    """SUCCESS 级别日志"""
    log(message, "INF")


def log_error(message: str) -> None:
    """ERROR 级别日志"""
    log(message, "ERR")


def log_warning(message: str) -> None:
    """WARNING 级别日志"""
    log(message, "WAR")


def log_debug(message: str) -> None:
    """DEBUG 级别日志（仅当 DEBUG=true 时输出）"""
    if os.environ.get('DEBUG', 'false').lower() == 'true':
        log(message, "DBG")


# ============ 辅助函数 ============

def log_reset() -> None:
    """重置/清空日志文件"""
    try:
        with open(LOG_FILE, 'w', encoding='utf-8') as f:
            f.write('')
    except Exception as e:
        print(f"[ERROR] 无法清空日志文件: {e}")


def log_path() -> str:
    """获取日志文件路径"""
    return LOG_FILE


def log_size() -> int:
    """获取日志文件大小（字节）"""
    try:
        return os.path.getsize(LOG_FILE)
    except (OSError, FileNotFoundError):
        return 0


# 如果直接运行此脚本，显示测试信息
if __name__ == '__main__':
    log_info("日志模块测试")
    log_success("成功消息测试")
    log_warning("警告消息测试")
    log_error("错误消息测试")
    print(f"\n日志文件路径: {log_path()}")
    print(f"日志文件大小: {log_size()} bytes")
