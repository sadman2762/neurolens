class Memory {
  const Memory({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.content,
    this.embedding,
    this.originalPath,
    this.visionCaption,
    this.visionScene,
    this.visionObjects,
    this.visionKeywords,
    this.visionColors,
    this.visionModel,
    this.visionImageHash,
    this.visionProcessedAt,
    this.isFavorite = false,
  });

  final String id;
  final String type;
  final String title;
  final String? content;
  final String? embedding;
  final String? originalPath;

  final String? visionCaption;
  final String? visionScene;
  final String? visionObjects;
  final String? visionKeywords;
  final String? visionColors;
  final String? visionModel;
  final String? visionImageHash;
  final DateTime? visionProcessedAt;

  final bool isFavorite;
  final DateTime createdAt;
}
