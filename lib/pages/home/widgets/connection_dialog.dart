import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hbaseguiv2/controllers/hbase_controller.dart';

class ConnectionDialog extends StatelessWidget {
  final HBaseController controller;
  final _zkQuorumController = TextEditingController();
  final _zkNodeController = TextEditingController();

  ConnectionDialog({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('连接到 HBase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _zkQuorumController,
            decoration: const InputDecoration(
              labelText: 'ZooKeeper Quorum',
              hintText: 'localhost:2181',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _zkNodeController,
            decoration: const InputDecoration(
              labelText: 'ZooKeeper Node',
              hintText: '/hbase',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            final zkQuorum = _zkQuorumController.text.trim();
            final zkNode = _zkNodeController.text.trim();
            
            if (zkQuorum.isEmpty || zkNode.isEmpty) {
              Get.snackbar(
                '错误',
                '请输入 ZooKeeper Quorum 和 Node',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
            
            await controller.connect(zkQuorum, zkNode);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('连接'),
        ),
      ],
    );
  }
} 