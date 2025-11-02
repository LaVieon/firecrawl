# Firecrawl 快速开始

## 最常用命令

```bash
# 启动/停止
./scripts/manage.sh start
./scripts/manage.sh stop
./scripts/manage.sh restart

# 查看状态和日志
./scripts/manage.sh status
./scripts/manage.sh logs

# 测试服务
./scripts/manage.sh test                          # 测试默认 URL（显示内容并保存）
./scripts/manage.sh test https://example.com      # 测试指定 URL

# 导出日志
./scripts/manage.sh export-logs
```

## 访问

- URL: <http://localhost:3002>
- 日志: /ssd_2/tools/firecrawl/logs
- 测试结果: /ssd*2/tools/firecrawl/logs/test*\*.md

## 详细文档

- 主文档: `README.md`
- 实现说明: `docs/implementation_notes/README.md`
