# 待办事项

## 域名申请完成后

- [ ] 更新 Supabase OAuth 回调地址 — 在 Supabase 后台添加新域名的 `/auth/confirm` 和 `/auth/reset-password` 回调地址
- [ ] 更新 nuxt.config.ts — 将 `marketingSiteUrl` 改为新域名
- [ ] 更新 Supabase Google OAuth 配置 — 在 Google Cloud Console 更新 Authorized JavaScript origins 和 redirect URIs
- [ ] 更新 Supabase Apple OAuth 配置 — 在 Apple Developer 后台配置 Sign in with Apple，并在 Supabase 填入 Service ID 和 Private Key
- [ ] 更新 .env 环境变量 — 更新 `NUXT_PUBLIC_MARKETING_SITE_URL`
- [ ] 配置 HTTPS 证书 — 使用 Let's Encrypt 或云服务商证书
- [ ] 更新 Google OAuth 控制台 — 确保 Google 侧的域名配置正确
- [ ] 更新 Apple Developer 后台 — 添加新域名到 Sign in with Apple 的 Return URLs

## 网站分析

- [ ] 申请 Google Analytics 4 (GA4) — 在 analytics.google.com 创建媒体资源，获取 Measurement ID (G-XXXXXXXXXX)
- [ ] 申请百度统计 — 在 tongji.baidu.com 注册并添加网站，获取 HM.js 跟踪代码
- [ ] 集成 Google Analytics 到 Web 端 — 在 Nuxt 项目中配置 @nuxtjs/google-analytics 或手动添加 gtag.js
- [ ] 集成百度统计到 Web 端 — 在 Nuxt 项目中添加百度统计脚本
- [ ] 配置环境变量 — 将 GA4 Measurement ID 和百度统计 HM ID 添加到 .env 文件

## 已完成的优化

- [x] 修复登录后页面不跳转的问题（SSR/CSR 状态同步问题）
- [x] 禁用 Nuxt UI 构建时请求 Google Fonts 元数据
- [x] 新增 Google 账号登录
- [x] 新增 Apple 账号登录
- [x] 优化登录页面 UI，保留 Google、Apple、邮箱密码登录和注册
