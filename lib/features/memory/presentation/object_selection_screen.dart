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
  State<ObjectSelectionScreen> createState() =>
      _ObjectSelectionScreenState();
}

enum _SelectionMode {
  tap,
  brush,
  erase,
}

class _ObjectSelectionScreenState extends State<ObjectSelectionScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _purple = Color(0xFF8B5CF6);

  final TransformationController _transformationController =
      TransformationController();

  final LocalSegmentationService _segmentationService =
      LocalSegmentationService();

  final List<List<Offset>> _strokes = <List<Offset>>[];

  List<Offset>? _activeStroke;

  ui.Image? _decodedImage;

  Offset? _selectedCanvasPoint;
  Offset? _selectedImagePoint;

  SegmentationResult? _segmentationResult;

  double _brushSize = 34;

  _SelectionMode _selectionMode = _SelectionMode.tap;

  bool _isLoadingImage = true;
  bool _isLoadingModels = true;
  bool _isSegmenting = false;

  @override
  void initState() {
    super.initState();

    _decodeImage();
    _initializeSegmentation();
  }

  Future<void> _initializeSegmentation() async {
    try {
      final message =
          await _segmentationService.debugInitialize();

      debugPrint(message);
      await _segmentationService.debugRunEncoder(
        widget.imageBytes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingModels = false;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'MobileSAM initialization failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingModels = false;
      });

      _showMessage(
        'Could not prepare object selection.',
      );
    }
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.imageBytes,
      );

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
      debugPrint(
        'Could not decode Object Eraser image: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingImage = false;
      });

      _showMessage(
        'Could not open this photo.',
      );
    }
  }

  void _setMode(_SelectionMode mode) {
    if (_isSegmenting) {
      return;
    }

    setState(() {
      _selectionMode = mode;
      _activeStroke = null;
    });
  }

  Future<void> _handleTap({
    required Offset localPosition,
    required Size canvasSize,
  }) async {
    if (_selectionMode != _SelectionMode.tap ||
        _isSegmenting) {
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
      _showMessage(
        'Tap directly on the photo.',
      );
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
      final result =
          await _segmentationService.segmentDetailedFromPoint(
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
      debugPrint(
        'MobileSAM decoder failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _showMessage(
        'Could not segment this object.',
      );
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

    if (imageRect == null ||
        !imageRect.contains(canvasPoint)) {
      return null;
    }

    final normalizedX =
        (canvasPoint.dx - imageRect.left) /
            imageRect.width;

    final normalizedY =
        (canvasPoint.dy - imageRect.top) /
            imageRect.height;

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

  void _startStroke(Offset point) {
    if (_selectionMode == _SelectionMode.tap ||
        _isSegmenting) {
      return;
    }

    setState(() {
      _activeStroke = <Offset>[point];

      if (_selectionMode ==
          _SelectionMode.brush) {
        _strokes.add(
          _activeStroke!,
        );
      }
    });
  }

  void _updateStroke(Offset point) {
    if (_activeStroke == null) {
      return;
    }

    setState(() {
      if (_selectionMode ==
          _SelectionMode.erase) {
        _eraseNear(point);
      } else if (_selectionMode ==
          _SelectionMode.brush) {
        _activeStroke!.add(point);
      }
    });
  }

  void _endStroke() {
    setState(() {
      _activeStroke = null;
    });
  }

  void _eraseNear(Offset point) {
    final eraseRadius =
        _brushSize * 0.7;

    _strokes.removeWhere(
      (stroke) {
        for (final strokePoint in stroke) {
          if ((strokePoint - point).distance <=
              eraseRadius) {
            return true;
          }
        }

        return false;
      },
    );
  }

  void _undo() {
    if (_isSegmenting) {
      return;
    }

    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });

      return;
    }

    if (_segmentationResult != null ||
        _selectedCanvasPoint != null) {
      setState(() {
        _segmentationResult = null;
        _selectedCanvasPoint = null;
        _selectedImagePoint = null;
      });
    }
  }

  void _clear() {
    if (_isSegmenting) {
      return;
    }

    setState(() {
      _strokes.clear();
      _activeStroke = null;
      _selectedCanvasPoint = null;
      _selectedImagePoint = null;
      _segmentationResult = null;
    });
  }

  Future<Uint8List?> _generateManualMask({
    required Size size,
  }) async {
    if (_strokes.isEmpty) {
      return null;
    }

    final recorder =
        ui.PictureRecorder();

    final canvas =
        Canvas(recorder);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.black,
    );

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = _brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.isEmpty) {
        continue;
      }

      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          _brushSize / 2,
          Paint()
            ..color = Colors.white,
        );

        continue;
      }

      final path = Path()
        ..moveTo(
          stroke.first.dx,
          stroke.first.dy,
        );

      for (
        var index = 1;
        index < stroke.length;
        index++
      ) {
        path.lineTo(
          stroke[index].dx,
          stroke[index].dy,
        );
      }

      canvas.drawPath(
        path,
        paint,
      );
    }

    final picture =
        recorder.endRecording();

    final image =
        await picture.toImage(
      size.width.ceil(),
      size.height.ceil(),
    );

    final byteData =
        await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();

    return byteData
        ?.buffer
        .asUint8List();
  }

  Future<void> _done(
    Size canvasSize,
  ) async {
    if (_isSegmenting) {
      return;
    }

    final automaticResult =
        _segmentationResult;

    if (automaticResult != null &&
        _strokes.isEmpty) {
      Navigator.of(context)
          .pop<ObjectSelectionResult>(
        ObjectSelectionResult(
          maskBytes:
              automaticResult.maskBytes,
          brushSize:
              _brushSize,
          selectedImagePoint:
              _selectedImagePoint,
        ),
      );

      return;
    }

    final manualMask =
        await _generateManualMask(
      size: canvasSize,
    );

    if (!mounted) {
      return;
    }

    if (manualMask == null) {
      _showMessage(
        'Tap an object or use the brush to select something first.',
      );

      return;
    }

    Navigator.of(context)
        .pop<ObjectSelectionResult>(
      ObjectSelectionResult(
        maskBytes: manualMask,
        brushSize: _brushSize,
        selectedImagePoint:
            _selectedImagePoint,
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
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
  Widget build(
    BuildContext context,
  ) {
    final isPreparing =
        _isLoadingImage ||
        _isLoadingModels;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Object Eraser',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed:
                _isSegmenting ||
                        (_strokes.isEmpty &&
                            _selectedCanvasPoint ==
                                null &&
                            _segmentationResult ==
                                null)
                    ? null
                    : _undo,
            icon: const Icon(
              Icons.undo_rounded,
            ),
          ),
          IconButton(
            tooltip:
                'Clear selection',
            onPressed:
                _isSegmenting ||
                        (_strokes.isEmpty &&
                            _selectedCanvasPoint ==
                                null &&
                            _segmentationResult ==
                                null)
                    ? null
                    : _clear,
            icon: const Icon(
              Icons
                  .delete_sweep_outlined,
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
            final canvasSize =
                Size(
              constraints.maxWidth,
              constraints.maxHeight -
                  150,
            );

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      12,
                      8,
                      12,
                      12,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        24,
                      ),
                      child: Container(
                        color:
                            Colors.black,
                        child: isPreparing
                            ? const _PreparingView()
                            : InteractiveViewer(
                                transformationController:
                                    _transformationController,
                                minScale: 1,
                                maxScale: 8,
                                panEnabled:
                                    _activeStroke ==
                                        null,
                                scaleEnabled:
                                    _selectionMode ==
                                        _SelectionMode
                                            .tap,
                                child:
                                    SizedBox(
                                  width:
                                      canvasSize
                                          .width,
                                  height:
                                      canvasSize
                                          .height,
                                  child:
                                      Stack(
                                    fit: StackFit
                                        .expand,
                                    children: [
                                      Image
                                          .memory(
                                        widget
                                            .imageBytes,
                                        fit: BoxFit
                                            .contain,
                                        gaplessPlayback:
                                            true,
                                      ),

                                      // Exact bitmap outline generated
                                      // from the same binary mask that
                                      // already aligned perfectly.
                                      if (_segmentationResult !=
                                          null)
                                        Positioned
                                            .fill(
                                          child:
                                              IgnorePointer(
                                            child:
                                                ImageFiltered(
                                              imageFilter:
                                                  ui.ImageFilter.blur(
                                                sigmaX:
                                                    1.2,
                                                sigmaY:
                                                    1.2,
                                              ),
                                              child:
                                                  Opacity(
                                                opacity:
                                                    0.45,
                                                child:
                                                    Image.memory(
                                                  _segmentationResult!
                                                      .outlineBytes,
                                                  fit: BoxFit
                                                      .contain,
                                                  filterQuality:
                                                      FilterQuality.none,
                                                  gaplessPlayback:
                                                      true,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      if (_segmentationResult !=
                                          null)
                                        Positioned
                                            .fill(
                                          child:
                                              IgnorePointer(
                                            child:
                                                Image.memory(
                                              _segmentationResult!
                                                  .outlineBytes,
                                              fit: BoxFit
                                                  .contain,
                                              filterQuality:
                                                  FilterQuality.none,
                                              gaplessPlayback:
                                                  true,
                                            ),
                                          ),
                                        ),

                                      GestureDetector(
                                        behavior:
                                            HitTestBehavior
                                                .opaque,
                                        onTapUp:
                                            (details) {
                                          _handleTap(
                                            localPosition:
                                                details
                                                    .localPosition,
                                            canvasSize:
                                                canvasSize,
                                          );
                                        },
                                        onPanStart:
                                            (details) {
                                          _startStroke(
                                            details
                                                .localPosition,
                                          );
                                        },
                                        onPanUpdate:
                                            (details) {
                                          _updateStroke(
                                            details
                                                .localPosition,
                                          );
                                        },
                                        onPanEnd:
                                            (_) {
                                          _endStroke();
                                        },
                                        child:
                                            CustomPaint(
                                          painter:
                                              _SelectionOverlayPainter(
                                            strokes:
                                                _strokes,
                                            brushSize:
                                                _brushSize,
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
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    18,
                    14,
                    18,
                    18,
                  ),
                  decoration:
                      const BoxDecoration(
                    color: _surface,
                    borderRadius:
                        BorderRadius
                            .vertical(
                      top:
                          Radius.circular(
                        28,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                                _ToolButton(
                              icon: Icons
                                  .touch_app_rounded,
                              label:
                                  'Select',
                              selected:
                                  _selectionMode ==
                                      _SelectionMode
                                          .tap,
                              onTap: () {
                                _setMode(
                                  _SelectionMode
                                      .tap,
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                _ToolButton(
                              icon: Icons
                                  .brush_rounded,
                              label:
                                  'Brush',
                              selected:
                                  _selectionMode ==
                                      _SelectionMode
                                          .brush,
                              onTap: () {
                                _setMode(
                                  _SelectionMode
                                      .brush,
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                _ToolButton(
                              icon: Icons
                                  .auto_fix_off_rounded,
                              label:
                                  'Erase',
                              selected:
                                  _selectionMode ==
                                      _SelectionMode
                                          .erase,
                              onTap: () {
                                _setMode(
                                  _SelectionMode
                                      .erase,
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                FilledButton
                                    .icon(
                              onPressed:
                                  isPreparing ||
                                          _isSegmenting
                                      ? null
                                      : () {
                                          _done(
                                            canvasSize,
                                          );
                                        },
                              style:
                                  FilledButton
                                      .styleFrom(
                                backgroundColor:
                                    _purple,
                                foregroundColor:
                                    Colors.white,
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 14,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    16,
                                  ),
                                ),
                              ),
                              icon:
                                  _isSegmenting
                                      ? const SizedBox(
                                          width:
                                              16,
                                          height:
                                              16,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons
                                              .auto_awesome_rounded,
                                          size:
                                              17,
                                        ),
                              label: Text(
                                _isSegmenting
                                    ? 'Selecting'
                                    : _segmentationResult !=
                                            null
                                        ? 'Remove'
                                        : 'Next',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectionMode !=
                          _SelectionMode
                              .tap) ...[
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .circle_outlined,
                              color: Colors
                                  .white54,
                              size: 17,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              'Brush size',
                              style:
                                  TextStyle(
                                color: Colors
                                    .white70,
                                fontSize:
                                    12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                                  Slider(
                                value:
                                    _brushSize,
                                min: 12,
                                max: 90,
                                activeColor:
                                    _purple,
                                inactiveColor:
                                    Colors
                                        .white12,
                                onChanged:
                                    _isSegmenting
                                        ? null
                                        : (value) {
                                            setState(
                                              () {
                                                _brushSize =
                                                    value;
                                              },
                                            );
                                          },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_selectionMode ==
                              _SelectionMode
                                  .tap &&
                          _selectedImagePoint !=
                              null) ...[
                        const SizedBox(
                          height: 13,
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            if (_isSegmenting)
                              const SizedBox(
                                width: 15,
                                height: 15,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      _purple,
                                ),
                              )
                            else
                              const Icon(
                                Icons
                                    .check_circle_rounded,
                                color:
                                    Color(
                                  0xFF4ADE80,
                                ),
                                size: 17,
                              ),
                            const SizedBox(
                              width: 7,
                            ),
                            Text(
                              _isSegmenting
                                  ? 'Detecting object...'
                                  : _segmentationResult !=
                                          null
                                      ? 'Object selected'
                                      : 'Object point selected',
                              style:
                                  TextStyle(
                                color: Colors
                                    .white
                                    .withValues(
                                  alpha: 0.7,
                                ),
                                fontSize:
                                    12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _PreparingView extends StatelessWidget {
  const _PreparingView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color:
                Color(0xFF8B5CF6),
          ),
          SizedBox(
            height: 14,
          ),
          Text(
            'Preparing object selection...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionOverlayPainter
    extends CustomPainter {
  const _SelectionOverlayPainter({
    required this.strokes,
    required this.brushSize,
    required this.selectedPoint,
    required this.isSegmenting,
    required this.hasAutomaticSelection,
  });

  final List<List<Offset>> strokes;
  final double brushSize;
  final Offset? selectedPoint;
  final bool isSegmenting;
  final bool hasAutomaticSelection;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    _paintManualStrokes(
      canvas,
    );

    _paintTapPoint(
      canvas,
    );
  }

  void _paintManualStrokes(
    Canvas canvas,
  ) {
    final strokePaint = Paint()
      ..color =
          const Color(0xAA8B5CF6)
      ..strokeWidth = brushSize
      ..strokeCap =
          StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round
      ..style =
          PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) {
        continue;
      }

      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          brushSize / 2,
          Paint()
            ..color =
                const Color(
              0xAA8B5CF6,
            )
            ..style =
                PaintingStyle.fill,
        );

        continue;
      }

      final path = Path()
        ..moveTo(
          stroke.first.dx,
          stroke.first.dy,
        );

      for (
        var index = 1;
        index < stroke.length;
        index++
      ) {
        path.lineTo(
          stroke[index].dx,
          stroke[index].dy,
        );
      }

      canvas.drawPath(
        path,
        strokePaint,
      );
    }
  }

  void _paintTapPoint(
    Canvas canvas,
  ) {
    final point =
        selectedPoint;

    if (point == null) {
      return;
    }

    // Once MobileSAM finishes, hide the tap indicator
    // and leave only the exact object outline.
    if (hasAutomaticSelection &&
        !isSegmenting) {
      return;
    }

    canvas.drawCircle(
      point,
      isSegmenting
          ? 21
          : 18,
      Paint()
        ..color =
            Colors.black.withValues(
          alpha: 0.42,
        )
        ..style =
            PaintingStyle.fill,
    );

    canvas.drawCircle(
      point,
      isSegmenting
          ? 15
          : 13,
      Paint()
        ..color =
            isSegmenting
                ? const Color(
                    0xFFC4B5FD,
                  )
                : Colors.white
        ..strokeWidth = 2
        ..style =
            PaintingStyle.stroke,
    );

    canvas.drawCircle(
      point,
      4,
      Paint()
        ..color =
            const Color(
          0xFFC4B5FD,
        )
        ..style =
            PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SelectionOverlayPainter
        oldDelegate,
  ) {
    return oldDelegate.strokes !=
            strokes ||
        oldDelegate.brushSize !=
            brushSize ||
        oldDelegate.selectedPoint !=
            selectedPoint ||
        oldDelegate.isSegmenting !=
            isSegmenting ||
        oldDelegate.hasAutomaticSelection !=
            hasAutomaticSelection;
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: selected
          ? const Color(
              0xFF312052,
            )
          : const Color(
              0xFF141B2D,
            ),
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 6,
            vertical: 13,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(
                        0xFFC4B5FD,
                      )
                    : Colors.white70,
                size: 21,
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors
                          .white60,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ObjectSelectionResult {
  const ObjectSelectionResult({
    required this.maskBytes,
    required this.brushSize,
    this.selectedImagePoint,
  });

  final Uint8List maskBytes;
  final double brushSize;

  final Offset? selectedImagePoint;
}