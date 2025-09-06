import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('作者',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('opoojkk'),
            const SizedBox(height: 24),

            Text('仓库',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('https://github.com/opoojkk/mosaic_pal'),
            const SizedBox(height: 24),

            Text('开源协议',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('MIT License'),
          ],
        ),
      ),
    );
  }
}
