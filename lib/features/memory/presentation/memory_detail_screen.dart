import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/data/image_edit_api_service.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/presentation/ai_tools_bottom_sheet.dart';
import 'package:neurolens/features/memory/presentation/manual_object_eraser_screen.dart';
import 'package:neurolens/features/memory/presentation/object_selection_screen.dart';
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
  static const Color _cardColor = Color(0xD9141B2D);
  static const Color _danger = Color(0xFFEF4444);

  late final Future<Uint8List?> _imageFuture;

  final ImageEditApiService _imageEditApiService = ImageEditApiService();

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
  // AI TOOLS
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
      _showMessage('Could not load this photo for AI editing.');

      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1321),
      builder: (bottomSheetContext) {
        return AiToolsBottomSheet(
          onObjectEraser: () async {
            Navigator.of(bottomSheetContext).pop();

            await _openAutomaticObjectEraser(imageBytes);
          },
          onManualEraser: () async {
            Navigator.of(bottomSheetContext).pop();

            await _openManualObjectEraser(imageBytes);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AUTOMATIC OBJECT ERASER
  // ---------------------------------------------------------------------------

  Future<void> _openAutomaticObjectEraser(Uint8List imageBytes) async {
    final result = await Navigator.of(context).push<ObjectSelectionResult>(
      MaterialPageRoute<ObjectSelectionResult>(
        builder: (_) =>
            ObjectSelectionScreen(imageBytes: imageBytes, title: widget.title),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    await _removeSelectedObject(
      imageBytes: imageBytes,
      maskBytes: result.maskBytes,
    );
  }

  Future<void> _removeSelectedObject({
    required Uint8List imageBytes,
    required Uint8List maskBytes,
  }) async {
    if (_isAiEditing) {
      return;
    }

    setState(() {
      _isAiEditing = true;
    });

    _showAiEditingDialog();

    try {
      final editedBytes = await _imageEditApiService.removeObject(
        imageBytes: imageBytes,
        maskBytes: maskBytes,
      );

      if (!mounted) {
        return;
      }

      _closeAiEditingDialog();

      if (editedBytes.isEmpty) {
        _showMessage('The AI service returned an empty image.');

        return;
      }

      //
      // IMPORTANT:
      // Replace the existing NeuroLens memory instead
      // of importing another copy into NeuroLens.
      //
      await _replaceWithAiEditedImage(editedBytes);
    } on ImageEditException catch (error) {
      if (!mounted) {
        return;
      }

      _closeAiEditingDialog();

      _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint('AI object removal error: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _closeAiEditingDialog();

      _showMessage('Could not remove the object.');
    } finally {
      if (mounted) {
        setState(() {
          _isAiEditing = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // MANUAL OBJECT ERASER
  // ---------------------------------------------------------------------------

  Future<void> _openManualObjectEraser(Uint8List imageBytes) async {
    final editedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (_) => ManualObjectEraserScreen(
          imageBytes: imageBytes,
          title: widget.title,
        ),
      ),
    );

    if (!mounted || editedBytes == null || editedBytes.isEmpty) {
      return;
    }

    //
    // Same replacement behavior as automatic eraser.
    //
    await _replaceWithAiEditedImage(editedBytes);
  }

  // ---------------------------------------------------------------------------
  // REPLACE CURRENT NEUROLENS IMAGE WITH AI IMAGE
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
          'Gallery permission is required to save the AI-edited photo.',
        );

        return;
      }

      //
      // Read the existing NeuroLens memory before replacing it.
      //
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

      //
      // Save AI result as a NEW physical gallery image.
      //
      // We deliberately do NOT delete the original gallery image.
      //
      final savedAsset = await PhotoManager.editor.saveImage(
        editedBytes,
        title: fileName,
        filename: fileName,
      );

      final newAssetId = savedAsset.id;

      if (newAssetId.isEmpty) {
        throw StateError('The edited gallery image has no asset ID.');
      }

      //
      // Replace the old NeuroLens DB record.
      //
      // This preserves:
      //
      // - original title
      // - favorite state
      // - original createdAt
      //
      // But changes:
      //
      // old gallery asset ID
      //          ↓
      // new AI-generated gallery asset ID
      //
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

      //
      // Replace the current detail route itself.
      //
      // Without this, this screen would still point at
      // widget.assetId (the OLD gallery asset).
      //
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              MemoryDetailScreen(assetId: newAssetId, title: oldMemory.title),
        ),
      );

      _showMessage('AI edit saved and replaced in NeuroLens.');
    } catch (error, stackTrace) {
      debugPrint('AI image replacement error: $error');

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
  // AI LOADING DIALOG
  // ---------------------------------------------------------------------------

  void _showAiEditingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Color(0xFF0D1321),
            surfaceTintColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  SizedBox(height: 20),
                  Text(
                    'Removing object...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'AI is rebuilding the background.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeAiEditingDialog() {
    if (!mounted) {
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  // ---------------------------------------------------------------------------
  // NORMAL PHOTO EDITOR
  //
  // This keeps the previous behavior:
  // save as another edited copy in NeuroLens.
  // ---------------------------------------------------------------------------

  Future<void> _openEditor() async {
    if (_isSharing || _isDeleting || _isSavingEdit || _isAiEditing) {
      return;
    }

    final editedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (_) =>
            PhotoEditorScreen(assetId: widget.assetId, title: widget.title),
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

  @override
  void dispose() {
    _imageEditApiService.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(memoryTimelineProvider);

    final memory = timeline.maybeWhen(data: _findMemory, orElse: () => null);

    final extractedText = memory?.content?.trim() ?? '';

    final createdAt = memory?.createdAt;

    final isBusy = _isSharing || _isDeleting || _isSavingEdit || _isAiEditing;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoBackground(
                  imageFuture: _imageFuture,
                  assetId: widget.assetId,
                ),

                const _BottomGradient(),

                Positioned(
                  top: 16,
                  left: 14,
                  child: _CircleActionButton(
                    tooltip: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onPressed: isBusy
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                  ),
                ),

                Positioned(
                  top: 16,
                  right: 14,
                  child: Row(
                    children: [
                      _CircleActionButton(
                        tooltip: memory?.isFavorite == true
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        onPressed:
                            memory == null || _isUpdatingFavorite || isBusy
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
                                size: 21,
                              ),
                      ),

                      const SizedBox(width: 9),

                      _CircleActionButton(
                        tooltip: 'Edit photo',
                        onPressed: isBusy ? null : _openEditor,
                        child: _isSavingEdit
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),

                      const SizedBox(width: 9),

                      _CircleActionButton(
                        tooltip: 'AI tools',
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
                                size: 21,
                              ),
                      ),

                      const SizedBox(width: 9),

                      _CircleActionButton(
                        tooltip: 'Share',
                        onPressed: isBusy ? null : _shareImage,
                        child: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.ios_share_rounded,
                                color: Colors.white,
                                size: 21,
                              ),
                      ),

                      const SizedBox(width: 9),

                      _CircleActionButton(
                        tooltip: 'More',
                        icon: Icons.more_horiz_rounded,
                        onPressed: isBusy
                            ? null
                            : () {
                                _showPhotoOptions(extractedText: extractedText);
                              },
                      ),
                    ],
                  ),
                ),

                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _DetailsPanel(
                    title: widget.title,
                    createdAt: createdAt,
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
                    onCopyPressed: () {
                      _copyExtractedText(extractedText);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoOptions({required String extractedText}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0D1321),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFFC4B5FD),
                  ),
                  title: const Text(
                    'Edit photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();

                    _openEditor();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.text_snippet_outlined,
                    color: Color(0xFFC4B5FD),
                  ),
                  title: const Text(
                    'Copy extracted text',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  enabled: extractedText.trim().isNotEmpty,
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();

                    _copyExtractedText(extractedText);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.ios_share_rounded,
                    color: Color(0xFF93C5FD),
                  ),
                  title: const Text(
                    'Share photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();

                    _shareImage();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFF87171),
                  ),
                  title: const Text(
                    'Remove from NeuroLens',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();

                    _confirmDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
            color: Colors.black,
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
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.48, 0.73, 1],
            colors: [
              Colors.black.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.02),
              Colors.black.withValues(alpha: 0.34),
              Colors.black.withValues(alpha: 0.88),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.title,
    required this.createdAt,
    required this.extractedText,
    required this.isSharing,
    required this.isDeleting,
    required this.onEditPressed,
    required this.onOcrPressed,
    required this.onSharePressed,
    required this.onDeletePressed,
    required this.onCopyPressed,
    required this.isSavingEdit,
  });

  final String title;
  final DateTime? createdAt;
  final String extractedText;

  final bool isSharing;
  final bool isDeleting;
  final bool isSavingEdit;

  final VoidCallback onEditPressed;
  final VoidCallback onOcrPressed;
  final VoidCallback onSharePressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onCopyPressed;

  @override
  Widget build(BuildContext context) {
    final isBusy = isSharing || isDeleting || isSavingEdit;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
          decoration: BoxDecoration(
            color: _MemoryDetailScreenState._surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _metadataText(createdAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PillActionButton(
                      icon: Icons.tune_rounded,
                      label: 'Edit',
                      foregroundColor: const Color(0xFFC4B5FD),
                      backgroundColor: const Color(
                        0xFF36235E,
                      ).withValues(alpha: 0.8),
                      onPressed: isBusy ? null : onEditPressed,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _PillActionButton(
                      icon: Icons.document_scanner_outlined,
                      label: 'OCR',
                      onPressed: extractedText.isEmpty ? null : onOcrPressed,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _PillActionButton(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      onPressed: isBusy ? null : onSharePressed,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _PillActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      foregroundColor: const Color(0xFFFF4D67),
                      backgroundColor: const Color(
                        0xFF581A29,
                      ).withValues(alpha: 0.56),
                      onPressed: isBusy ? null : onDeletePressed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 11),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 14, 13, 15),
          decoration: BoxDecoration(
            color: _MemoryDetailScreenState._cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted text',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      extractedText.isEmpty
                          ? 'No readable text was detected in this photo.'
                          : extractedText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              IconButton(
                tooltip: 'Copy text',
                onPressed: extractedText.isEmpty ? null : onCopyPressed,
                icon: Icon(
                  Icons.content_copy_rounded,
                  size: 18,
                  color: extractedText.isEmpty
                      ? Colors.white24
                      : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _metadataText(DateTime? createdAt) {
    if (createdAt == null) {
      return 'Image';
    }

    final date = createdAt.toLocal();

    final now = DateTime.now();

    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    final dateLabel = isToday
        ? 'Today'
        : '${date.day}/${date.month}/${date.year}';

    return 'Image  •  $dateLabel, $hour:$minute $period';
  }
}

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
          width: 42,
          height: 42,
          child: Center(
            child: Tooltip(
              message: tooltip,
              child: child ?? Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled
                    ? foregroundColor
                    : foregroundColor.withValues(alpha: 0.35),
                size: 16,
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
                    fontSize: 11,
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

class _ImageErrorView extends StatelessWidget {
  const _ImageErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
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
