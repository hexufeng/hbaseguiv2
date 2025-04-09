import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../services/hbase_service.dart';
import '../../routes/routes.dart';
import 'dart:isolate';
import 'dart:math';

class ConnectionController extends GetxController {
  final zkQuorumController = TextEditingController();
  final zkNodeController = TextEditingController();
  
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  
  late final HBaseService _hbaseService;

  @override
  void onInit() {
    super.onInit();
    _hbaseService = Get.find<HBaseService>();
    _loadSavedConnection();
  }

  @override
  void onClose() {
    zkQuorumController.dispose();
    zkNodeController.dispose();
    super.onClose();
  }

  Future<void> _loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    zkQuorumController.text = prefs.getString('zk_quorum') ?? 'localhost:2181';
    zkNodeController.text = prefs.getString('zk_node') ?? '/hbase';
  }

  void connect() async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      print('【连接调试】开始执行connect方法，线程ID: ${Isolate.current.hashCode}');
      print('【连接调试】连接参数：zkQuorum=${zkQuorumController.text}, zkNode=${zkNodeController.text}');
      
      // 验证输入
      if (zkQuorumController.text.isEmpty || zkNodeController.text.isEmpty) {
        errorMessage.value = '连接参数不能为空！';
        isLoading.value = false;
        return;
      }
      
      // 包装在安全区域中执行连接操作
      runZonedGuarded(() async {
        print('【连接调试】进入安全执行区域...');
        
        try {
          // 记录操作开始时间
          final stopwatch = Stopwatch()..start();
          
          // 尝试连接
          print('【连接调试】开始调用HBase服务的connect方法...');
          final connected = await Get.find<HBaseService>().connect(
            zkQuorumController.text,
            zkNodeController.text,
          );
          
          stopwatch.stop();
          print('【连接调试】连接操作耗时: ${stopwatch.elapsedMilliseconds}毫秒');
          print('【连接调试】connect方法返回: $connected');
          
          // 处理连接结果
          if (connected) {
            print('【连接调试】连接成功，保存连接参数');
            _saveConnectionInfo();
            
            // 导航到首页
            print('【连接调试】导航到首页');
            Get.offNamed('/home');
          } else {
            print('【连接调试】连接失败，显示错误消息');
            errorMessage.value = '连接失败，请检查连接参数和网络状态！已自动切换到模拟模式。';
            
            // 延迟后导航到首页并使用模拟模式
            print('【连接调试】3秒后自动进入模拟模式');
            await Future.delayed(const Duration(seconds: 3));
            
            if (errorMessage.value.isNotEmpty) {
              print('【连接调试】导航到首页(模拟模式)');
              Get.offNamed('/home');
            }
          }
        } catch (e, stack) {
          print('【连接错误】连接操作内部异常: $e');
          print('【连接错误】异常堆栈: $stack');
          
          // 设置更友好的错误消息
          errorMessage.value = '连接过程中发生异常，请稍后重试！\n错误详情: ${e.toString().substring(0, min(e.toString().length, 100))}';
          
          // 是否仍需自动进入模拟模式
          if (Get.find<HBaseService>().isMockMode.value) {
            print('【连接调试】3秒后自动进入模拟模式(异常后)');
            await Future.delayed(const Duration(seconds: 3));
            
            if (errorMessage.value.isNotEmpty) {
              print('【连接调试】导航到首页(异常后模拟模式)');
              Get.offNamed('/home');
            }
          }
        }
      }, (error, stackTrace) {
        // 处理未捕获的异常
        print('【严重错误】连接过程中未捕获的异常: $error');
        print('【严重错误】异常堆栈: $stackTrace');
        
        errorMessage.value = '发生意外错误，请稍后重试！\n错误详情: ${error.toString().substring(0, min(error.toString().length, 100))}';
      });
    } catch (outerError, outerStack) {
      print('【严重错误】连接控制器外层异常: $outerError');
      print('【严重错误】外层异常堆栈: $outerStack');
      
      errorMessage.value = '应用发生严重错误，请重启应用！';
    } finally {
      // 确保加载状态被重置
      isLoading.value = false;
      print('【连接调试】connect方法执行完毕');
    }
  }
  
  void _showConnectionFailureDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('连接失败'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('无法连接到HBase集群，请检查:'),
            const SizedBox(height: 8),
            Text('• ZooKeeper地址: ${zkQuorumController.text}'),
            Text('• ZooKeeper节点: ${zkNodeController.text}'),
            const SizedBox(height: 16),
            const Text('可能的原因:'),
            const Text('1. ZooKeeper服务未运行'),
            const Text('2. 网络连接问题'),
            const Text('3. HBase集群未启动'),
            const Text('4. 动态库未正确加载'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // 确保模拟模式关闭，以便下次尝试真实连接
              _hbaseService.isMockMode.value = false;
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
  
  void _showExceptionDialog(dynamic exception) {
    Get.dialog(
      AlertDialog(
        title: const Text('连接异常'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('连接过程中发生异常:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(exception.toString()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // 确保模拟模式关闭，以便下次尝试真实连接
              _hbaseService.isMockMode.value = false;
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _saveConnectionInfo() async {
    try {
      print('【连接调试】保存连接参数');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('zk_quorum', zkQuorumController.text);
      await prefs.setString('zk_node', zkNodeController.text);
      print('【连接调试】连接参数保存成功');
    } catch (e) {
      print('【连接错误】保存连接参数失败: $e');
      // 不影响主流程，连接仍然可以继续
    }
  }
} 