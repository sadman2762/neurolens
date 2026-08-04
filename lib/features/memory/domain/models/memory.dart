class Memory {
  final String id;
  final String type;
  final String title;
  final String? content;
  final String? embedding;
  final String? originalPath;
  final DateTime createdAt;

  const Memory({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    this.embedding,
    this.originalPath,
    required this.createdAt,
  });
}