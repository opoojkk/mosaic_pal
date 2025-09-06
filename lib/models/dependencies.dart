class Dependency {
  final String name;
  final String description;
  final String version;
  final String license;

  const Dependency({
    required this.name,
    required this.description,
    required this.version,
    required this.license,
  });

  factory Dependency.fromJson(Map<String, dynamic> json) {
    String asString(dynamic v, [String fallback = '']) =>
        (v == null) ? fallback : v.toString();

    return Dependency(
      name: asString(json['name'], '未知'),
      description: asString(json['description'], '暂无描述'),
      version: asString(json['version'], ''),
      license: asString(json['license'], '未知'),
    );
  }
}