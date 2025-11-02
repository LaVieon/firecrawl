# Firecrawl 服务实现说明

## 配置内容

### 1. 持久化运行

在 `docker-compose.yaml` 中为所有服务添加了 `restart: unless-stopped` 配置，确保：

- 容器崩溃时自动重启
- Docker 服务重启后自动恢复

### 2. 端口安全（3002）

`scripts/manage.sh start` 会自动：

- 检测端口 3002 是否被占用
- 停止占用端口的旧容器
- 清理已停止的容器
- 启动新服务并验证端口

### 3. 日志管理

**Docker 日志轮转** (在 docker-compose.yaml 中配置):

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "100m"
    max-file: "5"
```

**日志导出**:

- 使用 `scripts/manage.sh export-logs` 导出日志到 `logs/` 目录
- 使用 `scripts/manage.sh clean-logs N` 清理 N 天前的日志

## 目录结构

```
/ssd_2/tools/firecrawl/
├── docker-compose.yaml     # Docker Compose 配置（已优化）
├── .env                    # 环境变量
├── README.md               # 主文档
├── scripts/
│   └── manage.sh           # 管理脚本
├── logs/                   # 导出的日志文件
└── docs/
    └── implementation_notes/
        └── README.md       # 本文件
```

## 服务管理脚本

`scripts/manage.sh` 提供以下功能：

| 命令                | 功能                              |
| ------------------- | --------------------------------- |
| `start`             | 启动服务，自动检查和清理端口 3002 |
| `stop`              | 停止服务                          |
| `restart`           | 重启服务                          |
| `status`            | 查看服务状态和端口                |
| `logs [容器]`       | 查看实时日志                      |
| `export-logs`       | 导出所有日志到文件                |
| `clean-logs [天数]` | 清理旧日志文件                    |

## 配置细节

### Docker Compose 优化项

1. **重启策略**: 所有容器都配置了 `restart: unless-stopped`
2. **日志配置**: 所有容器都配置了日志轮转（100MB × 5）
3. **端口映射**: API 服务映射 3002:3002

### 启动流程

`scripts/manage.sh start` 执行的步骤：

1. 检查端口 3002 是否被占用
2. 如果被占用，停止旧的 firecrawl 容器
3. 清理所有已停止的 firecrawl 容器
4. 启动新服务
5. 显示容器状态

### 日志系统

**Docker 层**:

- 自动轮转，每个文件最大 100MB
- 保留最近 5 个文件
- 总空间约 500MB per container

**文件系统**:

- 使用 `export-logs` 导出到 `logs/` 目录
- 文件命名: `{容器名}_{日期时间}.log`
- 可手动或定时清理旧文件

## 集成到调用端程序

### Python 示例

```python
import requests
import subprocess

def ensure_firecrawl():
    try:
        requests.get("http://localhost:3002", timeout=5)
    except:
        subprocess.run(["/ssd_2/tools/firecrawl/scripts/manage.sh", "start"])

ensure_firecrawl()
```

### Shell 示例

```bash
# 在程序启动前检查
if ! curl -s http://localhost:3002 > /dev/null; then
    /ssd_2/tools/firecrawl/scripts/manage.sh start
fi
```

## 故障排查

1. **端口被占用**

   ```bash
   ./scripts/manage.sh start  # 会自动清理
   ```

2. **服务未响应**

   ```bash
   ./scripts/manage.sh status
   ./scripts/manage.sh logs
   ./scripts/manage.sh restart
   ```

3. **查看历史日志**
   ```bash
   ./scripts/manage.sh export-logs
   ls -lh logs/
   ```

## 可选配置

### 设置开机自启动（systemd）

创建 `/etc/systemd/system/firecrawl.service`:

```ini
[Unit]
Description=Firecrawl Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/ssd_2/tools/firecrawl
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

启用:

```bash
sudo systemctl enable firecrawl
sudo systemctl start firecrawl
```

### 设置日志自动清理（crontab）

```bash
# 每天凌晨 2 点清理 7 天前的日志
0 2 * * * /ssd_2/tools/firecrawl/scripts/manage.sh clean-logs 7
```

---

配置时间: 2025-11-03  
端口: 3002  
日志目录: /ssd_2/tools/firecrawl/logs
