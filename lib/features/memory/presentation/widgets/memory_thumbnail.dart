import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MemoryThumbnail extends StatelessWidget {
  const MemoryThumbnail({
    required this.assetId,
    super.key,
  });

  final String assetId;

  Future<Uint8List?> _loadThumbnail() async {
    final asset = await AssetEntity.fromId(assetId);

    return asset?.thumbnailDataWithSize(
      const ThumbnailSize.square(300),
      quality: 80,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _loadThumbnail(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;

        if (bytes == null) {
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.image_outlined),
            ),
          );
        }

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }
}