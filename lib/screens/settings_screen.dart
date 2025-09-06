import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return "${info.version}+${info.buildNumber}";
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
              // TODO: 主题切换逻辑，可以用 Provider / Riverpod 等实现
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('主题切换功能未实现')),
              );
            },
          ),
          const Divider(height: 1),
          FutureBuilder<String>(
            future: _getAppVersion(),
            builder: (context, snapshot) {
              final version =
              snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData
                  ? snapshot.data
                  : '加载中...';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('版本'),
                subtitle: Text(version ?? ''),
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
