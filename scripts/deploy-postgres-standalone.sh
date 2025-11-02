#!/bin/bash
# PostgreSQL 独立实例部署脚本
# 用途：为其他项目（如金融数据库）部署独立的 PostgreSQL 实例

set -e

# 配置（可根据项目修改）
CONTAINER_NAME="${CONTAINER_NAME:-postgres-finance}"
POSTGRES_VERSION="${POSTGRES_VERSION:-postgres:17-alpine}"
DATA_DIR="${DATA_DIR:-/ssd_2/postgres-finance}"
DB_NAME="${DB_NAME:-finance_db}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-请设置密码}"
EXTERNAL_PORT="${EXTERNAL_PORT:-5433}"

echo "════════════════════════════════════════════════════════"
echo "  PostgreSQL 独立实例部署"
echo "════════════════════════════════════════════════════════"
echo "容器名称: $CONTAINER_NAME"
echo "镜像: $POSTGRES_VERSION"
echo "数据目录: $DATA_DIR"
echo "数据库: $DB_NAME"
echo "端口: $EXTERNAL_PORT"
echo "════════════════════════════════════════════════════════"
echo ""
echo "使用方法："
echo "  export CONTAINER_NAME=my-postgres"
echo "  export DATA_DIR=/path/to/data"
echo "  export DB_NAME=mydb"
echo "  export DB_PASSWORD=mypassword"
echo "  export EXTERNAL_PORT=5433"
echo "  sudo ./deploy-postgres-standalone.sh"
echo ""
read -p "确认继续？[y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 停止旧容器
echo "📦 停止旧容器..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 创建数据目录
echo "📁 准备数据目录..."
mkdir -p $DATA_DIR
chmod 700 $DATA_DIR

# 启动容器
echo "🚀 启动 PostgreSQL..."
docker run -d \
  --name $CONTAINER_NAME \
  -e POSTGRES_PASSWORD=$DB_PASSWORD \
  -v $DATA_DIR:/var/lib/postgresql/data \
  -p $EXTERNAL_PORT:5432 \
  --restart unless-stopped \
  $POSTGRES_VERSION

# 等待启动
echo "⏳ 等待数据库启动..."
sleep 5

# 创建数据库
if [ "$DB_NAME" != "postgres" ]; then
    echo "📊 创建数据库..."
    docker exec $CONTAINER_NAME psql -U postgres -c "CREATE DATABASE $DB_NAME;"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 部署完成！"
echo "════════════════════════════════════════════════════════"
echo "容器: $CONTAINER_NAME"
echo "数据库: $DB_NAME"
echo "端口: $EXTERNAL_PORT"
echo "数据目录: $DATA_DIR"
echo ""
echo "连接命令: docker exec -it $CONTAINER_NAME psql -U postgres -d $DB_NAME"
echo "外部连接: psql -h localhost -p $EXTERNAL_PORT -U postgres -d $DB_NAME"
echo "════════════════════════════════════════════════════════"

