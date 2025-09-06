import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/dependencies.dart';

class DependenciesScreen extends StatelessWidget {
  const DependenciesScreen({super.key});

  Future<List<Dependency>> _loadDependencies() async {
    final jsonString = await rootBundle.loadString('assets/dependencies.json');
    final dynamic decoded = jsonDecode(jsonString);

    List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map && decoded['dependencies'] is List) {
      rawList = decoded['dependencies'] as List;
    } else {
      throw const FormatException('JSON 根节点必须是数组，或包含 "dependencies" 的对象');
    }

    return rawList.map<Dependency>((item) {
      if (item is! Map) {
        throw const FormatException('数组元素必须是对象（Map）');
      }
      return Dependency.fromJson(item.map(
            (key, value) => MapEntry(key.toString(), value),
      ));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('依赖列表'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Dependency>>(
        future: _loadDependencies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          final dependencies = snapshot.data ?? [];
          if (dependencies.isEmpty) {
            return const Center(child: Text('暂无依赖数据'));
          }

          return ListView.separated(
            itemCount: dependencies.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dep = dependencies[index];
              return ListTile(
                leading: const Icon(Icons.extension),
                title: Text(dep.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dep.description),
                    const SizedBox(height: 2),
                    Text(
                      "License: ${dep.license}",
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Text(
                  dep.version,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
