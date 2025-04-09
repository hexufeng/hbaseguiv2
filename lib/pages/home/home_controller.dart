import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/hbase_service.dart';
import '../../routes/routes.dart';

class HomeController extends GetxController {
  final searchController = TextEditingController();
  final commandController = TextEditingController();
  final tables = <String>[].obs;
  final filteredTables = <String>[].obs;
  final selectedTable = Rx<String?>(null);
  final tableData = <Map<String, dynamic>>[].obs;
  final isCommandPanelExpanded = false.obs;
  final currentFilter = Rx<Map<String, dynamic>?>(null);
  final isLoadingRows = false.obs;

  late final HBaseService _hbaseService;
  HBaseService get hbaseService => _hbaseService;
  
  @override
  void onInit() {
    super.onInit();
    _hbaseService = Get.find<HBaseService>();
    refreshTables();
  }

  @override
  void onClose() {
    searchController.dispose();
    commandController.dispose();
    super.onClose();
  }

  void filterTables(String query) {
    if (query.isEmpty) {
      filteredTables.value = tables;
    } else {
      filteredTables.value = tables.where(
        (table) => table.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  Future<void> refreshTables() async {
    print('开始刷新表列表...');
    EasyLoading.show(status: '加载表...');
    
    try {
      print('调用HBaseService.getTables()');
      final tableList = await _hbaseService.getTables();
      print('成功获取表列表，数量: ${tableList.length}');
      
      if (tableList.isEmpty) {
        print('获取到的表列表为空，可能是未连接或集群中没有表');
        EasyLoading.showInfo('未找到任何表');
      } else {
        print('表列表: ${tableList.join(", ")}');
      }
      
      tables.value = tableList;
      filteredTables.value = tableList;
      EasyLoading.dismiss();
      
    } catch (e) {
      print('获取表列表时出错: $e');
      EasyLoading.dismiss();
      
      // 显示详细错误对话框
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.dialog(
          AlertDialog(
            title: const Text('获取表列表失败'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('连接到HBase集群时出现错误，详细信息:'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(e.toString()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> selectTable(String table) async {
    selectedTable.value = table;
    await loadTableData();
  }

  Future<void> loadTableData({bool refresh = false}) async {
    isLoadingRows.value = true;
    
    if (refresh) {
      tableData.clear();
    }
    
    if (selectedTable.value == null || selectedTable.value!.isEmpty) {
      isLoadingRows.value = false;
      return;
    }
    
    try {
      String startRow = '';
      String endRow = '';
      String filterPrefix = '';
      
      if (currentFilter.value != null && currentFilter.value!['type'] == 'prefix') {
        filterPrefix = currentFilter.value!['value'] ?? '';
      }
      
      final result = await _hbaseService.getTableData(
        selectedTable.value!,
        startRow: startRow,
        endRow: endRow,
        limit: 50,
        filterPrefix: filterPrefix,
      );
      
      tableData.value = result;
    } catch (e) {
      tableData.clear();
      Get.snackbar('错误', '加载表数据时发生异常: $e', 
        snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoadingRows.value = false;
    }
  }

  void toggleCommandPanel() {
    isCommandPanelExpanded.toggle();
  }

  Future<void> executeCommand() async {
    if (selectedTable.value == null) {
      EasyLoading.showError('请先选择一个表');
      return;
    }

    if (commandController.text.isEmpty) {
      EasyLoading.showError('请输入命令');
      return;
    }

    EasyLoading.show(status: '执行命令...');
    try {
      await _hbaseService.executeCommand(
        selectedTable.value!,
        commandController.text,
      );
      
      // 刷新表数据
      await loadTableData();
      
      commandController.clear();
      EasyLoading.showSuccess('命令执行成功');
    } catch (e) {
      EasyLoading.showError('执行失败: ${e.toString()}');
    }
  }

  void showFilter() {
    Get.dialog(
      AlertDialog(
        title: const Text('过滤条件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Row Key 前缀',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  currentFilter.value = {
                    'type': 'prefix',
                    'value': value,
                  };
                } else {
                  currentFilter.value = null;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              loadTableData();
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }

  void showSettings() {
    final zkQuorum = _hbaseService.zkQuorum;
    final zkNode = _hbaseService.zkNode;
    final isConnected = _hbaseService.isConnected.value;
    
    Get.dialog(
      AlertDialog(
        title: const Text('连接信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isConnected)
              const Text('未连接到 HBase', style: TextStyle(color: Colors.red))
            else ...[
              Text('ZooKeeper Quorum: ${zkQuorum ?? "未设置"}'),
              Text('ZooKeeper Node: ${zkNode ?? "未设置"}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
} 