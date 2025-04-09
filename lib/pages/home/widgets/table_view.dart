import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hbaseguiv2/controllers/hbase_controller.dart';
import 'package:data_table_2/data_table_2.dart';

class TableView extends StatefulWidget {
  final HBaseController controller;

  const TableView({Key? key, required this.controller}) : super(key: key);

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  final _startRowController = TextEditingController();
  final _endRowController = TextEditingController();
  final _limitController = TextEditingController(text: '100');
  final _filterPrefixController = TextEditingController();
  final _data = <Map<String, dynamic>>[].obs;
  final _isLoading = false.obs;
  final _columns = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    ever(widget.controller.selectedTable, (_) => _refreshData());
  }

  Future<void> _refreshData() async {
    if (widget.controller.selectedTable.value == null) {
      _data.clear();
      _columns.clear();
      return;
    }

    _isLoading.value = true;
    try {
      final data = await widget.controller.getTableData(
        widget.controller.selectedTable.value!,
        startRow: _startRowController.text.trim(),
        endRow: _endRowController.text.trim(),
        limit: int.tryParse(_limitController.text) ?? 100,
        filterPrefix: _filterPrefixController.text.trim(),
      );
      
      // 收集所有列名
      final columns = <String>{};
      for (final row in data) {
        columns.addAll(row.keys);
      }
      
      _columns.value = columns;
      _data.value = data;
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startRowController,
                  decoration: const InputDecoration(
                    labelText: '开始行',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _endRowController,
                  decoration: const InputDecoration(
                    labelText: '结束行',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _limitController,
                  decoration: const InputDecoration(
                    labelText: '限制',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _filterPrefixController,
                  decoration: const InputDecoration(
                    labelText: '过滤前缀',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('查询'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (widget.controller.selectedTable.value == null) {
              return const Center(child: Text('请选择一个表格'));
            }

            if (_data.isEmpty) {
              return const Center(child: Text('没有数据'));
            }

            return DataTable2(
              columns: _columns.map((column) => DataColumn2(
                label: Text(column),
                size: ColumnSize.L,
              )).toList(),
              rows: _data.map((row) => DataRow2(
                cells: _columns.map((column) => DataCell(
                  Text(row[column]?.toString() ?? ''),
                )).toList(),
              )).toList(),
            );
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _startRowController.dispose();
    _endRowController.dispose();
    _limitController.dispose();
    _filterPrefixController.dispose();
    super.dispose();
  }
} 