# Firecrawl 服务

运行在端口 3002 的 Firecrawl 服务，配置了自动重启和日志管理。

## 快速使用

```bash
# 服务管理
./scripts/manage.sh start       # 启动（自动清理端口冲突）
./scripts/manage.sh stop        # 停止
./scripts/manage.sh restart     # 重启
./scripts/manage.sh status      # 查看状态

# 日志管理
./scripts/manage.sh logs                    # 查看实时日志
./scripts/manage.sh export-logs             # 导出日志到 logs/ 目录
./scripts/manage.sh clean-logs 7            # 清理 7 天前的日志
```

## 服务信息

- **端口**: 3002
- **访问**: http://localhost:3002
- **日志**: /ssd_2/tools/firecrawl/logs
- **配置**: docker-compose.yaml

## 配置特性

- ✅ 容器崩溃自动重启 (`restart: unless-stopped`)
- ✅ 启动时自动清理端口 3002 冲突
- ✅ Docker 日志自动轮转（100MB × 5 files）
- ✅ 可导出日志到文件系统

## Docker Compose

```bash
docker compose up -d        # 启动
docker compose down         # 停止
docker compose logs -f      # 查看日志
```

## 故障排查

```bash
# 1. 查看状态
./scripts/manage.sh status

# 2. 查看日志
./scripts/manage.sh logs

# 3. 导出日志分析
./scripts/manage.sh export-logs

# 4. 重启服务
./scripts/manage.sh restart
```

## 详细文档

参见 `docs/implementation_notes/` 目录
