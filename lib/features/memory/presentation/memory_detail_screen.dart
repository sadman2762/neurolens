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
  static const Color _backgroundColor = Color(0xFF050816);
  static const Color _surfaceColor = Color(0xFF0D1321);
  static const Color _purple = Color(0xFF8B5CF6);

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
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFF87171),
            size: 32,
          ),
          title: const Text(
            'Remove this image?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This image will be removed from NeuroLens. '
            'The original photo will remain in your phone gallery.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
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

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String tooltip,
  }) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: icon,
        color: Colors.white,
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          _buildActionButton(
            onPressed:
                _isSharing || _isDeleting ? null : _shareImage,
            tooltip: 'Share image',
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.share_outlined,
                    size: 21,
                  ),
          ),
          _buildActionButton(
            onPressed:
                _isSharing || _isDeleting ? null : _confirmDelete,
            tooltip: 'Remove from NeuroLens',
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: Color(0xFFF87171),
                  ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<Uint8List?>(
              future: _imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _purple,
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
          ),
        ),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                size: 34,
                color: Color(0xFFC084FC),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}