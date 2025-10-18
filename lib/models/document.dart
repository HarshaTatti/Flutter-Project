/// Model to represent a document loaded by the user
class Document {
  final String id;
  final String name;
  final String content;
  final String? filePath; // Absolute path if saved locally (non-web)
  final int? sizeBytes; // File size in bytes if available
  final DateTime loadedAt;

  Document({
    required this.id,
    required this.name,
    required this.content,
    this.filePath,
    this.sizeBytes,
    DateTime? loadedAt,
  }) : loadedAt = loadedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'filePath': filePath,
      'sizeBytes': sizeBytes,
      'loadedAt': loadedAt.toIso8601String(),
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      name: json['name'],
      content: json['content'],
      filePath: json['filePath'],
      sizeBytes: json['sizeBytes'],
      loadedAt: DateTime.parse(json['loadedAt']),
    );
  }
}
