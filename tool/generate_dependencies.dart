import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';

/// 本地依赖 -> License 映射表
/// (未知的保持空字符串，手动补充)
const Map<String, String> licenseMap = {
  "flutter": "BSD-3-Clause",
  "image_picker": "MIT",
  "path_provider": "BSD-3-Clause",
  "gallery_saver_plus": "MIT",
  "yaml": "MIT",
  "image": "MIT",
};

/// 本地依赖 -> 描述映射表
const Map<String, String> descriptionMap = {
  "flutter": "Flutter SDK",
  "image_picker": "选择图片/视频",
  "path_provider": "路径管理",
  "gallery_saver_plus": "保存图片/视频到相册",
  "yaml": "YAML 文件解析",
  "image": "图像处理库",
};

Future<void> main() async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ pubspec.yaml not found');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspec = loadYaml(pubspecContent);

  final dependencies = <Map<String, dynamic>>[];

  void parseDeps(YamlMap? deps) {
    if (deps == null) return;

    deps.forEach((key, value) {
      String version = "";
      if (value is String) {
        version = value;
      } else if (value is YamlMap && value['version'] != null) {
        version = value['version'].toString();
      }

      dependencies.add({
        "name": key,
        "version": version,
        "description": descriptionMap[key] ?? "",
        "license": licenseMap[key] ?? "",
      });
    });
  }

  parseDeps(pubspec['dependencies']);
  parseDeps(pubspec['dev_dependencies']);

  final output = {
    "dependencies": dependencies,
  };

  final outFile = File('assets/dependencies.json');
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(output));

  print('✅ Generated assets/dependencies.json with ${dependencies.length} entries');
}
