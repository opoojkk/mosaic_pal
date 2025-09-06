import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final Future<PackageInfo> _appInfo = PackageInfo.fromPlatform();

  void _showAppInfoDialog(BuildContext context, PackageInfo info) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('应用信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("应用名称: ${info.appName}"),
              Text("包名: ${info.packageName}"),
              Text("版本: ${info.version}"),
              Text("构建号: ${info.buildNumber}"),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('关闭'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('主题'),
            subtitle: const Text('切换浅色 / 深色模式'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题切换功能未实现')),
              );
            },
          ),
          const Divider(height: 1),
          FutureBuilder<PackageInfo>(
            future: _appInfo,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('版本'),
                  subtitle: Text('加载中...'),
                );
              }
              if (snapshot.hasError) {
                return ListTile(
                  leading: const Icon(Icons.error),
                  title: const Text('版本'),
                  subtitle: Text('获取失败: ${snapshot.error}'),
                );
              }

              final info = snapshot.data!;
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                subtitle: Text("${info.version}+${info.buildNumber}"),
                onTap: () => _showAppInfoDialog(context, info),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('关于'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
