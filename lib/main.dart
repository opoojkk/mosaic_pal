import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MosaicApp());
}

class MosaicApp extends StatelessWidget {
  const MosaicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '马赛克编辑器',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}
