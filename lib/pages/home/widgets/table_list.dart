import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hbaseguiv2/controllers/hbase_controller.dart';

class TableList extends StatelessWidget {
  final HBaseController controller;

  const TableList({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('表格列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.refreshTables,
                tooltip: '刷新表格列表',
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.tables.isEmpty) {
              return const Center(
                child: Text('没有可用的表格'),
              );
            }
            
            return ListView.builder(
              itemCount: controller.tables.length,
              itemBuilder: (context, index) {
                final tableName = controller.tables[index];
                return Obx(() => ListTile(
                  title: Text(tableName),
                  selected: tableName == controller.selectedTable.value,
                  onTap: () => controller.selectTable(tableName),
                ));
              },
            );
          }),
        ),
      ],
    );
  }
} 