import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:neurolens/features/memory/data/local_segmentation_service.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_sticker.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_sticker_library.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_sticker_widget.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_text.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_text_editor_sheet.dart';
import 'package:neurolens/features/memory/presentation/doodles/doodle_text_widget.dart';

enum _DoodleTool {
  pen,
  marker,
  eraser,
}

enum _DoodleEditorMode {
  draw,
  stickers,
  text,
  outline,
}

class DoodleEditorScreen extends StatefulWidget {
  const DoodleEditorScreen({
    required this.imageBytes,
    required this.title,
    super.key,
  });

  final Uint8List imageBytes;
  final String title;

  @override
  State<DoodleEditorScreen> createState() =>
      _DoodleEditorScreenState();
}

class _DoodleEditorScreenState extends State<DoodleEditorScreen> {
  static const Color _surface = Color(0xFF0D1321);
  static const Color _surfaceHighlight = Color(0xFF141B2D);

  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleLight = Color(0xFFC4B5FD);

  static const Color _green = Color(0xFF22C55E);
  static const Color _greenLight = Color(0xFF86EFAC);

  final GlobalKey _exportKey = GlobalKey();

  final TransformationController _transformationController =
      TransformationController();

  // ===========================================================================
  // MOBILE SAM
  // ===========================================================================

  final LocalSegmentationService _segmentationService =
      LocalSegmentationService();

  ui.Image? _decodedImage;

  bool _isPreparingSegmentation = true;
  bool _isSegmenting = false;

  // ===========================================================================
  // DRAWING
  // ===========================================================================

  final List<_DoodleStroke> _strokes = <_DoodleStroke>[];

  final List<_DoodleStroke> _redoStack = <_DoodleStroke>[];

  _DoodleStroke? _activeStroke;

  _DoodleTool _tool = _DoodleTool.pen;

  Color _selectedColor = Colors.white;

  double _brushSize = 8;

  // ===========================================================================
  // STICKERS
  // ===========================================================================

  final List<DoodleSticker> _stickers = <DoodleSticker>[];

  String? _selectedStickerId;

  String _selectedCategory =
      DoodleStickerLibrary.categories.first;

  // ===========================================================================
  // TEXT
  // ===========================================================================

  final List<DoodleText> _textElements = <DoodleText>[];

  String? _selectedTextId;

  // ===========================================================================
  // OBJECT OUTLINES
  // ===========================================================================

  final List<_ObjectOutline> _objectOutlines =
      <_ObjectOutline>[];

  final List<_ObjectOutline> _outlineRedoStack =
      <_ObjectOutline>[];

  Color _outlineColor = Colors.white;

  double _outlineWidth = 2.5;

  double _outlineDashLength = 10;

  final double _outlineGapLength = 7;

  // Slightly pushes the decorative line away from the object.
  final double _outlineOffset = 3;

  // ===========================================================================
  // CANVAS
  // ===========================================================================

  Size _canvasSize = Size.zero;

  // ===========================================================================
  // EDITOR
  // ===========================================================================

  _DoodleEditorMode _editorMode =
      _DoodleEditorMode.draw;

  bool _isExporting = false;

  // Floating editor panel opened from the top-right overflow button.
  bool _showTools = false;

  static const List<Color> _colors = [
    Colors.white,
    Color(0xFFFFE082),
    Color(0xFFFFB4C8),
    Color(0xFFF8BBD0),
    Color(0xFFC4B5FD),
    Color(0xFFA5B4FC),
    Color(0xFF93C5FD),
    Color(0xFF67E8F9),
    Color(0xFF86EFAC),
    Color(0xFFFDE68A),
    Color(0xFFFCA5A5),
  ];

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _initializeMobileSam();
  }

  Future<void> _initializeMobileSam() async {
    await _decodeImage();

    if (!mounted) {
      return;
    }

    await _prepareSegmentation();
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

      final oldImage = _decodedImage;

      setState(() {
        _decodedImage = frame.image;
      });

      oldImage?.dispose();

      codec.dispose();
    } catch (error, stackTrace) {
      debugPrint(
        'Doodle image decode failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
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
        widget.imageBytes,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Doodle MobileSAM preparation failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (mounted) {
        _showMessage(
          'Object Outline could not be prepared.',
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
  // DRAWING
  // ===========================================================================

  void _startStroke(
    Offset position,
  ) {
    if (_isExporting ||
        _editorMode != _DoodleEditorMode.draw) {
      return;
    }

    final stroke = _DoodleStroke(
      points: [
        position,
      ],
      color: _selectedColor,
      width: _brushSize,
      tool: _tool,
    );

    setState(() {
      _activeStroke = stroke;

      _strokes.add(
        stroke,
      );

      _redoStack.clear();

      _selectedStickerId = null;
      _selectedTextId = null;
    });
  }

  void _updateStroke(
    Offset position,
  ) {
    final stroke = _activeStroke;

    if (stroke == null ||
        _editorMode != _DoodleEditorMode.draw) {
      return;
    }

    setState(() {
      stroke.points.add(
        position,
      );
    });
  }

  void _endStroke() {
    _activeStroke = null;
  }

  // ===========================================================================
  // OBJECT OUTLINE
  // ===========================================================================

  Future<void> _handleOutlineTap({
    required Offset canvasPoint,
    required Size canvasSize,
  }) async {
    if (_editorMode !=
            _DoodleEditorMode.outline ||
        _isPreparingSegmentation ||
        _isSegmenting ||
        _isExporting) {
      return;
    }

    final imagePoint =
        _canvasPointToImage(
      canvasPoint: canvasPoint,
      canvasSize: canvasSize,
    );

    if (imagePoint == null) {
      _showMessage(
        'Tap directly on the photo.',
      );
      return;
    }

    setState(() {
      _isSegmenting = true;
    });

    try {
      final result =
          await _segmentationService
              .segmentDetailedFromPoint(
        imageBytes: widget.imageBytes,
        imagePoint: imagePoint,
      );

      final contour =
          await _extractObjectContour(
        result.maskBytes,
      );

      if (!mounted) {
        return;
      }

      if (contour.length < 3) {
        _showMessage(
          'Could not trace this object.',
        );
        return;
      }

      final outline =
          _ObjectOutline(
        id:
            'outline_${DateTime.now().microsecondsSinceEpoch}',
        imagePoints: contour,
        color: _outlineColor,
        width: _outlineWidth,
        dashLength:
            _outlineDashLength,
        gapLength:
            _outlineGapLength,
        offset:
            _outlineOffset,
      );

      setState(() {
        _objectOutlines.add(
          outline,
        );

        _outlineRedoStack.clear();
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Object outline selection failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (mounted) {
        _showMessage(
          'Could not outline this object.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSegmenting = false;
        });
      }
    }
  }

  // ===========================================================================
  // MASK -> CONTOUR
  // ===========================================================================

  Future<List<Offset>> _extractObjectContour(
    Uint8List maskBytes,
  ) async {
    final image = _decodedImage;

    if (image == null) {
      return const <Offset>[];
    }

    final codec =
        await ui.instantiateImageCodec(
      maskBytes,
    );

    final frame =
        await codec.getNextFrame();

    final maskImage =
        frame.image;

    try {
      final rgba =
          await maskImage.toByteData(
        format:
            ui.ImageByteFormat.rawRgba,
      );

      if (rgba == null) {
        return const <Offset>[];
      }

      final maskWidth =
          maskImage.width;

      final maskHeight =
          maskImage.height;

      if (maskWidth <= 1 ||
          maskHeight <= 1) {
        return const <Offset>[];
      }

      // ---------------------------------------------------------------------
      // Downsample very large masks.
      //
      // This keeps contour extraction fast while maintaining a smooth
      // decorative boundary.
      // ---------------------------------------------------------------------

      final longestSide =
          maskWidth > maskHeight
              ? maskWidth
              : maskHeight;

      final stride =
          longestSide > 700
              ? 4
              : longestSide > 400
                  ? 3
                  : longestSide > 220
                      ? 2
                      : 1;

      final gridWidth =
          (maskWidth / stride).ceil();

      final gridHeight =
          (maskHeight / stride).ceil();

      final foreground =
          List<bool>.filled(
        gridWidth * gridHeight,
        false,
      );

      bool pixelIsForeground(
        int x,
        int y,
      ) {
        final sourceX =
            (x * stride).clamp(
          0,
          maskWidth - 1,
        );

        final sourceY =
            (y * stride).clamp(
          0,
          maskHeight - 1,
        );

        final pixelIndex =
            (
                    sourceY *
                        maskWidth +
                    sourceX) *
                4;

        final r =
            rgba.getUint8(
          pixelIndex,
        );

        final g =
            rgba.getUint8(
          pixelIndex + 1,
        );

        final b =
            rgba.getUint8(
          pixelIndex + 2,
        );

        final a =
            rgba.getUint8(
          pixelIndex + 3,
        );

        final brightness =
            r > g
                ? (
                    r > b
                        ? r
                        : b)
                : (
                    g > b
                        ? g
                        : b);

        return a > 25 &&
            brightness > 35;
      }

      for (var y = 0;
          y < gridHeight;
          y++) {
        for (var x = 0;
            x < gridWidth;
            x++) {
          foreground[
                  y * gridWidth +
                      x] =
              pixelIsForeground(
            x,
            y,
          );
        }
      }

      bool isForeground(
        int x,
        int y,
      ) {
        if (x < 0 ||
            y < 0 ||
            x >= gridWidth ||
            y >= gridHeight) {
          return false;
        }

        return foreground[
            y * gridWidth + x];
      }

      // ---------------------------------------------------------------------
      // Build boundary segments around foreground cells.
      //
      // Every foreground pixel contributes only the edges that touch
      // background. This gives us the true outer boundary rather than a box.
      // ---------------------------------------------------------------------

      final segments =
          <_ContourSegment>[];

      for (var y = 0;
          y < gridHeight;
          y++) {
        for (var x = 0;
            x < gridWidth;
            x++) {
          if (!isForeground(
            x,
            y,
          )) {
            continue;
          }

          if (!isForeground(
            x,
            y - 1,
          )) {
            segments.add(
              _ContourSegment(
                _GridPoint(
                  x,
                  y,
                ),
                _GridPoint(
                  x + 1,
                  y,
                ),
              ),
            );
          }

          if (!isForeground(
            x + 1,
            y,
          )) {
            segments.add(
              _ContourSegment(
                _GridPoint(
                  x + 1,
                  y,
                ),
                _GridPoint(
                  x + 1,
                  y + 1,
                ),
              ),
            );
          }

          if (!isForeground(
            x,
            y + 1,
          )) {
            segments.add(
              _ContourSegment(
                _GridPoint(
                  x + 1,
                  y + 1,
                ),
                _GridPoint(
                  x,
                  y + 1,
                ),
              ),
            );
          }

          if (!isForeground(
            x - 1,
            y,
          )) {
            segments.add(
              _ContourSegment(
                _GridPoint(
                  x,
                  y + 1,
                ),
                _GridPoint(
                  x,
                  y,
                ),
              ),
            );
          }
        }
      }

      if (segments.isEmpty) {
        return const <Offset>[];
      }

      // ---------------------------------------------------------------------
      // Join boundary segments into closed loops.
      // ---------------------------------------------------------------------

      final loops =
          _buildContourLoops(
        segments,
      );

      if (loops.isEmpty) {
        return const <Offset>[];
      }

      // Largest loop is normally the selected object's outer silhouette.
      loops.sort(
        (
          a,
          b,
        ) =>
            b.length.compareTo(
          a.length,
        ),
      );

      final largest =
          loops.first;

      if (largest.length < 4) {
        return const <Offset>[];
      }

      // ---------------------------------------------------------------------
      // Convert grid coordinates to original image coordinates.
      // ---------------------------------------------------------------------

      final imageWidth =
          image.width.toDouble();

      final imageHeight =
          image.height.toDouble();

      final scaleX =
          imageWidth /
          maskWidth;

      final scaleY =
          imageHeight /
          maskHeight;

      var points =
          largest.map(
        (
          point,
        ) {
          return Offset(
            point.x *
                stride *
                scaleX,
            point.y *
                stride *
                scaleY,
          );
        },
      ).toList();

      // ---------------------------------------------------------------------
      // Simplify.
      // ---------------------------------------------------------------------

      points =
          _simplifyClosedContour(
        points,
        tolerance:
            imageWidth > 1500
                ? 4.5
                : 2.5,
      );

      // ---------------------------------------------------------------------
      // Smooth.
      // Two iterations produces a hand-drawn smooth contour without
      // destroying the detected shape.
      // ---------------------------------------------------------------------

      points =
          _smoothClosedContour(
        points,
        iterations: 2,
      );

      return points;
    } finally {
      maskImage.dispose();
      codec.dispose();
    }
  }

  List<List<_GridPoint>>
      _buildContourLoops(
    List<_ContourSegment> segments,
  ) {
    final adjacency =
        <_GridPoint, List<_GridPoint>>{};

    for (final segment
        in segments) {
      adjacency
          .putIfAbsent(
            segment.a,
            () =>
                <_GridPoint>[],
          )
          .add(
            segment.b,
          );

      adjacency
          .putIfAbsent(
            segment.b,
            () =>
                <_GridPoint>[],
          )
          .add(
            segment.a,
          );
    }

    final usedEdges =
        <_ContourEdge>{};

    final loops =
        <List<_GridPoint>>[];

    for (final segment
        in segments) {
      final initialEdge =
          _ContourEdge(
        segment.a,
        segment.b,
      );

      if (usedEdges.contains(
        initialEdge,
      )) {
        continue;
      }

      final loop =
          <_GridPoint>[
        segment.a,
      ];

      var previous =
          segment.a;

      var current =
          segment.b;

      usedEdges.add(
        initialEdge,
      );

      var safety =
          0;

      while (safety <
          segments.length + 5) {
        safety++;

        loop.add(
          current,
        );

        if (current ==
            loop.first) {
          break;
        }

        final neighbours =
            adjacency[current];

        if (neighbours == null ||
            neighbours.isEmpty) {
          break;
        }

        _GridPoint? next;

        for (final neighbour
            in neighbours) {
          if (neighbour ==
              previous) {
            continue;
          }

          final edge =
              _ContourEdge(
            current,
            neighbour,
          );

          if (!usedEdges.contains(
            edge,
          )) {
            next =
                neighbour;
            break;
          }
        }

        if (next == null) {
          for (final neighbour
              in neighbours) {
            final edge =
                _ContourEdge(
              current,
              neighbour,
            );

            if (!usedEdges.contains(
              edge,
            )) {
              next =
                  neighbour;
              break;
            }
          }
        }

        if (next == null) {
          break;
        }

        usedEdges.add(
          _ContourEdge(
            current,
            next,
          ),
        );

        previous =
            current;

        current =
            next;
      }

      if (loop.length >= 4) {
        loops.add(
          loop,
        );
      }
    }

    return loops;
  }

  // ===========================================================================
  // CONTOUR SIMPLIFICATION
  // ===========================================================================

  List<Offset>
      _simplifyClosedContour(
    List<Offset> points, {
    required double tolerance,
  }) {
    if (points.length <
        5) {
      return points;
    }

    final open =
        List<Offset>.from(
      points,
    );

    if (open.first ==
        open.last) {
      open.removeLast();
    }

    if (open.length <
        4) {
      return open;
    }

    // Pick a point roughly opposite the first to break the closed loop.
    var farthestIndex =
        1;

    var farthestDistance =
        0.0;

    final first =
        open.first;

    for (var i = 1;
        i < open.length;
        i++) {
      final delta =
          open[i] - first;

      final distance =
          delta.distanceSquared;

      if (distance >
          farthestDistance) {
        farthestDistance =
            distance;

        farthestIndex =
            i;
      }
    }

    final firstHalf =
        <Offset>[
      ...open.sublist(
        0,
        farthestIndex + 1,
      ),
    ];

    final secondHalf =
        <Offset>[
      ...open.sublist(
        farthestIndex,
      ),
      open.first,
    ];

    final simplifiedA =
        _rdp(
      firstHalf,
      tolerance,
    );

    final simplifiedB =
        _rdp(
      secondHalf,
      tolerance,
    );

    final result =
        <Offset>[
      ...simplifiedA,
      ...simplifiedB.skip(
        1,
      ),
    ];

    if (result.isNotEmpty &&
        result.first ==
            result.last) {
      result.removeLast();
    }

    return result;
  }

  List<Offset> _rdp(
    List<Offset> points,
    double epsilon,
  ) {
    if (points.length <
        3) {
      return List<Offset>.from(
        points,
      );
    }

    var maxDistance =
        0.0;

    var index =
        0;

    final start =
        points.first;

    final end =
        points.last;

    for (var i = 1;
        i <
            points.length - 1;
        i++) {
      final distance =
          _perpendicularDistance(
        points[i],
        start,
        end,
      );

      if (distance >
          maxDistance) {
        maxDistance =
            distance;

        index =
            i;
      }
    }

    if (maxDistance >
        epsilon) {
      final left =
          _rdp(
        points.sublist(
          0,
          index + 1,
        ),
        epsilon,
      );

      final right =
          _rdp(
        points.sublist(
          index,
        ),
        epsilon,
      );

      return [
        ...left.take(
          left.length - 1,
        ),
        ...right,
      ];
    }

    return [
      start,
      end,
    ];
  }

  double _perpendicularDistance(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
  ) {
    final dx =
        lineEnd.dx -
        lineStart.dx;

    final dy =
        lineEnd.dy -
        lineStart.dy;

    if (dx == 0 &&
        dy == 0) {
      return (
        point -
        lineStart
      ).distance;
    }

    final numerator =
        (
                dy *
                    point.dx -
                dx *
                    point.dy +
                lineEnd.dx *
                    lineStart.dy -
                lineEnd.dy *
                    lineStart.dx)
            .abs();

    final denominator =
        Offset(
      dx,
      dy,
    ).distance;

    return numerator /
        denominator;
  }

  // ===========================================================================
  // CONTOUR SMOOTHING
  // ===========================================================================

  List<Offset>
      _smoothClosedContour(
    List<Offset> points, {
    int iterations = 1,
  }) {
    if (points.length <
        3) {
      return points;
    }

    var result =
        List<Offset>.from(
      points,
    );

    for (var iteration = 0;
        iteration < iterations;
        iteration++) {
      final next =
          <Offset>[];

      for (var i = 0;
          i < result.length;
          i++) {
        final current =
            result[i];

        final following =
            result[
                (i + 1) %
                    result.length];

        final q =
            Offset(
          current.dx *
                  0.75 +
              following.dx *
                  0.25,
          current.dy *
                  0.75 +
              following.dy *
                  0.25,
        );

        final r =
            Offset(
          current.dx *
                  0.25 +
              following.dx *
                  0.75,
          current.dy *
                  0.25 +
              following.dy *
                  0.75,
        );

        next
          ..add(
            q,
          )
          ..add(
            r,
          );
      }

      result =
          next;
    }

    return result;
  }

  // ===========================================================================
  // COORDINATE MAPPING
  // ===========================================================================

  Offset? _canvasPointToImage({
    required Offset canvasPoint,
    required Size canvasSize,
  }) {
    final image =
        _decodedImage;

    if (image == null) {
      return null;
    }

    final imageSize =
        Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final imageRect =
        _calculateDisplayedImageRect(
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
        (
                canvasPoint.dx -
                    imageRect.left) /
            imageRect.width;

    final normalizedY =
        (
                canvasPoint.dy -
                    imageRect.top) /
            imageRect.height;

    return Offset(
      normalizedX *
          imageSize.width,
      normalizedY *
          imageSize.height,
    );
  }

  Rect? _calculateDisplayedImageRect({
    required Size canvasSize,
    required Size imageSize,
  }) {
    if (canvasSize.width <=
            0 ||
        canvasSize.height <=
            0 ||
        imageSize.width <=
            0 ||
        imageSize.height <=
            0) {
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

      displayedSize =
          Size(
        width,
        height,
      );

      origin =
          Offset(
        0,
        (
                canvasSize.height -
                    height) /
            2,
      );
    } else {
      final height =
          canvasSize.height;

      final width =
          height *
          imageAspect;

      displayedSize =
          Size(
        width,
        height,
      );

      origin =
          Offset(
        (
                canvasSize.width -
                    width) /
            2,
        0,
      );
    }

    return origin &
        displayedSize;
  }

  // ===========================================================================
  // OUTLINE ACTIONS
  // ===========================================================================

  void _removeLastOutline() {
    if (_objectOutlines.isEmpty ||
        _isSegmenting ||
        _isExporting) {
      return;
    }

    setState(() {
      final removed =
          _objectOutlines.removeLast();

      _outlineRedoStack.add(
        removed,
      );
    });
  }

  void _redoOutline() {
    if (_outlineRedoStack.isEmpty ||
        _isSegmenting ||
        _isExporting) {
      return;
    }

    setState(() {
      _objectOutlines.add(
        _outlineRedoStack.removeLast(),
      );
    });
  }

  void _clearOutlines() {
    if (_objectOutlines.isEmpty ||
        _isSegmenting ||
        _isExporting) {
      return;
    }

    setState(() {
      _objectOutlines.clear();
      _outlineRedoStack.clear();
    });
  }

  // ===========================================================================
  // ADD STICKER
  // ===========================================================================

  void _addSticker(
    DoodleStickerAsset asset,
  ) {
    if (_isExporting ||
        _canvasSize.isEmpty) {
      return;
    }

    final id =
        '${asset.id}_${DateTime.now().microsecondsSinceEpoch}';

    final highestLayer =
        _highestLayer + 1;

    final sticker =
        DoodleSticker(
      id: id,
      assetPath:
          asset.assetPath,
      category:
          asset.category,
      position:
          Offset(
        _canvasSize.width / 2,
        _canvasSize.height / 2,
      ),
      scale:
          0.85,
      rotation:
          0,
      zIndex:
          highestLayer,
    );

    setState(() {
      _stickers.add(
        sticker,
      );

      _selectedStickerId =
          sticker.id;

      _selectedTextId =
          null;
    });
  }

  // ===========================================================================
  // STICKER UPDATE
  // ===========================================================================

  void _updateSticker(
    DoodleSticker updatedSticker,
  ) {
    final index =
        _stickers.indexWhere(
      (
        sticker,
      ) =>
          sticker.id ==
          updatedSticker.id,
    );

    if (index ==
        -1) {
      return;
    }

    setState(() {
      _stickers[index] =
          updatedSticker;
    });
  }

  void _selectSticker(
    String id,
  ) {
    if (_isExporting) {
      return;
    }

    setState(() {
      _selectedStickerId =
          id;

      _selectedTextId =
          null;
    });
  }

  void _deleteSticker(
    String id,
  ) {
    if (_isExporting) {
      return;
    }

    setState(() {
      _stickers.removeWhere(
        (
          sticker,
        ) =>
            sticker.id ==
            id,
      );

      if (_selectedStickerId ==
          id) {
        _selectedStickerId =
            null;
      }
    });
  }

  DoodleSticker? get _selectedSticker {
    final id =
        _selectedStickerId;

    if (id ==
        null) {
      return null;
    }

    for (final sticker
        in _stickers) {
      if (sticker.id ==
          id) {
        return sticker;
      }
    }

    return null;
  }

  // ===========================================================================
  // STICKER ACTIONS
  // ===========================================================================

  void _duplicateSelectedSticker() {
    final selected =
        _selectedSticker;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    final id =
        '${selected.id}_copy_${DateTime.now().microsecondsSinceEpoch}';

    final copy =
        selected.copyWith(
      id:
          id,
      position:
          selected.position +
          const Offset(
            24,
            24,
          ),
      zIndex:
          _highestLayer + 1,
    );

    setState(() {
      _stickers.add(
        copy,
      );

      _selectedStickerId =
          copy.id;
    });
  }

  void _flipSelectedSticker() {
    final selected =
        _selectedSticker;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    _updateSticker(
      selected.copyWith(
        flipX:
            !selected.flipX,
      ),
    );
  }

  void _bringSelectedStickerForward() {
    final selected =
        _selectedSticker;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    _updateSticker(
      selected.copyWith(
        zIndex:
            _highestLayer + 1,
      ),
    );
  }

  void _sendSelectedStickerBackward() {
    final selected =
        _selectedSticker;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    _updateSticker(
      selected.copyWith(
        zIndex:
            _lowestLayer - 1,
      ),
    );
  }

  // ===========================================================================
  // TEXT
  // ===========================================================================

  Future<void> _addText() async {
    if (_isExporting ||
        _canvasSize.isEmpty) {
      return;
    }

    final result =
        await showModalBottomSheet<
            DoodleText>(
      context:
          context,
      isScrollControlled:
          true,
      backgroundColor:
          Colors.transparent,
      builder:
          (_) {
        return const DoodleTextEditorSheet();
      },
    );

    if (!mounted ||
        result ==
            null) {
      return;
    }

    final positioned =
        result.copyWith(
      position:
          Offset(
        (
                _canvasSize.width /
                    2) -
            80,
        (
                _canvasSize.height /
                    2) -
            30,
      ),
      zIndex:
          _highestLayer + 1,
    );

    setState(() {
      _textElements.add(
        positioned,
      );

      _selectedTextId =
          positioned.id;

      _selectedStickerId =
          null;
    });
  }

  Future<void> _editSelectedText() async {
    final selected =
        _selectedText;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    final result =
        await showModalBottomSheet<
            DoodleText>(
      context:
          context,
      isScrollControlled:
          true,
      backgroundColor:
          Colors.transparent,
      builder:
          (_) {
        return DoodleTextEditorSheet(
          initialText:
              selected,
        );
      },
    );

    if (!mounted ||
        result ==
            null) {
      return;
    }

    _updateText(
      result,
    );
  }

  void _updateText(
    DoodleText updated,
  ) {
    final index =
        _textElements.indexWhere(
      (
        element,
      ) =>
          element.id ==
          updated.id,
    );

    if (index ==
        -1) {
      return;
    }

    setState(() {
      _textElements[index] =
          updated;
    });
  }

  void _selectText(
    String id,
  ) {
    if (_isExporting) {
      return;
    }

    setState(() {
      _selectedTextId =
          id;

      _selectedStickerId =
          null;
    });
  }

  void _deleteText(
    String id,
  ) {
    if (_isExporting) {
      return;
    }

    setState(() {
      _textElements.removeWhere(
        (
          element,
        ) =>
            element.id ==
            id,
      );

      if (_selectedTextId ==
          id) {
        _selectedTextId =
            null;
      }
    });
  }

  DoodleText? get _selectedText {
    final id =
        _selectedTextId;

    if (id ==
        null) {
      return null;
    }

    for (final element
        in _textElements) {
      if (element.id ==
          id) {
        return element;
      }
    }

    return null;
  }

  void _duplicateSelectedText() {
    final selected =
        _selectedText;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    final copy =
        selected.copyWith(
      id:
          '${selected.id}_copy_${DateTime.now().microsecondsSinceEpoch}',
      position:
          selected.position +
          const Offset(
            24,
            24,
          ),
      zIndex:
          _highestLayer + 1,
    );

    setState(() {
      _textElements.add(
        copy,
      );

      _selectedTextId =
          copy.id;
    });
  }

  void _bringSelectedTextForward() {
    final selected =
        _selectedText;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    _updateText(
      selected.copyWith(
        zIndex:
            _highestLayer + 1,
      ),
    );
  }

  void _sendSelectedTextBackward() {
    final selected =
        _selectedText;

    if (selected ==
            null ||
        _isExporting) {
      return;
    }

    _updateText(
      selected.copyWith(
        zIndex:
            _lowestLayer - 1,
      ),
    );
  }

  // ===========================================================================
  // LAYER HELPERS
  // ===========================================================================

  int get _highestLayer {
    var highest =
        0;

    for (final sticker
        in _stickers) {
      if (sticker.zIndex >
          highest) {
        highest =
            sticker.zIndex;
      }
    }

    for (final element
        in _textElements) {
      if (element.zIndex >
          highest) {
        highest =
            element.zIndex;
      }
    }

    return highest;
  }

  int get _lowestLayer {
    if (_stickers.isEmpty &&
        _textElements.isEmpty) {
      return 0;
    }

    int? lowest;

    for (final sticker
        in _stickers) {
      if (lowest ==
              null ||
          sticker.zIndex <
              lowest) {
        lowest =
            sticker.zIndex;
      }
    }

    for (final element
        in _textElements) {
      if (lowest ==
              null ||
          element.zIndex <
              lowest) {
        lowest =
            element.zIndex;
      }
    }

    return lowest ??
        0;
  }

  // ===========================================================================
  // MODE
  // ===========================================================================

  void _setEditorMode(
    _DoodleEditorMode mode,
  ) {
    if (_isExporting ||
        _isSegmenting) {
      return;
    }

    if (mode ==
            _DoodleEditorMode.outline &&
        _isPreparingSegmentation) {
      _showMessage(
        'Object Outline is still preparing.',
      );

      return;
    }

    setState(() {
      _editorMode =
          mode;

      _activeStroke =
          null;

      if (mode ==
          _DoodleEditorMode.draw) {
        _selectedStickerId =
            null;

        _selectedTextId =
            null;
      }

      if (mode ==
          _DoodleEditorMode.stickers) {
        _selectedTextId =
            null;
      }

      if (mode ==
          _DoodleEditorMode.text) {
        _selectedStickerId =
            null;
      }

      if (mode ==
          _DoodleEditorMode.outline) {
        _selectedStickerId =
            null;

        _selectedTextId =
            null;
      }
    });
  }

  // ===========================================================================
  // HISTORY
  // ===========================================================================

  void _undo() {
    if (_isExporting ||
        _isSegmenting) {
      return;
    }

    if (_editorMode ==
            _DoodleEditorMode.outline &&
        _objectOutlines.isNotEmpty) {
      _removeLastOutline();
      return;
    }

    if (_strokes.isEmpty) {
      return;
    }

    setState(() {
      final stroke =
          _strokes.removeLast();

      _redoStack.add(
        stroke,
      );

      _activeStroke =
          null;
    });
  }

  void _redo() {
    if (_isExporting ||
        _isSegmenting) {
      return;
    }

    if (_editorMode ==
            _DoodleEditorMode.outline &&
        _outlineRedoStack.isNotEmpty) {
      _redoOutline();
      return;
    }

    if (_redoStack.isEmpty) {
      return;
    }

    setState(() {
      final stroke =
          _redoStack.removeLast();

      _strokes.add(
        stroke,
      );

      _activeStroke =
          null;
    });
  }

  bool get _canUndo {
    if (_editorMode ==
        _DoodleEditorMode.outline) {
      return _objectOutlines.isNotEmpty;
    }

    return _strokes.isNotEmpty;
  }

  bool get _canRedo {
    if (_editorMode ==
        _DoodleEditorMode.outline) {
      return _outlineRedoStack.isNotEmpty;
    }

    return _redoStack.isNotEmpty;
  }

  // ===========================================================================
  // CLEAR
  // ===========================================================================

  void _clear() {
    if ((_strokes.isEmpty &&
            _stickers.isEmpty &&
            _textElements.isEmpty &&
            _objectOutlines.isEmpty) ||
        _isExporting ||
        _isSegmenting) {
      return;
    }

    showDialog<void>(
      context:
          context,
      builder:
          (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              _surface,
          surfaceTintColor:
              Colors.transparent,
          title:
              const Text(
            'Clear doodles?',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content:
              const Text(
            'All drawings, stickers, text and object outlines will be removed.',
            style:
                TextStyle(
              color:
                  Colors.white60,
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _purple,
              ),
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                );

                setState(() {
                  _strokes.clear();
                  _redoStack.clear();

                  _stickers.clear();

                  _textElements.clear();

                  _objectOutlines.clear();
                  _outlineRedoStack.clear();

                  _activeStroke =
                      null;

                  _selectedStickerId =
                      null;

                  _selectedTextId =
                      null;
                });
              },
              child:
                  const Text(
                'Clear',
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // EXPORT
  // ===========================================================================

  Future<void> _save() async {
    if (_isExporting ||
        _isSegmenting) {
      return;
    }

    setState(() {
      _isExporting =
          true;

      _selectedStickerId =
          null;

      _selectedTextId =
          null;
    });

    try {
      _transformationController.value =
          Matrix4.identity();

      await WidgetsBinding
          .instance.endOfFrame;

      final boundary =
          _exportKey.currentContext
              ?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary ==
          null) {
        throw StateError(
          'Could not create doodle image.',
        );
      }

      final ui.Image image =
          await boundary.toImage(
        pixelRatio:
            3,
      );

      try {
        final byteData =
            await image.toByteData(
          format:
              ui.ImageByteFormat.png,
        );

        if (byteData ==
            null) {
          throw StateError(
            'Could not encode doodle image.',
          );
        }

        final result =
            byteData.buffer
                .asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );

        if (!mounted) {
          return;
        }

        Navigator.of(
          context,
        ).pop<Uint8List>(
          result,
        );
      } finally {
        image.dispose();
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'Doodle export failed: $error',
      );

      debugPrintStack(
        stackTrace:
            stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not save doodles.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting =
              false;
        });
      }
    }
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

    ScaffoldMessenger.of(
      context,
    )
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

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _decodedImage?.dispose();

    _segmentationService
        .clearImageCache();

    _transformationController
        .dispose();

    super.dispose();
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final hasContent =
        _strokes.isNotEmpty ||
        _stickers.isNotEmpty ||
        _textElements.isNotEmpty ||
        _objectOutlines.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===================================================================
          // FULL-SCREEN PHOTO WORKSPACE
          // ===================================================================

          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final viewportSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              final decodedImage = _decodedImage;

              final imageSize = decodedImage == null
                  ? viewportSize
                  : Size(
                      decodedImage.width.toDouble(),
                      decodedImage.height.toDouble(),
                    );

              final photoRect = _calculateDisplayedImageRect(
                    canvasSize: viewportSize,
                    imageSize: imageSize,
                  ) ??
                  Offset.zero & viewportSize;

              // Every editable item now lives in PHOTO-LOCAL coordinates.
              // This keeps drawings, text, stickers and outlines from being
              // edited in the black letterbox area.
              _canvasSize = photoRect.size;

              return InteractiveViewer(
                transformationController:
                    _transformationController,
                minScale: 1,
                maxScale: 8,
                scaleEnabled: true,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(
                  120,
                ),
                interactionEndFrictionCoefficient:
                    0.0000135,
                child: SizedBox(
                  width: viewportSize.width,
                  height: viewportSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Black letterbox space is intentional. The photo itself
                      // is always fully visible and is NEVER cropped to fill.
                      const ColoredBox(
                        color: Colors.black,
                      ),

                      Positioned.fromRect(
                        rect: photoRect,
                        child: RepaintBoundary(
                          key: _exportKey,
                          child: ClipRect(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // =================================================
                                // PHOTO
                                // =================================================

                                Image.memory(
                                  widget.imageBytes,
                                  width: photoRect.width,
                                  height: photoRect.height,
                                  fit: BoxFit.fill,
                                  filterQuality:
                                      FilterQuality.high,
                                  gaplessPlayback: true,
                                ),

                                // =================================================
                                // FREEHAND
                                // =================================================

                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _DoodlePainter(
                                        strokes: _strokes,
                                      ),
                                    ),
                                  ),
                                ),

                                // =================================================
                                // OBJECT OUTLINES
                                // =================================================

                                if (decodedImage != null)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter:
                                            _ObjectOutlinePainter(
                                          outlines:
                                              _objectOutlines,
                                          imageSize: imageSize,
                                        ),
                                      ),
                                    ),
                                  ),

                                // =================================================
                                // BACKGROUND DESELECT
                                // =================================================

                                if (_editorMode !=
                                        _DoodleEditorMode.draw &&
                                    _editorMode !=
                                        _DoodleEditorMode.outline &&
                                    !_isExporting)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior:
                                          HitTestBehavior.translucent,
                                      onTap: () {
                                        setState(() {
                                          _selectedStickerId =
                                              null;
                                          _selectedTextId =
                                              null;
                                        });
                                      },
                                    ),
                                  ),

                                // =================================================
                                // STICKERS + TEXT
                                // =================================================

                                ..._buildDecorations(),

                                // =================================================
                                // DRAW INTERACTION — PHOTO ONLY
                                // =================================================

                                if (_editorMode ==
                                        _DoodleEditorMode.draw &&
                                    !_isExporting)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior:
                                          HitTestBehavior.translucent,
                                      onPanStart: (details) {
                                        _startStroke(
                                          details.localPosition,
                                        );
                                      },
                                      onPanUpdate: (details) {
                                        _updateStroke(
                                          details.localPosition,
                                        );
                                      },
                                      onPanEnd: (_) {
                                        _endStroke();
                                      },
                                      onPanCancel:
                                          _endStroke,
                                    ),
                                  ),

                                // =================================================
                                // OBJECT OUTLINE TAP — PHOTO ONLY
                                // =================================================

                                if (_editorMode ==
                                        _DoodleEditorMode.outline &&
                                    !_isExporting)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior:
                                          HitTestBehavior.translucent,
                                      onTapUp: (details) {
                                        _handleOutlineTap(
                                          canvasPoint:
                                              details.localPosition,
                                          canvasSize:
                                              photoRect.size,
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ===================================================================
          // TOP CHROME
          // ===================================================================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                8,
                14,
                0,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    _GlassIconButton(
                      tooltip: 'Back',
                      icon:
                          Icons.arrow_back_ios_new_rounded,
                      onTap: _isExporting ||
                              _isSegmenting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Doodles',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(
                            height: 1,
                          ),
                          Text(
                            switch (_editorMode) {
                              _DoodleEditorMode.draw =>
                                'Draw',
                              _DoodleEditorMode.stickers =>
                                'Stickers',
                              _DoodleEditorMode.text =>
                                'Text',
                              _DoodleEditorMode.outline =>
                                'Object outline',
                            },
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.48,
                              ),
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _GlassIconButton(
                      tooltip: 'Undo',
                      icon: Icons.undo_rounded,
                      onTap: !_canUndo ||
                              _isExporting ||
                              _isSegmenting
                          ? null
                          : _undo,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    _GlassIconButton(
                      tooltip: 'Redo',
                      icon: Icons.redo_rounded,
                      onTap: !_canRedo ||
                              _isExporting ||
                              _isSegmenting
                          ? null
                          : _redo,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    _GlassIconButton(
                      tooltip: 'Editing tools',
                      icon: Icons.more_vert_rounded,
                      active: _showTools,
                      onTap: _isExporting ||
                              _isSegmenting
                          ? null
                          : () {
                              setState(() {
                                _showTools =
                                    !_showTools;
                              });
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===================================================================
          // MOBILE SAM STATUS
          // ===================================================================

          if (_editorMode ==
                  _DoodleEditorMode.outline &&
              _isPreparingSegmentation &&
              !_isSegmenting)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 66,
                ),
                child: Align(
                  alignment:
                      Alignment.topCenter,
                  child: _OutlineStatusPill(
                    text:
                        'Preparing Object Outline',
                    color: _purpleLight,
                  ),
                ),
              ),
            ),

          if (_isSegmenting)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 66,
                ),
                child: Align(
                  alignment:
                      Alignment.topCenter,
                  child: _OutlineStatusPill(
                    text: 'Tracing object',
                    color: _greenLight,
                  ),
                ),
              ),
            ),

          // ===================================================================
          // FLOATING TOOL DIALOG
          // ===================================================================

          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: IgnorePointer(
              ignoring: !_showTools,
              child: AnimatedSlide(
                duration: const Duration(
                  milliseconds: 260,
                ),
                curve: Curves.easeOutCubic,
                offset: _showTools
                    ? Offset.zero
                    : const Offset(
                        0,
                        1.08,
                      ),
                child: AnimatedOpacity(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  opacity:
                      _showTools ? 1 : 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.sizeOf(context)
                                  .height *
                              0.66,
                    ),
                    child: _buildToolbar(),
                  ),
                ),
              ),
            ),
          ),

          // ===================================================================
          // EXPORTING
          // ===================================================================

          if (_isExporting)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.62,
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                      SizedBox(
                        height: 14,
                      ),
                      Text(
                        'Saving',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ===================================================================
          // EMPTY ACTION STATE IS KEPT SILENT
          // ===================================================================

          if (!hasContent)
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ===========================================================================
  // DECORATIONS
  // ===========================================================================

  List<Widget> _buildDecorations() {
    final decorations =
        <_DecorationLayer>[];

    for (final sticker
        in _stickers) {
      decorations.add(
        _DecorationLayer(
          zIndex:
              sticker.zIndex,
          widget:
              DoodleStickerWidget(
            key:
                ValueKey(
              sticker.id,
            ),
            sticker:
                sticker,
            selected:
                !_isExporting &&
                _editorMode ==
                    _DoodleEditorMode.stickers &&
                _selectedStickerId ==
                    sticker.id,
            onSelected:
                () {
              if (_editorMode !=
                  _DoodleEditorMode.stickers) {
                return;
              }

              _selectSticker(
                sticker.id,
              );
            },
            onChanged:
                (
              updated,
            ) {
              if (_editorMode !=
                  _DoodleEditorMode.stickers) {
                return;
              }

              _updateSticker(
                updated,
              );
            },
            onDelete:
                () {
              _deleteSticker(
                sticker.id,
              );
            },
          ),
        ),
      );
    }

    for (final text
        in _textElements) {
      decorations.add(
        _DecorationLayer(
          zIndex:
              text.zIndex,
          widget:
              DoodleTextWidget(
            key:
                ValueKey(
              text.id,
            ),
            textElement:
                text,
            selected:
                !_isExporting &&
                _editorMode ==
                    _DoodleEditorMode.text &&
                _selectedTextId ==
                    text.id,
            onSelected:
                () {
              if (_editorMode !=
                  _DoodleEditorMode.text) {
                return;
              }

              _selectText(
                text.id,
              );
            },
            onChanged:
                (
              updated,
            ) {
              if (_editorMode !=
                  _DoodleEditorMode.text) {
                return;
              }

              _updateText(
                updated,
              );
            },
            onDelete:
                () {
              _deleteText(
                text.id,
              );
            },
          ),
        ),
      );
    }

    decorations.sort(
      (
        a,
        b,
      ) =>
          a.zIndex.compareTo(
        b.zIndex,
      ),
    );

    return decorations
        .map(
          (
            layer,
          ) =>
              layer.widget,
        )
        .toList();
  }

  // ===========================================================================
  // TOOLBAR
  // ===========================================================================

  Widget _buildToolbar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        28,
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 24,
          sigmaY: 24,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(
              0xE61A1B1F,
            ),
            borderRadius: BorderRadius.circular(
              28,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.10,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.34,
                ),
                blurRadius: 34,
                offset: const Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =========================================================
                  // HANDLE + HEADER
                  // =========================================================

                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.22,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        999,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showTools = false;
                          });
                        },
                        borderRadius:
                            BorderRadius.circular(
                          999,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            8,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Colors.white
                                .withValues(
                              alpha: 0.72,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // =========================================================
                  // MODES
                  // =========================================================

                  Container(
                    padding: const EdgeInsets.all(
                      4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.28,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        17,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              _EditorModeButton(
                            icon:
                                Icons.draw_rounded,
                            label: 'Draw',
                            selected:
                                _editorMode ==
                                    _DoodleEditorMode
                                        .draw,
                            onTap: () {
                              _setEditorMode(
                                _DoodleEditorMode
                                    .draw,
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child:
                              _EditorModeButton(
                            icon: Icons
                                .auto_awesome_rounded,
                            label: 'Stickers',
                            selected:
                                _editorMode ==
                                    _DoodleEditorMode
                                        .stickers,
                            onTap: () {
                              _setEditorMode(
                                _DoodleEditorMode
                                    .stickers,
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child:
                              _EditorModeButton(
                            icon: Icons
                                .text_fields_rounded,
                            label: 'Text',
                            selected:
                                _editorMode ==
                                    _DoodleEditorMode
                                        .text,
                            onTap: () {
                              _setEditorMode(
                                _DoodleEditorMode
                                    .text,
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child:
                              _EditorModeButton(
                            icon:
                                Icons.gesture_rounded,
                            label: 'Outline',
                            selected:
                                _editorMode ==
                                    _DoodleEditorMode
                                        .outline,
                            onTap: () {
                              _setEditorMode(
                                _DoodleEditorMode
                                    .outline,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 160,
                    ),
                    switchInCurve:
                        Curves.easeOut,
                    switchOutCurve:
                        Curves.easeIn,
                    child:
                        switch (_editorMode) {
                      _DoodleEditorMode.draw =>
                        _buildDrawControls(),
                      _DoodleEditorMode.stickers =>
                        _buildStickerControls(),
                      _DoodleEditorMode.text =>
                        _buildTextControls(),
                      _DoodleEditorMode.outline =>
                        _buildOutlineControls(),
                    },
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // =========================================================
                  // FOOTER ACTIONS
                  // =========================================================

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isExporting ||
                                      _isSegmenting
                                  ? null
                                  : _clear,
                          style: OutlinedButton
                              .styleFrom(
                            foregroundColor:
                                Colors.white,
                            side: BorderSide(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.14,
                              ),
                            ),
                            backgroundColor:
                                Colors.white
                                    .withValues(
                              alpha: 0.025,
                            ),
                            minimumSize:
                                const Size.fromHeight(
                              48,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons
                                .delete_sweep_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Clear',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed:
                              _isExporting ||
                                      _isSegmenting
                                  ? null
                                  : _save,
                          style:
                              FilledButton.styleFrom(
                            foregroundColor:
                                Colors.black,
                            backgroundColor:
                                Colors.white,
                            disabledBackgroundColor:
                                Colors.white
                                    .withValues(
                              alpha: 0.30,
                            ),
                            disabledForegroundColor:
                                Colors.black38,
                            minimumSize:
                                const Size.fromHeight(
                              48,
                            ),
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // OUTLINE CONTROLS
  // ===========================================================================

  Widget _buildOutlineControls() {
    return Column(
      key:
          const ValueKey(
        'outline-controls',
      ),
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal:
                12,
            vertical:
                10,
          ),
          decoration:
              BoxDecoration(
            color:
                _surfaceHighlight,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border:
                Border.all(
              color:
                  Colors.white.withValues(
                alpha:
                    0.05,
              ),
            ),
          ),
          child:
              Row(
            children: [
              Container(
                width:
                    34,
                height:
                    34,
                decoration:
                    BoxDecoration(
                  color:
                      _green.withValues(
                    alpha:
                        0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child:
                    const Icon(
                  Icons.touch_app_rounded,
                  color:
                      _greenLight,
                  size:
                      18,
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
                      _isPreparingSegmentation
                          ? 'Preparing MobileSAM'
                          : _isSegmenting
                              ? 'Tracing object...'
                              : 'Tap any object',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            11,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height:
                          2,
                    ),

                    Text(
                      'NeuroLens detects its silhouette and creates a dashed doodle outline.',
                      style:
                          TextStyle(
                        color:
                            Colors.white.withValues(
                          alpha:
                              0.4,
                        ),
                        fontSize:
                            9.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (_objectOutlines.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal:
                        8,
                    vertical:
                        5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        _purple.withValues(
                      alpha:
                          0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                  child:
                      Text(
                    '${_objectOutlines.length}',
                    style:
                        const TextStyle(
                      color:
                          _purpleLight,
                      fontSize:
                          10,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(
          height:
              12,
        ),

        // =====================================================================
        // COLORS
        // =====================================================================

        SizedBox(
          height:
              34,
          child:
              ListView.separated(
            scrollDirection:
                Axis.horizontal,
            itemCount:
                _colors.length,
            separatorBuilder:
                (
              context,
              index,
            ) =>
                    const SizedBox(
              width:
                  8,
            ),
            itemBuilder:
                (
              context,
              index,
            ) {
              final color =
                  _colors[index];

              final selected =
                  color ==
                  _outlineColor;

              return GestureDetector(
                onTap:
                    () {
                  setState(() {
                    _outlineColor =
                        color;
                  });
                },
                child:
                    AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds:
                        150,
                  ),
                  width:
                      31,
                  height:
                      31,
                  decoration:
                      BoxDecoration(
                    color:
                        color,
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          selected
                              ? _purpleLight
                              : Colors.white24,
                      width:
                          selected
                              ? 3
                              : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(
          height:
              8,
        ),

        // =====================================================================
        // WIDTH
        // =====================================================================

        Row(
          children: [
            const SizedBox(
              width:
                  52,
              child:
                  Text(
                'Width',
                style:
                    TextStyle(
                  color:
                      Colors.white60,
                  fontSize:
                      10,
                ),
              ),
            ),

            Expanded(
              child:
                  Slider(
                value:
                    _outlineWidth,
                min:
                    1,
                max:
                    7,
                activeColor:
                    _purple,
                inactiveColor:
                    Colors.white12,
                onChanged:
                    (
                  value,
                ) {
                  setState(() {
                    _outlineWidth =
                        value;
                  });
                },
              ),
            ),

            SizedBox(
              width:
                  35,
              child:
                  Text(
                _outlineWidth
                    .toStringAsFixed(
                  1,
                ),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.white54,
                  fontSize:
                      9,
                ),
              ),
            ),
          ],
        ),

        // =====================================================================
        // DASH
        // =====================================================================

        Row(
          children: [
            const SizedBox(
              width:
                  52,
              child:
                  Text(
                'Dash',
                style:
                    TextStyle(
                  color:
                      Colors.white60,
                  fontSize:
                      10,
                ),
              ),
            ),

            Expanded(
              child:
                  Slider(
                value:
                    _outlineDashLength,
                min:
                    3,
                max:
                    24,
                activeColor:
                    _purple,
                inactiveColor:
                    Colors.white12,
                onChanged:
                    (
                  value,
                ) {
                  setState(() {
                    _outlineDashLength =
                        value;
                  });
                },
              ),
            ),

            SizedBox(
              width:
                  35,
              child:
                  Text(
                _outlineDashLength
                    .round()
                    .toString(),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.white54,
                  fontSize:
                      9,
                ),
              ),
            ),
          ],
        ),

        if (_objectOutlines.isNotEmpty)
          Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed:
                    _removeLastOutline,
                icon:
                    const Icon(
                  Icons.undo_rounded,
                  size:
                      16,
                ),
                label:
                    const Text(
                  'Last',
                ),
              ),

              TextButton.icon(
                onPressed:
                    _clearOutlines,
                icon:
                    const Icon(
                  Icons.delete_outline_rounded,
                  size:
                      16,
                ),
                label:
                    const Text(
                  'Clear outlines',
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ===========================================================================
  // DRAW CONTROLS
  // ===========================================================================

  Widget _buildDrawControls() {
    return Column(
      key:
          const ValueKey(
        'draw-controls',
      ),
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  _ToolButton(
                icon:
                    Icons.edit_rounded,
                label:
                    'Pen',
                selected:
                    _tool ==
                    _DoodleTool.pen,
                onTap:
                    () {
                  setState(() {
                    _tool =
                        _DoodleTool.pen;
                  });
                },
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Expanded(
              child:
                  _ToolButton(
                icon:
                    Icons.brush_rounded,
                label:
                    'Marker',
                selected:
                    _tool ==
                    _DoodleTool.marker,
                onTap:
                    () {
                  setState(() {
                    _tool =
                        _DoodleTool.marker;
                  });
                },
              ),
            ),

            const SizedBox(
              width:
                  8,
            ),

            Expanded(
              child:
                  _ToolButton(
                icon:
                    Icons.auto_fix_normal_rounded,
                label:
                    'Eraser',
                selected:
                    _tool ==
                    _DoodleTool.eraser,
                onTap:
                    () {
                  setState(() {
                    _tool =
                        _DoodleTool.eraser;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
              14,
        ),

        SizedBox(
          height:
              38,
          child:
              ListView.separated(
            scrollDirection:
                Axis.horizontal,
            itemCount:
                _colors.length,
            separatorBuilder:
                (
              context,
              index,
            ) =>
                    const SizedBox(
              width:
                  9,
            ),
            itemBuilder:
                (
              context,
              index,
            ) {
              final color =
                  _colors[index];

              final selected =
                  color ==
                  _selectedColor;

              return GestureDetector(
                onTap:
                    () {
                  setState(() {
                    _selectedColor =
                        color;

                    if (_tool ==
                        _DoodleTool.eraser) {
                      _tool =
                          _DoodleTool.pen;
                    }
                  });
                },
                child:
                    AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds:
                        150,
                  ),
                  width:
                      34,
                  height:
                      34,
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color:
                        color,
                    border:
                        Border.all(
                      color:
                          selected
                              ? _purpleLight
                              : Colors.white24,
                      width:
                          selected
                              ? 3
                              : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(
          height:
              12,
        ),

        Row(
          children: [
            const Text(
              'Size',
              style:
                  TextStyle(
                color:
                    Colors.white60,
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
                    2,
                max:
                    42,
                activeColor:
                    _purple,
                inactiveColor:
                    Colors.white12,
                onChanged:
                    (
                  value,
                ) {
                  setState(() {
                    _brushSize =
                        value;
                  });
                },
              ),
            ),

            SizedBox(
              width:
                  38,
              child:
                  Text(
                _brushSize
                    .round()
                    .toString(),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.white60,
                  fontSize:
                      11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // STICKER CONTROLS
  // ===========================================================================

  Widget _buildStickerControls() {
    final stickerAssets =
        DoodleStickerLibrary
            .byCategory(
      _selectedCategory,
    );

    return Column(
      key:
          const ValueKey(
        'sticker-controls',
      ),
      mainAxisSize:
          MainAxisSize.min,
      children: [
        SizedBox(
          height:
              36,
          child:
              ListView.separated(
            scrollDirection:
                Axis.horizontal,
            itemCount:
                DoodleStickerLibrary
                    .categories.length,
            separatorBuilder:
                (
              context,
              index,
            ) =>
                    const SizedBox(
              width:
                  8,
            ),
            itemBuilder:
                (
              context,
              index,
            ) {
              final category =
                  DoodleStickerLibrary
                      .categories[index];

              final selected =
                  category ==
                  _selectedCategory;

              return ChoiceChip(
                label:
                    Text(
                  category,
                ),
                selected:
                    selected,
                onSelected:
                    (_) {
                  setState(() {
                    _selectedCategory =
                        category;
                  });
                },
              );
            },
          ),
        ),

        const SizedBox(
          height:
              12,
        ),

        SizedBox(
          height:
              82,
          child:
              ListView.separated(
            scrollDirection:
                Axis.horizontal,
            itemCount:
                stickerAssets.length,
            separatorBuilder:
                (
              context,
              index,
            ) =>
                    const SizedBox(
              width:
                  10,
            ),
            itemBuilder:
                (
              context,
              index,
            ) {
              final asset =
                  stickerAssets[index];

              return _StickerPickerItem(
                asset:
                    asset,
                onTap:
                    () {
                  _addSticker(
                    asset,
                  );
                },
              );
            },
          ),
        ),

        if (_selectedSticker !=
            null) ...[
          const SizedBox(
            height:
                12,
          ),

          _buildStickerActions(),
        ],
      ],
    );
  }

  Widget _buildStickerActions() {
    return _ActionBar(
      children: [
        _LayerAction(
          icon:
              Icons.copy_rounded,
          label:
              'Duplicate',
          onTap:
              _duplicateSelectedSticker,
        ),
        _LayerAction(
          icon:
              Icons.flip_rounded,
          label:
              'Flip',
          onTap:
              _flipSelectedSticker,
        ),
        _LayerAction(
          icon:
              Icons.flip_to_front_rounded,
          label:
              'Front',
          onTap:
              _bringSelectedStickerForward,
        ),
        _LayerAction(
          icon:
              Icons.flip_to_back_rounded,
          label:
              'Back',
          onTap:
              _sendSelectedStickerBackward,
        ),
        _LayerAction(
          icon:
              Icons.delete_outline_rounded,
          label:
              'Delete',
          destructive:
              true,
          onTap:
              () {
            final id =
                _selectedStickerId;

            if (id !=
                null) {
              _deleteSticker(
                id,
              );
            }
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // TEXT CONTROLS
  // ===========================================================================

  Widget _buildTextControls() {
    return Column(
      key:
          const ValueKey(
        'text-controls',
      ),
      mainAxisSize:
          MainAxisSize.min,
      children: [
        SizedBox(
          width:
              double.infinity,
          child:
              FilledButton.icon(
            onPressed:
                _isExporting
                    ? null
                    : _addText,
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  _purple.withValues(
                alpha:
                    0.18,
              ),
              foregroundColor:
                  _purpleLight,
              padding:
                  const EdgeInsets.symmetric(
                vertical:
                    13,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                side:
                    BorderSide(
                  color:
                      _purple.withValues(
                    alpha:
                        0.4,
                  ),
                ),
              ),
            ),
            icon:
                const Icon(
              Icons.add_rounded,
            ),
            label:
                const Text(
              'Add Text',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),

        if (_selectedText !=
            null) ...[
          const SizedBox(
            height:
                12,
          ),

          _ActionBar(
            children: [
              _LayerAction(
                icon:
                    Icons.edit_rounded,
                label:
                    'Edit',
                onTap:
                    _editSelectedText,
              ),
              _LayerAction(
                icon:
                    Icons.copy_rounded,
                label:
                    'Duplicate',
                onTap:
                    _duplicateSelectedText,
              ),
              _LayerAction(
                icon:
                    Icons.flip_to_front_rounded,
                label:
                    'Front',
                onTap:
                    _bringSelectedTextForward,
              ),
              _LayerAction(
                icon:
                    Icons.flip_to_back_rounded,
                label:
                    'Back',
                onTap:
                    _sendSelectedTextBackward,
              ),
              _LayerAction(
                icon:
                    Icons.delete_outline_rounded,
                label:
                    'Delete',
                destructive:
                    true,
                onTap:
                    () {
                  final id =
                      _selectedTextId;

                  if (id !=
                      null) {
                    _deleteText(
                      id,
                    );
                  }
                },
              ),
            ],
          ),
        ] else ...[
          const SizedBox(
            height:
                10,
          ),

          Text(
            'Add a quote or caption, then drag, resize and rotate it.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white.withValues(
                alpha:
                    0.38,
              ),
              fontSize:
                  10.5,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// OBJECT OUTLINE MODEL
// =============================================================================

class _ObjectOutline {
  const _ObjectOutline({
    required this.id,
    required this.imagePoints,
    required this.color,
    required this.width,
    required this.dashLength,
    required this.gapLength,
    required this.offset,
  });

  final String id;

  /// Coordinates in ORIGINAL image pixel space.
  final List<Offset> imagePoints;

  final Color color;

  final double width;

  final double dashLength;

  final double gapLength;

  final double offset;
}

// =============================================================================
// OBJECT OUTLINE PAINTER
// =============================================================================

class _ObjectOutlinePainter extends CustomPainter {
  const _ObjectOutlinePainter({
    required this.outlines,
    required this.imageSize,
  });

  final List<_ObjectOutline> outlines;
  final Size imageSize;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (outlines.isEmpty ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return;
    }

    final imageRect =
        _displayedImageRect(
      canvasSize: size,
      imageSize: imageSize,
    );

    for (final outline
        in outlines) {
      if (outline.imagePoints.length <
          3) {
        continue;
      }

      final mapped =
          outline.imagePoints.map(
        (
          point,
        ) {
          return Offset(
            imageRect.left +
                point.dx /
                    imageSize.width *
                    imageRect.width,
            imageRect.top +
                point.dy /
                    imageSize.height *
                    imageRect.height,
          );
        },
      ).toList();

      // ---------------------------------------------------------------------
      // Slightly move contour outward.
      //
      // This is intentionally subtle. It makes the white dashed line sit
      // just outside the selected person/object instead of covering its edge.
      // ---------------------------------------------------------------------

      final centroid =
          _centroid(
        mapped,
      );

      final expanded =
          mapped.map(
        (
          point,
        ) {
          final vector =
              point -
              centroid;

          final distance =
              vector.distance;

          if (distance <
              0.001) {
            return point;
          }

          return point +
              Offset(
                    vector.dx /
                        distance,
                    vector.dy /
                        distance,
                  ) *
                  outline.offset;
        },
      ).toList();

      final path =
          _smoothPath(
        expanded,
      );

      final paint =
          Paint()
            ..color =
                outline.color
            ..style =
                PaintingStyle.stroke
            ..strokeWidth =
                outline.width
            ..strokeCap =
                StrokeCap.round
            ..strokeJoin =
                StrokeJoin.round;

      _drawDashedPath(
        canvas:
            canvas,
        path:
            path,
        paint:
            paint,
        dashLength:
            outline.dashLength,
        gapLength:
            outline.gapLength,
      );
    }
  }

  Rect _displayedImageRect({
    required Size canvasSize,
    required Size imageSize,
  }) {
    final canvasAspect =
        canvasSize.width /
        canvasSize.height;

    final imageAspect =
        imageSize.width /
        imageSize.height;

    if (imageAspect >
        canvasAspect) {
      final width =
          canvasSize.width;

      final height =
          width /
          imageAspect;

      return Rect.fromLTWH(
        0,
        (
                canvasSize.height -
                    height) /
            2,
        width,
        height,
      );
    }

    final height =
        canvasSize.height;

    final width =
        height *
        imageAspect;

    return Rect.fromLTWH(
      (
              canvasSize.width -
                  width) /
          2,
      0,
      width,
      height,
    );
  }

  Offset _centroid(
    List<Offset> points,
  ) {
    var x =
        0.0;

    var y =
        0.0;

    for (final point
        in points) {
      x +=
          point.dx;

      y +=
          point.dy;
    }

    return Offset(
      x /
          points.length,
      y /
          points.length,
    );
  }

  Path _smoothPath(
    List<Offset> points,
  ) {
    final path =
        Path();

    if (points.isEmpty) {
      return path;
    }

    final first =
        points.first;

    final last =
        points.last;

    final start =
        Offset(
      (
              first.dx +
                  last.dx) /
          2,
      (
              first.dy +
                  last.dy) /
          2,
    );

    path.moveTo(
      start.dx,
      start.dy,
    );

    for (var i = 0;
        i < points.length;
        i++) {
      final current =
          points[i];

      final next =
          points[
              (i + 1) %
                  points.length];

      final midpoint =
          Offset(
        (
                current.dx +
                    next.dx) /
            2,
        (
                current.dy +
                    next.dy) /
            2,
      );

      path.quadraticBezierTo(
        current.dx,
        current.dy,
        midpoint.dx,
        midpoint.dy,
      );
    }

    path.close();

    return path;
  }

  void _drawDashedPath({
    required Canvas canvas,
    required Path path,
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric
        in path.computeMetrics()) {
      var distance =
          0.0;

      while (distance <
          metric.length) {
        final end =
            (
                    distance +
                        dashLength)
                .clamp(
          0.0,
          metric.length,
        );

        final segment =
            metric.extractPath(
          distance,
          end,
        );

        canvas.drawPath(
          segment,
          paint,
        );

        distance =
            end +
            gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _ObjectOutlinePainter oldDelegate,
  ) {
    return true;
  }
}

// =============================================================================
// CONTOUR INTERNAL TYPES
// =============================================================================

class _GridPoint {
  const _GridPoint(
    this.x,
    this.y,
  );

  final int x;
  final int y;

  @override
  bool operator ==(
    Object other,
  ) {
    return other is _GridPoint &&
        other.x ==
            x &&
        other.y ==
            y;
  }

  @override
  int get hashCode =>
      Object.hash(
        x,
        y,
      );
}

class _ContourSegment {
  const _ContourSegment(
    this.a,
    this.b,
  );

  final _GridPoint a;
  final _GridPoint b;
}

class _ContourEdge {
  const _ContourEdge(
    this.a,
    this.b,
  );

  final _GridPoint a;
  final _GridPoint b;

  @override
  bool operator ==(
    Object other,
  ) {
    if (other
        is! _ContourEdge) {
      return false;
    }

    return (
            a ==
                other.a &&
            b ==
                other.b) ||
        (
            a ==
                other.b &&
            b ==
                other.a);
  }

  @override
  int get hashCode {
    final hashA =
        a.hashCode;

    final hashB =
        b.hashCode;

    return hashA <
            hashB
        ? Object.hash(
            hashA,
            hashB,
          )
        : Object.hash(
            hashB,
            hashA,
          );
  }
}

// =============================================================================
// DECORATION LAYER
// =============================================================================

class _DecorationLayer {
  const _DecorationLayer({
    required this.zIndex,
    required this.widget,
  });

  final int zIndex;
  final Widget widget;
}

// =============================================================================
// STROKE
// =============================================================================

class _DoodleStroke {
  _DoodleStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final _DoodleTool tool;
}

// =============================================================================
// DRAW PAINTER
// =============================================================================

class _DoodlePainter extends CustomPainter {
  const _DoodlePainter({
    required this.strokes,
  });

  final List<_DoodleStroke> strokes;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    canvas.saveLayer(
      Offset.zero &
          size,
      Paint(),
    );

    for (final stroke
        in strokes) {
      if (stroke.points.isEmpty) {
        continue;
      }

      final paint =
          Paint()
            ..strokeCap =
                StrokeCap.round
            ..strokeJoin =
                StrokeJoin.round
            ..style =
                PaintingStyle.stroke;

      switch (stroke.tool) {
        case _DoodleTool.pen:
          paint
            ..color =
                stroke.color
            ..strokeWidth =
                stroke.width
            ..blendMode =
                BlendMode.srcOver;

        case _DoodleTool.marker:
          paint
            ..color =
                stroke.color.withValues(
              alpha:
                  0.42,
            )
            ..strokeWidth =
                stroke.width *
                2
            ..blendMode =
                BlendMode.srcOver;

        case _DoodleTool.eraser:
          paint
            ..color =
                Colors.transparent
            ..strokeWidth =
                stroke.width *
                2.3
            ..blendMode =
                BlendMode.clear;
      }

      if (stroke.points.length ==
          1) {
        final point =
            stroke.points.first;

        canvas.drawCircle(
          point,
          paint.strokeWidth /
              2,
          stroke.tool ==
                  _DoodleTool.eraser
              ? (
                  Paint()
                    ..blendMode =
                        BlendMode.clear)
              : (
                  Paint()
                    ..color =
                        paint.color
                    ..blendMode =
                        paint.blendMode),
        );

        continue;
      }

      final path =
          Path()
            ..moveTo(
              stroke.points.first.dx,
              stroke.points.first.dy,
            );

      for (var index = 1;
          index <
              stroke.points.length -
                  1;
          index++) {
        final current =
            stroke.points[index];

        final next =
            stroke.points[
                index + 1];

        final midpoint =
            Offset(
          (
                  current.dx +
                      next.dx) /
              2,
          (
                  current.dy +
                      next.dy) /
              2,
        );

        path.quadraticBezierTo(
          current.dx,
          current.dy,
          midpoint.dx,
          midpoint.dy,
        );
      }

      final last =
          stroke.points.last;

      path.lineTo(
        last.dx,
        last.dy,
      );

      canvas.drawPath(
        path,
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _DoodlePainter oldDelegate,
  ) {
    return true;
  }
}

// =============================================================================
// MODE BUTTON
// =============================================================================

class _EditorModeButton extends StatelessWidget {
  const _EditorModeButton({
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
          ? Colors.white.withValues(
              alpha: 0.11,
            )
          : Colors.transparent,
      borderRadius: BorderRadius.circular(
        13,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          13,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(
                        alpha: 0.48,
                      ),
              ),
              const SizedBox(
                height: 4,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(
                            alpha: 0.48,
                          ),
                    fontSize: 9.5,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w500,
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
// TOOL BUTTON
// =============================================================================

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
      color:
          selected
              ? const Color(
                  0xFF8B5CF6,
                ).withValues(
                  alpha:
                      0.15,
                )
              : const Color(
                  0xFF141B2D,
                ),
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                11,
          ),
          child:
              Column(
            children: [
              Icon(
                icon,
                size:
                    19,
                color:
                    selected
                        ? const Color(
                            0xFFC4B5FD,
                          )
                        : Colors.white60,
              ),
              const SizedBox(
                height:
                    4,
              ),
              Text(
                label,
                style:
                    TextStyle(
                  color:
                      selected
                          ? Colors.white
                          : Colors.white60,
                  fontSize:
                      10,
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
// STICKER PICKER
// =============================================================================

class _StickerPickerItem extends StatelessWidget {
  const _StickerPickerItem({
    required this.asset,
    required this.onTap,
  });

  final DoodleStickerAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          const Color(
        0xFF141B2D,
      ),
      borderRadius:
          BorderRadius.circular(
        15,
      ),
      clipBehavior:
          Clip.antiAlias,
      child:
          InkWell(
        onTap:
            onTap,
        child:
            SizedBox(
          width:
              76,
          height:
              76,
          child:
              Padding(
            padding:
                const EdgeInsets.all(
              8,
            ),
            child:
                Image.asset(
              asset.assetPath,
              fit:
                  BoxFit.contain,
              filterQuality:
                  FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ACTION BAR
// =============================================================================

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            8,
        vertical:
            8,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF141B2D,
        ),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children:
            children,
      ),
    );
  }
}

// =============================================================================
// LAYER ACTION
// =============================================================================

class _LayerAction extends StatelessWidget {
  const _LayerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(
    BuildContext context,
  ) {
    final color =
        destructive
            ? const Color(
                0xFFF87171,
              )
            : Colors.white70;

    return InkWell(
      onTap:
          onTap,
      borderRadius:
          BorderRadius.circular(
        10,
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal:
              6,
          vertical:
              5,
        ),
        child:
            Column(
          children: [
            Icon(
              icon,
              size:
                  18,
              color:
                  color,
            ),
            const SizedBox(
              height:
                  3,
            ),
            Text(
              label,
              style:
                  TextStyle(
                color:
                    color,
                fontSize:
                    8.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PREMIUM TOP CONTROL
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
  Widget build(
    BuildContext context,
  ) {
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          999,
        ),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 14,
            sigmaY: 14,
          ),
          child: Material(
            color: active
                ? Colors.white.withValues(
                    alpha: 0.18,
                  )
                : Colors.black.withValues(
                    alpha: 0.34,
                  ),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder:
                  const CircleBorder(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? Colors.white
                      : Colors.white.withValues(
                          alpha: 0.25,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// OUTLINE STATUS
// =============================================================================

class _OutlineStatusPill extends StatelessWidget {
  const _OutlineStatusPill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
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
            0xE60D1321,
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
                  13,
              height:
                  13,
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
    );
  }
}