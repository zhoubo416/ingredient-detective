import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/splash_page.dart';
import 'services/subscription_manager.dart';
import 'services/usage_manager.dart';

void main() async {
  // 确保Widgets绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 加载环境变量文件
  await dotenv.load(fileName: "assets/.env");
  
  // 初始化订阅管理器（在后台进行）
  SubscriptionManager();
  
  // 初始化使用次数管理器（构造函数中已包含初始化逻辑）
  UsageManager();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '配料侦探',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
