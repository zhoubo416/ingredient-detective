# 配料侦探

配料侦探包含两套应用：

- Flutter 客户端：根目录，负责移动端 / Web 客户端界面
- Nuxt 后端与管理后台：[apps/web](apps/web)，负责登录、OCR、AI 分析、历史记录接口和 Web 后台

## 权限

- `Pro` 会员可使用拍照分析、相册上传分析、手动输入配料分析
- 非 `Pro` 用户可使用登录、个人资料、历史记录等非分析功能
- 订阅状态由 Nuxt 后端管理（`/api/subscription/status`、`/api/subscription/sync`）
- 最终放行以服务端校验为准

## 端口分工

- `3000` 固定给 Nuxt 后端
- Flutter Web 不要绑定 `3000`
- Flutter 通过 `assets/.env` 里的 `BACKEND_API_URL` 调 Nuxt 的 `/api/*`

## 开发环境

- Flutter 3.41+ / Dart 3.11+
- Node.js 20+ / npm 10+
- Xcode（macOS 桌面版需要）
- Supabase 项目
- 可选：DashScope / DeepSeek / 阿里云 OCR

## 启动步骤

### 1. 启动 Nuxt 后端

```bash
cd apps/web
npm install
npm run dev -- --port 3000 --host 0.0.0.0
```

启动后 `http://127.0.0.1:3000` 可本地访问，局域网设备通过 `http://<电脑IP>:3000` 访问。

### 2. 启动 Flutter

```bash
flutter pub get
flutter run                # 自动检测设备
flutter run -d macos       # macOS 桌面端
flutter run -d chrome      # Web
```

### 3. iOS 真机调试

iPhone 不能访问 `127.0.0.1`，需修改 `assets/.env`：

```bash
ipconfig getifaddr en0     # 获取电脑局域网 IP，如 192.168.1.248
```

```env
BACKEND_API_URL=http://192.168.1.248:3000
```

Nuxt 已用 `--host 0.0.0.0` 启动，无需额外配置。

首次运行 iOS 项目若提示 CocoaPods 未安装：

```bash
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
gem install cocoapods
cd ios && pod deintegrate && pod install && cd ..
```

## 环境变量

**Flutter** — 读取 `assets/.env`：

```env
BACKEND_API_URL=http://127.0.0.1:3000
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
REVENUECAT_API_KEY=
```

**Nuxt** — 在 `apps/web/.env` 配置：

- `NUXT_PUBLIC_SUPABASE_URL`、`NUXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `LLM_PROVIDER`、`LLM_MODEL`
- `DASHSCOPE_API_KEY`、`DEEPSEEK_API_KEY`
- `ALIYUN_ACCESS_KEY_ID`、`ALIYUN_ACCESS_KEY_SECRET`

## Supabase 初始化

1. SQL Editor 执行 [schema.sql](apps/web/supabase/schema.sql)
2. Authentication → URL Configuration 添加：
   - `http://127.0.0.1:3000/auth/confirm`
   - `http://127.0.0.1:3000/auth/reset-password`

## 常见问题

**iPhone 连不上后端** → Nuxt 启动是否用了 `--host 0.0.0.0`？`assets/.env` 是否指向电脑局域网 IP？

**Flutter Web 分析接口失败** → 确认 Nuxt 在 `3000` 运行，Flutter Web 没有绑定 `3000`。

**macOS 桌面版启动失败，找不到 `xcodebuild`** → 需要完整 Xcode 环境。

## 项目结构

```text
.
├── apps/web/          # Nuxt 后端与 Web 管理后台
├── assets/            # Flutter 静态资源和本地环境变量
├── lib/               # Flutter 应用代码
├── android/
├── ios/
├── macos/
├── windows/
└── linux/
```
