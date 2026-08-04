class Memory {
  final String id;
  final String type;
  final String title;
  final String? originalPath;
  final DateTime createdAt;

  const Memory({
    required this.id,
    required this.type,
    required this.title,
    this.originalPath,
    required this.createdAt,
  });
}