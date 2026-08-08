class VisionMetadata {
  const VisionMetadata({
    required this.imageHash,
    required this.caption,
    required this.scene,
    required this.objects,
    required this.keywords,
    required this.colors,
    required this.visibleText,
    required this.confidence,
    required this.model,
    required this.processingTimeMs,
  });

  final String imageHash;
  final String caption;
  final String scene;
  final List<String> objects;
  final List<String> keywords;
  final List<String> colors;
  final List<String> visibleText;
  final double confidence;
  final String model;
  final int processingTimeMs;

  factory VisionMetadata.fromJson(Map<String, dynamic> json) {
    return VisionMetadata(
      imageHash: json['image_hash'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      scene: json['scene'] as String? ?? '',
      objects: _toStringList(json['objects']),
      keywords: _toStringList(json['keywords']),
      colors: _toStringList(json['colors']),
      visibleText: _toStringList(json['visible_text']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      model: json['model'] as String? ?? '',
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
