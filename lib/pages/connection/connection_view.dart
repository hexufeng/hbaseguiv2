import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'connection_controller.dart';

class ConnectionView extends GetView<ConnectionController> {
  const ConnectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接到 HBase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo或标题
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(Icons.storage, size: 64, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 8),
                    const Text(
                      'HBase GUI',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('连接到您的HBase集群', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 连接表单
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller.zkQuorumController,
                      decoration: const InputDecoration(
                        labelText: 'ZooKeeper Quorum',
                        hintText: '例如: zk1.example.com:2181,zk2.example.com:2181',
                        prefixIcon: Icon(Icons.dns),
                        border: OutlineInputBorder(),
                        helperText: '输入ZooKeeper服务器地址，多个地址用英文逗号分隔',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.zkNodeController,
                      decoration: const InputDecoration(
                        labelText: 'ZooKeeper Node',
                        hintText: '/hbase',
                        prefixIcon: Icon(Icons.folder),
                        border: OutlineInputBorder(),
                        helperText: 'HBase在ZooKeeper中的节点路径，通常为/hbase',
                      ),
                    ),
                    
                    // 错误消息显示
                    Obx(() => controller.errorMessage.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              controller.errorMessage.value,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          )
                        : const SizedBox.shrink()),
                    
                    const SizedBox(height: 24),
                    
                    // 连接按钮
                    Obx(() => ElevatedButton.icon(
                      onPressed: controller.isLoading.value ? null : controller.connect,
                      icon: controller.isLoading.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.link),
                      label: Text(controller.isLoading.value ? '连接中...' : '连接'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 连接说明
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '连接说明',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• ZooKeeper Quorum: HBase的ZooKeeper地址，格式为host:port'),
                    Text('  地址示例: music-im-hbase-3.gy.ntes.com,music-im-hbase-4.gy.ntes.com'),
                    Text('• ZooKeeper Node: HBase在ZooKeeper中的节点路径，通常为/hbase'),
                    SizedBox(height: 8),
                    Text(
                      '故障排除:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• 如果连接时程序闪退，请检查域名格式是否正确'),
                    Text('• 确保域名完整，例如包含.com等顶级域名'),
                    Text('• 确保网络连接稳定，可以访问HBase服务器'),
                    Text('• 连接超时15秒后将自动终止，防止程序无响应'),
                    SizedBox(height: 8),
                    Text(
                      '注意：如果连接失败，将自动降级到模拟模式，显示模拟数据。',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 