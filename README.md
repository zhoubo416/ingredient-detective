# 配料侦探

配料侦探目前包含两套应用：

- Flutter 客户端：位于根目录，负责移动端 / Web 客户端界面
- Nuxt 后端与管理后台：位于 [apps/web](/Users/bozhou/code/github/ingredient-detective/apps/web)，负责登录、OCR、AI 分析、历史记录接口和 Web 后台

当前权限规则：

- `Pro` 会员才可使用配料分析功能
- 配料分析包含：拍照分析、相册上传分析、手动输入配料分析
- 非 `Pro` 用户仍可正常使用登录、个人资料、健康信息、历史记录等非分析功能
- 最终放行以 Nuxt 服务端为准，前端锁定只是用户提示，后端也会强制校验

最容易出错的点是端口分工：

- `3000` 固定给 Nuxt 后端
- Flutter Web 不要占用 `3000`
- Flutter 通过 `assets/.env` 里的 `BACKEND_API_URL` 调 Nuxt 的 `/api/*`

## 开发环境

- Flutter 3.41+
- Dart 3.11+
- Node.js 20+
- npm 10+
- Supabase 项目
- 可选：DashScope / DeepSeek / 阿里云 OCR

如果要运行 macOS 桌面版，还需要完整 Xcode 和 `xcodebuild`。

## 启动步骤

### 1. 启动 Nuxt 后端，固定使用 3000

```bash
cd apps/web
npm install
npm run dev -- --port 3000 --host 127.0.0.1
```

启动后确认：

- Web 后台地址：`http://127.0.0.1:3000`
- Flutter 调用的 API 也在这个地址下，例如 `http://127.0.0.1:3000/api/analysis`

### 2. 启动 Flutter

先在项目根目录安装依赖：

```bash
flutter pub get
```

移动端或桌面端：

```bash
flutter run
```

Flutter Web：

```bash
flutter run -d chrome
```

不要用 `flutter run -d chrome --web-port 3000`，否则会和 Nuxt 后端抢占 `3000`，导致 `/api/analysis`、`/api/history` 请求打到错误的服务。

### 3. iOS 真机调试

在 iPhone 上调试时，`BACKEND_API_URL` 不能使用 `127.0.0.1`（那是手机自己），需要改成电脑的局域网 IP：

```bash
# 获取电脑局域网 IP
ipconfig getifaddr en0
# 输出类似：192.168.1.248
```

然后更新 `assets/.env`：

```env
BACKEND_API_URL=http://192.168.1.248:3000
```

同时 Nuxt 后端需要监听局域网：

```bash
cd apps/web
npm run dev -- --port 3000 --host 0.0.0.0
```

首次运行 iOS 项目时，如果 CocoaPods 未安装：

```bash
# 使用 Homebrew Ruby 安装 CocoaPods
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
gem install cocoapods

# 重新配置 iOS 依赖
cd ios
pod deintegrate
pod install
cd ..
```

## 环境变量

### Flutter

Flutter 在启动时读取 [assets/.env](/Users/bozhou/code/github/ingredient-detective/assets/.env)：

```env
BACKEND_API_URL=http://127.0.0.1:3000
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
REVENUECAT_API_KEY=...
```

关键要求：

- `BACKEND_API_URL` 必须指向 Nuxt 服务
- 本地模拟器开发建议固定为 `http://127.0.0.1:3000`
- iOS 真机调试需要改成电脑的局域网 IP，例如 `http://192.168.1.248:3000`
- `REVENUECAT_API_KEY` 为可选配置，未配置时 RevenueCat 不会初始化，但订阅状态仍可从后端 API 获取

### Nuxt

Nuxt 需要在 `apps/web/.env` 中配置：

- `NUXT_PUBLIC_SUPABASE_URL`
- `NUXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `LLM_PROVIDER`
- `LLM_MODEL`
- `DASHSCOPE_API_KEY`
- `DEEPSEEK_API_KEY`
- `ALIYUN_ACCESS_KEY_ID`
- `ALIYUN_ACCESS_KEY_SECRET`

## Supabase 初始化

1. 在 Supabase SQL Editor 执行 [schema.sql](/Users/bozhou/code/github/ingredient-detective/apps/web/supabase/schema.sql)
2. 在 `Authentication -> URL Configuration` 增加：
   - `http://127.0.0.1:3000/auth/confirm`
   - `http://127.0.0.1:3000/auth/reset-password`

### 会员状态同步

订阅状态统一由后端管理，存储在 Supabase Auth 的 `app_metadata` 中：

- Flutter 和 Web 端都通过 `/api/subscription/status` 从后端获取订阅状态
- Flutter 购买或恢复订阅后，通过 `/api/subscription/sync` 将 RevenueCat 状态同步到后端
- Nuxt Web 后台读取这个状态来决定是否解锁分析功能
- 同一 Supabase 账号在 Flutter 升级后，Web 端重新进入后台即可继承 `Pro` 权限

## 常见问题

### `ERR_CONNECTION_REFUSED 127.0.0.1:3001`

说明 Flutter 还在请求旧端口。检查 [assets/.env](/Users/bozhou/code/github/ingredient-detective/assets/.env) 的 `BACKEND_API_URL` 是否为 `http://127.0.0.1:3000`，然后重启 Flutter。

### Flutter Web 能打开，但分析接口失败

通常是因为 Flutter Web 占用了 `3000`，Nuxt 后端没有运行，或者没跑在 `3000`。先确认：

1. Nuxt 已在 `127.0.0.1:3000` 启动
2. Flutter Web 没有固定绑定 `3000`
3. `BACKEND_API_URL` 指向 `http://127.0.0.1:3000`

如果错误提示是“当前账号未开通 Pro”，那不是端口问题，而是账号本身还没有同步出有效的 `Pro` 会员状态。

### macOS 桌面版启动失败，提示找不到 `xcodebuild`

这是本机缺少完整 Xcode 环境，不是项目代码问题。

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
