#!/bin/bash
# PostgreSQL 17 部署脚本 for Firecrawl
# 用途：部署或重建 Firecrawl 使用的 PostgreSQL 17 数据库

set -e

# 配置
CONTAINER_NAME="postgres-postgres-1"
POSTGRES_VERSION="postgres:17-alpine"
DATA_DIR="/data/postgres"
DB_NAME="firecrawl"
DB_USER="postgres"

# 检查密码是否设置
if [ -z "$DB_PASSWORD" ]; then
    echo "错误：请设置 DB_PASSWORD 环境变量"
    echo "使用方法：DB_PASSWORD=your_password ./deploy-postgres.sh"
    exit 1
fi

echo "════════════════════════════════════════════════════════"
echo "  PostgreSQL 17 部署脚本 (Firecrawl)"
echo "════════════════════════════════════════════════════════"
echo "容器名称: $CONTAINER_NAME"
echo "镜像: $POSTGRES_VERSION"
echo "数据目录: $DATA_DIR"
echo "数据库: $DB_NAME"
echo "════════════════════════════════════════════════════════"
echo ""
read -p "确认继续？[y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 1. 停止并删除旧容器
echo "📦 停止旧容器..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 2. 清空数据目录
echo "🗑️  清空数据目录..."
rm -rf $DATA_DIR/*

# 3. 启动新容器
echo "🚀 启动 PostgreSQL 17..."
docker run -d \
  --name $CONTAINER_NAME \
  --network firecrawl_backend \
  -e POSTGRES_PASSWORD=$DB_PASSWORD \
  -v $DATA_DIR:/var/lib/postgresql/data \
  -p 5432:5432 \
  --restart unless-stopped \
  $POSTGRES_VERSION

# 4. 等待启动
echo "⏳ 等待数据库启动..."
sleep 5

# 5. 创建数据库
echo "📊 创建数据库..."
docker exec $CONTAINER_NAME psql -U postgres -c "CREATE DATABASE $DB_NAME;"
docker exec $CONTAINER_NAME psql -U postgres -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# 6. 初始化 Firecrawl schema（从 nuq-simple.sql）
if [ -f "/ssd_2/tools/firecrawl/nuq-simple.sql" ]; then
    echo "📋 初始化数据库表结构..."
    docker exec -i $CONTAINER_NAME psql -U postgres -d $DB_NAME < /ssd_2/tools/firecrawl/nuq-simple.sql
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 部署完成！"
echo "════════════════════════════════════════════════════════"
echo "容器: $CONTAINER_NAME"
echo "数据库: $DB_NAME"
echo "端口: 5432"
echo ""
echo "连接测试: docker exec -it $CONTAINER_NAME psql -U postgres -d $DB_NAME"
echo "════════════════════════════════════════════════════════"
