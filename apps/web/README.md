# Ingredient Detective Web

Nuxt 站点包含两部分：

- 官网首页，用于展示产品能力和引导注册
- 登录后使用的分析后台，负责上传图片、服务端 OCR、AI 分析和历史记录展示

## 启动

1. 复制 `.env.example` 为 `.env`
2. 在 Supabase SQL Editor 执行 [schema.sql](./supabase/schema.sql)
3. 安装依赖：`npm install`
4. 启动开发环境：`npm run dev`
5. 在 Supabase `Authentication -> URL Configuration` 里加入：
   - `http://localhost:3000/auth/confirm`
   - `http://localhost:3000/auth/reset-password`

## 环境变量

- `NUXT_PUBLIC_SUPABASE_URL`
- `NUXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `LLM_PROVIDER` 可选，建议 `qwen` 或 `deepseek`
- `LLM_MODEL` 可选，例如 `qwen-plus`、`deepseek-chat`
- `DASHSCOPE_API_KEY`
- `DEEPSEEK_API_KEY`
- `ALIYUN_ACCESS_KEY_ID`
- `ALIYUN_ACCESS_KEY_SECRET`

## 路由

- `/` 营销首页
- `/login` 登录/注册
- `/auth/confirm` 邮箱确认回跳
- `/auth/reset-password` 设置新密码
- `/dashboard` 受保护的分析台
- `/dashboard/history` 历史记录

## 与 Flutter 的关系

当前 Flutter app 仍保留原有本地逻辑。后续可以把移动端改成：

1. 使用 Supabase Auth 登录
2. 上传图片或配料文本到 Nuxt 后端 `/api/analysis`
3. 从 `/api/history` 读取同一账号的历史记录
