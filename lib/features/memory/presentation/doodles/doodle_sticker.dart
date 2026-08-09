import 'package:flutter/material.dart';

class DoodleSticker {
  const DoodleSticker({
    required this.id,
    required this.assetPath,
    required this.category,
    required this.position,
    required this.scale,
    required this.rotation,
    required this.zIndex,
    this.flipX = false,
    this.flipY = false,
  });

  final String id;
  final String assetPath;
  final String category;

  final Offset position;

  final double scale;
  final double rotation;

  final int zIndex;

  final bool flipX;
  final bool flipY;

  DoodleSticker copyWith({
    String? id,
    String? assetPath,
    String? category,
    Offset? position,
    double? scale,
    double? rotation,
    int? zIndex,
    bool? flipX,
    bool? flipY,
  }) {
    return DoodleSticker(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      category: category ?? this.category,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }
}