import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

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
            Icon(
              Icons.photo_library,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              '选择图片开始编辑',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
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

class MosaicOperation {
  final List<Offset> points;
  final double brushSize;

  MosaicOperation(this.points, this.brushSize);
}

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
      final bytes = await File(widget.imagePath).readAsBytes();

      // 获取图像尺寸信息
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      setState(() {
        _originalImageBytes = bytes;
        _processedImageBytes = bytes;
        _displayImage = frame.image;
        _imageSize = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载图片失败: $e')),
        );
      }
    }
  }

  void _addMosaicOperation(List<Offset> points, Size canvasSize) {
    if (points.isEmpty) return;

    // 存储画布大小
    _canvasSize = canvasSize;

    // 移除当前操作之后的所有操作（为了支持重做）
    _operations.removeRange(_currentOperationIndex + 1, _operations.length);

    // 添加新操作
    _operations.add(MosaicOperation(points, _brushSize));
    _currentOperationIndex = _operations.length - 1;

    _applyAllOperations(canvasSize);
  }

  void _undo() {
    if (_currentOperationIndex >= 0) {
      _currentOperationIndex--;
      _applyAllOperations(_canvasSize);
    }
  }

  void _redo() {
    if (_currentOperationIndex < _operations.length - 1) {
      _currentOperationIndex++;
      _applyAllOperations(_canvasSize);
    }
  }

  Future<void> _applyAllOperations(Size canvasSize) async {
    if (_originalImageBytes == null) return;

    try {
      // 从原图开始
      Uint8List currentBytes = _originalImageBytes!;

      // 逐个应用操作
      for (int i = 0; i <= _currentOperationIndex; i++) {
        if (i < _operations.length) {
          currentBytes = await _applyMosaicOperation(currentBytes, _operations[i], canvasSize);
        }
      }

      // 更新显示图像
      final codec = await ui.instantiateImageCodec(currentBytes);
      final frame = await codec.getNextFrame();

      setState(() {
        _processedImageBytes = currentBytes;
        _displayImage = frame.image;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理图片失败: $e')),
        );
      }
    }
  }

  Future<Uint8List> _applyMosaicOperation(Uint8List imageBytes, MosaicOperation operation, Size canvasSize) async {
    try {
      // 解码图像
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Failed to decode image');
        return imageBytes;
      }

      final mosaicSize = (operation.brushSize / 3).clamp(8.0, 30.0).toInt();
      final scaleX = _imageSize.width / canvasSize.width;
      final scaleY = _imageSize.height / canvasSize.height;

      print('Applying mosaic: points=${operation.points.length}, mosaicSize=$mosaicSize, scale=($scaleX, $scaleY)');

      // 创建一个Set来存储已处理的区域，避免重复处理
      Set<String> processedRegions = {};

      // 为每个点应用马赛克效果，减少采样间隔以获得更连续的效果
      for (int i = 0; i < operation.points.length; i += 2) {
        final point = operation.points[i];

        final imageX = (point.dx * scaleX).clamp(0.0, _imageSize.width - 1);
        final imageY = (point.dy * scaleY).clamp(0.0, _imageSize.height - 1);

        final brushRadius = operation.brushSize * scaleX / 2;
        final left = (imageX - brushRadius).clamp(0.0, _imageSize.width - 1).toInt();
        final top = (imageY - brushRadius).clamp(0.0, _imageSize.height - 1).toInt();
        final right = (imageX + brushRadius).clamp(0.0, _imageSize.width - 1).toInt();
        final bottom = (imageY + brushRadius).clamp(0.0, _imageSize.height - 1).toInt();

        // 创建区域标识符，避免重复处理相同区域
        final regionKey = '${left ~/ mosaicSize}_${top ~/ mosaicSize}';
        if (processedRegions.contains(regionKey)) continue;
        processedRegions.add(regionKey);

        if (right > left && bottom > top) {
          // 应用马赛克效果到指定区域
          _applyMosaicToRegion(image, left, top, right, bottom, mosaicSize);
        }
      }

      // 编码回 Uint8List
      final encodedImage = img.encodePng(image);
      print('Mosaic applied successfully, encoded image size: ${encodedImage.length}');
      return Uint8List.fromList(encodedImage);
    } catch (e) {
      print('Error applying mosaic: $e');
      // 出错返回原图
      return imageBytes;
    }
  }

  void _applyMosaicToRegion(img.Image image, int left, int top, int right, int bottom, int mosaicSize) {
    // 确保边界在图像范围内
    left = left.clamp(0, image.width - 1);
    top = top.clamp(0, image.height - 1);
    right = right.clamp(0, image.width);
    bottom = bottom.clamp(0, image.height);

    for (int y = top; y < bottom; y += mosaicSize) {
      for (int x = left; x < right; x += mosaicSize) {
        // 计算马赛克块的边界
        final blockRight = (x + mosaicSize).clamp(x, image.width);
        final blockBottom = (y + mosaicSize).clamp(y, image.height);
        
        if (x >= image.width || y >= image.height || blockRight <= x || blockBottom <= y) continue;

        // 获取块的平均颜色
        int totalR = 0, totalG = 0, totalB = 0, totalA = 0;
        int pixelCount = 0;

        // 采样计算平均颜色
        for (int by = y; by < blockBottom; by++) {
          for (int bx = x; bx < blockRight; bx++) {
            if (bx < image.width && by < image.height) {
              final pixel = image.getPixel(bx, by);
              totalR += img.getRed(pixel);
              totalG += img.getGreen(pixel);
              totalB += img.getBlue(pixel);
              totalA += img.getAlpha(pixel);
              pixelCount++;
            }
          }
        }

        if (pixelCount > 0) {
          final avgR = (totalR / pixelCount).round().clamp(0, 255);
          final avgG = (totalG / pixelCount).round().clamp(0, 255);
          final avgB = (totalB / pixelCount).round().clamp(0, 255);
          final avgA = (totalA / pixelCount).round().clamp(0, 255);
          final avgColor = img.getColor(avgR, avgG, avgB, avgA);

          // 用平均颜色填充整个块
          for (int by = y; by < blockBottom; by++) {
            for (int bx = x; bx < blockRight; bx++) {
              if (bx < image.width && by < image.height) {
                image.setPixel(bx, by, avgColor);
              }
            }
          }
        }
      }
    }
  }


  void _showBrushSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                    onChanged: (value) {
                      setDialogState(() {
                        tempBrushSize = value;
                      });
                    },
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _brushSize = tempBrushSize;
                    });
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
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'mosaic_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(_processedImageBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片已保存到: ${file.path}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '确定',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
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
            onPressed: _currentOperationIndex < _operations.length - 1 ? _redo : null,
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

class MosaicCanvas extends StatefulWidget {
  final ui.Image image;
  final double brushSize;
  final Function(List<Offset>, Size) onMosaicOperation;

  const MosaicCanvas({
    super.key,
    required this.image,
    required this.brushSize,
    required this.onMosaicOperation,
  });

  @override
  State<MosaicCanvas> createState() => _MosaicCanvasState();
}

class _MosaicCanvasState extends State<MosaicCanvas> {
  final List<Offset> _currentStroke = [];
  bool _isDrawing = false;
  Size _canvasSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentStroke.clear();
                  _currentStroke.add(details.localPosition);
                  _isDrawing = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                if (_currentStroke.isNotEmpty) {
                  widget.onMosaicOperation(List.from(_currentStroke), _canvasSize);
                  setState(() {
                    _currentStroke.clear();
                    _isDrawing = false;
                  });
                }
              },
              child: CustomPaint(
                painter: ImagePainter(
                  image: widget.image,
                  currentStroke: _currentStroke,
                  brushSize: widget.brushSize,
                  isDrawing: _isDrawing,
                ),
                size: Size.infinite,
              ),
            );
          },
        ),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> currentStroke;
  final double brushSize;
  final bool isDrawing;

  ImagePainter({
    required this.image,
    required this.currentStroke,
    required this.brushSize,
    required this.isDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制图片
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());

    // 绘制当前笔画预览
    if (isDrawing && currentStroke.isNotEmpty) {
      // 绘制笔画轨迹
      final strokePaint = Paint()
        ..color = Colors.red.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = brushSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (currentStroke.length > 1) {
        final path = Path();
        path.moveTo(currentStroke.first.dx, currentStroke.first.dy);

        for (int i = 1; i < currentStroke.length; i++) {
          path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
        }

        canvas.drawPath(path, strokePaint);
      }

      // 绘制当前画笔位置圆圈
      if (currentStroke.isNotEmpty) {
        final previewPaint = Paint()
          ..color = Colors.red.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(
          currentStroke.last,
          brushSize / 2,
          previewPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}