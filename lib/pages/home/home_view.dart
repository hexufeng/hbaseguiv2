import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../services/hbase_service.dart';
import '../../routes/routes.dart';
import 'home_controller.dart';
import 'dart:io' show Platform;
import 'package:hbaseguiv2/controllers/hbase_controller.dart';
import 'package:hbaseguiv2/pages/home/widgets/connection_dialog.dart';
import 'package:hbaseguiv2/pages/home/widgets/table_list.dart';
import 'package:hbaseguiv2/pages/home/widgets/table_view.dart';

class HomeView extends GetView<HBaseController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HBase GUI'),
        actions: [
          Obx(() => Switch(
                value: controller.isMockMode.value,
                onChanged: (value) {
                  controller.toggleMockMode();
                },
              )),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshTables,
          ),
          Obx(() => TextButton(
            onPressed: () => _showConnectionDialog(context),
            child: Text(
              controller.isConnected.value ? '已连接' : '未连接',
              style: TextStyle(
                color: controller.isConnected.value ? Colors.green : Colors.red,
              ),
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (!controller.isConnected.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('未连接到 HBase'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showConnectionDialog(context),
                  child: const Text('连接'),
                ),
                const SizedBox(height: 32),
                if (!controller.isConnected.value) ...[
                  const Text('动态库未加载', style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showLibraryInfo(context),
                    child: const Text('查看动态库信息'),
                  ),
                ],
              ],
            ),
          );
        }
        
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: TableList(controller: controller),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 3,
              child: TableView(controller: controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMockModeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('当前处于模拟模式'),
          const SizedBox(height: 20),
          const Text('要使用真实HBase连接，请确保：'),
          const SizedBox(height: 10),
          const Text('1. 已安装Java 8或更高版本'),
          const SizedBox(height: 10),
          const Text('2. 已设置JAVA_HOME环境变量'),
          const SizedBox(height: 10),
          const Text('3. 动态库已正确安装'),
          const SizedBox(height: 20),
          const Text('动态库位置：'),
          if (Platform.isMacOS) ...[
            const Text('- ../Frameworks/libhbase_bridge.dylib'),
            const Text('- [应用目录]/macos/Runner/Frameworks/libhbase_bridge.dylib'),
            const Text('- /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/Frameworks/libhbase_bridge.dylib'),
          ] else if (Platform.isWindows) ...[
            const Text('- ../Frameworks/hbase_bridge.dll'),
            const Text('- [应用目录]/windows/Runner/Frameworks/hbase_bridge.dll'),
          ] else ...[
            const Text('- ../Frameworks/libhbase_bridge.so'),
            const Text('- [应用目录]/linux/Runner/Frameworks/libhbase_bridge.so'),
          ],
        ],
      ),
    );
  }

  void _showConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConnectionDialog(controller: controller),
    );
  }

  void _showLibraryInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('动态库信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前处于模拟模式，因为无法加载动态库。'),
            const SizedBox(height: 16),
            const Text('动态库应该位于以下位置之一：'),
            const SizedBox(height: 8),
            if (Platform.isMacOS) ...[
              const Text('• ../Frameworks/libhbase_bridge.dylib'),
              const Text('• [应用目录]/macos/Runner/Frameworks/libhbase_bridge.dylib'),
              const Text('• /Users/hexufeng/Learn/MacAPP/hbaseguiv2/macos/Runner/Frameworks/libhbase_bridge.dylib'),
            ] else if (Platform.isWindows) ...[
              const Text('• ../Frameworks/hbase_bridge.dll'),
              const Text('• [应用目录]/windows/Runner/Frameworks/hbase_bridge.dll'),
            ] else ...[
              const Text('• ../Frameworks/libhbase_bridge.so'),
              const Text('• [应用目录]/linux/Runner/Frameworks/libhbase_bridge.so'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 