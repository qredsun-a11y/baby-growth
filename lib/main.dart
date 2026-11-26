import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'services/notification_service.dart';

/// App 入口。
/// 启动前做三件事：绑定 Flutter 引擎、初始化时区、初始化本地通知。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 本地通知需要用"时区"来算几点提醒，先加载时区数据库
  tz.initializeTimeZones();
  // 中国用户固定用上海时区（UTC+8），避免读取系统时区名出错
  tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

  // 初始化通知插件并请求权限（首次使用会弹系统授权）
  await NotificationService.instance.init();

  runApp(const BabyNutritionApp());
}

/// 通知点击回调的顶层入口（iOS 后台点击通知时会走这里）。
/// 这里只做占位，实际跳转逻辑在 NotificationService 里配置。
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // 点击通知后可以导航到首页，这里先留空避免编译报错
}
