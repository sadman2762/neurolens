import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/data/inpainting/offline_inpainting_service.dart';
import 'package:neurolens/features/memory/data/local_segmentation_service.dart';

enum _EraserMode {
  select,
  brush,
  protect,
}

enum _MaskActionType {
  selection,
  stroke,
  protectedSelection,
  protectedStroke,
}

class ObjectEraserScreen extends StatefulWidget {
  const ObjectEraserScreen({
    required this.imageBytes,
    required this.title,
    super.key,
  });

  final Uint8List imageBytes;
  final String title;

  @override
  State<ObjectEraserScreen> createState() =>
      _ObjectEraserScreenState();
}

class _ObjectEraserScreenState extends State<ObjectEraserScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _surfaceHighlight = Color(0xFF141B2D);

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleLight = Color(0xFFC4B5FD);

  static const Color _green = Color(0xFF22C55E);
  static const Color _protectGreen = Color(0xFF22C55E);
  static const Color _protectGreenLight = Color(0xFF86EFAC);

  // ===========================================================================
  // ZOOM
  // ===========================================================================

  final TransformationController _transformationController =
      TransformationController();

  static const double _minZoom = 1.0;
  static const double _maxZoom = 8.0;

  final LocalSegmentationService _segmentationService =
      LocalSegmentationService();

  final OfflineInpaintingService _offlineInpaintingService =
      OfflineInpaintingService();

  late Uint8List _currentImageBytes;

  ui.Image? _decodedImage;

  final List<SegmentationResult> _selectedMasks =
      <SegmentationResult>[];

  final List<List<Offset>> _strokes =
      <List<Offset>>[];

  final List<SegmentationResult> _protectedMasks =
      <SegmentationResult>[];

  final List<List<Offset>> _protectedStrokes =
      <List<Offset>>[];

  final List<_MaskAction> _history =
      <_MaskAction>[];

  List<Offset>? _activeStroke;
  List<Offset>? _activeProtectedStroke;

  _EraserMode _mode = _EraserMode.select;

  double _brushSize = 90;

  bool _isLoadingImage = true;
  bool _isPreparingSegmentation = true;
  bool _isSegmenting = false;
  bool _isRemoving = false;
  bool _hasEditedImage = false;

  @override
  void initState() {
    super.initState();

    _currentImageBytes = widget.imageBytes;

    _initialize();
  }

  Future<void> _initialize() async {
    await _decodeCurrentImage();

    if (!mounted) {
      return;
    }

    await _prepareSegmentation();
  }

  // ===========================================================================
  // ZOOM HELPERS
  // ===========================================================================

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // ===========================================================================
  // IMAGE
  // ===========================================================================

  Future<void> _decodeCurrentImage() async {
    try {
      final codec = await ui.instantiateImageCodec(
        _currentImageBytes,
      );

      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        codec.dispose();
        return;
      }

      final oldImage = _decodedImage;

      setState(() {
        _decodedImage = frame.image;
        _isLoadingImage = false;
      });

      oldImage?.dispose();
      codec.dispose();
    } catch (error, stackTrace) {
      debugPrint(
        'Object Eraser image decode failed: $error',
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

  Future<void> _prepareSegmentation() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPreparingSegmentation = true;
    });

    try {
      await _segmentationService.debugInitialize();

      _segmentationService.clearImageCache();

      await _segmentationService.debugRunEncoder(
        _currentImageBytes,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'MobileSAM preparation failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (mounted) {
        _showMessage(
          'Smart Select could not be prepared. '
          'You can still use the brush.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingSegmentation = false;
        });
      }
    }
  }

  // ===========================================================================
  // MODE
  // ===========================================================================

  void _setMode(
    _EraserMode mode,
  ) {
    if (_isRemoving ||
        _isSegmenting) {
      return;
    }

    if ((mode == _EraserMode.select ||
            mode == _EraserMode.protect) &&
        _isPreparingSegmentation) {
      _showMessage(
        'Smart Select is still preparing.',
      );

      return;
    }

    setState(() {
      _mode = mode;

      _activeStroke = null;
      _activeProtectedStroke = null;
    });
  }

  // ===========================================================================
  // SMART SELECT / SMART PROTECT
  // ===========================================================================

  Future<void> _handleTap({
    required Offset canvasPoint,
    required Size canvasSize,
  }) async {
    if ((_mode != _EraserMode.select &&
            _mode != _EraserMode.protect) ||
        _isRemoving ||
        _isSegmenting ||
        _isPreparingSegmentation ||
        _isLoadingImage) {
      return;
    }

    final imagePoint = _canvasPointToImage(
      canvasPoint: canvasPoint,
      canvasSize: canvasSize,
    );

    if (imagePoint == null) {
      _showMessage(
        'Tap directly on the photo.',
      );

      return;
    }

    final protectMode =
        _mode == _EraserMode.protect;

    setState(() {
      _isSegmenting = true;
    });

    try {
      final result = protectMode
          ? await _segmentationService.segmentProtectedSubject(
              imageBytes: _currentImageBytes,
              imagePoint: imagePoint,
            )
          : await _segmentationService.segmentDetailedFromPoint(
              imageBytes: _currentImageBytes,
              imagePoint: imagePoint,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        if (protectMode) {
          _protectedMasks.add(
            result,
          );

          _history.add(
            _MaskAction.protectedSelection(
              result,
            ),
          );
        } else {
          _selectedMasks.add(
            result,
          );

          _history.add(
            _MaskAction.selection(
              result,
            ),
          );
        }
      });
    } catch (error, stackTrace) {
      debugPrint(
        'MobileSAM selection failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        protectMode
            ? 'Could not protect this subject.'
            : 'Could not select this object.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSegmenting = false;
        });
      }
    }
  }

  // ===========================================================================
  // BRUSH
  // ===========================================================================

  void _startStroke({
    required Offset canvasPoint,
    required Size canvasSize,
  }) {
    if ((_mode != _EraserMode.brush &&
            _mode != _EraserMode.protect) ||
        _isRemoving ||
        _isLoadingImage ||
        _isSegmenting) {
      return;
    }

    final imagePoint = _canvasPointToImage(
      canvasPoint: canvasPoint,
      canvasSize: canvasSize,
    );

    if (imagePoint == null) {
      return;
    }

    final stroke = <Offset>[
      imagePoint,
    ];

    setState(() {
      if (_mode == _EraserMode.protect) {
        _activeProtectedStroke = stroke;

        _protectedStrokes.add(
          stroke,
        );

        _history.add(
          _MaskAction.protectedStroke(
            stroke,
          ),
        );
      } else {
        _activeStroke = stroke;

        _strokes.add(
          stroke,
        );

        _history.add(
          _MaskAction.stroke(
            stroke,
          ),
        );
      }
    });
  }

  void _updateStroke({
    required Offset canvasPoint,
    required Size canvasSize,
  }) {
    if ((_mode != _EraserMode.brush &&
            _mode != _EraserMode.protect) ||
        _isRemoving ||
        _isSegmenting) {
      return;
    }

    final stroke =
        _mode == _EraserMode.protect
            ? _activeProtectedStroke
            : _activeStroke;

    if (stroke == null) {
      return;
    }

    final imagePoint = _canvasPointToImage(
      canvasPoint: canvasPoint,
      canvasSize: canvasSize,
    );

    if (imagePoint == null) {
      return;
    }

    setState(() {
      stroke.add(
        imagePoint,
      );
    });
  }

  void _endStroke() {
    _activeStroke = null;
    _activeProtectedStroke = null;
  }

  // ===========================================================================
  // COORDINATES
  // ===========================================================================

  Offset? _canvasPointToImage({
    required Offset canvasPoint,
    required Size canvasSize,
  }) {
    final image = _decodedImage;

    if (image == null) {
      return null;
    }

    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final imageRect = _calculateDisplayedImageRect(
      canvasSize: canvasSize,
      imageSize: imageSize,
    );

    if (imageRect == null ||
        !imageRect.contains(
          canvasPoint,
        )) {
      return null;
    }

    final normalizedX =
        (canvasPoint.dx -
                imageRect.left) /
            imageRect.width;

    final normalizedY =
        (canvasPoint.dy -
                imageRect.top) /
            imageRect.height;

    return Offset(
      normalizedX *
          imageSize.width,
      normalizedY *
          imageSize.height,
    );
  }

  Offset _imagePointToCanvas({
    required Offset imagePoint,
    required Size canvasSize,
  }) {
    final image = _decodedImage!;

    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final imageRect = _calculateDisplayedImageRect(
      canvasSize: canvasSize,
      imageSize: imageSize,
    )!;

    return Offset(
      imageRect.left +
          (imagePoint.dx /
                  imageSize.width) *
              imageRect.width,
      imageRect.top +
          (imagePoint.dy /
                  imageSize.height) *
              imageRect.height,
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
        canvasSize.width /
        canvasSize.height;

    final imageAspect =
        imageSize.width /
        imageSize.height;

    late final Size displayedSize;
    late final Offset origin;

    if (imageAspect >
        canvasAspect) {
      final width =
          canvasSize.width;

      final height =
          width /
          imageAspect;

      displayedSize = Size(
        width,
        height,
      );

      origin = Offset(
        0,
        (canvasSize.height -
                height) /
            2,
      );
    } else {
      final height =
          canvasSize.height;

      final width =
          height *
          imageAspect;

      displayedSize = Size(
        width,
        height,
      );

      origin = Offset(
        (canvasSize.width -
                width) /
            2,
        0,
      );
    }

    return origin &
        displayedSize;
  }

  double _displayBrushSize(
    Size canvasSize,
  ) {
    final image = _decodedImage;

    if (image == null) {
      return _brushSize;
    }

    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final imageRect = _calculateDisplayedImageRect(
      canvasSize: canvasSize,
      imageSize: imageSize,
    );

    if (imageRect == null) {
      return _brushSize;
    }

    return _brushSize *
        imageRect.width /
        imageSize.width;
  }

  // ===========================================================================
  // HISTORY
  // ===========================================================================

  bool get _hasMask =>
      _selectedMasks.isNotEmpty ||
      _strokes.isNotEmpty;

  bool get _hasProtection =>
      _protectedMasks.isNotEmpty ||
      _protectedStrokes.isNotEmpty;

  bool get _hasAnyOverlay =>
      _hasMask ||
      _hasProtection;

  void _undo() {
    if (_isRemoving ||
        _isSegmenting ||
        _history.isEmpty) {
      return;
    }

    final last =
        _history.removeLast();

    setState(() {
      switch (last.type) {
        case _MaskActionType.selection:
          final selection =
              last.selection;

          if (selection != null) {
            _selectedMasks.remove(
              selection,
            );
          }
          break;

        case _MaskActionType.stroke:
          final stroke =
              last.stroke;

          if (stroke != null) {
            _strokes.remove(
              stroke,
            );
          }
          break;

        case _MaskActionType.protectedSelection:
          final selection =
              last.selection;

          if (selection != null) {
            _protectedMasks.remove(
              selection,
            );
          }
          break;

        case _MaskActionType.protectedStroke:
          final stroke =
              last.stroke;

          if (stroke != null) {
            _protectedStrokes.remove(
              stroke,
            );
          }
          break;
      }

      _activeStroke = null;
      _activeProtectedStroke = null;
    });
  }

  void _clearSelection() {
    if (_isRemoving ||
        _isSegmenting ||
        !_hasAnyOverlay) {
      return;
    }

    setState(() {
      _selectedMasks.clear();
      _strokes.clear();

      _protectedMasks.clear();
      _protectedStrokes.clear();

      _history.clear();

      _activeStroke = null;
      _activeProtectedStroke = null;
    });
  }

  // ===========================================================================
  // MASK CREATION
  // ===========================================================================

  Future<Uint8List> _createRemoveMask() async {
    final image = _decodedImage;

    if (image == null) {
      throw StateError(
        'Image is not available.',
      );
    }

    final recorder =
        ui.PictureRecorder();

    final canvas =
        Canvas(
      recorder,
    );

    final fullRect =
        Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    canvas.drawRect(
      fullRect,
      Paint()
        ..color =
            Colors.transparent,
    );

    // -----------------------------------------------------------------------
    // SMART REMOVE MASKS
    // -----------------------------------------------------------------------

    for (final result
        in _selectedMasks) {
      final maskImage =
          await _decodeUiImage(
        result.maskBytes,
      );

      try {
        canvas.drawImageRect(
          maskImage,
          Rect.fromLTWH(
            0,
            0,
            maskImage.width.toDouble(),
            maskImage.height.toDouble(),
          ),
          fullRect,
          Paint()
            ..blendMode =
                BlendMode.srcOver
            ..filterQuality =
                FilterQuality.none,
        );
      } finally {
        maskImage.dispose();
      }
    }

    // -----------------------------------------------------------------------
    // REMOVE BRUSH
    // -----------------------------------------------------------------------

    final brushPaint =
        Paint()
          ..color =
              Colors.white
          ..strokeWidth =
              _brushSize
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round
          ..style =
              PaintingStyle.stroke
          ..blendMode =
              BlendMode.srcOver;

    for (final stroke
        in _strokes) {
      _drawStroke(
        canvas: canvas,
        stroke: stroke,
        paint: brushPaint,
        brushSize: _brushSize,
      );
    }

    return _finishMask(
      recorder: recorder,
      width: image.width,
      height: image.height,
    );
  }

  Future<Uint8List?> _createProtectionMask() async {
    if (!_hasProtection) {
      return null;
    }

    final image = _decodedImage;

    if (image == null) {
      throw StateError(
        'Image is not available.',
      );
    }

    final recorder =
        ui.PictureRecorder();

    final canvas =
        Canvas(
      recorder,
    );

    final fullRect =
        Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    canvas.drawRect(
      fullRect,
      Paint()
        ..color =
            Colors.transparent,
    );

    // -----------------------------------------------------------------------
    // SMART PROTECTED SUBJECTS
    // -----------------------------------------------------------------------

    for (final result
        in _protectedMasks) {
      final maskImage =
          await _decodeUiImage(
        result.maskBytes,
      );

      try {
        canvas.drawImageRect(
          maskImage,
          Rect.fromLTWH(
            0,
            0,
            maskImage.width.toDouble(),
            maskImage.height.toDouble(),
          ),
          fullRect,
          Paint()
            ..blendMode =
                BlendMode.srcOver
            ..filterQuality =
                FilterQuality.none,
        );
      } finally {
        maskImage.dispose();
      }
    }

    // -----------------------------------------------------------------------
    // PROTECT BRUSH
    // -----------------------------------------------------------------------

    final protectPaint =
        Paint()
          ..color =
              Colors.white
          ..strokeWidth =
              _brushSize
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round
          ..style =
              PaintingStyle.stroke
          ..blendMode =
              BlendMode.srcOver;

    for (final stroke
        in _protectedStrokes) {
      _drawStroke(
        canvas: canvas,
        stroke: stroke,
        paint: protectPaint,
        brushSize: _brushSize,
      );
    }

    return _finishMask(
      recorder: recorder,
      width: image.width,
      height: image.height,
    );
  }

  Future<Uint8List> _finishMask({
    required ui.PictureRecorder recorder,
    required int width,
    required int height,
  }) async {
    final picture =
        recorder.endRecording();

    final maskImage =
        await picture.toImage(
      width,
      height,
    );

    try {
      final byteData =
          await maskImage.toByteData(
        format:
            ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw StateError(
          'Could not encode mask.',
        );
      }

      return byteData.buffer
          .asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } finally {
      maskImage.dispose();
      picture.dispose();
    }
  }

  void _drawStroke({
    required Canvas canvas,
    required List<Offset> stroke,
    required Paint paint,
    required double brushSize,
  }) {
    if (stroke.isEmpty) {
      return;
    }

    if (stroke.length == 1) {
      canvas.drawCircle(
        stroke.first,
        brushSize / 2,
        Paint()
          ..color =
              Colors.white
          ..style =
              PaintingStyle.fill,
      );

      return;
    }

    final path =
        Path()
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

  Future<ui.Image> _decodeUiImage(
    Uint8List bytes,
  ) async {
    final codec =
        await ui.instantiateImageCodec(
      bytes,
    );

    try {
      final frame =
          await codec.getNextFrame();

      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  // ===========================================================================
  // OFFLINE REMOVE
  // ===========================================================================

  Future<void> _removeSelectedArea() async {
    if (_isRemoving ||
        _isSegmenting) {
      return;
    }

    if (!_hasMask) {
      _showMessage(
        'Select an object or paint an area first.',
      );

      return;
    }

    setState(() {
      _isRemoving = true;
    });

    try {
      final hadProtection =
          _hasProtection;

      final removeMaskBytes =
          await _createRemoveMask();

      final protectionMaskBytes =
          await _createProtectionMask();

      if (!mounted) {
        return;
      }

      final editedBytes =
          await _offlineInpaintingService.inpaint(
        imageBytes:
            _currentImageBytes,
        maskBytes:
            removeMaskBytes,
        protectionMaskBytes:
            protectionMaskBytes,
      );

      if (!mounted) {
        return;
      }

      if (editedBytes.isEmpty) {
        throw const OfflineInpaintingException(
          'Offline AI returned an empty image.',
        );
      }

      setState(() {
        _currentImageBytes =
            editedBytes;

        _selectedMasks.clear();
        _strokes.clear();

        _protectedMasks.clear();
        _protectedStrokes.clear();

        _history.clear();

        _activeStroke = null;
        _activeProtectedStroke = null;

        _hasEditedImage = true;
        _isLoadingImage = true;
      });

      //
      // New image generated: return the viewport
      // to its normal position.
      //
      _resetZoom();

      await _decodeCurrentImage();

      if (!mounted) {
        return;
      }

      await _prepareSegmentation();

      if (!mounted) {
        return;
      }

      _showMessage(
        hadProtection
            ? 'Removed while preserving protected areas.'
            : 'Removed offline. Continue editing or save.',
      );
    } on OfflineInpaintingException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Offline object removal failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not rebuild the selected area.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  Future<void> _resetToOriginal() async {
    if (_isRemoving ||
        _isSegmenting) {
      return;
    }

    setState(() {
      _currentImageBytes =
          widget.imageBytes;

      _selectedMasks.clear();
      _strokes.clear();

      _protectedMasks.clear();
      _protectedStrokes.clear();

      _history.clear();

      _activeStroke = null;
      _activeProtectedStroke = null;

      _hasEditedImage = false;
      _isLoadingImage = true;
    });

    //
    // Reset viewport too.
    //
    _resetZoom();

    await _decodeCurrentImage();

    if (!mounted) {
      return;
    }

    await _prepareSegmentation();
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  void _saveAndFinish() {
    if (_isRemoving ||
        _isSegmenting) {
      return;
    }

    if (!_hasEditedImage) {
      _showMessage(
        'Remove something first.',
      );

      return;
    }

    Navigator.of(context)
        .pop<Uint8List>(
      _currentImageBytes,
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(
            message,
          ),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              _surfaceHighlight,
        ),
      );
  }

  @override
  void dispose() {
    _decodedImage?.dispose();

    _segmentationService
        .clearImageCache();

    _transformationController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          _background,
      appBar: AppBar(
        backgroundColor:
            _background,
        foregroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        titleSpacing: 2,
        title: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Object Eraser',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    -0.25,
              ),
            ),
            SizedBox(
              height: 2,
            ),
            Text(
              'On-device AI',
              style: TextStyle(
                color:
                    Colors.white38,
                fontSize: 10,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          _AppBarAction(
            tooltip:
                'Undo',
            icon:
                Icons.undo_rounded,
            onPressed:
                _history.isEmpty ||
                        _isRemoving ||
                        _isSegmenting
                    ? null
                    : _undo,
          ),
          const SizedBox(
            width: 4,
          ),
          _AppBarAction(
            tooltip:
                'Clear masks',
            icon:
                Icons.delete_sweep_outlined,
            onPressed:
                !_hasAnyOverlay ||
                        _isRemoving ||
                        _isSegmenting
                    ? null
                    : _clearSelection,
          ),
          if (_hasEditedImage) ...[
            const SizedBox(
              width: 4,
            ),
            _AppBarAction(
              tooltip:
                  'Reset original',
              icon:
                  Icons.restart_alt_rounded,
              onPressed:
                  _isRemoving ||
                          _isSegmenting
                      ? null
                      : _resetToOriginal,
            ),
          ],
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                  child: DecoratedBox(
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.black,
                      border:
                          Border.all(
                        color:
                            Colors.white.withValues(
                          alpha:
                              0.055,
                        ),
                      ),
                    ),
                    child:
                        LayoutBuilder(
                      builder: (
                        context,
                        constraints,
                      ) {
                        final canvasSize =
                            Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );

                        // =====================================================
                        // INTERACTIVE VIEWER
                        //
                        // Everything inside this widget is transformed
                        // together:
                        //
                        // image
                        // smart masks
                        // protect masks
                        // brush overlays
                        // interaction layer
                        //
                        // Therefore taps and brush coordinates continue to use
                        // the exact same canvas coordinate system even after
                        // zooming.
                        // =====================================================

                        return InteractiveViewer(
                          transformationController:
                              _transformationController,

                          minScale:
                              _minZoom,
                          maxScale:
                              _maxZoom,

                          scaleEnabled:
                              !_isRemoving,

                          //
                          // Smart Select can pan normally with one finger
                          // after zooming.
                          //
                          // Brush / Protect reserve one-finger drag for
                          // painting. Two-finger pinch still works.
                          //
                          panEnabled:
                              _mode ==
                                  _EraserMode.select,

                          boundaryMargin:
                              const EdgeInsets.all(
                            80,
                          ),

                          clipBehavior:
                              Clip.none,

                          interactionEndFrictionCoefficient:
                              0.0000135,

                          child: SizedBox(
                            width:
                                canvasSize.width,
                            height:
                                canvasSize.height,
                            child: Stack(
                              fit:
                                  StackFit.expand,
                              children: [
                                if (!_isLoadingImage)
                                  Image.memory(
                                    _currentImageBytes,
                                    fit:
                                        BoxFit.contain,
                                    gaplessPlayback:
                                        true,
                                    filterQuality:
                                        FilterQuality.high,
                                  ),

                                // =============================================
                                // REMOVE MASKS
                                // =============================================

                                if (!_isLoadingImage)
                                  ..._selectedMasks.map(
                                    (
                                      result,
                                    ) {
                                      return Positioned.fill(
                                        child:
                                            IgnorePointer(
                                          child:
                                              Opacity(
                                            opacity:
                                                0.48,
                                            child:
                                                Image.memory(
                                              result.maskBytes,
                                              fit:
                                                  BoxFit.contain,
                                              gaplessPlayback:
                                                  true,
                                              filterQuality:
                                                  FilterQuality.none,
                                              color:
                                                  _purple,
                                              colorBlendMode:
                                                  BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // =============================================
                                // PROTECTED MASKS
                                // =============================================

                                if (!_isLoadingImage)
                                  ..._protectedMasks.map(
                                    (
                                      result,
                                    ) {
                                      return Positioned.fill(
                                        child:
                                            IgnorePointer(
                                          child:
                                              Opacity(
                                            opacity:
                                                0.46,
                                            child:
                                                Image.memory(
                                              result.maskBytes,
                                              fit:
                                                  BoxFit.contain,
                                              gaplessPlayback:
                                                  true,
                                              filterQuality:
                                                  FilterQuality.none,
                                              color:
                                                  _protectGreen,
                                              colorBlendMode:
                                                  BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // =============================================
                                // REMOVE BRUSH OVERLAY
                                // =============================================

                                if (!_isLoadingImage)
                                  Positioned.fill(
                                    child:
                                        IgnorePointer(
                                      child:
                                          CustomPaint(
                                        painter:
                                            _BrushOverlayPainter(
                                          strokes:
                                              _strokes,
                                          mapPoint:
                                              (
                                            point,
                                          ) {
                                            return _imagePointToCanvas(
                                              imagePoint:
                                                  point,
                                              canvasSize:
                                                  canvasSize,
                                            );
                                          },
                                          brushSize:
                                              _displayBrushSize(
                                            canvasSize,
                                          ),
                                          color:
                                              _purple,
                                        ),
                                      ),
                                    ),
                                  ),

                                // =============================================
                                // PROTECT BRUSH OVERLAY
                                // =============================================

                                if (!_isLoadingImage)
                                  Positioned.fill(
                                    child:
                                        IgnorePointer(
                                      child:
                                          CustomPaint(
                                        painter:
                                            _BrushOverlayPainter(
                                          strokes:
                                              _protectedStrokes,
                                          mapPoint:
                                              (
                                            point,
                                          ) {
                                            return _imagePointToCanvas(
                                              imagePoint:
                                                  point,
                                              canvasSize:
                                                  canvasSize,
                                            );
                                          },
                                          brushSize:
                                              _displayBrushSize(
                                            canvasSize,
                                          ),
                                          color:
                                              _protectGreen,
                                        ),
                                      ),
                                    ),
                                  ),

                                // =============================================
                                // INTERACTION
                                // =============================================

                                if (!_isLoadingImage)
                                  Positioned.fill(
                                    child:
                                        GestureDetector(
                                      behavior:
                                          HitTestBehavior.opaque,

                                      // ---------------------------------------
                                      // TAP
                                      // ---------------------------------------

                                      onTapUp:
                                          _mode ==
                                                      _EraserMode.select ||
                                                  _mode ==
                                                      _EraserMode.protect
                                              ? (
                                                  details,
                                                ) {
                                                  _handleTap(
                                                    canvasPoint:
                                                        details.localPosition,
                                                    canvasSize:
                                                        canvasSize,
                                                  );
                                                }
                                              : null,

                                      // ---------------------------------------
                                      // ONE-FINGER BRUSH
                                      // ---------------------------------------

                                      onPanStart:
                                          _mode ==
                                                      _EraserMode.brush ||
                                                  _mode ==
                                                      _EraserMode.protect
                                              ? (
                                                  details,
                                                ) {
                                                  _startStroke(
                                                    canvasPoint:
                                                        details.localPosition,
                                                    canvasSize:
                                                        canvasSize,
                                                  );
                                                }
                                              : null,

                                      onPanUpdate:
                                          _mode ==
                                                      _EraserMode.brush ||
                                                  _mode ==
                                                      _EraserMode.protect
                                              ? (
                                                  details,
                                                ) {
                                                  _updateStroke(
                                                    canvasPoint:
                                                        details.localPosition,
                                                    canvasSize:
                                                        canvasSize,
                                                  );
                                                }
                                              : null,

                                      onPanEnd:
                                          _mode ==
                                                      _EraserMode.brush ||
                                                  _mode ==
                                                      _EraserMode.protect
                                              ? (_) {
                                                  _endStroke();
                                                }
                                              : null,

                                      onPanCancel:
                                          _mode ==
                                                      _EraserMode.brush ||
                                                  _mode ==
                                                      _EraserMode.protect
                                              ? _endStroke
                                              : null,
                                    ),
                                  ),

                                if (_isLoadingImage)
                                  const _LoadingView(
                                    title:
                                        'Opening photo...',
                                  ),

                                if (_isSegmenting)
                                  Positioned(
                                    top: 16,
                                    left: 0,
                                    right: 0,
                                    child:
                                        _StatusPill(
                                      icon:
                                          _mode ==
                                                  _EraserMode.protect
                                              ? Icons.shield_outlined
                                              : Icons.auto_awesome_rounded,
                                      text:
                                          _mode ==
                                                  _EraserMode.protect
                                              ? 'Protecting subject'
                                              : 'Selecting object',
                                      color:
                                          _mode ==
                                                  _EraserMode.protect
                                              ? _protectGreenLight
                                              : _purpleLight,
                                    ),
                                  ),

                                if (_isPreparingSegmentation &&
                                    !_isLoadingImage &&
                                    !_isSegmenting)
                                  const Positioned(
                                    top: 16,
                                    left: 0,
                                    right: 0,
                                    child:
                                        _StatusPill(
                                      icon:
                                          Icons.memory_rounded,
                                      text:
                                          'Preparing Smart Select',
                                      color:
                                          _purpleLight,
                                    ),
                                  ),

                                if (_hasEditedImage &&
                                    !_isRemoving &&
                                    !_isLoadingImage)
                                  const Positioned(
                                    top: 16,
                                    left: 16,
                                    child:
                                        _EditedBadge(),
                                  ),

                                if (_isRemoving)
                                  Positioned.fill(
                                    child:
                                        ColoredBox(
                                      color:
                                          Colors.black.withValues(
                                        alpha:
                                            0.72,
                                      ),
                                      child:
                                          const _RemovingView(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            _buildControls(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTROLS
  // ===========================================================================

  Widget _buildControls() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            _surface,
        borderRadius:
            const BorderRadius.vertical(
          top:
              Radius.circular(
            28,
          ),
        ),
        border:
            Border(
          top:
              BorderSide(
            color:
                Colors.white.withValues(
              alpha:
                  0.05,
            ),
          ),
        ),
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      9,
                  vertical:
                      5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      _green.withValues(
                    alpha:
                        0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    999,
                  ),
                  border:
                      Border.all(
                    color:
                        _green.withValues(
                      alpha:
                          0.17,
                    ),
                  ),
                ),
                child:
                    const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_bolt_rounded,
                      color:
                          Color(
                        0xFF86EFAC,
                      ),
                      size:
                          13,
                    ),
                    SizedBox(
                      width:
                          5,
                    ),
                    Text(
                      'Offline AI',
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xFF86EFAC,
                        ),
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              if (_hasAnyOverlay)
                Text(
                  '${_selectedMasks.length + _strokes.length} remove'
                  '${_hasProtection ? ' • ${_protectedMasks.length + _protectedStrokes.length} protected' : ''}',
                  style:
                      TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha:
                          0.38,
                    ),
                    fontSize:
                        10,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(
            height:
                12,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _ModeButton(
                  icon:
                      Icons.touch_app_rounded,
                  title:
                      'Smart Select',
                  subtitle:
                      _isPreparingSegmentation
                          ? 'Preparing...'
                          : 'Tap objects',
                  selected:
                      _mode ==
                      _EraserMode.select,
                  enabled:
                      !_isPreparingSegmentation,
                  accentColor:
                      _purple,
                  accentLight:
                      _purpleLight,
                  onTap:
                      () {
                    _setMode(
                      _EraserMode.select,
                    );
                  },
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    _ModeButton(
                  icon:
                      Icons.brush_rounded,
                  title:
                      'Brush',
                  subtitle:
                      'Add remove mask',
                  selected:
                      _mode ==
                      _EraserMode.brush,
                  enabled:
                      true,
                  accentColor:
                      _purple,
                  accentLight:
                      _purpleLight,
                  onTap:
                      () {
                    _setMode(
                      _EraserMode.brush,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                _ModeButton(
              icon:
                  Icons.shield_outlined,
              title:
                  'Protect',
              subtitle:
                  'Tap or paint anything that must remain untouched',
              selected:
                  _mode ==
                  _EraserMode.protect,
              enabled:
                  !_isPreparingSegmentation,
              accentColor:
                  _protectGreen,
              accentLight:
                  _protectGreenLight,
              onTap:
                  () {
                _setMode(
                  _EraserMode.protect,
                );
              },
            ),
          ),

          AnimatedSwitcher(
            duration:
                const Duration(
              milliseconds:
                  180,
            ),
            child:
                (_mode ==
                            _EraserMode.brush ||
                        _mode ==
                            _EraserMode.protect)
                    ? Padding(
                        key:
                            ValueKey(
                          'brush-${_mode.name}',
                        ),
                        padding:
                            const EdgeInsets.only(
                          top:
                              12,
                        ),
                        child:
                            Container(
                          decoration:
                              BoxDecoration(
                            color:
                                _surfaceHighlight,
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                            border:
                                Border.all(
                              color:
                                  Colors.white.withValues(
                                alpha:
                                    0.045,
                              ),
                            ),
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                12,
                          ),
                          child:
                              Row(
                            children: [
                              Container(
                                width:
                                    30,
                                height:
                                    30,
                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape.circle,
                                  border:
                                      Border.all(
                                    color:
                                        (_mode ==
                                                    _EraserMode.protect
                                                ? _protectGreenLight
                                                : _purpleLight)
                                            .withValues(
                                      alpha:
                                          0.7,
                                    ),
                                  ),
                                ),
                                child:
                                    Center(
                                  child:
                                      Container(
                                    width:
                                        4 +
                                        (_brushSize / 360) *
                                            12,
                                    height:
                                        4 +
                                        (_brushSize / 360) *
                                            12,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          _mode ==
                                                  _EraserMode.protect
                                              ? _protectGreenLight
                                              : _purpleLight,
                                      shape:
                                          BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width:
                                    8,
                              ),

                              Text(
                                _mode ==
                                        _EraserMode.protect
                                    ? 'Protect Brush'
                                    : 'Remove Brush',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),

                              Expanded(
                                child:
                                    Slider(
                                  value:
                                      _brushSize,
                                  min:
                                      25,
                                  max:
                                      360,
                                  activeColor:
                                      _mode ==
                                              _EraserMode.protect
                                          ? _protectGreen
                                          : _purple,
                                  inactiveColor:
                                      Colors.white12,
                                  onChanged:
                                      _isRemoving
                                          ? null
                                          : (
                                              value,
                                            ) {
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
                        ),
                      )
                    : const SizedBox.shrink(
                        key:
                            ValueKey(
                          'no-brush',
                        ),
                      ),
          ),

          const SizedBox(
            height:
                14,
          ),

          Row(
            children: [
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusTitle,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height:
                          4,
                    ),

                    Text(
                      _statusSubtitle,
                      maxLines:
                          2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color:
                            Colors.white.withValues(
                          alpha:
                              0.43,
                        ),
                        fontSize:
                            10.5,
                        height:
                            1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width:
                    14,
              ),

              _PremiumRemoveButton(
                enabled:
                    _hasMask &&
                    !_isRemoving &&
                    !_isSegmenting &&
                    !_isLoadingImage,
                isProcessing:
                    _isRemoving,
                onPressed:
                    _removeSelectedArea,
              ),
            ],
          ),

          if (_hasEditedImage) ...[
            const SizedBox(
              height:
                  12,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  FilledButton.icon(
                onPressed:
                    _isRemoving ||
                            _isSegmenting
                        ? null
                        : _saveAndFinish,
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      Colors.white.withValues(
                    alpha:
                        0.08,
                  ),
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      Colors.white.withValues(
                    alpha:
                        0.035,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical:
                        14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    side:
                        BorderSide(
                      color:
                          _purpleLight.withValues(
                        alpha:
                            0.22,
                      ),
                    ),
                  ),
                ),
                icon:
                    const Icon(
                  Icons.check_rounded,
                  size:
                      19,
                ),
                label:
                    const Text(
                  'Save & Finish',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _statusTitle {
    if (_isRemoving) {
      return 'Rebuilding selected area';
    }

    if (_isSegmenting) {
      return _mode ==
              _EraserMode.protect
          ? 'Detecting protected subject'
          : 'Detecting object';
    }

    if (_mode ==
        _EraserMode.protect) {
      return 'Protect important areas';
    }

    if (_hasMask) {
      return 'Ready to remove';
    }

    if (_hasEditedImage) {
      return 'Edit complete';
    }

    if (_mode ==
        _EraserMode.select) {
      return 'Tap objects to select';
    }

    return 'Paint unwanted areas';
  }

  String get _statusSubtitle {
    if (_isRemoving) {
      return 'LaMa is reconstructing the background while protected pixels remain untouched.';
    }

    if (_mode ==
        _EraserMode.protect) {
      return 'Tap or paint protected areas. Pinch with two fingers to zoom.';
    }

    if (_hasMask &&
        _hasProtection) {
      return 'Green areas have priority and will never be sent to LaMa for reconstruction.';
    }

    if (_hasMask) {
      return 'Protect nearby faces, hands or body parts when objects overlap them.';
    }

    if (_hasEditedImage) {
      return 'Keep editing, or save the finished result.';
    }

    if (_mode ==
        _EraserMode.select) {
      return 'Tap objects to select. Pinch with two fingers to zoom.';
    }

    return 'Paint unwanted areas. Pinch with two fingers to zoom.';
  }
}

// =============================================================================
// HISTORY
// =============================================================================

class _MaskAction {
  const _MaskAction._({
    required this.type,
    this.selection,
    this.stroke,
  });

  factory _MaskAction.selection(
    SegmentationResult result,
  ) {
    return _MaskAction._(
      type:
          _MaskActionType.selection,
      selection:
          result,
    );
  }

  factory _MaskAction.stroke(
    List<Offset> stroke,
  ) {
    return _MaskAction._(
      type:
          _MaskActionType.stroke,
      stroke:
          stroke,
    );
  }

  factory _MaskAction.protectedSelection(
    SegmentationResult result,
  ) {
    return _MaskAction._(
      type:
          _MaskActionType.protectedSelection,
      selection:
          result,
    );
  }

  factory _MaskAction.protectedStroke(
    List<Offset> stroke,
  ) {
    return _MaskAction._(
      type:
          _MaskActionType.protectedStroke,
      stroke:
          stroke,
    );
  }

  final _MaskActionType type;

  final SegmentationResult? selection;

  final List<Offset>? stroke;
}

// =============================================================================
// BRUSH OVERLAY
// =============================================================================

class _BrushOverlayPainter extends CustomPainter {
  const _BrushOverlayPainter({
    required this.strokes,
    required this.mapPoint,
    required this.brushSize,
    required this.color,
  });

  final List<List<Offset>> strokes;

  final Offset Function(
    Offset imagePoint,
  )
  mapPoint;

  final double brushSize;
  final Color color;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final glowPaint =
        Paint()
          ..color =
              color.withValues(
            alpha:
                0.22,
          )
          ..strokeWidth =
              brushSize +
              8
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round
          ..style =
              PaintingStyle.stroke;

    final strokePaint =
        Paint()
          ..color =
              color.withValues(
            alpha:
                0.57,
          )
          ..strokeWidth =
              brushSize
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round
          ..style =
              PaintingStyle.stroke;

    for (final stroke
        in strokes) {
      if (stroke.isEmpty) {
        continue;
      }

      if (stroke.length == 1) {
        final point =
            mapPoint(
          stroke.first,
        );

        canvas.drawCircle(
          point,
          brushSize / 2,
          Paint()
            ..color =
                color.withValues(
              alpha:
                  0.57,
            ),
        );

        continue;
      }

      final first =
          mapPoint(
        stroke.first,
      );

      final path =
          Path()
            ..moveTo(
              first.dx,
              first.dy,
            );

      for (
        var index = 1;
        index < stroke.length;
        index++
      ) {
        final point =
            mapPoint(
          stroke[index],
        );

        path.lineTo(
          point.dx,
          point.dy,
        );
      }

      canvas.drawPath(
        path,
        glowPaint,
      );

      canvas.drawPath(
        path,
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _BrushOverlayPainter oldDelegate,
  ) {
    return true;
  }
}

// =============================================================================
// PREMIUM REMOVE BUTTON
// =============================================================================

class _PremiumRemoveButton extends StatelessWidget {
  const _PremiumRemoveButton({
    required this.enabled,
    required this.isProcessing,
    required this.onPressed,
  });

  final bool enabled;
  final bool isProcessing;
  final VoidCallback onPressed;

  @override
  Widget build(
    BuildContext context,
  ) {
    final active =
        enabled &&
        !isProcessing;

    return Opacity(
      opacity:
          active ||
                  isProcessing
              ? 1
              : 0.38,
      child:
          DecoratedBox(
        decoration:
            BoxDecoration(
          gradient:
              active ||
                      isProcessing
                  ? const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        Color(
                          0xFFA78BFA,
                        ),
                        Color(
                          0xFF8B5CF6,
                        ),
                        Color(
                          0xFF6D28D9,
                        ),
                      ],
                    )
                  : const LinearGradient(
                      colors: [
                        Color(
                          0xFF353A48,
                        ),
                        Color(
                          0xFF292E3B,
                        ),
                      ],
                    ),
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          boxShadow:
              active
                  ? [
                      BoxShadow(
                        color:
                            const Color(
                          0xFF8B5CF6,
                        ).withValues(
                          alpha:
                              0.24,
                        ),
                        blurRadius:
                            18,
                        offset:
                            const Offset(
                          0,
                          6,
                        ),
                      ),
                    ]
                  : null,
        ),
        child:
            Material(
          color:
              Colors.transparent,
          child:
              InkWell(
            onTap:
                active
                    ? onPressed
                    : null,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            child:
                Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    18,
                vertical:
                    14,
              ),
              child:
                  Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  if (isProcessing)
                    const SizedBox(
                      width:
                          17,
                      height:
                          17,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                        color:
                            Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.auto_fix_high_rounded,
                      color:
                          Colors.white,
                      size:
                          18,
                    ),

                  const SizedBox(
                    width:
                        8,
                  ),

                  Text(
                    isProcessing
                        ? 'Removing'
                        : 'Remove',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODE BUTTON
// =============================================================================

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.accentColor,
    required this.accentLight,
  });

  final IconData icon;

  final String title;
  final String subtitle;

  final bool selected;
  final bool enabled;

  final VoidCallback onTap;

  final Color accentColor;
  final Color accentLight;

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds:
            180,
      ),
      decoration:
          BoxDecoration(
        color:
            selected
                ? accentColor.withValues(
                    alpha:
                        0.14,
                  )
                : _ObjectEraserScreenState
                    ._surfaceHighlight,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              selected
                  ? accentColor.withValues(
                      alpha:
                          0.42,
                    )
                  : Colors.white.withValues(
                      alpha:
                          0.045,
                    ),
        ),
      ),
      child:
          Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        clipBehavior:
            Clip.antiAlias,
        child:
            InkWell(
          onTap:
              enabled
                  ? onTap
                  : null,
          child:
              Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  12,
              vertical:
                  11,
            ),
            child:
                Row(
              children: [
                Container(
                  width:
                      38,
                  height:
                      38,
                  decoration:
                      BoxDecoration(
                    color:
                        selected
                            ? accentColor.withValues(
                                alpha:
                                    0.16,
                              )
                            : Colors.white.withValues(
                                alpha:
                                    0.035,
                              ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      Icon(
                    icon,
                    color:
                        enabled
                            ? selected
                                ? accentLight
                                : Colors.white70
                            : Colors.white24,
                    size:
                        20,
                  ),
                ),

                const SizedBox(
                  width:
                      10,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            TextStyle(
                          color:
                              enabled
                                  ? Colors.white
                                  : Colors.white30,
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        subtitle,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            TextStyle(
                          color:
                              Colors.white.withValues(
                            alpha:
                                enabled
                                    ? 0.40
                                    : 0.18,
                          ),
                          fontSize:
                              9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TOP APP BAR ACTION
// =============================================================================

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(
    BuildContext context,
  ) {
    final enabled =
        onPressed != null;

    return Tooltip(
      message:
          tooltip,
      child:
          Material(
        color:
            Colors.white.withValues(
          alpha:
              enabled
                  ? 0.055
                  : 0.025,
        ),
        shape:
            const CircleBorder(),
        child:
            InkWell(
          onTap:
              onPressed,
          customBorder:
              const CircleBorder(),
          child:
              SizedBox(
            width:
                38,
            height:
                38,
            child:
                Icon(
              icon,
              size:
                  19,
              color:
                  enabled
                      ? Colors.white70
                      : Colors.white24,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STATUS PILL
// =============================================================================

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          ClipRRect(
        borderRadius:
            BorderRadius.circular(
          999,
        ),
        child:
            BackdropFilter(
          filter:
              ui.ImageFilter.blur(
            sigmaX:
                12,
            sigmaY:
                12,
          ),
          child:
              Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  12,
              vertical:
                  8,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xCC0D1321,
              ),
              borderRadius:
                  BorderRadius.circular(
                999,
              ),
              border:
                  Border.all(
                color:
                    Colors.white.withValues(
                  alpha:
                      0.08,
                ),
              ),
            ),
            child:
                Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                SizedBox(
                  width:
                      12,
                  height:
                      12,
                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        1.7,
                    color:
                        color,
                  ),
                ),

                const SizedBox(
                  width:
                      8,
                ),

                Icon(
                  icon,
                  color:
                      color,
                  size:
                      14,
                ),

                const SizedBox(
                  width:
                      6,
                ),

                Text(
                  text,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        10.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EDITED BADGE
// =============================================================================

class _EditedBadge extends StatelessWidget {
  const _EditedBadge();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            10,
        vertical:
            6,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF052E1B,
        ).withValues(
          alpha:
              0.92,
        ),
        borderRadius:
            BorderRadius.circular(
          999,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFF22C55E,
          ).withValues(
            alpha:
                0.24,
          ),
        ),
      ),
      child:
          const Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color:
                Color(
              0xFF86EFAC,
            ),
            size:
                14,
          ),
          SizedBox(
            width:
                5,
          ),
          Text(
            'Edited',
            style:
                TextStyle(
              color:
                  Color(
                0xFFBBF7D0,
              ),
              fontSize:
                  10.5,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LOADING
// =============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView({
    required this.title,
  });

  final String title;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width:
                54,
            height:
                54,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFF8B5CF6,
              ).withValues(
                alpha:
                    0.08,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Padding(
              padding:
                  EdgeInsets.all(
                15,
              ),
              child:
                  CircularProgressIndicator(
                strokeWidth:
                    2,
                color:
                    Color(
                  0xFFC4B5FD,
                ),
              ),
            ),
          ),

          const SizedBox(
            height:
                16,
          ),

          Text(
            title,
            style:
                const TextStyle(
              color:
                  Colors.white70,
              fontSize:
                  12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REMOVING
// =============================================================================

class _RemovingView extends StatelessWidget {
  const _RemovingView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          Container(
        margin:
            const EdgeInsets.symmetric(
          horizontal:
              34,
        ),
        padding:
            const EdgeInsets.fromLTRB(
          28,
          26,
          28,
          24,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xF20D1321,
          ),
          borderRadius:
              BorderRadius.circular(
            24,
          ),
          border:
              Border.all(
            color:
                const Color(
              0xFF8B5CF6,
            ).withValues(
              alpha:
                  0.18,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(
                0xFF8B5CF6,
              ).withValues(
                alpha:
                    0.12,
              ),
              blurRadius:
                  32,
            ),
          ],
        ),
        child:
            const Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            SizedBox(
              width:
                  42,
              height:
                  42,
              child:
                  CircularProgressIndicator(
                strokeWidth:
                    2.4,
                color:
                    Color(
                  0xFFC4B5FD,
                ),
              ),
            ),

            SizedBox(
              height:
                  20,
            ),

            Text(
              'Rebuilding background',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize:
                    16,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    -0.2,
              ),
            ),

            SizedBox(
              height:
                  7,
            ),

            Text(
              'Protected subjects stay untouched while neural inpainting rebuilds the selected area.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white54,
                fontSize:
                    11,
                height:
                    1.45,
              ),
            ),

            SizedBox(
              height:
                  14,
            ),

            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color:
                      Color(
                    0xFF86EFAC,
                  ),
                  size:
                      13,
                ),
                SizedBox(
                  width:
                      5,
                ),
                Text(
                  'Protected pixels are locked',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF86EFAC,
                    ),
                    fontSize:
                        9.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}