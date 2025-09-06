import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
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

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('选择主题'),
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (mode) {
                if (mode != null) themeProvider.setTheme(mode);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (mode) {
                if (mode != null) themeProvider.setTheme(mode);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (mode) {
                if (mode != null) themeProvider.setTheme(mode);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    String subtitle;
    switch (themeProvider.themeMode) {
      case ThemeMode.system:
        subtitle = "跟随系统";
        break;
      case ThemeMode.light:
        subtitle = "浅色模式";
        break;
      case ThemeMode.dark:
        subtitle = "深色模式";
        break;
    }

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
            subtitle: Text(subtitle),
            onTap: () => _showThemeDialog(context, themeProvider),
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
