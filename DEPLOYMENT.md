# Firecrawl 2.5 部署说明

## 当前配置

- **Firecrawl**: v2.5 (Port 3002)
- **PostgreSQL**: 17.0 (Port 5432, 容器: postgres-postgres-1)
- **数据库**: firecrawl
- **密码**: 在 `.env` 文件中配置

## 快速启动

```bash
# 启动服务
docker compose up -d

# 查看状态
docker ps | grep -E "firecrawl|postgres"

# 查看日志
docker logs firecrawl-api-1 -f

# 测试 API
curl -X POST http://localhost:3002/v1/scrape \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

## 日常管理

```bash
# 重启服务
docker compose restart

# 停止服务
docker compose down

# 连接数据库
docker exec -it postgres-postgres-1 psql -U postgres -d firecrawl

# 备份数据库
docker exec postgres-postgres-1 pg_dump -U postgres firecrawl > backup_$(date +%Y%m%d).sql
```

## 重新部署 PostgreSQL

如需重新部署数据库，使用 `scripts/deploy-postgres.sh` 脚本。

## 多实例部署

如需为其他项目部署独立的 PostgreSQL 实例，使用 `scripts/deploy-postgres-standalone.sh`，配置不同的端口和数据目录。

