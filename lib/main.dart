import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:async';

import 'routes/app_pages.dart';
import 'routes/routes.dart';
import 'theme/app_theme.dart';
import 'services/hbase_service.dart';
import 'controllers/hbase_controller.dart';
import 'package:flutter/foundation.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 注册全局错误处理
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('【严重错误】Flutter框架错误: ${details.exception}');
      print('【严重错误】错误详情: ${details.toString()}');
    };
    
    // 平台特定初始化
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // 桌面平台初始化
      _initDesktop();
    }
    
    _initServices();
    _initControllers();
    
    // 运行应用
    runApp(const MyApp());
  }, (error, stackTrace) {
    // 处理未捕获的异常
    print('【致命错误】应用捕获到未处理的异常: $error');
    print('【致命错误】异常堆栈:\n$stackTrace');
    
    // 这里可以添加上报错误的逻辑
  });
}

void _initDesktop() async {
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

void _initServices() {
  // 初始化HBase服务
  Get.put(HBaseService());
}

void _initControllers() {
  // 初始化HBase控制器
  Get.put(HBaseController());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HBase GUI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      builder: EasyLoading.init(),
      debugShowCheckedModeBanner: false,
    );
  }
}
