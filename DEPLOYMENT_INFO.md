# Firecrawl 2.5 部署信息

## 部署时间
2025-11-02

## 部署位置
- 目录: `/ssd_2/tools/firecrawl`
- 版本: Firecrawl 2.5 (v2.5.0)

## 架构说明
✅ **使用共享 PostgreSQL** - 复用服务器现有的 PostgreSQL 服务 (postgres-postgres-1)
- 更加规范和高效
- 节省服务器资源
- 便于统一管理和备份

## 服务端口
- API 服务: `3002` (主端口)
- PostgreSQL: `5432` (共享服务，容器：postgres-postgres-1)
- Redis: 6379 (容器内部)
- Playwright Service: 3000 (容器内部)

## 数据库配置
- **数据库名：** `firecrawl`
- **Schema：** `nuq`
- **连接方式：** 通过 host.docker.internal 连接到主机的 PostgreSQL
- **用户名：** postgres
- **密码：** Xdjf@1234

## 访问地址
- API 端点: `http://localhost:3002`
- Bull Queue 管理面板: `http://localhost:3002/admin/CHANGEME/queues`

## Docker 容器
```bash
# 查看容器状态
cd /ssd_2/tools/firecrawl && docker compose ps

# 查看日志
docker logs firecrawl-api-1

# 停止服务
docker compose down

# 启动服务
docker compose up -d

# 重启服务
docker compose restart
```

## 数据库管理
```bash
# 连接到 firecrawl 数据库
docker exec -it postgres-postgres-1 psql -U postgres -d firecrawl

# 查看所有表
docker exec postgres-postgres-1 psql -U postgres -d firecrawl -c "\dt nuq.*"

# 查看队列任务数量
docker exec postgres-postgres-1 psql -U postgres -d firecrawl -c "SELECT status, COUNT(*) FROM nuq.queue_scrape GROUP BY status;"
```

## API 测试
```bash
# 测试 scrape 端点
curl -X POST http://localhost:3002/v1/scrape \
  -H 'Content-Type: application/json' \
  -d '{"url": "https://example.com"}'

# 测试 crawl 端点
curl -X POST http://localhost:3002/v1/crawl \
  -H 'Content-Type: application/json' \
  -d '{"url": "https://firecrawl.dev"}'
```

## 配置说明
- 环境变量配置文件: `.env`
- 不使用数据库认证 (USE_DB_AUTHENTICATION=false)
- PostgreSQL 使用简化版初始化脚本 (无 pg_cron 扩展)
- 使用预构建的 Docker 镜像
- **数据库连接：** postgres://postgres:Xdjf@1234@host.docker.internal:5432/firecrawl

## 注意事项
1. 使用服务器现有的 PostgreSQL 服务，数据存储在 postgres-postgres-1 容器中
2. 数据库名为 `firecrawl`，所有表都在 `nuq` schema 下
3. 由于网络限制，使用了简化版数据库初始化脚本，移除了 pg_cron 自动清理任务
4. 如需定期清理数据库，建议手动设置 cron 任务
5. 备份时只需备份共享的 PostgreSQL 容器即可

## 版本升级
从 Firecrawl 1.0 (位于 `/home/qiu/firecrawl`) 升级到 Firecrawl 2.5

## 架构优化记录
- 2025-11-02: 从独立 PostgreSQL 迁移到共享 PostgreSQL（postgres-postgres-1）
  - 减少容器数量：4个 → 3个
  - 节省资源占用
  - 提升架构规范性
