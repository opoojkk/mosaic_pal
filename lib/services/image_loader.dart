import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageLoader {
  static Future<(Uint8List, ui.Image)> loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return (bytes, frame.image);
  }
}
