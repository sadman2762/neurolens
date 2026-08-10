import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/data/inpainting/offline_inpainting_service.dart';
import 'package:neurolens/features/memory/data/local_segmentation_service.dart';

enum _EraserMode { select, brush, protect }

enum _MaskActionType { selection, stroke, protectedSelection, protectedStroke }

class ObjectEraserScreen extends StatefulWidget {
  const ObjectEraserScreen({
    required this.imageBytes,
    required this.title,
    super.key,
  });

  final Uint8List imageBytes;
  final String title;

  @override
  State<ObjectEraserScreen> createState() => _ObjectEraserScreenState();
}

class _ObjectEraserScreenState extends State<ObjectEraserScreen>
    with TickerProviderStateMixin {
  static const Color _surfaceHighlight = Color(0xFF141B2D);

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleLight = Color(0xFFC4B5FD);

  static const Color _protectGreen = Color(0xFF22C55E);
  static const Color _protectGreenLight = Color(0xFF86EFAC);

  // ===========================================================================
  // ZOOM
  // ===========================================================================

  final TransformationController _transformationController =
      TransformationController();

  late final AnimationController _zoomResetController;

  Animation<Matrix4>? _zoomResetAnimation;

  static const double _minZoom = 1.0;
  static const double _maxZoom = 8.0;

  final LocalSegmentationService _segmentationService =
      LocalSegmentationService();

  final OfflineInpaintingService _offlineInpaintingService =
      OfflineInpaintingService();

  late Uint8List _currentImageBytes;

  ui.Image? _decodedImage;

  final List<SegmentationResult> _selectedMasks = <SegmentationResult>[];

  final List<List<Offset>> _strokes = <List<Offset>>[];

  final List<SegmentationResult> _protectedMasks = <SegmentationResult>[];

  final List<List<Offset>> _protectedStrokes = <List<Offset>>[];

  final List<_MaskAction> _history = <_MaskAction>[];

  List<Offset>? _activeStroke;
  List<Offset>? _activeProtectedStroke;

  _EraserMode _mode = _EraserMode.select;

  double _brushSize = 90;

  bool _isLoadingImage = true;
  bool _isPreparingSegmentation = true;
  bool _isSegmenting = false;
  bool _isRemoving = false;
  bool _hasEditedImage = false;

  // Floating editor panel.
  bool _showTools = false;

  @override
  void initState() {
    super.initState();

    _currentImageBytes = widget.imageBytes;

    _zoomResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _zoomResetController.addListener(() {
      final animation = _zoomResetAnimation;

      if (animation != null) {
        _transformationController.value = animation.value;
      }
    });

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

  void _resetZoomImmediately() {
    _zoomResetController.stop();

    _zoomResetAnimation = null;

    _transformationController.value = Matrix4.identity();
  }

  Future<void> _animateZoomToDefault() async {
    final currentMatrix = _transformationController.value.clone();

    final currentScale = currentMatrix.getMaxScaleOnAxis();

    final translation = currentMatrix.getTranslation();

    final isAlreadyDefault =
        (currentScale - 1.0).abs() < 0.001 &&
        translation.x.abs() < 0.5 &&
        translation.y.abs() < 0.5;

    if (isAlreadyDefault) {
      _resetZoomImmediately();
      return;
    }

    _zoomResetController.stop();

    _zoomResetController.reset();

    _zoomResetAnimation =
        Matrix4Tween(begin: currentMatrix, end: Matrix4.identity()).animate(
          CurvedAnimation(
            parent: _zoomResetController,
            curve: Curves.easeOutCubic,
          ),
        );

    try {
      await _zoomResetController.forward();
    } on TickerCanceled {
      return;
    }

    if (!mounted) {
      return;
    }

    _zoomResetAnimation = null;

    _transformationController.value = Matrix4.identity();
  }

  // ===========================================================================
  // IMAGE
  // ===========================================================================

  Future<void> _decodeCurrentImage() async {
    try {
      final codec = await ui.instantiateImageCodec(_currentImageBytes);

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
      debugPrint('Object Eraser image decode failed: $error');

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

      await _segmentationService.debugRunEncoder(_currentImageBytes);
    } catch (error, stackTrace) {
      debugPrint('MobileSAM preparation failed: $error');

      debugPrintStack(stackTrace: stackTrace);

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

  void _setMode(_EraserMode mode) {
    if (_isRemoving || _isSegmenting) {
      return;
    }

    if ((mode == _EraserMode.select || mode == _EraserMode.protect) &&
        _isPreparingSegmentation) {
      _showMessage('Smart Select is still preparing.');

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
    if ((_mode != _EraserMode.select && _mode != _EraserMode.protect) ||
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
      _showMessage('Tap directly on the photo.');

      return;
    }

    final protectMode = _mode == _EraserMode.protect;

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
          _protectedMasks.add(result);

          _history.add(_MaskAction.protectedSelection(result));
        } else {
          _selectedMasks.add(result);

          _history.add(_MaskAction.selection(result));
        }
      });
    } catch (error, stackTrace) {
      debugPrint('MobileSAM selection failed: $error');

      debugPrintStack(stackTrace: stackTrace);

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

  void _startStroke({required Offset canvasPoint, required Size canvasSize}) {
    if ((_mode != _EraserMode.brush && _mode != _EraserMode.protect) ||
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

    final stroke = <Offset>[imagePoint];

    setState(() {
      if (_mode == _EraserMode.protect) {
        _activeProtectedStroke = stroke;

        _protectedStrokes.add(stroke);

        _history.add(_MaskAction.protectedStroke(stroke));
      } else {
        _activeStroke = stroke;

        _strokes.add(stroke);

        _history.add(_MaskAction.stroke(stroke));
      }
    });
  }

  void _updateStroke({required Offset canvasPoint, required Size canvasSize}) {
    if ((_mode != _EraserMode.brush && _mode != _EraserMode.protect) ||
        _isRemoving ||
        _isSegmenting) {
      return;
    }

    final stroke = _mode == _EraserMode.protect
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
      stroke.add(imagePoint);
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

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final imageRect = _calculateDisplayedImageRect(
      canvasSize: canvasSize,
      imageSize: imageSize,
    );

    if (imageRect == null || !imageRect.contains(canvasPoint)) {
      return null;
    }

    final normalizedX = (canvasPoint.dx - imageRect.left) / imageRect.width;

    final normalizedY = (canvasPoint.dy - imageRect.top) / imageRect.height;

    return Offset(
      normalizedX * imageSize.width,
      normalizedY * imageSize.height,
    );
  }

  Offset _imagePointToCanvas({
    required Offset imagePoint,
    required Size canvasSize,
  }) {
    final image = _decodedImage!;

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final imageRect = _calculateDisplayedImageRect(
      canvasSize: canvasSize,
      imageSize: imageSize,
    )!;

    return Offset(
      imageRect.left + (imagePoint.dx / imageSize.width) * imageRect.width,
      imageRect.top + (imagePoint.dy / imageSize.height) * imageRect.height,
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

    final canvasAspect = canvasSize.width / canvasSize.height;

    final imageAspect = imageSize.width / imageSize.height;

    late final Size displayedSize;
    late final Offset origin;

    if (imageAspect > canvasAspect) {
      final width = canvasSize.width;

      final height = width / imageAspect;

      displayedSize = Size(width, height);

      origin = Offset(0, (canvasSize.height - height) / 2);
    } else {
      final height = canvasSize.height;

      final width = height * imageAspect;

      displayedSize = Size(width, height);

      origin = Offset((canvasSize.width - width) / 2, 0);
    }

    return origin & displayedSize;
  }

  double _displayBrushSize(Size canvasSize) {
    final image = _decodedImage;

    if (image == null) {
      return _brushSize;
    }

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final imageRect = _calculateDisplayedImageRect(
      canvasSize: canvasSize,
      imageSize: imageSize,
    );

    if (imageRect == null) {
      return _brushSize;
    }

    return _brushSize * imageRect.width / imageSize.width;
  }

  // ===========================================================================
  // HISTORY
  // ===========================================================================

  bool get _hasMask => _selectedMasks.isNotEmpty || _strokes.isNotEmpty;

  bool get _hasProtection =>
      _protectedMasks.isNotEmpty || _protectedStrokes.isNotEmpty;

  bool get _hasAnyOverlay => _hasMask || _hasProtection;

  void _undo() {
    if (_isRemoving || _isSegmenting || _history.isEmpty) {
      return;
    }

    final last = _history.removeLast();

    setState(() {
      switch (last.type) {
        case _MaskActionType.selection:
          final selection = last.selection;

          if (selection != null) {
            _selectedMasks.remove(selection);
          }
          break;

        case _MaskActionType.stroke:
          final stroke = last.stroke;

          if (stroke != null) {
            _strokes.remove(stroke);
          }
          break;

        case _MaskActionType.protectedSelection:
          final selection = last.selection;

          if (selection != null) {
            _protectedMasks.remove(selection);
          }
          break;

        case _MaskActionType.protectedStroke:
          final stroke = last.stroke;

          if (stroke != null) {
            _protectedStrokes.remove(stroke);
          }
          break;
      }

      _activeStroke = null;
      _activeProtectedStroke = null;
    });
  }

  void _clearSelection() {
    if (_isRemoving || _isSegmenting || !_hasAnyOverlay) {
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
      throw StateError('Image is not available.');
    }

    final recorder = ui.PictureRecorder();

    final canvas = Canvas(recorder);

    final fullRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    canvas.drawRect(fullRect, Paint()..color = Colors.transparent);

    for (final result in _selectedMasks) {
      final maskImage = await _decodeUiImage(result.maskBytes);

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
            ..blendMode = BlendMode.srcOver
            ..filterQuality = FilterQuality.none,
        );
      } finally {
        maskImage.dispose();
      }
    }

    final brushPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = _brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.srcOver;

    for (final stroke in _strokes) {
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
      throw StateError('Image is not available.');
    }

    final recorder = ui.PictureRecorder();

    final canvas = Canvas(recorder);

    final fullRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    canvas.drawRect(fullRect, Paint()..color = Colors.transparent);

    for (final result in _protectedMasks) {
      final maskImage = await _decodeUiImage(result.maskBytes);

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
            ..blendMode = BlendMode.srcOver
            ..filterQuality = FilterQuality.none,
        );
      } finally {
        maskImage.dispose();
      }
    }

    final protectPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = _brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.srcOver;

    for (final stroke in _protectedStrokes) {
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
    final picture = recorder.endRecording();

    final maskImage = await picture.toImage(width, height);

    try {
      final byteData = await maskImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw StateError('Could not encode mask.');
      }

      return byteData.buffer.asUint8List(
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
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      return;
    }

    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);

    for (var index = 1; index < stroke.length; index++) {
      path.lineTo(stroke[index].dx, stroke[index].dy);
    }

    canvas.drawPath(path, paint);
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);

    try {
      final frame = await codec.getNextFrame();

      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  // ===========================================================================
  // OFFLINE REMOVE
  // ===========================================================================

  Future<void> _removeSelectedArea() async {
    if (_isRemoving || _isSegmenting) {
      return;
    }

    if (!_hasMask) {
      _showMessage('Select an object or paint an area first.');

      return;
    }

    // -----------------------------------------------------------------------
    // IMPORTANT:
    //
    // If the user is zoomed in, smoothly restore the image to its original
    // viewport BEFORE showing the rebuilding overlay.
    // -----------------------------------------------------------------------

    await _animateZoomToDefault();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRemoving = true;
    });

    try {
      final hadProtection = _hasProtection;

      final removeMaskBytes = await _createRemoveMask();

      final protectionMaskBytes = await _createProtectionMask();

      if (!mounted) {
        return;
      }

      final editedBytes = await _offlineInpaintingService.inpaint(
        imageBytes: _currentImageBytes,
        maskBytes: removeMaskBytes,
        protectionMaskBytes: protectionMaskBytes,
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
        _currentImageBytes = editedBytes;

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

      _resetZoomImmediately();

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

      _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint('Offline object removal failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage('Could not rebuild the selected area.');
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
    if (_isRemoving || _isSegmenting) {
      return;
    }

    await _animateZoomToDefault();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentImageBytes = widget.imageBytes;

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

    _resetZoomImmediately();

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
    if (_isRemoving || _isSegmenting) {
      return;
    }

    if (!_hasEditedImage) {
      _showMessage('Remove something first.');

      return;
    }

    Navigator.of(context).pop<Uint8List>(_currentImageBytes);
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surfaceHighlight,
        ),
      );
  }

  @override
  void dispose() {
    _decodedImage?.dispose();

    _segmentationService.clearImageCache();

    _zoomResetController.dispose();

    _transformationController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===================================================================
          // FULL-SCREEN PHOTO WORKSPACE
          // ===================================================================
          LayoutBuilder(
            builder: (context, constraints) {
              final viewportSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return InteractiveViewer(
                transformationController: _transformationController,
                minScale: _minZoom,
                maxScale: _maxZoom,
                scaleEnabled: !_isRemoving,
                panEnabled: _mode == _EraserMode.select,
                boundaryMargin: const EdgeInsets.all(120),
                clipBehavior: Clip.hardEdge,
                interactionEndFrictionCoefficient: 0.0000135,
                child: SizedBox(
                  width: viewportSize.width,
                  height: viewportSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Black letterbox space is intentional.
                      // The photo always uses BoxFit.contain, so no part of it
                      // is cropped simply to fill the device screen.
                      const ColoredBox(color: Colors.black),

                      if (!_isLoadingImage)
                        Image.memory(
                          _currentImageBytes,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.high,
                        ),

                      // =====================================================
                      // REMOVE MASKS
                      // =====================================================
                      if (!_isLoadingImage)
                        ..._selectedMasks.map((result) {
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.48,
                                child: Image.memory(
                                  result.maskBytes,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.none,
                                  color: _purple,
                                  colorBlendMode: BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        }),

                      // =====================================================
                      // PROTECTED MASKS
                      // =====================================================
                      if (!_isLoadingImage)
                        ..._protectedMasks.map((result) {
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 0.46,
                                child: Image.memory(
                                  result.maskBytes,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  filterQuality: FilterQuality.none,
                                  color: _protectGreen,
                                  colorBlendMode: BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        }),

                      // =====================================================
                      // REMOVE BRUSH
                      // =====================================================
                      if (!_isLoadingImage)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _BrushOverlayPainter(
                                strokes: _strokes,
                                mapPoint: (point) {
                                  return _imagePointToCanvas(
                                    imagePoint: point,
                                    canvasSize: viewportSize,
                                  );
                                },
                                brushSize: _displayBrushSize(viewportSize),
                                color: _purple,
                              ),
                            ),
                          ),
                        ),

                      // =====================================================
                      // PROTECT BRUSH
                      // =====================================================
                      if (!_isLoadingImage)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _BrushOverlayPainter(
                                strokes: _protectedStrokes,
                                mapPoint: (point) {
                                  return _imagePointToCanvas(
                                    imagePoint: point,
                                    canvasSize: viewportSize,
                                  );
                                },
                                brushSize: _displayBrushSize(viewportSize),
                                color: _protectGreen,
                              ),
                            ),
                          ),
                        ),

                      // =====================================================
                      // EDIT INTERACTION
                      //
                      // Coordinate conversion already rejects touches in the
                      // black letterbox region, so users cannot edit outside
                      // the actual photo.
                      // =====================================================
                      if (!_isLoadingImage)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp:
                                _mode == _EraserMode.select ||
                                    _mode == _EraserMode.protect
                                ? (details) {
                                    _handleTap(
                                      canvasPoint: details.localPosition,
                                      canvasSize: viewportSize,
                                    );
                                  }
                                : null,
                            onPanStart:
                                _mode == _EraserMode.brush ||
                                    _mode == _EraserMode.protect
                                ? (details) {
                                    _startStroke(
                                      canvasPoint: details.localPosition,
                                      canvasSize: viewportSize,
                                    );
                                  }
                                : null,
                            onPanUpdate:
                                _mode == _EraserMode.brush ||
                                    _mode == _EraserMode.protect
                                ? (details) {
                                    _updateStroke(
                                      canvasPoint: details.localPosition,
                                      canvasSize: viewportSize,
                                    );
                                  }
                                : null,
                            onPanEnd:
                                _mode == _EraserMode.brush ||
                                    _mode == _EraserMode.protect
                                ? (_) {
                                    _endStroke();
                                  }
                                : null,
                            onPanCancel:
                                _mode == _EraserMode.brush ||
                                    _mode == _EraserMode.protect
                                ? _endStroke
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ===================================================================
          // TOP FLOATING BAR
          // ===================================================================
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  children: [
                    _GlassIconButton(
                      tooltip: 'Back',
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _isRemoving || _isSegmenting
                          ? null
                          : () {
                              Navigator.of(context).maybePop();
                            },
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Object Eraser',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            switch (_mode) {
                              _EraserMode.select => 'Smart select',
                              _EraserMode.brush => 'Remove brush',
                              _EraserMode.protect => 'Protect',
                            },
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.56),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    _GlassIconButton(
                      tooltip: 'Undo',
                      icon: Icons.undo_rounded,
                      onTap: _history.isEmpty || _isRemoving || _isSegmenting
                          ? null
                          : _undo,
                    ),

                    const SizedBox(width: 7),

                    _GlassIconButton(
                      tooltip: 'Editing tools',
                      icon: Icons.more_vert_rounded,
                      active: _showTools,
                      onTap: _isRemoving || _isSegmenting
                          ? null
                          : () {
                              setState(() {
                                _showTools = !_showTools;
                              });
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===================================================================
          // STATUS
          // ===================================================================
          if (_isLoadingImage) const _LoadingView(title: 'Opening photo...'),

          if (_isSegmenting)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 66),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _StatusPill(
                    icon: _mode == _EraserMode.protect
                        ? Icons.shield_outlined
                        : Icons.auto_awesome_rounded,
                    text: _mode == _EraserMode.protect
                        ? 'Protecting subject'
                        : 'Selecting object',
                    color: _mode == _EraserMode.protect
                        ? _protectGreenLight
                        : _purpleLight,
                  ),
                ),
              ),
            ),

          if (_isPreparingSegmentation &&
              !_isLoadingImage &&
              !_isSegmenting &&
              !_isRemoving)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 66),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _StatusPill(
                    icon: Icons.memory_rounded,
                    text: 'Preparing Smart Select',
                    color: _purpleLight,
                  ),
                ),
              ),
            ),

          if (_hasEditedImage && !_isRemoving && !_isLoadingImage)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 68, left: 14),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _EditedBadge(),
                ),
              ),
            ),

          // ===================================================================
          // FLOATING EDITOR PANEL
          // ===================================================================
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: IgnorePointer(
              ignoring: !_showTools,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                offset: _showTools ? Offset.zero : const Offset(0, 1.08),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _showTools ? 1 : 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.70,
                    ),
                    child: _buildControls(),
                  ),
                ),
              ),
            ),
          ),

          // ===================================================================
          // REBUILDING OVERLAY
          // ===================================================================
          if (_isRemoving)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.45),
                child: const _RemovingView(),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FLOATING CONTROLS
  // ===========================================================================

  Widget _buildControls() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xE61A1B1F),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                  const SizedBox(height: 13),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Object Eraser',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      if (_hasAnyOverlay)
                        _PanelIconButton(
                          tooltip: 'Clear selection',
                          icon: Icons.delete_sweep_outlined,
                          onTap: _clearSelection,
                        ),

                      if (_hasEditedImage) ...[
                        const SizedBox(width: 6),
                        _PanelIconButton(
                          tooltip: 'Restore original',
                          icon: Icons.restart_alt_rounded,
                          onTap: _resetToOriginal,
                        ),
                      ],

                      const SizedBox(width: 6),

                      _PanelIconButton(
                        tooltip: 'Close',
                        icon: Icons.close_rounded,
                        onTap: () {
                          setState(() {
                            _showTools = false;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _statusSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // =========================================================
                  // MODE SELECTOR
                  // =========================================================
                  Row(
                    children: [
                      Expanded(
                        child: _CompactModeButton(
                          icon: Icons.touch_app_rounded,
                          label: 'Select',
                          selected: _mode == _EraserMode.select,
                          enabled: !_isPreparingSegmentation,
                          color: _purpleLight,
                          onTap: () {
                            _setMode(_EraserMode.select);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactModeButton(
                          icon: Icons.brush_rounded,
                          label: 'Brush',
                          selected: _mode == _EraserMode.brush,
                          enabled: true,
                          color: _purpleLight,
                          onTap: () {
                            _setMode(_EraserMode.brush);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactModeButton(
                          icon: Icons.shield_outlined,
                          label: 'Protect',
                          selected: _mode == _EraserMode.protect,
                          enabled: !_isPreparingSegmentation,
                          color: _protectGreenLight,
                          onTap: () {
                            _setMode(_EraserMode.protect);
                          },
                        ),
                      ),
                    ],
                  ),

                  // =========================================================
                  // BRUSH SIZE
                  // =========================================================
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 170),
                    child:
                        (_mode == _EraserMode.brush ||
                            _mode == _EraserMode.protect)
                        ? Padding(
                            key: ValueKey('brush-${_mode.name}'),
                            padding: const EdgeInsets.only(top: 14),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.055),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.065),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Center(
                                      child: Container(
                                        width: 5 + (_brushSize / 360) * 10,
                                        height: 5 + (_brushSize / 360) * 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _mode == _EraserMode.protect
                                              ? _protectGreenLight
                                              : _purpleLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Size',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _brushSize,
                                      min: 25,
                                      max: 360,
                                      activeColor: _mode == _EraserMode.protect
                                          ? _protectGreenLight
                                          : _purpleLight,
                                      inactiveColor: Colors.white12,
                                      onChanged: _isRemoving
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _brushSize = value;
                                              });
                                            },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-brush')),
                  ),

                  const SizedBox(height: 14),

                  // =========================================================
                  // CURRENT STATE
                  // =========================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.045),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _statusTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_hasAnyOverlay) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '${_selectedMasks.length + _strokes.length} remove'
                                  '${_hasProtection ? '  •  ${_protectedMasks.length + _protectedStrokes.length} protected' : ''}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.38),
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_isPreparingSegmentation)
                          const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.7,
                              color: _purpleLight,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =========================================================
                  // REMOVE
                  // =========================================================
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _hasMask &&
                              !_isRemoving &&
                              !_isSegmenting &&
                              !_isLoadingImage
                          ? _removeSelectedArea
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.10,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.32,
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: _isRemoving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: Text(
                        _isRemoving ? 'Removing' : 'Remove selected area',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  if (_hasEditedImage) ...[
                    const SizedBox(height: 9),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRemoving || _isSegmenting
                            ? null
                            : _saveAndFinish,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Save & Finish',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _statusTitle {
    if (_isRemoving) {
      return 'Rebuilding selected area';
    }

    if (_isSegmenting) {
      return _mode == _EraserMode.protect
          ? 'Detecting protected subject'
          : 'Detecting object';
    }

    if (_mode == _EraserMode.protect) {
      return 'Protect important areas';
    }

    if (_hasMask) {
      return 'Ready to remove';
    }

    if (_hasEditedImage) {
      return 'Edit complete';
    }

    if (_mode == _EraserMode.select) {
      return 'Tap objects to select';
    }

    return 'Paint unwanted areas';
  }

  String get _statusSubtitle {
    if (_isRemoving) {
      return 'LaMa is reconstructing the background while protected pixels remain untouched.';
    }

    if (_mode == _EraserMode.protect) {
      return 'Tap or paint protected areas. Pinch with two fingers to zoom.';
    }

    if (_hasMask && _hasProtection) {
      return 'Green areas have priority and will never be sent to LaMa for reconstruction.';
    }

    if (_hasMask) {
      return 'Protect nearby faces, hands or body parts when objects overlap them.';
    }

    if (_hasEditedImage) {
      return 'Keep editing, or save the finished result.';
    }

    if (_mode == _EraserMode.select) {
      return 'Tap objects to select. Pinch with two fingers to zoom.';
    }

    return 'Paint unwanted areas. Pinch with two fingers to zoom.';
  }
}

// =============================================================================
// PREMIUM FLOATING CONTROLS
// =============================================================================

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: active
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: enabled ? 0.34 : 0.18),
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.white.withValues(alpha: active ? 0.20 : 0.10),
              ),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  icon,
                  size: 19,
                  color: enabled ? Colors.white : Colors.white24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  const _PanelIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 17,
              color: onTap == null ? Colors.white24 : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactModeButton extends StatelessWidget {
  const _CompactModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.11)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.17)
              : Colors.white.withValues(alpha: 0.055),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: !enabled
                      ? Colors.white24
                      : selected
                      ? color
                      : Colors.white60,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: !enabled
                        ? Colors.white24
                        : selected
                        ? Colors.white
                        : Colors.white60,
                    fontSize: 9.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
// HISTORY
// =============================================================================

class _MaskAction {
  const _MaskAction._({required this.type, this.selection, this.stroke});

  factory _MaskAction.selection(SegmentationResult result) {
    return _MaskAction._(type: _MaskActionType.selection, selection: result);
  }

  factory _MaskAction.stroke(List<Offset> stroke) {
    return _MaskAction._(type: _MaskActionType.stroke, stroke: stroke);
  }

  factory _MaskAction.protectedSelection(SegmentationResult result) {
    return _MaskAction._(
      type: _MaskActionType.protectedSelection,
      selection: result,
    );
  }

  factory _MaskAction.protectedStroke(List<Offset> stroke) {
    return _MaskAction._(type: _MaskActionType.protectedStroke, stroke: stroke);
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

  final Offset Function(Offset imagePoint) mapPoint;

  final double brushSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = brushSize + 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.57)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) {
        continue;
      }

      if (stroke.length == 1) {
        final point = mapPoint(stroke.first);

        canvas.drawCircle(
          point,
          brushSize / 2,
          Paint()..color = color.withValues(alpha: 0.57),
        );

        continue;
      }

      final first = mapPoint(stroke.first);

      final path = Path()..moveTo(first.dx, first.dy);

      for (var index = 1; index < stroke.length; index++) {
        final point = mapPoint(stroke[index]);

        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, glowPaint);

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushOverlayPainter oldDelegate) {
    return true;
  }
}

// =============================================================================
// PREMIUM REMOVE BUTTON
// =============================================================================

// =============================================================================
// MODE BUTTON
// =============================================================================

// =============================================================================
// TOP APP BAR ACTION
// =============================================================================

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
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xCC0D1321),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.7,
                    color: color,
                  ),
                ),

                const SizedBox(width: 8),

                Icon(icon, color: color, size: 14),

                const SizedBox(width: 6),

                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF052E1B).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.24),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF86EFAC), size: 14),
          SizedBox(width: 5),
          Text(
            'Edited',
            style: TextStyle(
              color: Color(0xFFBBF7D0),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
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
  const _LoadingView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(15),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFC4B5FD),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Rebuilding background',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Protected subjects stay untouched while neural inpainting rebuilds the selected area.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: colorScheme.primary,
                    size: 13,
                  ),

                  const SizedBox(width: 5),

                  Flexible(
                    child: Text(
                      'Protected pixels are locked',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
