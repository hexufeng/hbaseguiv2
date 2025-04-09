import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hbaseguiv2/services/hbase_service.dart';

class HBaseController extends GetxController {
  final _hbaseService = Get.find<HBaseService>();
  
  final isConnected = false.obs;
  final selectedTable = Rx<String?>(null);
  final tables = <String>[].obs;
  
  final zkQuorumController = TextEditingController();
  final zkNodeController = TextEditingController();
  
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isMockMode = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    isConnected.value = _hbaseService.isConnected.value;
    
    // 监听连接状态变化
    ever(_hbaseService.isConnected, (bool connected) {
      isConnected.value = connected;
      if (connected) {
        refreshTables();
      } else {
        tables.clear();
        selectedTable.value = null;
      }
    });
  }
  
  Future<void> connect(String zkQuorum, String zkNode) async {
    final result = await _hbaseService.connect(zkQuorum, zkNode);
    if (result) {
      await refreshTables();
    }
  }
  
  Future<void> disconnect() async {
    await _hbaseService.disconnect();
  }
  
  Future<void> refreshTables() async {
    if (!isConnected.value) return;
    final tableList = await _hbaseService.getTables();
    tables.value = tableList;
  }
  
  void selectTable(String tableName) {
    selectedTable.value = tableName;
  }
  
  Future<List<Map<String, dynamic>>> getTableData(
    String tableName, {
    String? startRow,
    String? endRow,
    int limit = 100,
    String? filterPrefix,
  }) async {
    if (!isConnected.value) return [];
    return _hbaseService.getTableData(
      tableName,
      startRow: startRow ?? '',
      endRow: endRow ?? '',
      limit: limit,
      filterPrefix: filterPrefix ?? '',
    );
  }
  
  Future<bool> executeCommand(String tableName, String command) async {
    if (!isConnected.value) return false;
    return _hbaseService.executeCommand(tableName, command);
  }
  
  void toggleMockMode() {
    isMockMode.value = !isMockMode.value;
    _hbaseService.isMockMode.value = isMockMode.value;
    if (isMockMode.value) {
      _hbaseService.disconnect();
    }
  }
  
  @override
  void onClose() {
    zkQuorumController.dispose();
    zkNodeController.dispose();
    _hbaseService.disconnect();
    super.onClose();
  }
} 