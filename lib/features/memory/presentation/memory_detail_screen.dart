import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/providers/memory_providers.dart';
import 'package:photo_manager/photo_manager.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({
    required this.assetId,
    required this.title,
    super.key,
  });

  final String assetId;
  final String title;

  @override
  ConsumerState<MemoryDetailScreen> createState() =>
      _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  late final Future<Uint8List?> _imageFuture;
  late final Future<String> _ocrFuture;

  @override
  void initState() {
    super.initState();

    _imageFuture = _loadImage();
    _ocrFuture = ref
        .read(ocrProcessingServiceProvider)
        .processImage(memoryId: widget.assetId);
  }

  Future<Uint8List?> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);
    return asset?.originBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Uint8List?>(
              future: _imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final bytes = snapshot.data;

                if (bytes == null) {
                  return const Center(
                    child: Text('This image is no longer available.'),
                  );
                }

                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          FutureBuilder<String>(
            future: _ocrFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }

              final text = snapshot.data?.trim() ?? '';

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  text.isEmpty
                      ? 'No text detected in this image.'
                      : 'Text extracted and saved locally.',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}