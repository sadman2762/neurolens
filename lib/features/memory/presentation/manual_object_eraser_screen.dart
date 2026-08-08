import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/data/image_edit_api_service.dart';

class ManualObjectEraserScreen extends StatefulWidget {
  const ManualObjectEraserScreen({
    required this.imageBytes,
    required this.title,
    super.key,
  });

  final Uint8List imageBytes;
  final String title;

  @override
  State<ManualObjectEraserScreen> createState() =>
      _ManualObjectEraserScreenState();
}

class _ManualObjectEraserScreenState extends State<ManualObjectEraserScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleLight = Color(0xFFC4B5FD);

  final ImageEditApiService _imageEditApiService = ImageEditApiService();

  final List<List<Offset>> _strokes = <List<Offset>>[];

  List<Offset>? _activeStroke;

  late Uint8List _currentImageBytes;

  ui.Image? _decodedImage;

  bool _isLoading = true;
  bool _isRemoving = false;
  bool _hasEditedImage = false;

  double _brushSize = 90;

  @override
  void initState() {
    super.initState();

    _currentImageBytes = widget.imageBytes;

    _decodeCurrentImage();
  }

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
        _isLoading = false;
      });

      oldImage?.dispose();
      codec.dispose();
    } catch (error, stackTrace) {
      debugPrint('Manual eraser image decode failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('Could not open this photo.');
    }
  }

  void _startStroke({required Offset canvasPoint, required Size canvasSize}) {
    if (_isRemoving || _isLoading) {
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
      _activeStroke = <Offset>[imagePoint];

      _strokes.add(_activeStroke!);
    });
  }

  void _updateStroke({required Offset canvasPoint, required Size canvasSize}) {
    if (_isRemoving) {
      return;
    }

    final stroke = _activeStroke;

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
  }

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

  void _undo() {
    if (_isRemoving || _strokes.isEmpty) {
      return;
    }

    setState(() {
      _strokes.removeLast();
      _activeStroke = null;
    });
  }

  void _clear() {
    if (_isRemoving || _strokes.isEmpty) {
      return;
    }

    setState(() {
      _strokes.clear();
      _activeStroke = null;
    });
  }

  Future<void> _resetToOriginal() async {
    if (_isRemoving) {
      return;
    }

    setState(() {
      _currentImageBytes = widget.imageBytes;

      _strokes.clear();
      _activeStroke = null;

      _hasEditedImage = false;

      _isLoading = true;
    });

    await _decodeCurrentImage();
  }

  Future<void> _removePaintedArea() async {
    if (_isRemoving) {
      return;
    }

    if (_strokes.isEmpty) {
      _showMessage('Paint over something you want to remove.');

      return;
    }

    final image = _decodedImage;

    if (image == null) {
      return;
    }

    setState(() {
      _isRemoving = true;
    });

    try {
      final maskBytes = await _createMask(
        width: image.width,
        height: image.height,
      );

      if (!mounted) {
        return;
      }

      final editedBytes = await _imageEditApiService.removeObject(
        imageBytes: _currentImageBytes,
        maskBytes: maskBytes,
      );

      if (!mounted) {
        return;
      }

      if (editedBytes.isEmpty) {
        throw const ImageEditException(
          'The AI service returned an empty image.',
        );
      }

      setState(() {
        _currentImageBytes = editedBytes;

        _strokes.clear();
        _activeStroke = null;

        _hasEditedImage = true;

        _isLoading = true;
      });

      await _decodeCurrentImage();

      if (!mounted) {
        return;
      }

      _showMessage('Object removed. You can paint another area or save.');
    } on ImageEditException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (error, stackTrace) {
      debugPrint('Manual AI removal failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage('Could not remove the selected area.');
    } finally {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });
      }
    }
  }

  void _saveAndFinish() {
    if (_isRemoving) {
      return;
    }

    if (!_hasEditedImage) {
      _showMessage('Remove something first.');

      return;
    }

    Navigator.of(context).pop<Uint8List>(_currentImageBytes);
  }

  Future<Uint8List> _createMask({
    required int width,
    required int height,
  }) async {
    final recorder = ui.PictureRecorder();

    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.fill,
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
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );

        continue;
      }

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);

      for (var index = 1; index < stroke.length; index++) {
        path.lineTo(stroke[index].dx, stroke[index].dy);
      }

      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();

    final maskImage = await picture.toImage(width, height);

    final byteData = await maskImage.toByteData(format: ui.ImageByteFormat.png);

    maskImage.dispose();

    if (byteData == null) {
      throw StateError('Could not encode manual mask.');
    }

    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _decodedImage?.dispose();

    _imageEditApiService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manual Eraser',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Undo stroke',
            onPressed: _strokes.isEmpty || _isRemoving ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),

          IconButton(
            tooltip: 'Clear paint',
            onPressed: _strokes.isEmpty || _isRemoving ? null : _clear,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),

          if (_hasEditedImage)
            IconButton(
              tooltip: 'Reset to original',
              onPressed: _isRemoving ? null : _resetToOriginal,
              icon: const Icon(Icons.restart_alt_rounded),
            ),

          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxHeight - 175,
            );

            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (!_isLoading)
                              Image.memory(
                                _currentImageBytes,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),

                            if (!_isLoading)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) {
                                  _startStroke(
                                    canvasPoint: details.localPosition,
                                    canvasSize: canvasSize,
                                  );
                                },
                                onPanUpdate: (details) {
                                  _updateStroke(
                                    canvasPoint: details.localPosition,
                                    canvasSize: canvasSize,
                                  );
                                },
                                onPanEnd: (_) {
                                  _endStroke();
                                },
                                child: CustomPaint(
                                  painter: _ManualMaskPainter(
                                    strokes: _strokes,
                                    mapPoint: (point) {
                                      return _imagePointToCanvas(
                                        imagePoint: point,
                                        canvasSize: canvasSize,
                                      );
                                    },
                                    brushSize: _displayBrushSize(canvasSize),
                                  ),
                                ),
                              ),

                            if (_isLoading) const _ManualEraserLoadingView(),

                            if (_isRemoving)
                              Positioned.fill(
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.58),
                                  child: const Center(child: _RemovingView()),
                                ),
                              ),

                            if (_hasEditedImage && !_isRemoving && !_isLoading)
                              Positioned(
                                top: 14,
                                left: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF16A34A,
                                    ).withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Edited',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: const BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.brush_rounded,
                            color: _purpleLight,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Brush size',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: _brushSize,
                              min: 30,
                              max: 360,
                              activeColor: _purple,
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

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasEditedImage
                                      ? 'Keep editing or save'
                                      : 'Paint over what you want removed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hasEditedImage
                                      ? 'Paint another area to remove more, or save this result.'
                                      : 'The purple area will be rebuilt by AI.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          FilledButton.icon(
                            onPressed:
                                _strokes.isEmpty || _isRemoving || _isLoading
                                ? null
                                : _removePaintedArea,
                            style: FilledButton.styleFrom(
                              backgroundColor: _purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _isRemoving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_fix_high_rounded,
                                    size: 18,
                                  ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),

                      if (_hasEditedImage) ...[
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isRemoving ? null : _saveAndFinish,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: _purpleLight.withValues(alpha: 0.55),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.save_alt_rounded, size: 18),
                            label: const Text(
                              'Save & Finish',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
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

class _ManualMaskPainter extends CustomPainter {
  const _ManualMaskPainter({
    required this.strokes,
    required this.mapPoint,
    required this.brushSize,
  });

  final List<List<Offset>> strokes;

  final Offset Function(Offset imagePoint) mapPoint;

  final double brushSize;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.24)
      ..strokeWidth = brushSize + 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final strokePaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.58)
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
          Paint()..color = const Color(0xFF8B5CF6).withValues(alpha: 0.58),
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
  bool shouldRepaint(covariant _ManualMaskPainter oldDelegate) {
    return true;
  }
}

class _ManualEraserLoadingView extends StatelessWidget {
  const _ManualEraserLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          SizedBox(height: 14),
          Text(
            'Opening photo...',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovingView extends StatelessWidget {
  const _RemovingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: Color(0xFFC4B5FD)),
        SizedBox(height: 18),
        Text(
          'Removing object...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'AI is rebuilding the selected area.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
