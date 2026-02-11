# LiteCron - 智能体开发指南

LiteCron 是一个基于 Docker 的轻量级 Python 脚本定时任务调度器。

## 项目概述

一个极简的容器化调度器，基于 YAML 配置和 cron 表达式执行 Python 脚本。支持 `schedule` 和 `apscheduler` 两种后端库。内置 Web 管理界面和通知系统。

## 核心特性

- **定时调度**: 基于 cron 表达式的灵活定时执行
- **Web 管理界面**: 浏览器中查看状态和管理任务
- **通知系统**: 支持 Webhook 和 NTFY 多种通知方式
- **日志管理**: 自动记录任务执行日志
- **环境隔离**: Docker 容器化，配置与代码分离
- **热重载**: 修改配置无需重建镜像

## 项目架构

```
lite-cron/
├── 📜 manage.py                  # 管理脚本（Python实现，支持交互式菜单）
├── 🐳 Dockerfile                 # Docker 镜像构建文件
├── 🐳 compose.yml                # 容器编排配置
├── 🐳 compose.example.yml        # 容器编排配置示例
├── 📝 requirements.txt           # Python 依赖
├── 📄 config.yml                 # 任务配置文件
├── 📄 config.example.yml         # 配置示例文件
├── 📁 src/                       # 源代码目录（容器内 /app/）
│   ├── webapp.py                 # Web 管理界面 (Flask)
│   ├── notify.py                 # 通知模块
│   ├── make_cron.py              # 生成 crontab 配置文件
│   ├── make_env.py               # 生成环境变量配置文件
│   ├── task_wrapper.py           # 任务执行包装器（Python）
│   ├── entrypoint.sh             # 容器启动入口
│   ├── 📁 template/              # HTML 模板目录
│   │   └── index.html            # 主页面模板
│   └── 📁 static/                # 静态资源目录
│       ├── app.js                # 前端交互逻辑
│       └── style.css             # 样式文件
├── 📁 tasks/                     # 任务脚本目录（项目内置，可手动添加新脚本）
│   ├── ikuuu.py                  # iKuuu 签到
│   ├── pttime.py                 # PTTime 签到
│   ├── smzdm.py                  # 什么值得买签到
│   ├── tieba.py                  # 百度贴吧签到
│   ├── fnclub.py                 # 飞牛Nas论坛签到
│   └── aliyunpan.py              # 阿里云盘签到
├── 📁 data/                      # 持久化数据目录
└── 📁 logs/                      # 运行时日志目录
```

## 快速开始

### 环境要求

- Docker 20.10+
- Docker Compose 2.0+
- Python 3.8+ (本地开发可选)
- Git

### 安装部署

```bash
# 1. 克隆项目
git clone https://github.com/yourusername/lite-cron.git
cd lite-cron

# 2. 复制配置并编辑
cp config.example.yml config.yml
vim config.yml

# 3. 构建并启动
python manage.py build
python manage.py start

# 4. 访问 Web 界面
# 默认地址: http://localhost:5000
```

## 管理命令

`manage.py` 提供交互式菜单和命令行两种使用方式：

### 交互式菜单（推荐）

```bash
python manage.py              # 启动交互式菜单
```

交互式菜单特性：
- 📋 分组显示：容器相关、任务相关、通用功能
- 🎨 彩色输出：状态一目了然
- 🔄 自动清屏：操作完成后自动清理界面
- ⚡ 快捷操作：输入数字即可执行

### 命令行模式

#### 容器管理

```bash
python manage.py start        # 启动容器
python manage.py stop         # 停止容器
python manage.py restart      # 重启容器
python manage.py status       # 查看容器状态
python manage.py logs         # 查看容器日志
python manage.py shell        # 进入容器 shell
python manage.py reload       # 重新加载配置
```

#### 任务管理

```bash
python manage.py list              # 查看定时任务计划列表
python manage.py run TaskName      # 立即执行指定任务
python manage.py run --all         # 执行所有已启用任务
python manage.py tasklogs          # 查看任务执行日志
python manage.py validate          # 验证 YAML 配置
```

#### 系统维护

```bash
python manage.py build                   # 构建镜像（自动生成标签）
python manage.py build v1.0.0            # 构建并指定版本标签
python manage.py build --no-cache        # 强制重新安装依赖
python manage.py update                  # 更新项目（拉取代码并重启）
python manage.py clean                   # 清理 7 天前的日志文件
python manage.py notify "消息"            # 发送测试通知
python manage.py notify "消息" -l         # 发送测试通知附带最近 15 行日志
python manage.py notify "消息" -l -n 30   # 发送测试通知附带最近 30 行日志
python manage.py help                    # 显示帮助信息
```

## 构建命令

### Docker 构建

```bash
# 使用缓存构建（推荐）
docker build -t lite-cron .

# 强制重新构建（不使用缓存）
docker build --no-cache -t lite-cron .

# 使用 docker-compose 构建
docker compose build
docker compose build --no-cache

# 使用 manage.py 构建（自动生成标签）
python manage.py build
python manage.py build v1.0.0
python manage.py build --no-cache
```

### 构建缓存机制

Docker 构建优化策略：
1. **系统依赖层**（apt-get）：只要前面的指令不变，这层一直缓存
2. **Python 依赖层**（pip）：只有 `requirements.txt` 变化时才重新安装
3. **应用文件层**（COPY）：每次构建都会更新，但前两层已缓存所以很快

何时使用 `--no-cache`：
- 需要更新系统包或 Python 包到最新版本时
- 怀疑缓存层损坏导致问题时
- 正常开发不需要使用，第一次之后的构建会快很多

## 开发命令

### 本地开发

```bash
# 安装依赖
pip install -r requirements.txt

# 本地运行 Web 界面
python src/webapp.py

# 测试任务脚本
python tasks/ikuuu.py

# 验证 YAML 配置
python manage.py validate

# 本地测试通知
python -c "from src.notify import notify; notify('标题', '内容')"
```

### 任务开发

添加新任务脚本时：
1. 放入 `tasks/` 目录
2. 在 `config.yml` 中添加条目并配置调度
3. 本地测试：`python tasks/your_script.py`
4. 验证环境变量已设置
5. 构建并运行容器测试集成

## 配置格式

### 任务配置 (config.yml)

```yaml
tasks:
  - name: "TaskName"
    schedule: "0 2 * * *"    # Cron 表达式（5 字段格式）
    script: "tasks/script.py"  # 相对于 /app 的路径
    description: "任务描述"
    enabled: true
    env:
      VAR_NAME: "值"

# 通知配置
notify:
  on_failure: true        # 任务失败时发送通知
  on_success: false       # 任务成功时也发送通知

  # Webhook 通知
  webhook:
    url: ""                # Webhook URL
    method: "POST"         # HTTP 方法
    content_type: "application/json"
    headers: |
      Authorization: Bearer xxx

  # NTFY 通知
  ntfy:
    url: ""               # NTFY 服务器地址
    topic: ""             # Topic 名称
    priority: "3"         # 优先级 1-5
```

### Cron 表达式格式

```
* * * * *
│ │ │ │ └── 星期 (0-7, 0和7都代表星期日)
│ │ │ └──── 月份 (1-12)
│ │ └────── 日期 (1-31)
│ └──────── 小时 (0-23)
└────────── 分钟 (0-59)

# 常用示例：
0 2 * * *       # 每天凌晨 2 点
*/5 * * * *     # 每 5 分钟
0 9 * * 1       # 每周一上午 9 点
30 4 * * 0,6    # 每周六和周日凌晨 4:30
0 */3 * * *     # 每 3 小时
```

### 环境变量配置

任务级环境变量（优先级更高）：

```yaml
tasks:
  - name: "Example"
    env:
      API_KEY: "xxx"       # 任务专属变量
      DEBUG: "true"
```

全局环境变量：

```yaml
global_env:
  TZ: "Asia/Shanghai"      # 时区
  LOG_LEVEL: "INFO"        # 日志级别
  WEBUI_PORT: "5000"       # Web 界面端口（默认 5000）
```

## Web 管理界面

### 访问地址

- 本地: http://localhost:5000
- 容器内: http://127.0.0.1:5000

### 功能特性

- **仪表盘**: 查看整体运行状态
- **任务列表**: 查看所有任务的执行状态和历史
- **手动执行**: 点击按钮立即执行任务
- **日志查看**: 查看任务执行日志
- **配置编辑**: 在线编辑配置文件

## 通知系统

### Webhook 通知

支持多种内容格式：

```yaml
notify:
  webhook:
    url: "https://hooks.example.com/send"
    method: "POST"
    content_type: "application/json"
    headers: |
      Authorization: Bearer your_token
```

请求体格式：
- `application/json`: `{"title": "xxx", "content": "xxx"}`
- `application/x-www-form-urlencoded`: `title=xxx&content=xxx`
- `text/plain`: `xxx`

### NTFY 通知

```yaml
notify:
  ntfy:
    url: "https://ntfy.sh"
    topic: "lite-cron"
    priority: "3"
    username: "user"
    password: "pass"
```

### 通知触发条件

```yaml
notify:
  on_failure: true    # 失败时通知 ✅ 默认
  on_success: false   # 成功时也通知（可选）
```

## 代码风格规范

### Python 代码风格

- **Python 版本**: 3.11+
- **类型注解**: 对函数签名使用 typing 模块（Dict、List、Optional）
- **文档字符串**: 对模块/类使用三引号文档字符串，描述使用中文
- **注释**: 本项目优先使用中文注释
- **行长度**: 无严格限制，保持可读即可

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类 | PascalCase | `LiteCronScheduler`、`ScriptRunner` |
| 函数 | snake_case | `load_config`、`run_script` |
| 变量 | snake_case | `cron_expr`、`script_path` |
| 常量 | UPPER_SNAKE_CASE | `DEFAULT_TIMEOUT`、`LOG_LEVEL` |
| 私有方法 | 下划线前缀 | `_signal_handler`、`_load_config` |
| 任务脚本 | snake_case | `ikuuu_signin`、`pttime_check` |

### 导入顺序

```python
# 1. 标准库优先
import os
import sys
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

# 2. 第三方库
import yaml
import requests

# 3. 本地模块
from notify import notify
from scheduler import Scheduler

# 4. 可选导入（带降级方案）
try:
    import schedule
    USE_SCHEDULE = True
except ImportError:
    from apscheduler.schedulers.background import BackgroundScheduler
    USE_SCHEDULE = False
```

### 错误处理

- 尽可能使用 try-except 块捕获特定异常类型
- 使用 emoji 标记记录错误：`❌` 表示错误，`⚠️` 表示警告
- 错误消息始终包含上下文（脚本名称、文件路径）
- 使用 f-string 格式化错误

```python
try:
    result = operation()
except ValueError as e:
    logger.error(f"❌ 参数错误: {task_name} - {str(e)}")
except requests.RequestException as e:
    logger.error(f"❌ 网络请求失败: {url} - {str(e)}")
except Exception as e:
    logger.error(f"❌ 未知错误: {task_name} - {str(e)}")
    raise  # 重新抛出未知异常
```

### 日志标准

使用 emoji 标记日志级别：

| 标记 | 用途 | 场景 |
|------|------|------|
| 📋 | 配置/信息 | 加载配置、启动信息 |
| ✅ | 成功 | 操作完成、任务成功 |
| ❌ | 错误 | 操作失败、异常 |
| ⚠️ | 警告 | 可恢复问题、需要注意 |
| 📅 | 调度 | 定时触发、下次执行 |
| 🔄 | 运行状态 | 状态变更、重试 |
| 🚀 | 任务开始 | 任务启动 |
| 🏁 | 任务结束 | 任务完成 |

### 任务脚本结构

```python
#!/usr/bin/env python3
"""
任务描述：一句话说明任务功能
"""
import os
import sys
import logging
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 环境变量（在 config.yml 中配置）
EMAIL = os.environ.get('MY_EMAIL')
PASSWORD = os.environ.get('MY_PWD')


def main():
    """主函数：任务逻辑"""
    try:
        logger.info("🚀 任务开始")

        # 任务逻辑
        logger.info("📋 执行签到...")
        result = sign_in(EMAIL, PASSWORD)

        if result:
            logger.info("✅ 签到成功")
            return 0
        else:
            logger.warning("⚠️ 签到失败")
            return 1

    except Exception as e:
        logger.error(f"❌ 任务异常: {str(e)}")
        return 1

    finally:
        logger.info("🏁 任务结束")


def sign_in(email: str, password: str) -> bool:
    """签到函数"""
    # 实现逻辑
    return True


if __name__ == '__main__':
    sys.exit(main())
```

## Shell 脚本规范

### 基础规范

```bash
#!/bin/bash
set -e  # 遇错即停

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印函数
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}
```

### 最佳实践

- 使用 bash 并启用严格模式：`#!/bin/bash` + `set -e`
- 输出中包含有用的 emoji 标记
- 操作前检查必需文件
- 使用带默认值的环境变量：`${VAR:-默认值}`
- 尽可能保持脚本幂等性
- 函数封装复用逻辑

## Docker 规范

### Dockerfile 最佳实践

```dockerfile
# 1. 使用特定版本标签，避免 latest
FROM python:3.11-slim

# 2. 设置维护者
LABEL maintainer="you@example.com"

# 3. 安装系统依赖
RUN apt-get update && apt-get install -y \
    cron \
    && rm -rf /var/lib/apt/lists/*

# 4. 设置工作目录
WORKDIR /app

# 5. 先复制依赖文件再复制代码（利用缓存）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. 复制应用文件
COPY . .

# 7. 暴露端口
EXPOSE 5000

# 8. 健康检查
HEALTHCHECK --interval=30s --timeout=10s \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')" || exit 1

# 9. 入口脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

### compose.yml

```yaml
version: '3.8'

services:
  lite-cron:
    build: .
    container_name: lite-cron
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ./config.yml:/app/config.yml:ro
      - ./tasks:/app/tasks:ro
      - ./logs:/app/logs
      - ./data:/app/data
    environment:
      - TZ=Asia/Shanghai
      - LOG_LEVEL=INFO
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5000/')"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 常见问题 (FAQ)

### Q1: 任务没有执行？

检查步骤：
1. 验证容器状态：`python manage.py status`
2. 检查容器日志：`python manage.py logs`
3. 验证 cron 表达式是否正确：`python manage.py list`
4. 确认任务已启用：`enabled: true`
5. 检查宿主机时间是否正确

### Q2: 如何查看任务日志？

```bash
# 查看所有任务日志
python manage.py tasklogs

# 查看特定任务的日志
docker exec lite-cron cat /app/logs/ikuuu.log
```

### Q3: 如何添加新任务？

1. 在 `tasks/` 目录创建新的 Python 脚本
2. 在 `config.yml` 中添加任务配置
3. 验证配置：`python manage.py validate`
4. 重启容器：`python manage.py restart`

### Q4: 通知没有收到？

1. 验证 `config.yml` 中的通知配置
2. 检查 Webhook URL 是否可访问
3. 确认 NTFY 服务器配置正确
4. 发送测试通知：
   ```bash
   python manage.py notify "测试消息"                    # 基础测试
   python manage.py notify "测试消息" -l                 # 附带最近日志
   python manage.py notify "测试消息" -l -n 30          # 指定日志行数
   ```

### Q5: 如何更新任务脚本？

1. 修改 `tasks/` 中的脚本
2. 重启容器：`python manage.py restart`
3. 验证执行：`python manage.py run TaskName`

### Q6: 容器无法启动？

```bash
# 检查端口是否被占用
netstat -tlnp | grep 5000

# 查看详细错误
docker compose logs

# 检查配置文件语法
python manage.py validate
```

## 故障排查

### 容器相关

```bash
# 1. 查看容器状态
docker ps -a

# 2. 查看容器日志
docker logs lite-cron

# 3. 进入容器排查
docker exec -it lite-cron /bin/bash

# 4. 检查进程
docker exec lite-cron ps aux

# 5. 检查资源使用
docker stats lite-cron
```

### 网络相关

```bash
# 检查容器网络
docker network ls
docker network inspect lite-cron_default

# 测试容器网络
docker exec lite-cron ping -c 3 example.com
```

### 权限相关

```bash
# 确保日志目录可写
chmod -R 777 logs/
chmod -R 777 data/
```

## 性能优化

### 容器优化

- 使用 `python:3.11-slim` 减少镜像体积
- 使用 `--no-cache-dir` 减少 pip 安装体积
- 合理设置健康检查间隔

### 任务优化

- 避免长时间阻塞的任务
- 使用连接池复用 HTTP 连接
- 设置合理的超时时间

### 日志优化

- 定期清理旧日志：`./manage.sh clean`
- 日志文件轮转
- 控制日志级别（生产环境用 INFO）

## 安全指南

### 环境变量安全

```yaml
# ❌ 错误：直接在配置中写明文密码
env:
  PASSWORD: "my_secret_password"

# ✅ 正确：使用 Docker Secrets 或外部密钥管理
env:
  PASSWORD_FILE: /run/secrets/password
```

### 文件权限

```bash
# 敏感文件权限
chmod 600 config.yml
chmod 600 .env

# 日志目录权限
chmod 755 logs/
```

### 网络安全

- Web 界面使用反向代理加 HTTPS
- Webhook 使用 HTTPS
- 限制容器网络访问

### 镜像安全

```bash
# 扫描镜像漏洞
docker scout cve lite-cron

# 使用已知漏洞较少的镜像版本
FROM python:3.11-slim-bookworm
```

## 贡献指南

### 提交 Issue

报告 Bug 时请包含：
1. 复现步骤
2. 期望行为
3. 实际行为
4. 环境信息（Docker 版本、操作系统等）
5. 日志截图

### 提交 PR

1. Fork 项目
2. 创建功能分支：`git checkout -b feature/xxx`
3. 提交更改：`git commit -m "feat: 添加 xxx 功能"`
4. 推送分支：`git push origin feature/xxx`
5. 创建 Pull Request

### 代码规范

- 遵循项目现有的代码风格
- 添加中文注释
- 为新功能添加文档
- 确保所有测试通过

## 无 Lint/测试框架

本项目有意采用最小化工具链：
- 未配置 pytest、flake8、black 或 mypy
- 依赖手动测试和 Docker 构建
- 保持代码简单可读

## 许可证

MIT License

## 参考资源

- [Cron 表达式在线生成器](https://crontab.guru/)
- [Croniter Python 库](https://croniter.readthedocs.io/)
- [Docker 官方文档](https://docs.docker.com/)
- [Flask 官方文档](https://flask.palletsprojects.com/)
