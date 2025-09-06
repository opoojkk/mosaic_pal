import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/mosaic_operation.dart';
import '../services/image_loader.dart';
import '../services/image_saver.dart';
import '../services/mosaic_processor.dart';
import '../widgets/mosaic_canvas.dart';

class MosaicEditor extends StatefulWidget {
  final String imagePath;

  const MosaicEditor({super.key, required this.imagePath});

  @override
  State<MosaicEditor> createState() => _MosaicEditorState();
}

class _MosaicEditorState extends State<MosaicEditor> {
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  ui.Image? _displayImage;

  final List<MosaicOperation> _operations = [];
  int _currentOperationIndex = -1;
  double _brushSize = 30.0;
  bool _isLoading = true;
  Size _imageSize = Size.zero;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final (bytes, image) = await ImageLoader.loadImage(widget.imagePath);
      setState(() {
        _originalImageBytes = bytes;
        _processedImageBytes = bytes;
        _displayImage = image;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载图片失败: $e')));
      }
    }
  }

  void _addMosaicOperation(List<Offset> points, Size canvasSize) {
    if (points.isEmpty) return;
    _canvasSize = canvasSize;

    _operations.removeRange(_currentOperationIndex + 1, _operations.length);
    _operations.add(MosaicOperation(points, _brushSize));
    _currentOperationIndex = _operations.length - 1;

    _applyAllOperations();
  }

  void _undo() {
    if (_currentOperationIndex >= 0) {
      _currentOperationIndex--;
      _applyAllOperations();
    }
  }

  void _redo() {
    if (_currentOperationIndex < _operations.length - 1) {
      _currentOperationIndex++;
      _applyAllOperations();
    }
  }

  Future<void> _applyAllOperations() async {
    if (_originalImageBytes == null) return;
    try {
      final processor = MosaicProcessor(_imageSize);
      final currentBytes = await processor.applyOperations(
        _originalImageBytes!,
        _operations,
        _currentOperationIndex,
        _canvasSize,
      );

      final codec = await ui.instantiateImageCodec(currentBytes);
      final frame = await codec.getNextFrame();

      setState(() {
        _processedImageBytes = currentBytes;
        _displayImage = frame.image;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('处理图片失败: $e')));
      }
    }
  }

  void _showBrushSizeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempBrushSize = _brushSize;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('画笔设置'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '画笔大小: ${tempBrushSize.toInt()}px',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempBrushSize,
                    min: 20,
                    max: 120,
                    divisions: 20,
                    label: tempBrushSize.toInt().toString(),
                    onChanged: (value) =>
                        setDialogState(() => tempBrushSize = value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在图片上滑动手指添加马赛克效果',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() => _brushSize = tempBrushSize);
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveImage() async {
    if (_processedImageBytes == null) return;
    try {
      final path = await ImageSaver.saveImage(_processedImageBytes!);
      if (mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片已保存到: $path'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: '确定', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('马赛克编辑'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.brush),
            onPressed: _showBrushSizeDialog,
            tooltip: '画笔设置',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _currentOperationIndex >= 0 ? _undo : null,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _currentOperationIndex < _operations.length - 1
                ? _redo
                : null,
            tooltip: '重做',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _processedImageBytes != null ? _saveImage : null,
            tooltip: '保存',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _displayImage != null
          ? MosaicCanvas(
              image: _displayImage!,
              brushSize: _brushSize,
              onMosaicOperation: _addMosaicOperation,
            )
          : const Center(child: Text('图片加载失败')),
    );
  }
}
