import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/home_page.dart';
import 'theme.dart';

/// 根组件：配置主题和首页。
/// 单页 + 内部导航，V1 不需要路由框架，保持简单。
class BabyNutritionApp extends StatelessWidget {
  const BabyNutritionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '宝宝营养助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // 日期选择器等组件依赖本地化代理，缺失会导致弹窗渲染为空白
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const HomePage(),
    );
  }
}
