import 'dart:io';
import 'dart:typed_data';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

class ImageSaver {
  static Future<String?> saveImage(Uint8List imageBytes) async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }
    directory ??= await getApplicationDocumentsDirectory();

    final fileName = 'mosaic_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);

    final result = await GallerySaver.saveImage(file.path);
    return (result ?? false) ? file.path : null;
  }
}
