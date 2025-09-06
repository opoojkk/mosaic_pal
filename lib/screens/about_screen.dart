import 'package:flutter/material.dart';
import 'dependencies_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('作者'),
            subtitle: Text('Your Name'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.link),
            title: Text('仓库'),
            subtitle: Text('https://github.com/your-repo'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('开源协议'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DependenciesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
