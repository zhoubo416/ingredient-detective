# 配料侦探 - 食品成分分析助手

一款基于Flutter开发的智能食品成分分析应用，通过拍照识别食品配料表，提供健康分析和建议。

## 功能特性

- 📸 拍照识别食品配料表
- 🔍 AI智能分析成分安全性
- 📊 健康评分和建议
- 📱 历史记录管理
- 🔒 隐私保护设计

## 应用图标生成指南

### 准备图标文件

1. **准备源图标文件**：
   - 创建一个1024×1024像素的PNG格式图标
   - 保存为 `assets/icon.png`
   - 确保图标设计简洁、清晰、易于识别

2. **图标设计要求**：
   - 正方形设计（1024×1024像素）
   - PNG格式（支持透明背景）
   - 文件大小不超过2MB
   - 设计风格简洁现代

### 生成多平台图标

1. **安装依赖**：
   ```bash
   flutter pub get
   ```

2. **生成图标**：
   ```bash
   flutter pub run flutter_launcher_icons
   ```

3. **验证生成结果**：
   - iOS图标位置：`ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Android图标位置：`android/app/src/main/res/mipmap-*/ic_launcher.png`

### 支持的平台

- **iOS**：生成20+种尺寸图标（20×20到1024×1024）
- **Android**：生成5种分辨率图标（hdpi到xxxhdpi）
- **其他平台**：可根据需要配置macOS、Windows、Linux等

### 配置文件说明

项目包含 `flutter_launcher_icons.yaml` 配置文件，用于自定义图标生成设置：

```yaml
flutter_icons:
  image_path: "assets/icon.png"
  android: true
  ios: true
```

## 开发环境

- Flutter 3.x+
- Dart 3.x+
- iOS 14.0+
- Android 8.0+

## 快速开始

1. 克隆项目
2. 安装依赖：`flutter pub get`
3. 运行应用：`flutter run`

## 项目结构

```
lib/
├── pages/          # 页面组件
├── services/       # 服务层
├── models/         # 数据模型
├── widgets/        # 通用组件
└── utils/          # 工具类
```

## 开发进度

✅ 基础功能开发完成  
✅ 应用图标设计完成  
🔧 持续优化中...