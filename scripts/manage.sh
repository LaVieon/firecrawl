#!/bin/bash
# Firecrawl 服务管理脚本

set -e

FIRECRAWL_DIR="/ssd_2/tools/firecrawl"
LOG_DIR="$FIRECRAWL_DIR/logs"
TARGET_PORT=3002

cd "$FIRECRAWL_DIR"

case "$1" in
    start)
        echo "🚀 启动 Firecrawl 服务..."
        
        # 检查并清理端口
        if netstat -tuln 2>/dev/null | grep -q ":$TARGET_PORT " || ss -tuln 2>/dev/null | grep -q ":$TARGET_PORT "; then
            echo "端口 $TARGET_PORT 被占用，停止旧服务..."
            docker compose down --remove-orphans 2>/dev/null || true
        fi
        
        # 清理已停止的容器
        docker ps -a --filter "name=firecrawl" --filter "status=exited" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
        
        # 启动服务
        docker compose up -d
        sleep 3
        
        echo "✅ 服务已启动"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "firecrawl|NAMES"
        ;;
        
    stop)
        echo "🛑 停止服务..."
        docker compose down --remove-orphans
        echo "✅ 服务已停止"
        ;;
        
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
        
    status)
        echo "📊 服务状态："
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "firecrawl|NAMES"
        echo ""
        if curl -s http://localhost:$TARGET_PORT > /dev/null 2>&1; then
            echo "✅ 服务运行正常 (http://localhost:$TARGET_PORT)"
        else
            echo "❌ 服务未响应"
        fi
        ;;
        
    logs)
        echo "📋 查看实时日志 (Ctrl+C 退出)..."
        docker logs -f "${2:-firecrawl-api-1}"
        ;;
        
    export-logs)
        echo "📋 导出日志到 $LOG_DIR..."
        mkdir -p "$LOG_DIR"
        DATE=$(date +"%Y%m%d_%H%M%S")
        
        for container in firecrawl-api-1 firecrawl-playwright-service-1 firecrawl-redis-1; do
            if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
                docker logs "$container" > "$LOG_DIR/${container}_${DATE}.log" 2>&1
                echo "  ✅ $container"
            fi
        done
        
        echo "✅ 日志已导出到: $LOG_DIR"
        ls -lh "$LOG_DIR"/*.log 2>/dev/null | tail -5
        ;;
        
    clean-logs)
        DAYS=${2:-7}
        echo "🗑️  清理 $DAYS 天前的日志..."
        find "$LOG_DIR" -name "*.log" -type f -mtime +$DAYS -delete 2>/dev/null || true
        echo "✅ 完成"
        ;;
        
    test)
        echo "🧪 测试 Firecrawl 服务..."
        TEST_URL="${2:-https://mp.weixin.qq.com/s/ejwuAXWc9o2DnCF9nKCNag}"
        
        echo "测试 URL: $TEST_URL"
        echo "正在抓取..."
        echo ""
        
        RESPONSE=$(curl -s -X POST http://localhost:$TARGET_PORT/v2/scrape \
            -H "Content-Type: application/json" \
            -d "{\"url\": \"$TEST_URL\", \"formats\": [\"markdown\"]}")
        
        if echo "$RESPONSE" | grep -q '"success".*true'; then
            echo "✅ 测试成功"
            echo ""
            
            # 提取并显示内容
            mkdir -p "$LOG_DIR"
            OUTPUT_FILE="$LOG_DIR/test_$(date +%Y%m%d_%H%M%S).md"
            
            # 使用 Python 解析 JSON
            RESULT=$(echo "$RESPONSE" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    title = data.get("data", {}).get("metadata", {}).get("title", "无标题")
    markdown = data.get("data", {}).get("markdown", "")
    print(f"TITLE:{title}")
    print(f"CONTENT_LEN:{len(markdown)}")
    with open("'"$OUTPUT_FILE"'", "w", encoding="utf-8") as f:
        f.write(markdown)
    print(markdown[:2000])  # 前2000字符
except Exception as e:
    print(f"ERROR:{e}")
' 2>&1)
            
            if echo "$RESULT" | grep -q "^TITLE:"; then
                TITLE=$(echo "$RESULT" | grep "^TITLE:" | cut -d: -f2-)
                CONTENT_LEN=$(echo "$RESULT" | grep "^CONTENT_LEN:" | cut -d: -f2)
                PREVIEW=$(echo "$RESULT" | grep -v "^TITLE:" | grep -v "^CONTENT_LEN:")
                
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "标题: $TITLE"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "内容预览:"
                echo "$PREVIEW"
                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "内容长度: $CONTENT_LEN 字符"
                echo "响应长度: $(echo "$RESPONSE" | wc -c) 字节"
                echo "完整内容已保存到: $OUTPUT_FILE"
            else
                echo "解析失败，保存原始响应"
                echo "$RESPONSE" > "$OUTPUT_FILE.json"
                echo "原始响应已保存到: $OUTPUT_FILE.json"
            fi
        else
            echo "❌ 测试失败"
            echo ""
            echo "$RESPONSE" | head -c 500
        fi
        ;;
        
    *)
        echo "🔥 Firecrawl 服务管理"
        echo ""
        echo "用法: $0 {start|stop|restart|status|logs|export-logs|clean-logs|test}"
        echo ""
        echo "命令:"
        echo "  start        - 启动服务（自动清理端口冲突）"
        echo "  stop         - 停止服务"
        echo "  restart      - 重启服务"
        echo "  status       - 查看服务状态"
        echo "  logs [容器]  - 查看实时日志（默认: api）"
        echo "  export-logs  - 导出所有日志到文件"
        echo "  clean-logs [天数] - 清理旧日志（默认: 7天）"
        echo "  test [url]   - 测试服务（默认测试微信文章）"
        echo ""
        echo "示例:"
        echo "  $0 start"
        echo "  $0 test"
        echo "  $0 test https://example.com"
        echo "  $0 logs firecrawl-api-1"
        echo ""
        exit 1
        ;;
esac

