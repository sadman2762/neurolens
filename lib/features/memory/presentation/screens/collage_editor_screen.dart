import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CollageEditorScreen extends StatefulWidget {
  const CollageEditorScreen({
    required this.initialAssetId,
    required this.title,
    super.key,
  });

  final String initialAssetId;
  final String title;

  @override
  State<CollageEditorScreen> createState() => _CollageEditorScreenState();
}

// =============================================================================
// LAYOUTS
// =============================================================================

enum CollageLayoutType {
  // 2 photos
  twoVertical,
  twoHorizontal,

  // 3 photos
  threeLeft,
  threeRight,
  threeTop,
  threeBottom,
  threeColumns,

  // 4 photos
  fourGrid,
  fourTopWide,
  fourBottomWide,
  fourLeftWide,
  fourRightWide,

  // 6 photos
  sixGrid,
  sixTopWide,
  sixBottomWide,
}

// =============================================================================
// ASPECT RATIOS
// =============================================================================

enum CollageAspectRatio { square, portrait, story }

// =============================================================================
// EDITOR CONTROLS
// =============================================================================

enum CollageControlType { layout, ratio, spacing, corners, background }

// =============================================================================
// COLLAGE EDITOR
// =============================================================================

class _CollageEditorScreenState extends State<CollageEditorScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _surfaceLight = Color(0xFF171E2C);
  static const Color _accent = Color(0xFF8B5CF6);

  final GlobalKey _collageBoundaryKey = GlobalKey();

  final List<AssetEntity?> _slots = List<AssetEntity?>.filled(
    6,
    null,
    growable: false,
  );

  CollageLayoutType _selectedLayout = CollageLayoutType.twoVertical;

  CollageAspectRatio _selectedRatio = CollageAspectRatio.square;

  CollageControlType _selectedControl = CollageControlType.layout;

  double _spacing = 3;
  double _cornerRadius = 0;

  Color _collageBackground = Colors.white;

  bool _isPickingPhoto = false;
  bool _isExporting = false;
  bool _isLoadingInitialPhoto = true;

  final List<Color> _backgroundColors = const [
    Colors.white,
    Colors.black,
    Color(0xFF1E1E1E),
    Color(0xFFE8E8E8),
    Color(0xFFF5EFE6),
    Color(0xFFFFE4E6),
    Color(0xFFEDE9FE),
    Color(0xFFDBEAFE),
    Color(0xFFD1FAE5),
    Color(0xFFFFF3C4),
  ];

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _loadInitialPhoto();
  }

  Future<void> _loadInitialPhoto() async {
    try {
      final assetId = widget.initialAssetId.trim();

      if (assetId.isEmpty) {
        return;
      }

      final asset = await AssetEntity.fromId(assetId);

      if (!mounted) {
        return;
      }

      if (asset != null) {
        setState(() {
          _slots[0] = asset;
        });
      } else {
        debugPrint(
          'CollageEditorScreen: '
          'Could not find initial asset with id $assetId',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'CollageEditorScreen initial photo error: $error',
      );

      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitialPhoto = false;
        });
      }
    }
  }

  // ===========================================================================
  // REQUIRED PHOTO COUNT
  // ===========================================================================

  int get _requiredPhotoCount {
    switch (_selectedLayout) {
      case CollageLayoutType.twoVertical:
      case CollageLayoutType.twoHorizontal:
        return 2;

      case CollageLayoutType.threeLeft:
      case CollageLayoutType.threeRight:
      case CollageLayoutType.threeTop:
      case CollageLayoutType.threeBottom:
      case CollageLayoutType.threeColumns:
        return 3;

      case CollageLayoutType.fourGrid:
      case CollageLayoutType.fourTopWide:
      case CollageLayoutType.fourBottomWide:
      case CollageLayoutType.fourLeftWide:
      case CollageLayoutType.fourRightWide:
        return 4;

      case CollageLayoutType.sixGrid:
      case CollageLayoutType.sixTopWide:
      case CollageLayoutType.sixBottomWide:
        return 6;
    }
  }

  int get _filledPhotoCount {
    var count = 0;

    for (var index = 0; index < _requiredPhotoCount; index++) {
      if (_slots[index] != null) {
        count++;
      }
    }

    return count;
  }

  bool get _isCollageComplete => _filledPhotoCount == _requiredPhotoCount;

  // ===========================================================================
  // ASPECT RATIO
  // ===========================================================================

  double get _aspectRatio {
    switch (_selectedRatio) {
      case CollageAspectRatio.square:
        return 1;

      case CollageAspectRatio.portrait:
        return 4 / 5;

      case CollageAspectRatio.story:
        return 9 / 16;
    }
  }

  String _ratioName(CollageAspectRatio ratio) {
    switch (ratio) {
      case CollageAspectRatio.square:
        return '1:1';

      case CollageAspectRatio.portrait:
        return '4:5';

      case CollageAspectRatio.story:
        return '9:16';
    }
  }

  // ===========================================================================
  // LAYOUT GROUP
  // ===========================================================================

  int _layoutPhotoCount(CollageLayoutType layout) {
    switch (layout) {
      case CollageLayoutType.twoVertical:
      case CollageLayoutType.twoHorizontal:
        return 2;

      case CollageLayoutType.threeLeft:
      case CollageLayoutType.threeRight:
      case CollageLayoutType.threeTop:
      case CollageLayoutType.threeBottom:
      case CollageLayoutType.threeColumns:
        return 3;

      case CollageLayoutType.fourGrid:
      case CollageLayoutType.fourTopWide:
      case CollageLayoutType.fourBottomWide:
      case CollageLayoutType.fourLeftWide:
      case CollageLayoutType.fourRightWide:
        return 4;

      case CollageLayoutType.sixGrid:
      case CollageLayoutType.sixTopWide:
      case CollageLayoutType.sixBottomWide:
        return 6;
    }
  }

  // ===========================================================================
  // SELECT PHOTO FOR SLOT
  // ===========================================================================

  Future<void> _pickPhotoForSlot(int slotIndex) async {
    if (_isPickingPhoto || _isExporting || _isLoadingInitialPhoto) {
      return;
    }

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (!permission.hasAccess) {
        _showMessage(
          'Gallery permission is required to select a photo.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      final currentAsset = _slots[slotIndex];

      final result = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.image,
          selectedAssets:
              currentAsset == null ? const [] : [currentAsset],
          themeColor: _accent,
        ),
      );

      if (!mounted || result == null || result.isEmpty) {
        return;
      }

      setState(() {
        _slots[slotIndex] = result.first;
      });
    } catch (error) {
      _showMessage('Could not select photo: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  // ===========================================================================
  // REMOVE PHOTO
  // ===========================================================================

  void _removePhotoFromSlot(int index) {
    if (_isExporting || _isLoadingInitialPhoto) {
      return;
    }

    setState(() {
      _slots[index] = null;
    });
  }

  // ===========================================================================
  // CHANGE LAYOUT
  // ===========================================================================

  void _changeLayout(CollageLayoutType layout) {
    if (_isExporting) {
      return;
    }

    setState(() {
      _selectedLayout = layout;
    });
  }

  // ===========================================================================
  // HIGH-RES EXPORT
  // ===========================================================================

  Future<void> _exportCollage() async {
    if (_isExporting) {
      return;
    }

    if (!_isCollageComplete) {
      _showMessage('Add photos to every frame before saving.');

      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (!permission.hasAccess) {
        _showMessage(
          'Gallery permission is required to save the collage.',
        );

        return;
      }

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return;
      }

      final boundaryContext = _collageBoundaryKey.currentContext;

      if (boundaryContext == null || !boundaryContext.mounted) {
        throw StateError('Collage render area is unavailable.');
      }

      final renderObject = boundaryContext.findRenderObject();

      if (renderObject is! RenderRepaintBoundary) {
        throw StateError(
          'Could not prepare collage for export.',
        );
      }

      final logicalSize = renderObject.size;

      if (logicalSize.width <= 0 || logicalSize.height <= 0) {
        throw StateError('Invalid collage export size.');
      }

      const targetLongestSide = 2400.0;

      final longestLogicalSide =
          logicalSize.width > logicalSize.height
              ? logicalSize.width
              : logicalSize.height;

      var pixelRatio =
          targetLongestSide / longestLogicalSide;

      pixelRatio = pixelRatio.clamp(1.0, 8.0);

      final image = await renderObject.toImage(
        pixelRatio: pixelRatio,
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();

      if (byteData == null) {
        throw StateError(
          'Could not encode collage image.',
        );
      }

      final bytes = byteData.buffer.asUint8List();

      if (bytes.isEmpty) {
        throw StateError(
          'Collage export returned empty image data.',
        );
      }

      final timestamp =
          DateTime.now().millisecondsSinceEpoch;

      final fileName =
          'neurolens_collage_$timestamp.png';

      final savedAsset =
          await PhotoManager.editor.saveImage(
        bytes,
        title: fileName,
        filename: fileName,
      );

      if (savedAsset.id.isEmpty) {
        throw StateError(
          'The saved collage has no gallery ID.',
        );
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Collage saved to your gallery.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Collage export error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (mounted) {
        _showMessage(
          'Could not save collage: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed:
              _isPickingPhoto || _isExporting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Collage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed:
                !_isCollageComplete || _isExporting
                    ? null
                    : _exportCollage,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFC4B5FD),
                    ),
                  )
                : const Icon(
                    Icons.download_rounded,
                    size: 19,
                  ),
            label: Text(
              _isExporting ? 'Saving' : 'Save',
              style: TextStyle(
                color: _isCollageComplete
                    ? const Color(0xFFC4B5FD)
                    : Colors.white24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                4,
                18,
                4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_filledPhotoCount of '
                      '$_requiredPhotoCount photos',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _isLoadingInitialPhoto
                        ? 'Loading photo...'
                        : 'Tap a frame to add',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.4,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _buildCollageCanvas(),
            ),

            _buildControlsPanel(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // COLLAGE CANVAS
  // ===========================================================================

  Widget _buildCollageCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              14,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: RepaintBoundary(
                  key: _collageBoundaryKey,
                  child: ColoredBox(
                    color: _collageBackground,
                    child: Padding(
                      padding:
                          EdgeInsets.all(_spacing),
                      child: _CollagePreview(
                        slots: _slots,
                        layout: _selectedLayout,
                        spacing: _spacing,
                        cornerRadius:
                            _cornerRadius,
                        showControls:
                            !_isExporting,
                        onSelectPhoto:
                            _pickPhotoForSlot,
                        onRemovePhoto:
                            _removePhotoFromSlot,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // CONTROL PANEL
  // ===========================================================================

  Widget _buildControlsPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSelectedControl(),

            const SizedBox(height: 4),

            Container(
              height: 1,
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),

            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedControl() {
    switch (_selectedControl) {
      case CollageControlType.layout:
        return _buildLayoutControl();

      case CollageControlType.ratio:
        return _buildRatioControl();

      case CollageControlType.spacing:
        return _buildSpacingControl();

      case CollageControlType.corners:
        return _buildCornersControl();

      case CollageControlType.background:
        return _buildBackgroundControl();
    }
  }

  Widget _buildLayoutControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        10,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Layouts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '2 • 3 • 4 • 6 photos',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.38,
                  ),
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  CollageLayoutType
                      .values
                      .length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 10),
              itemBuilder: (
                context,
                index,
              ) {
                final layout =
                    CollageLayoutType
                        .values[index];

                return _LayoutButton(
                  layout: layout,
                  photoCount:
                      _layoutPhotoCount(
                    layout,
                  ),
                  selected:
                      _selectedLayout ==
                          layout,
                  onTap: () {
                    _changeLayout(layout);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatioControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Aspect Ratio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children:
                CollageAspectRatio.values
                    .map((ratio) {
              final selected =
                  _selectedRatio == ratio;

              return Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: Material(
                    color: selected
                        ? _accent
                        : _surfaceLight,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    clipBehavior:
                        Clip.antiAlias,
                    child: InkWell(
                      onTap: _isExporting
                          ? null
                          : () {
                              setState(() {
                                _selectedRatio =
                                    ratio;
                              });
                            },
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                        child: Column(
                          children: [
                            _RatioPreview(
                              ratio: ratio,
                              selected:
                                  selected,
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            Text(
                              _ratioName(
                                ratio,
                              ),
                              style:
                                  TextStyle(
                                color: selected
                                    ? Colors
                                        .white
                                    : Colors
                                        .white70,
                                fontSize:
                                    12,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        14,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Spacing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _spacing.round().toString(),
                style: const TextStyle(
                  color: Color(0xFFC4B5FD),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          Slider(
            value: _spacing,
            min: 0,
            max: 24,
            divisions: 24,
            activeColor: _accent,
            inactiveColor:
                Colors.white.withValues(
              alpha: 0.12,
            ),
            onChanged: _isExporting
                ? null
                : (value) {
                    setState(() {
                      _spacing = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCornersControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        14,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Corners',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _cornerRadius
                    .round()
                    .toString(),
                style: const TextStyle(
                  color: Color(0xFFC4B5FD),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          Slider(
            value: _cornerRadius,
            min: 0,
            max: 32,
            divisions: 32,
            activeColor: _accent,
            inactiveColor:
                Colors.white.withValues(
              alpha: 0.12,
            ),
            onChanged: _isExporting
                ? null
                : (value) {
                    setState(() {
                      _cornerRadius = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundControl() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Background',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  _backgroundColors.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 12),
              itemBuilder: (
                context,
                index,
              ) {
                final color =
                    _backgroundColors[index];

                final selected =
                    _collageBackground
                            .toARGB32() ==
                        color.toARGB32();

                return GestureDetector(
                  onTap: _isExporting
                      ? null
                      : () {
                          setState(() {
                            _collageBackground =
                                color;
                          });
                        },
                  child: AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 160,
                    ),
                    width: 48,
                    height: 48,
                    padding: EdgeInsets.all(
                      selected ? 3 : 0,
                    ),
                    decoration:
                        BoxDecoration(
                      shape:
                          BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color:
                                  const Color(
                                0xFFC4B5FD,
                              ),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Container(
                      decoration:
                          BoxDecoration(
                        color: color,
                        shape:
                            BoxShape.circle,
                        border: Border.all(
                          color: Colors.white
                              .withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return SizedBox(
      height: 78,
      child: Row(
        children: [
          Expanded(
            child: _ToolbarButton(
              icon:
                  Icons.grid_view_rounded,
              label: 'Layout',
              selected:
                  _selectedControl ==
                      CollageControlType
                          .layout,
              onTap: () {
                setState(() {
                  _selectedControl =
                      CollageControlType
                          .layout;
                });
              },
            ),
          ),

          Expanded(
            child: _ToolbarButton(
              icon:
                  Icons.aspect_ratio_rounded,
              label: 'Ratio',
              selected:
                  _selectedControl ==
                      CollageControlType
                          .ratio,
              onTap: () {
                setState(() {
                  _selectedControl =
                      CollageControlType
                          .ratio;
                });
              },
            ),
          ),

          Expanded(
            child: _ToolbarButton(
              icon:
                  Icons.space_bar_rounded,
              label: 'Spacing',
              selected:
                  _selectedControl ==
                      CollageControlType
                          .spacing,
              onTap: () {
                setState(() {
                  _selectedControl =
                      CollageControlType
                          .spacing;
                });
              },
            ),
          ),

          Expanded(
            child: _ToolbarButton(
              icon: Icons
                  .rounded_corner_rounded,
              label: 'Corners',
              selected:
                  _selectedControl ==
                      CollageControlType
                          .corners,
              onTap: () {
                setState(() {
                  _selectedControl =
                      CollageControlType
                          .corners;
                });
              },
            ),
          ),

          Expanded(
            child: _ToolbarButton(
              icon:
                  Icons.palette_outlined,
              label: 'Background',
              selected:
                  _selectedControl ==
                      CollageControlType
                          .background,
              onTap: () {
                setState(() {
                  _selectedControl =
                      CollageControlType
                          .background;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COLLAGE PREVIEW
// =============================================================================

class _CollagePreview extends StatelessWidget {
  const _CollagePreview({
    required this.slots,
    required this.layout,
    required this.spacing,
    required this.cornerRadius,
    required this.showControls,
    required this.onSelectPhoto,
    required this.onRemovePhoto,
  });

  final List<AssetEntity?> slots;
  final CollageLayoutType layout;

  final double spacing;
  final double cornerRadius;

  final bool showControls;

  final ValueChanged<int> onSelectPhoto;
  final ValueChanged<int> onRemovePhoto;

  Widget _slot(int index) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        cornerRadius,
      ),
      child: _CollageSlot(
        key: ValueKey(
          'slot-$index-'
          '${slots[index]?.id ?? 'empty'}',
        ),
        asset: slots[index],
        slotIndex: index,
        showControls: showControls,
        onSelectPhoto: () {
          onSelectPhoto(index);
        },
        onRemovePhoto: () {
          onRemovePhoto(index);
        },
      ),
    );
  }

  Widget _horizontal(
    int first,
    int second, {
    int firstFlex = 1,
    int secondFlex = 1,
  }) {
    return Row(
      children: [
        Expanded(
          flex: firstFlex,
          child: _slot(first),
        ),

        SizedBox(width: spacing),

        Expanded(
          flex: secondFlex,
          child: _slot(second),
        ),
      ],
    );
  }

  Widget _vertical(
    int first,
    int second, {
    int firstFlex = 1,
    int secondFlex = 1,
  }) {
    return Column(
      children: [
        Expanded(
          flex: firstFlex,
          child: _slot(first),
        ),

        SizedBox(height: spacing),

        Expanded(
          flex: secondFlex,
          child: _slot(second),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case CollageLayoutType.twoVertical:
        return _horizontal(0, 1);

      case CollageLayoutType.twoHorizontal:
        return _vertical(0, 1);

      case CollageLayoutType.threeLeft:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _slot(0),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _vertical(1, 2),
            ),
          ],
        );

      case CollageLayoutType.threeRight:
        return Row(
          children: [
            Expanded(
              child: _vertical(0, 1),
            ),
            SizedBox(width: spacing),
            Expanded(
              flex: 2,
              child: _slot(2),
            ),
          ],
        );

      case CollageLayoutType.threeTop:
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: _slot(0),
            ),
            SizedBox(height: spacing),
            Expanded(
              child: _horizontal(1, 2),
            ),
          ],
        );

      case CollageLayoutType.threeBottom:
        return Column(
          children: [
            Expanded(
              child: _horizontal(0, 1),
            ),
            SizedBox(height: spacing),
            Expanded(
              flex: 2,
              child: _slot(2),
            ),
          ],
        );

      case CollageLayoutType.threeColumns:
        return Row(
          children: [
            Expanded(child: _slot(0)),
            SizedBox(width: spacing),
            Expanded(child: _slot(1)),
            SizedBox(width: spacing),
            Expanded(child: _slot(2)),
          ],
        );

      case CollageLayoutType.fourGrid:
        return Column(
          children: [
            Expanded(
              child: _horizontal(0, 1),
            ),
            SizedBox(height: spacing),
            Expanded(
              child: _horizontal(2, 3),
            ),
          ],
        );

      case CollageLayoutType.fourTopWide:
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: _slot(0),
            ),
            SizedBox(height: spacing),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _slot(1),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(2),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(3),
                  ),
                ],
              ),
            ),
          ],
        );

      case CollageLayoutType.fourBottomWide:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _slot(0),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(1),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(2),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing),
            Expanded(
              flex: 2,
              child: _slot(3),
            ),
          ],
        );

      case CollageLayoutType.fourLeftWide:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: _slot(0),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _slot(1),
                  ),
                  SizedBox(
                    height: spacing,
                  ),
                  Expanded(
                    child: _slot(2),
                  ),
                  SizedBox(
                    height: spacing,
                  ),
                  Expanded(
                    child: _slot(3),
                  ),
                ],
              ),
            ),
          ],
        );

      case CollageLayoutType.fourRightWide:
        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _slot(0),
                  ),
                  SizedBox(
                    height: spacing,
                  ),
                  Expanded(
                    child: _slot(1),
                  ),
                  SizedBox(
                    height: spacing,
                  ),
                  Expanded(
                    child: _slot(2),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              flex: 2,
              child: _slot(3),
            ),
          ],
        );

      case CollageLayoutType.sixGrid:
        return Column(
          children: [
            Expanded(
              child: _horizontal(0, 1),
            ),
            SizedBox(height: spacing),
            Expanded(
              child: _horizontal(2, 3),
            ),
            SizedBox(height: spacing),
            Expanded(
              child: _horizontal(4, 5),
            ),
          ],
        );

      case CollageLayoutType.sixTopWide:
        return Column(
          children: [
            Expanded(
              flex: 2,
              child: _slot(0),
            ),

            SizedBox(height: spacing),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _slot(1),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(2),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _slot(3),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(4),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(5),
                  ),
                ],
              ),
            ),
          ],
        );

      case CollageLayoutType.sixBottomWide:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _slot(0),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(1),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(2),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _slot(3),
                  ),
                  SizedBox(
                    width: spacing,
                  ),
                  Expanded(
                    child: _slot(4),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing),

            Expanded(
              flex: 2,
              child: _slot(5),
            ),
          ],
        );
    }
  }
}

// =============================================================================
// COLLAGE SLOT
// =============================================================================

class _CollageSlot extends StatelessWidget {
  const _CollageSlot({
    required this.asset,
    required this.slotIndex,
    required this.showControls,
    required this.onSelectPhoto,
    required this.onRemovePhoto,
    super.key,
  });

  final AssetEntity? asset;
  final int slotIndex;

  final bool showControls;

  final VoidCallback onSelectPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    if (asset == null) {
      return _EmptyCollageFrame(
        slotNumber: slotIndex + 1,
        onTap: onSelectPhoto,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _CollageImage(
          asset: asset!,
        ),

        if (showControls) ...[
          Positioned(
            left: 6,
            top: 6,
            child: _SmallCircleButton(
              icon:
                  Icons.photo_library_outlined,
              tooltip: 'Replace',
              onTap: onSelectPhoto,
            ),
          ),

          Positioned(
            right: 6,
            top: 6,
            child: _SmallCircleButton(
              icon: Icons.close_rounded,
              tooltip: 'Remove',
              onTap: onRemovePhoto,
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// EMPTY FRAME
// =============================================================================

class _EmptyCollageFrame
    extends StatelessWidget {
  const _EmptyCollageFrame({
    required this.slotNumber,
    required this.onTap,
  });

  final int slotNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF171E2C),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white
                  .withValues(
                alpha: 0.13,
              ),
              width: 1.2,
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final compact =
                    constraints.maxWidth <
                            90 ||
                        constraints
                                .maxHeight <
                            90;

                return Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width:
                          compact ? 32 : 42,
                      height:
                          compact ? 32 : 42,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF8B5CF6,
                        ).withValues(
                          alpha: 0.16,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        Icons
                            .add_photo_alternate_rounded,
                        color:
                            const Color(
                          0xFFC4B5FD,
                        ),
                        size:
                            compact ? 17 : 22,
                      ),
                    ),

                    if (!compact) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '$slotNumber',
                        style: TextStyle(
                          color: Colors.white
                              .withValues(
                            alpha: 0.4,
                          ),
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// INTERACTIVE IMAGE
// =============================================================================

class _CollageImage
    extends StatefulWidget {
  const _CollageImage({
    required this.asset,
  });

  final AssetEntity asset;

  @override
  State<_CollageImage> createState() =>
      _CollageImageState();
}

class _CollageImageState
    extends State<_CollageImage> {
  final TransformationController
      _controller =
      TransformationController();

  late Future<Uint8List?>
      _imageFuture;

  @override
  void initState() {
    super.initState();

    _loadImage();
  }

  @override
  void didUpdateWidget(
    covariant _CollageImage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.asset.id !=
        widget.asset.id) {
      _controller.value =
          Matrix4.identity();

      _loadImage();
    }
  }

  void _loadImage() {
    _imageFuture =
        widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(
        2000,
        2000,
      ),
      quality: 100,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _resetPosition() {
    _controller.value =
        Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child:
          FutureBuilder<Uint8List?>(
        future: _imageFuture,
        builder: (
          context,
          snapshot,
        ) {
          final bytes =
              snapshot.data;

          if (bytes == null) {
            return const ColoredBox(
              color:
                  Color(0xFF171E2C),
              child: Center(
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(
                    0xFF8B5CF6,
                  ),
                ),
              ),
            );
          }

          return GestureDetector(
            onDoubleTap:
                _resetPosition,
            child: InteractiveViewer(
              transformationController:
                  _controller,
              clipBehavior:
                  Clip.hardEdge,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1,
              maxScale: 6,
              interactionEndFrictionCoefficient:
                  0.0000135,
              child: SizedBox.expand(
                child: Image.memory(
                  bytes,
                  width:
                      double.infinity,
                  height:
                      double.infinity,
                  fit: BoxFit.cover,
                  gaplessPlayback:
                      true,
                  filterQuality:
                      FilterQuality
                          .high,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// SMALL CIRCLE ACTION
// =============================================================================

class _SmallCircleButton
    extends StatelessWidget {
  const _SmallCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black
            .withValues(
          alpha: 0.58,
        ),
        shape:
            const CircleBorder(),
        clipBehavior:
            Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder:
              const CircleBorder(),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TOOLBAR BUTTON
// =============================================================================

class _ToolbarButton
    extends StatelessWidget {
  const _ToolbarButton({
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected
                ? const Color(
                    0xFFC4B5FD,
                  )
                : Colors.white54,
            size: 22,
          ),

          const SizedBox(height: 5),

          Text(
            label,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? const Color(
                      0xFFC4B5FD,
                    )
                  : Colors.white54,
              fontSize: 10,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RATIO PREVIEW
// =============================================================================

class _RatioPreview
    extends StatelessWidget {
  const _RatioPreview({
    required this.ratio,
    required this.selected,
  });

  final CollageAspectRatio ratio;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    double width;
    double height;

    switch (ratio) {
      case CollageAspectRatio.square:
        width = 28;
        height = 28;
        break;

      case CollageAspectRatio.portrait:
        width = 24;
        height = 30;
        break;

      case CollageAspectRatio.story:
        width = 18;
        height = 32;
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: selected
              ? Colors.white
              : Colors.white60,
          width: 1.6,
        ),
        borderRadius:
            BorderRadius.circular(2),
      ),
    );
  }
}

// =============================================================================
// LAYOUT BUTTON
// =============================================================================

class _LayoutButton
    extends StatelessWidget {
  const _LayoutButton({
    required this.layout,
    required this.photoCount,
    required this.selected,
    required this.onTap,
  });

  final CollageLayoutType layout;
  final int photoCount;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(
              0xFF8B5CF6,
            )
          : const Color(
              0xFF171E2C,
            ),
      borderRadius:
          BorderRadius.circular(14),
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    10,
                  ),
                  child: CustomPaint(
                    painter:
                        _LayoutIconPainter(
                      layout: layout,
                      selected:
                          selected,
                    ),
                  ),
                ),
              ),

              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment:
                      Alignment.center,
                  decoration:
                      BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.black
                            .withValues(
                            alpha:
                                0.5,
                          ),
                    shape:
                        BoxShape.circle,
                  ),
                  child: Text(
                    '$photoCount',
                    style: TextStyle(
                      color: selected
                          ? const Color(
                              0xFF6D4AE4,
                            )
                          : Colors.white,
                      fontSize: 9,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
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
// LAYOUT ICON PAINTER
// =============================================================================

class _LayoutIconPainter
    extends CustomPainter {
  _LayoutIconPainter({
    required this.layout,
    required this.selected,
  });

  final CollageLayoutType layout;
  final bool selected;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = selected
          ? Colors.white
          : Colors.white
              .withValues(
              alpha: 0.72,
            )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 1.7;

    final left = 1.0;
    final top = 1.0;
    final right =
        size.width - 1;
    final bottom =
        size.height - 1;

    canvas.drawRect(
      Rect.fromLTRB(
        left,
        top,
        right,
        bottom,
      ),
      paint,
    );

    void vertical(double x) {
      canvas.drawLine(
        Offset(
          size.width * x,
          top,
        ),
        Offset(
          size.width * x,
          bottom,
        ),
        paint,
      );
    }

    void horizontal(double y) {
      canvas.drawLine(
        Offset(
          left,
          size.height * y,
        ),
        Offset(
          right,
          size.height * y,
        ),
        paint,
      );
    }

    switch (layout) {
      case CollageLayoutType.twoVertical:
        vertical(0.5);
        break;

      case CollageLayoutType.twoHorizontal:
        horizontal(0.5);
        break;

      case CollageLayoutType.threeLeft:
        vertical(0.62);

        canvas.drawLine(
          Offset(
            size.width * 0.62,
            size.height * 0.5,
          ),
          Offset(
            right,
            size.height * 0.5,
          ),
          paint,
        );
        break;

      case CollageLayoutType.threeRight:
        vertical(0.38);

        canvas.drawLine(
          Offset(
            left,
            size.height * 0.5,
          ),
          Offset(
            size.width * 0.38,
            size.height * 0.5,
          ),
          paint,
        );
        break;

      case CollageLayoutType.threeTop:
        horizontal(0.62);

        canvas.drawLine(
          Offset(
            size.width * 0.5,
            size.height * 0.62,
          ),
          Offset(
            size.width * 0.5,
            bottom,
          ),
          paint,
        );
        break;

      case CollageLayoutType.threeBottom:
        horizontal(0.38);

        canvas.drawLine(
          Offset(
            size.width * 0.5,
            top,
          ),
          Offset(
            size.width * 0.5,
            size.height * 0.38,
          ),
          paint,
        );
        break;

      case CollageLayoutType.threeColumns:
        vertical(1 / 3);
        vertical(2 / 3);
        break;

      case CollageLayoutType.fourGrid:
        vertical(0.5);
        horizontal(0.5);
        break;

      case CollageLayoutType.fourTopWide:
        horizontal(0.62);

        canvas.drawLine(
          Offset(
            size.width / 3,
            size.height * 0.62,
          ),
          Offset(
            size.width / 3,
            bottom,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            size.width * 2 / 3,
            size.height * 0.62,
          ),
          Offset(
            size.width * 2 / 3,
            bottom,
          ),
          paint,
        );
        break;

      case CollageLayoutType.fourBottomWide:
        horizontal(0.38);

        canvas.drawLine(
          Offset(
            size.width / 3,
            top,
          ),
          Offset(
            size.width / 3,
            size.height * 0.38,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            size.width * 2 / 3,
            top,
          ),
          Offset(
            size.width * 2 / 3,
            size.height * 0.38,
          ),
          paint,
        );
        break;

      case CollageLayoutType.fourLeftWide:
        vertical(0.62);

        canvas.drawLine(
          Offset(
            size.width * 0.62,
            size.height / 3,
          ),
          Offset(
            right,
            size.height / 3,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            size.width * 0.62,
            size.height * 2 / 3,
          ),
          Offset(
            right,
            size.height * 2 / 3,
          ),
          paint,
        );
        break;

      case CollageLayoutType.fourRightWide:
        vertical(0.38);

        canvas.drawLine(
          Offset(
            left,
            size.height / 3,
          ),
          Offset(
            size.width * 0.38,
            size.height / 3,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            left,
            size.height * 2 / 3,
          ),
          Offset(
            size.width * 0.38,
            size.height * 2 / 3,
          ),
          paint,
        );
        break;

      case CollageLayoutType.sixGrid:
        vertical(0.5);
        horizontal(1 / 3);
        horizontal(2 / 3);
        break;

      case CollageLayoutType.sixTopWide:
        horizontal(0.48);
        horizontal(0.74);

        canvas.drawLine(
          Offset(
            size.width / 2,
            size.height * 0.48,
          ),
          Offset(
            size.width / 2,
            size.height * 0.74,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            size.width / 3,
            size.height * 0.74,
          ),
          Offset(
            size.width / 3,
            bottom,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            size.width * 2 / 3,
            size.height * 0.74,
          ),
          Offset(
            size.width * 2 / 3,
            bottom,
          ),
          paint,
        );
        break;

      case CollageLayoutType.sixBottomWide:
        horizontal(0.26);
        horizontal(0.52);

        canvas.drawLine(
          Offset(
            size.width / 3,
            top,
          ),
          Offset(
            size.width / 3,
            size.height * 0.26,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            size.width * 2 / 3,
            top,
          ),
          Offset(
            size.width * 2 / 3,
            size.height * 0.26,
          ),
          paint,
        );

        canvas.drawLine(
          Offset(
            size.width / 2,
            size.height * 0.26,
          ),
          Offset(
            size.width / 2,
            size.height * 0.52,
          ),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(
    covariant _LayoutIconPainter oldDelegate,
  ) {
    return oldDelegate.layout != layout ||
        oldDelegate.selected != selected;
  }
}