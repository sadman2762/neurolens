import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/providers/memory_providers.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

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

  bool _isSharing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<Uint8List?> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);
    return asset?.originBytes;
  }

  Future<void> _shareImage() async {
    if (_isSharing || _isDeleting) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final asset = await AssetEntity.fromId(widget.assetId);

      if (asset == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This image is no longer available.'),
          ),
        );
        return;
      }

      final imageFile = await asset.originFile ?? await asset.file;

      if (imageFile == null || !await imageFile.exists()) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access this image.'),
          ),
        );
        return;
      }

      if (!mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              imageFile.path,
              name: widget.title,
            ),
          ],
          subject: widget.title,
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share this image: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (_isSharing || _isDeleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Remove this image?'),
          content: const Text(
            'This image will be removed from NeuroLens. '
            'The original photo will remain in your phone gallery.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor:
                    Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    await _deleteImageMemory();
  }

  Future<void> _deleteImageMemory() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(memoryRepositoryProvider)
          .deleteMemory(widget.assetId);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove this image: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _isSharing || _isDeleting ? null : _shareImage,
            tooltip: 'Share image',
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: _isSharing || _isDeleting ? null : _confirmDelete,
            tooltip: 'Remove from NeuroLens',
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<Uint8List?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (snapshot.hasError) {
            return const _ImageErrorView(
              message: 'Could not load this image.',
            );
          }

          final bytes = snapshot.data;

          if (bytes == null) {
            return const _ImageErrorView(
              message: 'This image is no longer available.',
            );
          }

          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 5,
            boundaryMargin: const EdgeInsets.all(40),
            child: Center(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImageErrorView extends StatelessWidget {
  const _ImageErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 56,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}