import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'image_painter.dart';

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
    return LayoutBuilder(
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
    );
  }
}
