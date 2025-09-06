import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'mosaic_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MosaicEditor(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('马赛克编辑器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library,
                size: 100, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 32),
            Text('选择图片开始编辑',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(
              '支持手势滑动添加马赛克效果',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('选择图片'),
            ),
          ],
        ),
      ),
    );
  }
}
