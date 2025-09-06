import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import '../models/mosaic_operation.dart';

class MosaicProcessor {
  final ui.Size imageSize;

  MosaicProcessor(this.imageSize);

  Future<Uint8List> applyOperations(
      Uint8List originalBytes,
      List<MosaicOperation> operations,
      int currentIndex,
      ui.Size canvasSize,
      ) async {
    Uint8List currentBytes = originalBytes;

    for (int i = 0; i <= currentIndex; i++) {
      if (i < operations.length) {
        currentBytes = await _applyMosaicOperation(
          currentBytes,
          operations[i],
          canvasSize,
        );
      }
    }

    return currentBytes;
  }

  Future<Uint8List> _applyMosaicOperation(
      Uint8List imageBytes,
      MosaicOperation operation,
      ui.Size canvasSize,
      ) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final mosaicSize = (operation.brushSize / 3).clamp(8.0, 30.0).toInt();
    final scaleX = imageSize.width / canvasSize.width;
    final scaleY = imageSize.height / canvasSize.height;

    Set<String> processedRegions = {};

    for (int i = 0; i < operation.points.length; i += 2) {
      final point = operation.points[i];
      final imageX = (point.dx * scaleX).clamp(0.0, imageSize.width - 1);
      final imageY = (point.dy * scaleY).clamp(0.0, imageSize.height - 1);

      final brushRadius = operation.brushSize * scaleX / 2;
      final left = (imageX - brushRadius).clamp(0.0, imageSize.width - 1).toInt();
      final top = (imageY - brushRadius).clamp(0.0, imageSize.height - 1).toInt();
      final right = (imageX + brushRadius).clamp(0.0, imageSize.width - 1).toInt();
      final bottom = (imageY + brushRadius).clamp(0.0, imageSize.height - 1).toInt();

      final regionKey = '${left ~/ mosaicSize}_${top ~/ mosaicSize}';
      if (processedRegions.contains(regionKey)) continue;
      processedRegions.add(regionKey);

      if (right > left && bottom > top) {
        _applyMosaicToRegion(image, left, top, right, bottom, mosaicSize);
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  void _applyMosaicToRegion(
      img.Image image,
      int left,
      int top,
      int right,
      int bottom,
      int mosaicSize,
      ) {
    for (int y = top; y < bottom; y += mosaicSize) {
      for (int x = left; x < right; x += mosaicSize) {
        final blockRight = (x + mosaicSize).clamp(x, image.width);
        final blockBottom = (y + mosaicSize).clamp(y, image.height);

        int totalR = 0, totalG = 0, totalB = 0, totalA = 0, count = 0;

        for (int by = y; by < blockBottom; by++) {
          for (int bx = x; bx < blockRight; bx++) {
            final pixel = image.getPixel(bx, by);
            totalR += pixel.r.toInt();
            totalG += pixel.g.toInt();
            totalB += pixel.b.toInt();
            totalA += pixel.a.toInt();
            count++;
          }
        }

        if (count > 0) {
          final avgColor = img.ColorInt32.rgba(
            (totalR / count).round(),
            (totalG / count).round(),
            (totalB / count).round(),
            (totalA / count).round(),
          );

          for (int by = y; by < blockBottom; by++) {
            for (int bx = x; bx < blockRight; bx++) {
              image.setPixel(bx, by, avgColor);
            }
          }
        }
      }
    }
  }
}
