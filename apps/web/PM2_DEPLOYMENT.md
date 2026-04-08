# Ingredient Detective Web - PM2 部署指南

## 文件说明

- `ecosystem.config.js` - PM2 启动配置文件
- `ingredient-detective-web-*.tar.gz` - 打包好的应用程序

## 部署步骤

### 1. 解压应用
```bash
tar -xzf ingredient-detective-web-*.tar.gz
cd <解压目录>
```

### 2. 配置环境变量
创建 `.env` 文件：
```bash
cat > .env << 'EOF'
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
NUXT_PUBLIC_SUPABASE_URL=your_supabase_url
NUXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_key
NUXT_PUBLIC_GOOGLE_ANALYTICS_ID=your_ga_id
LLM_PROVIDER=your_llm_provider
LLM_MODEL=your_model
DASHSCOPE_API_KEY=your_api_key
EOF
```

### 3. 安装/更新 PM2
```bash
npm install -g pm2
```

### 4. 启动应用
```bash
# 使用 PM2 启动
pm2 start ecosystem.config.js

# 查看状态
pm2 status

# 查看日志
pm2 logs ingredient-detective-web

# 停止应用
pm2 stop ingredient-detective-web

# 重启应用
pm2 restart ingredient-detective-web

# 删除应用
pm2 delete ingredient-detective-web
```

### 5. 开机自启
```bash
pm2 startup
pm2 save
```

## PM2 配置说明

文件 `ecosystem.config.js` 包含以下配置：

| 参数 | 说明 |
|------|------|
| `name` | 应用名称 |
| `exec_mode: cluster` | 集群模式 |
| `instances: max` | 自动使用全部 CPU 核心 |
| `script` | 启动脚本 |
| `PORT` | 监听端口（默认 3000）|
| `HOST` | 监听地址（默认 0.0.0.0）|
| `max_memory_restart` | 内存超过 1GB 时自动重启 |
| `restart_delay` | 重启间隔 4 秒 |
| `max_restarts` | 最多重启 10 次 |
| `min_uptime` | 最小运行时间 10 秒 |

## 日志文件

日志文件位置：
- `logs/error.log` - 错误日志
- `logs/out.log` - 输出日志
- `logs/combined.log` - 合并日志

## 监控和维护

```bash
# 监控进程
pm2 monit

# 查看详细信息
pm2 show ingredient-detective-web

# 保存 PM2 进程列表
pm2 save

# 恢复 PM2 进程列表
pm2 resurrect
```

## 故障排查

### 应用启动失败
```bash
# 查看详细错误日志
pm2 logs ingredient-detective-web --err

# 检查端口是否被占用
lsof -i :3000
```

### 内存泄漏
PM2 已配置自动重启（1GB 内存限制），但如果频繁重启，检查：
1. 日志文件中的错误信息
2. 应用代码中的内存泄漏

### 性能优化
- 增加 `max_memory_restart` 的值
- 调整 `instances` 数量
- 启用 `watch: true` 用于开发环境

## 更新应用

1. 生成新的打包文件
2. 停止当前应用：`pm2 stop ingredient-detective-web`
3. 解压新包覆盖文件
4. 重启应用：`pm2 restart ingredient-detective-web`

或者使用 PM2 的零停机重启：
```bash
pm2 reload ingredient-detective-web
```
