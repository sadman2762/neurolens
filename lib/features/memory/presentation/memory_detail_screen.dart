import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/presentation/ai_tools_bottom_sheet.dart';
import 'package:neurolens/features/memory/presentation/screens/doodle_editor_screen.dart';
import 'package:neurolens/features/memory/presentation/object_eraser_screen.dart';
import 'package:neurolens/features/memory/presentation/photo_editor_screen.dart';
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
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  static const Color _backgroundColor = Color(0xFF050816);
  static const Color _surfaceColor = Color(0xE60D1321);
  static const Color _danger = Color(0xFFEF4444);

  late final Future<Uint8List?> _imageFuture;

  bool _isSharing = false;
  bool _isDeleting = false;
  bool _isSavingEdit = false;
  bool _isUpdatingFavorite = false;
  bool _isAiEditing = false;

  @override
  void initState() {
    super.initState();

    _imageFuture = _loadImage();
  }

  Future<Uint8List?> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);

    return asset?.originBytes;
  }

  // ---------------------------------------------------------------------------
  // ADVANCED TOOLS
  // ---------------------------------------------------------------------------

  Future<void> _openAiTools() async {
    if (_isAiEditing || _isSharing || _isDeleting || _isSavingEdit) {
      return;
    }

    final imageBytes = await _imageFuture;

    if (!mounted) {
      return;
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      _showMessage('Could not load this photo for editing.');

      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1321),
      builder: (bottomSheetContext) {
        return AiToolsBottomSheet(
          onObjectEraser: () {
            Navigator.of(bottomSheetContext).pop();

            _openObjectEraser(imageBytes);
          },
          onDoodles: () {
            Navigator.of(bottomSheetContext).pop();

            _openDoodles(imageBytes);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UNIFIED OBJECT ERASER
  // ---------------------------------------------------------------------------

  Future<void> _openObjectEraser(Uint8List imageBytes) async {
    if (_isAiEditing || _isSavingEdit) {
      return;
    }

    setState(() {
      _isAiEditing = true;
    });

    try {
      final editedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) {
            return ObjectEraserScreen(
              imageBytes: imageBytes,
              title: widget.title,
            );
          },
        ),
      );

      if (!mounted) {
        return;
      }

      if (editedBytes == null || editedBytes.isEmpty) {
        return;
      }

      await _replaceWithAiEditedImage(editedBytes);
    } catch (error, stackTrace) {
      debugPrint('Unified Object Eraser error: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage('Could not finish the Object Eraser edit.');
    } finally {
      if (mounted) {
        setState(() {
          _isAiEditing = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DOODLES
  // ---------------------------------------------------------------------------

  Future<void> _openDoodles(Uint8List imageBytes) async {
    if (_isAiEditing || _isSavingEdit) {
      return;
    }

    setState(() {
      _isAiEditing = true;
    });

    try {
      final editedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) {
            return DoodleEditorScreen(
              imageBytes: imageBytes,
              title: widget.title,
            );
          },
        ),
      );

      if (!mounted) {
        return;
      }

      if (editedBytes == null || editedBytes.isEmpty) {
        return;
      }

      await _replaceWithAiEditedImage(editedBytes);
    } catch (error, stackTrace) {
      debugPrint('Doodle editor error: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage('Could not finish the Doodles edit.');
    } finally {
      if (mounted) {
        setState(() {
          _isAiEditing = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // REPLACE CURRENT NEUROLENS IMAGE WITH ADVANCED EDIT
  // ---------------------------------------------------------------------------

  Future<void> _replaceWithAiEditedImage(Uint8List editedBytes) async {
    if (_isSavingEdit) {
      return;
    }

    setState(() {
      _isSavingEdit = true;
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (!permission.hasAccess) {
        _showMessage(
          'Gallery permission is required to save the edited photo.',
        );

        return;
      }

      final repository = ref.read(memoryRepositoryProvider);

      final oldMemory = await repository.getMemoryById(widget.assetId);

      if (oldMemory == null) {
        _showMessage('Could not find the current NeuroLens memory.');

        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final cleanTitle = oldMemory.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');

      final fileName = cleanTitle.isEmpty
          ? 'neurolens_ai_$timestamp.png'
          : '${cleanTitle}_ai_$timestamp.png';

      final savedAsset = await PhotoManager.editor.saveImage(
        editedBytes,
        title: fileName,
        filename: fileName,
      );

      final newAssetId = savedAsset.id;

      if (newAssetId.isEmpty) {
        throw StateError('The edited gallery image has no asset ID.');
      }

      await repository.replaceImageMemory(
        oldId: oldMemory.id,
        newId: newAssetId,
        title: oldMemory.title,
        createdAt: oldMemory.createdAt,
        isFavorite: oldMemory.isFavorite,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) {
            return MemoryDetailScreen(
              assetId: newAssetId,
              title: oldMemory.title,
            );
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Advanced image replacement error: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage('Could not replace the image: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingEdit = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // NORMAL PHOTO EDITOR
  // ---------------------------------------------------------------------------

  Future<void> _openEditor() async {
    if (_isSharing || _isDeleting || _isSavingEdit || _isAiEditing) {
      return;
    }

    final editedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (_) {
          return PhotoEditorScreen(
            assetId: widget.assetId,
            title: widget.title,
          );
        },
      ),
    );

    if (!mounted || editedBytes == null || editedBytes.isEmpty) {
      return;
    }

    await _saveEditedCopy(editedBytes);
  }

  Future<void> _saveEditedCopy(Uint8List editedBytes) async {
    if (_isSavingEdit) {
      return;
    }

    setState(() {
      _isSavingEdit = true;
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (!permission.hasAccess) {
        _showMessage(
          'Gallery permission is required to save the edited photo.',
        );

        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final cleanTitle = widget.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');

      final fileName = cleanTitle.isEmpty
          ? 'neurolens_edit_$timestamp.png'
          : '${cleanTitle}_edited_$timestamp.png';

      final savedAsset = await PhotoManager.editor.saveImage(
        editedBytes,
        title: fileName,
        filename: fileName,
      );

      final importedCount = await ref
          .read(photoImportServiceProvider)
          .importPhotos(selectedAssets: [savedAsset]);

      if (!mounted) {
        return;
      }

      if (importedCount == 1) {
        _showMessage('Edited copy saved, indexed and added to NeuroLens.');
      } else {
        _showMessage('Edited copy was saved to your gallery.');
      }
    } catch (error, stackTrace) {
      debugPrint('Edited photo save error: $error');

      debugPrintStack(stackTrace: stackTrace);

      _showMessage('Could not save the edited photo: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingEdit = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // FAVORITE
  // ---------------------------------------------------------------------------

  Future<void> _toggleFavorite(Memory memory) async {
    if (_isUpdatingFavorite) {
      return;
    }

    setState(() {
      _isUpdatingFavorite = true;
    });

    try {
      await ref.read(memoryRepositoryProvider).toggleMemoryFavorite(memory);
    } catch (error) {
      _showMessage('Could not update favorite: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SHARE
  // ---------------------------------------------------------------------------

  Future<void> _shareImage() async {
    if (_isSharing || _isDeleting || _isAiEditing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final asset = await AssetEntity.fromId(widget.assetId);

      if (asset == null) {
        _showMessage('This image is no longer available.');

        return;
      }

      final imageFile = await asset.originFile ?? await asset.file;

      if (imageFile == null || !await imageFile.exists()) {
        _showMessage('Could not access this image.');

        return;
      }

      if (!mounted) {
        return;
      }

      final renderBox = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imageFile.path, name: widget.title)],
          subject: widget.title,
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } catch (error) {
      _showMessage('Could not share this image: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // OCR COPY
  // ---------------------------------------------------------------------------

  Future<void> _copyExtractedText(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      _showMessage('No extracted text is available.');

      return;
    }

    await Clipboard.setData(ClipboardData(text: cleanText));

    _showMessage('Extracted text copied.');
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete() async {
    if (_isSharing || _isDeleting || _isAiEditing) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1321),
          surfaceTintColor: Colors.transparent,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFF87171),
            size: 34,
          ),
          title: const Text(
            'Remove this photo?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'The photo will be removed from NeuroLens. '
            'The original image will remain in your phone gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
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
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _deleteImageMemory();
  }

  Future<void> _deleteImageMemory() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(memoryRepositoryProvider).deleteMemory(widget.assetId);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }

      _showMessage('Could not remove this photo: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Memory? _findMemory(List<Memory> memories) {
    for (final memory in memories) {
      if (memory.id == widget.assetId) {
        return memory;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(memoryTimelineProvider);

    final memory = timeline.maybeWhen(data: _findMemory, orElse: () => null);

    final extractedText = memory?.content?.trim() ?? '';

    final isBusy = _isSharing || _isDeleting || _isSavingEdit || _isAiEditing;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ===============================================================
            // TOP NAV
            //
            // The photo starts BELOW this row. Nothing here overlays the photo.
            // Edit and Share are intentionally only available from the 3-dot
            // menu.
            // ===============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                children: [
                  _CircleActionButton(
                    tooltip: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onPressed: isBusy
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                  ),

                  const Spacer(),

                  _CircleActionButton(
                    tooltip: memory?.isFavorite == true
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onPressed: memory == null || _isUpdatingFavorite || isBusy
                        ? null
                        : () {
                            _toggleFavorite(memory);
                          },
                    child: _isUpdatingFavorite
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            memory?.isFavorite == true
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                  ),

                  const SizedBox(width: 9),

                  _CircleActionButton(
                    tooltip: 'Advanced tools',
                    onPressed: isBusy ? null : _openAiTools,
                    child: _isAiEditing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFC4B5FD),
                            ),
                          )
                        : const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFC4B5FD),
                            size: 25,
                          ),
                  ),
                ],
              ),
            ),

            // ===============================================================
            // PHOTO
            //
            // The whole image is visible. BoxFit.contain preserves landscape
            // and portrait photos without cropping.
            // ===============================================================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: double.infinity,
                    color: _backgroundColor,
                    child: _PhotoBackground(
                      imageFuture: _imageFuture,
                      assetId: widget.assetId,
                    ),
                  ),
                ),
              ),
            ),

            // ===============================================================
            // ACTIONS ONLY
            //
            // No file name.
            // No date.
            // No extracted text box.
            // ===============================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: _DetailsPanel(
                extractedText: extractedText,
                isSharing: _isSharing,
                isDeleting: _isDeleting,
                isSavingEdit: _isSavingEdit || _isAiEditing,
                onEditPressed: _openEditor,
                onOcrPressed: () {
                  _copyExtractedText(extractedText);
                },
                onSharePressed: _shareImage,
                onDeletePressed: _confirmDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PHOTO BACKGROUND
// =============================================================================

class _PhotoBackground extends StatelessWidget {
  const _PhotoBackground({required this.imageFuture, required this.assetId});

  final Future<Uint8List?> imageFuture;
  final String assetId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: Color(0xFF050816),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const _ImageErrorView(
            message: 'This photo is no longer available.',
          );
        }

        return Hero(
          tag: 'memory-image-$assetId',
          child: Material(
            color: Colors.transparent,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: SizedBox.expand(
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// BOTTOM GRADIENT
// =============================================================================

// =============================================================================
// DETAILS PANEL
// =============================================================================

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.extractedText,
    required this.isSharing,
    required this.isDeleting,
    required this.onEditPressed,
    required this.onOcrPressed,
    required this.onSharePressed,
    required this.onDeletePressed,
    required this.isSavingEdit,
  });

  final String extractedText;

  final bool isSharing;
  final bool isDeleting;
  final bool isSavingEdit;

  final VoidCallback onEditPressed;
  final VoidCallback onOcrPressed;
  final VoidCallback onSharePressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final isBusy = isSharing || isDeleting || isSavingEdit;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: _MemoryDetailScreenState._surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillActionButton(
              icon: Icons.tune_rounded,
              label: 'Edit',
              foregroundColor: const Color(0xFFC4B5FD),
              backgroundColor: const Color(0xFF36235E).withValues(alpha: 0.72),
              onPressed: isBusy ? null : onEditPressed,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: _PillActionButton(
              icon: Icons.document_scanner_outlined,
              label: 'OCR',
              onPressed: extractedText.isEmpty || isBusy ? null : onOcrPressed,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: _PillActionButton(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              onPressed: isBusy ? null : onSharePressed,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: _PillActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              foregroundColor: const Color(0xFFFF667B),
              backgroundColor: const Color(0xFF581A29).withValues(alpha: 0.48),
              onPressed: isBusy ? null : onDeletePressed,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CIRCLE ACTION BUTTON
// =============================================================================

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: Tooltip(
              message: tooltip,
              child: child ?? Icon(icon, color: Colors.white, size: 25),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PILL BUTTON
// =============================================================================

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foregroundColor = Colors.white,
    this.backgroundColor = const Color(0xFF171E2C),
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled
                    ? foregroundColor
                    : foregroundColor.withValues(alpha: 0.35),
                size: 19,
              ),

              const SizedBox(width: 5),

              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled
                        ? foregroundColor
                        : foregroundColor.withValues(alpha: 0.35),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ERROR
// =============================================================================

class _ImageErrorView extends StatelessWidget {
  const _ImageErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050816),
      child: Center(
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
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
      ),
    );
  }
}
