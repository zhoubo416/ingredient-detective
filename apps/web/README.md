# Ingredient Detective Web

这个目录是 Nuxt 应用，包含两部分：

- 官网首页
- 登录后的分析后台与 `/api/*` 服务端接口

本地开发时，这个 Nuxt 服务必须占用 `3000`。Flutter 客户端会把它当成后端来调用。

## 启动

### 1. 配置环境变量

复制 `.env.example` 为 `.env`，然后填入以下变量：

- `NUXT_PUBLIC_SUPABASE_URL`
- `NUXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `LLM_PROVIDER`
- `LLM_MODEL`
- `DASHSCOPE_API_KEY`
- `DEEPSEEK_API_KEY`
- `ALIYUN_ACCESS_KEY_ID`
- `ALIYUN_ACCESS_KEY_SECRET`

### 2. 初始化数据库

在 Supabase SQL Editor 执行 [schema.sql](/Users/bozhou/code/github/ingredient-detective/apps/web/supabase/schema.sql)

### 3. 安装依赖

```bash
npm install
```

### 4. 启动开发环境

```bash
npm run dev -- --port 3000 --host 127.0.0.1
```

启动成功后应看到：

- `Local: http://127.0.0.1:3000/`

### 5. 配置 Supabase 回跳地址

在 Supabase `Authentication -> URL Configuration` 中加入：

- `http://127.0.0.1:3000/auth/confirm`
- `http://127.0.0.1:3000/auth/reset-password`

## 路由

- `/` 营销首页
- `/login` 登录/注册
- `/auth/confirm` 邮箱确认回跳
- `/auth/reset-password` 设置新密码
- `/dashboard` 受保护的分析台
- `/dashboard/history` 历史记录

## API

- `POST /api/analysis`
- `GET /api/history`
- `DELETE /api/history/:id`

这些接口会读取 Supabase 登录态，并在服务端执行 OCR、AI 分析和历史记录读写。

## 与 Flutter 的关系

Flutter 客户端不直接访问第三方 OCR / LLM 服务，而是调用这个 Nuxt 服务：

1. Flutter 登录 Supabase
2. Flutter 把 token 带到 `http://127.0.0.1:3000/api/*`
3. Nuxt 服务端完成 OCR、AI 分析和数据库写入

关键约束：

- Nuxt 固定使用 `3000`
- Flutter Web 不要占用 `3000`
- Flutter 的 `BACKEND_API_URL` 必须指向 `http://127.0.0.1:3000`
