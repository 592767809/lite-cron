#!/usr/bin/env python3
"""
生成 crontab 配置文件
从 config.yml 读取任务配置，生成 /tmp/crontab 文件
"""
import os
import sys
import yaml

# 导入日志模块
sys.path.insert(0, os.path.dirname(__file__))
from logger import log_info, log_success, log_error, log_warning


def generate_cron(config_path='config.yml', cron_file='/tmp/crontab'):
    """
    根据 config.yml 生成 crontab 文件

    Args:
        config_path: 配置文件路径
        cron_file: 输出的 crontab 文件路径

    Returns:
        bool: 是否成功
    """
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
    except FileNotFoundError:
        log_error(f"错误: 未找到配置文件 {config_path}")
        return False
    except yaml.YAMLError as e:
        log_error(f"错误: 解析 YAML 失败: {e}")
        return False

    # 写入 crontab 文件
    with open(cron_file, 'a', encoding='utf-8') as f:
        f.write("# 定时任务定义\n")

        if 'tasks' not in config or not config['tasks']:
            log_warning("未配置任何任务")
            return True

        for task in config['tasks']:
            if not task.get('enabled', True):
                log_info(f"禁用任务: {task.get('name', '未命名任务')}")
                continue

            name = task.get('name', '未命名任务')
            schedule = task.get('schedule', '0 * * * *')
            script = task.get('script', '')

            if not script:
                log_warning(f"跳过任务 {name}: 未配置脚本路径")
                continue

            if not os.path.exists(script):
                log_warning(f"跳过任务 {name}: 脚本不存在 {script}")
                continue

            # 任务注释
            f.write(f"# 任务: {name}\n")

            # 生成 cron 行 - 使用 shell 加载环境变量后执行
            # 注意：cron 默认使用 sh，使用 . 命令加载环境变量
            if os.path.exists('/app/task_wrapper.py'):
                cron_line = f"{schedule} cd /app && . /app/.env 2>/dev/null; python3 /app/task_wrapper.py '{name}' '{script}' >> /proc/1/fd/1 2>&1\n"
            else:
                # 降级到直接执行
                cron_line = f"{schedule} cd /app && . /app/.env 2>/dev/null; python3 {script} >> /proc/1/fd/1 2>&1\n"

            f.write(cron_line)
            f.write("\n")
            log_success(f"已添加任务: {name} ({schedule}) -> {script}")

        f.write("\n")

    return True


def main():
    """主函数"""
    # 默认路径
    config_path = 'config.yml'
    cron_file = '/tmp/crontab'

    # 支持命令行参数
    if len(sys.argv) > 1:
        config_path = sys.argv[1]
    if len(sys.argv) > 2:
        cron_file = sys.argv[2]

    success = generate_cron(config_path, cron_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
