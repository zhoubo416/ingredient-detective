# 应用图标生成指南

## 📱 图标规格要求

### App Store 图标
- **尺寸**: 1024×1024像素
- **格式**: PNG（推荐）或JPEG
- **背景**: 透明或纯色背景
- **风格**: 简洁、易识别

### iOS 应用图标
需要准备以下尺寸的图标：

| 设备 | 尺寸 | 用途 |
|------|------|------|
| iPhone/iPad | 1024×1024 | App Store |
| iPhone | 180×180 | iPhone 6 Plus @3x |
| iPhone | 120×120 | iPhone @2x |
| iPhone | 167×167 | iPad Pro @2x |
| iPad | 152×152 | iPad @2x |
| iPad | 76×76 | iPad @1x |

## 🎨 图标设计建议

### 设计元素
- **主色调**: 蓝色系（与当前应用主题一致）
- **图标元素**: 放大镜 + 食品图标
- **文字**: 避免使用文字，保持简洁
- **风格**: 扁平化设计，现代感

### 设计工具推荐
- **Figma**（免费在线设计工具）
- **Adobe Illustrator**（专业矢量设计）
- **Canva**（模板化设计）
- **Sketch**（Mac专用设计工具）

## 📁 iOS 图标文件配置

### 图标文件命名规范
```
AppIcon.appiconset/
├── icon-1024.png          (1024×1024)
├── icon-180.png           (180×180)
├── icon-167.png           (167×167)
├── icon-152.png           (152×152)
├── icon-120.png           (120×120)
└── icon-76.png            (76×76)
```

### Contents.json 配置文件
在 `ios/Runner/Assets.xcassets/AppIcon.appiconset/` 目录下创建 `Contents.json`：

```json
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon-40.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon-60.png",
      "scale" : "3x"
    },
    // ... 更多尺寸配置
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
```

## 🔧 Flutter 图标配置

### 更新 pubspec.yaml
在 `pubspec.yaml` 中添加图标配置：

```yaml
flutter:
  uses-material-design: true
  
  # 应用图标配置
  icons:
    android: true
    ios: true
    
  # 启动画面配置（可选）
  splash:
    image: assets/splash.png
    color: "#2196F3"
```

### 生成图标命令
使用 Flutter 命令生成图标：
```bash
# 确保有 icons/ 目录和图标文件
flutter pub run flutter_launcher_icons:main
```

## 🚀 快速生成图标的方法

### 方法1：使用在线工具
1. 访问 [App Icon Generator](https://appicon.co/)
2. 上传1024×1024的主图标
3. 下载生成的图标包
4. 解压并替换到项目中

### 方法2：使用 Flutter 插件
安装图标生成插件：
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

配置 `flutter_launcher_icons.yaml`：
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
  min_sdk_android: 21
```

## ✅ 图标检查清单

### 设计检查
- [ ] 图标在不同背景下清晰可见
- [ ] 没有模糊或锯齿边缘
- [ ] 颜色对比度足够
- [ ] 在小尺寸下仍然可识别

### 技术检查
- [ ] 所有尺寸的图标都已准备
- [ ] 文件格式正确（PNG推荐）
- [ ] 没有透明背景问题
- [ ] 文件命名规范

### 测试检查
- [ ] 在真实设备上测试图标显示
- [ ] 检查不同屏幕尺寸的适配
- [ ] 验证启动画面的显示效果

## 📝 常见问题

### Q: 图标显示模糊怎么办？
A: 确保使用矢量源文件生成各尺寸图标，不要简单缩放。

### Q: 图标在设备上显示不正确？
A: 检查 Contents.json 配置是否正确，尺寸是否匹配。

### Q: 如何更新现有图标？
A: 替换图标文件后，需要清理缓存并重新构建：
```bash
flutter clean
flutter pub get
flutter build ios
```

---

*本指南最后更新于2024年12月*