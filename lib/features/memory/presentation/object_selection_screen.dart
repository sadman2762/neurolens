import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/data/local_segmentation_service.dart';

class ObjectSelectionScreen extends StatefulWidget {
  const ObjectSelectionScreen({
    required this.imageBytes,
    required this.title,
    super.key,
  });

  final Uint8List imageBytes;
  final String title;

  @override
  State<ObjectSelectionScreen> createState() => _ObjectSelectionScreenState();
}

class _ObjectSelectionScreenState extends State<ObjectSelectionScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _purple = Color(0xFF8B5CF6);

  final TransformationController _transformationController =
      TransformationController();

  final LocalSegmentationService _segmentationService =
      LocalSegmentationService();

  ui.Image? _decodedImage;

  Offset? _selectedCanvasPoint;
  Offset? _selectedImagePoint;

  SegmentationResult? _segmentationResult;

  bool _isLoadingImage = true;
  bool _isLoadingModels = true;
  bool _isSegmenting = false;

  //
  // Prevent an interaction that was used for pinch/pan
  // from accidentally being interpreted as an object tap.
  //
  bool _wasTransformGesture = false;

  @override
  void initState() {
    super.initState();

    _decodeImage();
    _initializeSegmentation();
  }

  Future<void> _initializeSegmentation() async {
    try {
      final message = await _segmentationService.debugInitialize();

      debugPrint(message);

      await _segmentationService.debugRunEncoder(widget.imageBytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingModels = false;
      });
    } catch (error, stackTrace) {
      debugPrint('MobileSAM initialization failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingModels = false;
      });

      _showMessage('Could not prepare object selection.');
    }
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);

      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        codec.dispose();
        return;
      }

      setState(() {
        _decodedImage = frame.image;
        _isLoadingImage = false;
      });

      codec.dispose();
    } catch (error, stackTrace) {
      debugPrint('Could not decode Object Eraser image: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingImage = false;
      });

      _showMessage('Could not open this photo.');
    }
  }

  Future<void> _handleTap({
    required Offset localPosition,
    required Size canvasSize,
  }) async {
    if (_isSegmenting || _isLoadingImage || _isLoadingModels) {
      return;
    }

    final image = _decodedImage;

    if (image == null) {
      return;
    }

    final imagePoint = _mapCanvasPointToImage(
      canvasPoint: localPosition,
      canvasSize: canvasSize,
      imageSize: Size(
        image.width.toDouble(),
        image.height.toDouble(),
      ),
    );

    if (imagePoint == null) {
      _showMessage('Tap directly on the photo.');
      return;
    }

    setState(() {
      _selectedCanvasPoint = localPosition;
      _selectedImagePoint = imagePoint;
      _segmentationResult = null;
      _isSegmenting = true;
    });

    debugPrint(
      'Selected image coordinate: '
      'x=${imagePoint.dx.toStringAsFixed(1)}, '
      'y=${imagePoint.dy.toStringAsFixed(1)}',
    );

    try {
      final result = await _segmentationService.segmentDetailedFromPoint(
        imageBytes: widget.imageBytes,
        imagePoint: imagePoint,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _segmentationResult = result;
      });
    } catch (error, stackTrace) {
      debugPrint('MobileSAM decoder failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage('Could not select this object.');
    } finally {
      if (mounted) {
        setState(() {
          _isSegmenting = false;
        });
      }
    }
  }

  Offset? _mapCanvasPointToImage({
    required Offset canvasPoint,
    required Size canvasSize,
    required Size imageSize,
  }) {
    final imageRect = _calculateDisplayedImageRect(
      canvasSize: canvasSize,
      imageSize: imageSize,
    );

    if (imageRect == null || !imageRect.contains(canvasPoint)) {
      return null;
    }

    final normalizedX =
        (canvasPoint.dx - imageRect.left) / imageRect.width;

    final normalizedY =
        (canvasPoint.dy - imageRect.top) / imageRect.height;

    return Offset(
      normalizedX * imageSize.width,
      normalizedY * imageSize.height,
    );
  }

  Rect? _calculateDisplayedImageRect({
    required Size canvasSize,
    required Size imageSize,
  }) {
    if (canvasSize.width <= 0 ||
        canvasSize.height <= 0 ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return null;
    }

    final canvasAspect =
        canvasSize.width / canvasSize.height;

    final imageAspect =
        imageSize.width / imageSize.height;

    late final Size displayedSize;
    late final Offset origin;

    if (imageAspect > canvasAspect) {
      final width = canvasSize.width;
      final height = width / imageAspect;

      displayedSize = Size(
        width,
        height,
      );

      origin = Offset(
        0,
        (canvasSize.height - height) / 2,
      );
    } else {
      final height = canvasSize.height;
      final width = height * imageAspect;

      displayedSize = Size(
        width,
        height,
      );

      origin = Offset(
        (canvasSize.width - width) / 2,
        0,
      );
    }

    return origin & displayedSize;
  }

  void _undo() {
    if (_isSegmenting) {
      return;
    }

    setState(() {
      _segmentationResult = null;
      _selectedCanvasPoint = null;
      _selectedImagePoint = null;
    });
  }

  void _clear() {
    if (_isSegmenting) {
      return;
    }

    setState(() {
      _segmentationResult = null;
      _selectedCanvasPoint = null;
      _selectedImagePoint = null;
    });
  }

  void _done() {
    if (_isSegmenting) {
      return;
    }

    final result = _segmentationResult;

    if (result == null) {
      _showMessage('Tap an object first.');
      return;
    }

    Navigator.of(context).pop<ObjectSelectionResult>(
      ObjectSelectionResult(
        maskBytes: result.maskBytes,
        selectedImagePoint: _selectedImagePoint,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _segmentationService.clearImageCache();

    _decodedImage?.dispose();

    _transformationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPreparing =
        _isLoadingImage || _isLoadingModels;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Object Eraser',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo selection',
            onPressed:
                _isSegmenting ||
                    (_selectedCanvasPoint == null &&
                        _segmentationResult == null)
                ? null
                : _undo,
            icon: const Icon(
              Icons.undo_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Clear selection',
            onPressed:
                _isSegmenting ||
                    (_selectedCanvasPoint == null &&
                        _segmentationResult == null)
                ? null
                : _clear,
            icon: const Icon(
              Icons.delete_sweep_outlined,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxHeight - 130,
            );

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      12,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                      child: Container(
                        color: Colors.black,
                        child: isPreparing
                            ? const _PreparingView()
                            : InteractiveViewer(
                                transformationController:
                                    _transformationController,

                                //
                                // =========================================
                                // TWO-FINGER PINCH ZOOM
                                // =========================================
                                //
                                minScale: 1.0,
                                maxScale: 8.0,

                                //
                                // Allows moving around the image while
                                // zoomed.
                                //
                                panEnabled: true,

                                //
                                // Enables pinch-to-zoom.
                                //
                                scaleEnabled: true,

                                //
                                // Gives slightly more natural movement at
                                // the boundary when zoomed.
                                //
                                boundaryMargin:
                                    const EdgeInsets.all(
                                      40,
                                    ),

                                //
                                // Natural zoom sensitivity.
                                //
                                interactionEndFrictionCoefficient:
                                    0.0000135,

                                //
                                // Do not clip transformed image internally.
                                // Outer ClipRRect still keeps everything
                                // inside the photo area.
                                //
                                clipBehavior: Clip.none,

                                onInteractionStart: (
                                  details,
                                ) {
                                  _wasTransformGesture =
                                      false;
                                },

                                onInteractionUpdate: (
                                  details,
                                ) {
                                  //
                                  // scale != 1 means a real pinch gesture.
                                  //
                                  if ((details.scale - 1.0)
                                          .abs() >
                                      0.001) {
                                    _wasTransformGesture =
                                        true;
                                  }
                                },

                                child: SizedBox(
                                  width: canvasSize.width,
                                  height: canvasSize.height,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        widget.imageBytes,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                      ),

                                      //
                                      // SOFT MASK / OUTLINE GLOW
                                      //
                                      if (_segmentationResult !=
                                          null)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child:
                                                ImageFiltered(
                                              imageFilter:
                                                  ui.ImageFilter
                                                      .blur(
                                                sigmaX:
                                                    1.2,
                                                sigmaY:
                                                    1.2,
                                              ),
                                              child: Opacity(
                                                opacity:
                                                    0.45,
                                                child:
                                                    Image.memory(
                                                  _segmentationResult!
                                                      .outlineBytes,
                                                  fit: BoxFit
                                                      .contain,
                                                  filterQuality:
                                                      FilterQuality
                                                          .none,
                                                  gaplessPlayback:
                                                      true,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      //
                                      // SHARP MASK / OUTLINE
                                      //
                                      if (_segmentationResult !=
                                          null)
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            child:
                                                Image.memory(
                                              _segmentationResult!
                                                  .outlineBytes,
                                              fit: BoxFit
                                                  .contain,
                                              filterQuality:
                                                  FilterQuality
                                                      .none,
                                              gaplessPlayback:
                                                  true,
                                            ),
                                          ),
                                        ),

                                      //
                                      // SINGLE-FINGER OBJECT TAP
                                      //
                                      Positioned.fill(
                                        child:
                                            GestureDetector(
                                          behavior:
                                              HitTestBehavior
                                                  .translucent,

                                          onTapUp: (
                                            details,
                                          ) {
                                            //
                                            // If this interaction was
                                            // actually a pinch zoom,
                                            // ignore it as an object tap.
                                            //
                                            if (_wasTransformGesture) {
                                              _wasTransformGesture =
                                                  false;
                                              return;
                                            }

                                            _handleTap(
                                              localPosition:
                                                  details
                                                      .localPosition,
                                              canvasSize:
                                                  canvasSize,
                                            );
                                          },

                                          child:
                                              CustomPaint(
                                            painter:
                                                _SelectionPointPainter(
                                              selectedPoint:
                                                  _selectedCanvasPoint,
                                              isSegmenting:
                                                  _isSegmenting,
                                              hasAutomaticSelection:
                                                  _segmentationResult !=
                                                      null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                //
                // BOTTOM CONTROL PANEL
                //
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    18,
                  ),
                  decoration:
                      const BoxDecoration(
                    color: _surface,
                    borderRadius:
                        BorderRadius.vertical(
                      top: Radius.circular(
                        28,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  _isSegmenting
                                      ? 'Detecting object...'
                                      : _segmentationResult !=
                                              null
                                          ? 'Object selected'
                                          : 'Tap an object',
                                  style:
                                      const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  _isSegmenting
                                      ? 'NeuroLens is finding its exact shape.'
                                      : _segmentationResult !=
                                              null
                                          ? 'Tap another object to change the selection.'
                                          : 'Tap directly on the person or object you want to remove. Pinch with two fingers to zoom.',
                                  style:
                                      TextStyle(
                                    color: Colors.white
                                        .withValues(
                                      alpha: 0.48,
                                    ),
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                          FilledButton.icon(
                            onPressed:
                                isPreparing ||
                                        _isSegmenting ||
                                        _segmentationResult ==
                                            null
                                    ? null
                                    : _done,
                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  _purple,
                              foregroundColor:
                                  Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),
                            ),
                            icon: _isSegmenting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .auto_fix_high_rounded,
                                    size: 18,
                                  ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// PREPARING VIEW
// ============================================================================

class _PreparingView extends StatelessWidget {
  const _PreparingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(
              0xFF8B5CF6,
            ),
          ),
          SizedBox(
            height: 14,
          ),
          Text(
            'Preparing object selection...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 6,
          ),
          Text(
            'AI selection runs on your device.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SELECTION POINT
// ============================================================================

class _SelectionPointPainter extends CustomPainter {
  const _SelectionPointPainter({
    required this.selectedPoint,
    required this.isSegmenting,
    required this.hasAutomaticSelection,
  });

  final Offset? selectedPoint;
  final bool isSegmenting;
  final bool hasAutomaticSelection;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final point = selectedPoint;

    if (point == null) {
      return;
    }

    if (hasAutomaticSelection &&
        !isSegmenting) {
      return;
    }

    canvas.drawCircle(
      point,
      isSegmenting ? 21 : 18,
      Paint()
        ..color = Colors.black.withValues(
          alpha: 0.42,
        )
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      point,
      isSegmenting ? 15 : 13,
      Paint()
        ..color = isSegmenting
            ? const Color(
                0xFFC4B5FD,
              )
            : Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(
      point,
      4,
      Paint()
        ..color = const Color(
          0xFFC4B5FD,
        )
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SelectionPointPainter oldDelegate,
  ) {
    return oldDelegate.selectedPoint !=
            selectedPoint ||
        oldDelegate.isSegmenting !=
            isSegmenting ||
        oldDelegate.hasAutomaticSelection !=
            hasAutomaticSelection;
  }
}

// ============================================================================
// RESULT
// ============================================================================

class ObjectSelectionResult {
  const ObjectSelectionResult({
    required this.maskBytes,
    this.selectedImagePoint,
  });

  final Uint8List maskBytes;

  final Offset? selectedImagePoint;
}

