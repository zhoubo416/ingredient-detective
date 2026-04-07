# SEO & Analytics 配置指南

本文档说明如何配置网站的 SEO 优化和分析工具（Google Analytics、百度统计）。

## SEO 优化

### Meta 标签配置

以下元标签已在 `nuxt.config.ts` 中配置：

- **基础 Meta**：字符集、视口、描述、关键词、作者、主题颜色
- **Open Graph**：用于社交媒体分享时的显示内容
- **Twitter Card**：针对 Twitter 分享的卡片格式
- **规范链接**：指定首选 URL，帮助搜索引擎抓取

### 当前配置

```typescript
// nuxt.config.ts 中的 app.head 配置包含：
- 标题和描述
- 关键词：食品成分分析、配料表、营养成分、食品安全、AI识别等
- Open Graph meta 标签
- Canonical 链接
```

## Google Analytics 配置

### 步骤 1: 获取 Measurement ID

1. 访问 [Google Analytics](https://analytics.google.com/)
2. 创建新的 Google Analytics 4 属性
3. 复制 **Measurement ID**（格式：G-XXXXXXXXXX）

### 步骤 2: 配置环境变量

在 `.env.local` 或部署环境中添加：

```env
NUXT_PUBLIC_GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
```

### 步骤 3: 验证

1. 启动本地开发服务器：`npm run dev`
2. 打开浏览器开发者工具
3. 访问应用页面
4. 在 Google Analytics 实时报表中应该能看到流量

## 百度统计配置

### 步骤 1: 获取跟踪 ID

1. 访问 [百度统计](https://tongji.baidu.com/)
2. 登录账户并创建新网站
3. 复制 **跟踪代码** ID（hm.js 后面的数字）

### 步骤 2: 配置环境变量

在 `.env.local` 或部署环境中添加：

```env
NUXT_PUBLIC_BAIDU_TRACKING_ID=XXXXXXXXXX
```

### 步骤 3: 验证

1. 启动开发服务器
2. 打开浏览器
3. 在百度统计后台的"实时"页面应该能看到访问数据

## 部署到生产环境

### Vercel 部署

在 Vercel 项目设置中添加环境变量：

```
NUXT_PUBLIC_GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
NUXT_PUBLIC_BAIDU_TRACKING_ID=XXXXXXXXXX
```

### 其他部署平台

根据平台的环境变量配置方式添加上述两个变量。

## 验证清单

- [ ] Google Analytics ID 已获取并配置
- [ ] 百度统计 ID 已获取并配置
- [ ] 环境变量已在生产环境配置
- [ ] 在 Google Analytics 中查看实时报表
- [ ] 在百度统计中查看实时流量
- [ ] 页面 Meta 标签正确显示（F12 检查 `<head>` 标签）

## Meta 标签优化建议

根据实际需求修改以下内容：

1. **og:image**：Set 为实际的 OG 图像 URL
2. **description**：确保简洁且包含关键词
3. **keywords**：添加更多相关关键词
4. **canonical**：更改为实际域名
5. **baidu-site-verification**：从百度验证页面获取代码

## 搜索引擎收录

### Google Search Console

1. 访问 [Google Search Console](https://search.google.com/search-console)
2. 添加属性并验证所有权
3. 提交 sitemap（如已生成）

### 百度搜索资源平台

1. 访问 [百度搜索资源平台](https://ziyuan.baidu.com/)
2. 添加网站并验证所有权
3. 提交网站地图和 robots.txt

## 常见问题

**Q: 统计脚本没有加载？**
A: 检查环境变量是否正确配置，使用 `console.log(config.public)` 调试。

**Q: Google Analytics 没有数据？**
A: 
- 确保 ID 正确
- 检查广告拦截器是否阻止了脚本
- 等待 24 小时，GA 需要时间处理数据

**Q: 百度统计没有数据？**
A:
- 网站需要已备案（中国大陆）
- 检查百度爬虫是否能访问网站
- 使用百度统计的"调试"功能验证

## 相关资源

- [Google Analytics 文档](https://support.google.com/analytics)
- [百度统计帮助](https://tongji.baidu.com/help/index)
- [Nuxt Head 配置](https://nuxt.com/docs/api/composables/use-head)
