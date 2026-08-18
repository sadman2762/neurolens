import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import 'photo_editor/filters/engine/filter_image_processor.dart';
import 'photo_editor/filters/filter_processor.dart';
import 'photo_editor/filters/midnight_vignette.dart';
import 'photo_editor/filters/neurolens_filters.dart';

import 'photo_editor/filters/presets/neurolens_filter_presets.dart';

import 'photo_editor/filters/lut/neurolens_filter_recipe.dart';
import 'photo_editor/filters/lut/neurolens_filter_recipes.dart';
import 'photo_editor/filters/lut/neurolens_grade_widget.dart';

class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({
    required this.assetId,
    required this.title,
    super.key,
  });

  final String assetId;
  final String title;

  @override
  State<PhotoEditorScreen> createState() =>
      _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  // ===========================================================================
  // THEME
  // ===========================================================================

  static const Color _background = Color(0xFF050816);

  static const Color _surface = Color(0xFF0D1321);

  static const Color _surfaceLight = Color(0xFF151C2E);

  static const Color _purple = Color(0xFF8B5CF6);

  static const Color _purpleLight = Color(0xFFC4B5FD);

  static const Color _textPrimary = Color(0xFFF8FAFC);

  static const Color _textSecondary = Color(0xFF94A3B8);

  // ===========================================================================
  // FILTER NAMES
  // ===========================================================================

  static const String _normalFilterName = 'Normal';

  static const String _midnightFilterName = 'Midnight';

  // ===========================================================================
  // IDENTITY MATRIX
  // ===========================================================================

  static const List<double> _identityMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  // ===========================================================================
  // IMAGE
  // ===========================================================================

  late final Future<Uint8List?> _imageFuture;

  // ===========================================================================
  // FILTER EDITOR STATE
  // ===========================================================================

  FilterEditorState? _activeFilterEditor;

  String _selectedFilterName = _normalFilterName;

  final Map<String, double> _visibleIntensity = <String, double>{};

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _imageFuture = _loadImage();
  }

  // ===========================================================================
  // LOAD IMAGE
  // ===========================================================================

  Future<Uint8List?> _loadImage() async {
    final asset = await AssetEntity.fromId(
      widget.assetId,
    );

    if (asset == null) {
      return null;
    }

    final bytes = await asset.originBytes;

    if (bytes == null) {
      return null;
    }

    return bytes;
  }

  // ===========================================================================
  // COMPLETE / EXPORT
  // ===========================================================================

  Future<void> _handleEditingComplete(
    Uint8List editedBytes,
  ) async {
    Uint8List outputBytes = editedBytes;

    // =======================================================================
    // PREMIUM MIDNIGHT EXPORT
    // =======================================================================

    if (_selectedFilterName == _midnightFilterName) {
      final intensity = _visibleIntensityFor(
        _midnightFilterName,
      );

      outputBytes = await FilterImageProcessor.apply(
        imageBytes: editedBytes,
        recipe: NeuroLensFilterPresets.midnight,
        intensity: intensity,
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop<Uint8List>(
      outputBytes,
    );
  }

  // ===========================================================================
  // PREMIUM THUMBNAIL RECIPES
  // ===========================================================================

  NeuroLensFilterRecipe? _premiumRecipeByName(
    String name,
  ) {
    return NeuroLensFilterRecipes.byName(
      name,
    );
  }

  // ===========================================================================
  // FILTER LIST
  // ===========================================================================

  List<FilterModel> _buildNeuroLensFilters() {
    return NeuroLensFilters.all
        .where(
          (filter) => filter.isColorFilter,
        )
        .map(
          (filter) {
            final List<double> matrix;

            // Midnight remains identity inside ProImageEditor.
            //
            // Its final premium processing happens during export.
            if (filter.name == _midnightFilterName) {
              matrix = _identityMatrix;
            } else {
              matrix = FilterProcessor.matrixFor(
                filter: filter,
                intensity: filter.defaultIntensity,
              );
            }

            return FilterModel(
              name: filter.name,
              filters: [
                matrix,
              ],
            );
          },
        )
        .toList(
          growable: false,
        );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool _isMidnightFilter(
    FilterModel filter,
  ) {
    return filter.name == _midnightFilterName;
  }

  // ===========================================================================
  // INTENSITY
  // ===========================================================================

  double _visibleIntensityFor(
    String filterName,
  ) {
    return _visibleIntensity[filterName] ?? 0.55;
  }

  double _boostMatrixIntensity(
    double value,
  ) {
    final v = value.clamp(
      0.0,
      1.0,
    );

    if (v <= 0.001) {
      return 0.0;
    }

    return (
      0.17 +
      (v * 0.83)
    ).clamp(
      0.0,
      1.0,
    );
  }

  // ===========================================================================
  // INTENSITY PANEL
  // ===========================================================================

  Future<void> _openIntensityPanel() async {
    final editor = _activeFilterEditor;

    if (editor == null || !editor.mounted) {
      return;
    }

    final filterName = editor.selectedFilter.name;

    _selectedFilterName = filterName;

    final isMidnight = filterName == _midnightFilterName;

    double currentValue = _visibleIntensityFor(
      filterName,
    );

    await showModalBottomSheet<void>(
      context: editor.context,
      backgroundColor: _surface,
      barrierColor: Colors.transparent,
      isScrollControlled: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (
        sheetContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final percentage = (
              currentValue * 100
            ).round();

            return SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: _surface,
                padding: const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to filters',
                          onPressed: () {
                            Navigator.of(
                              sheetContext,
                            ).pop();
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: _purpleLight,
                          ),
                        ),

                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filterName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                '$percentage',
                                style: const TextStyle(
                                  color: _purpleLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.of(
                              sheetContext,
                            ).pop();
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              color: _purpleLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2.4,
                        activeTrackColor: _purple,
                        inactiveTrackColor:
                            _purpleLight.withValues(
                          alpha: 0.20,
                        ),
                        thumbColor: _purpleLight,
                        overlayColor: _purple.withValues(
                          alpha: 0.18,
                        ),
                        thumbShape:
                            const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        overlayShape:
                            const RoundSliderOverlayShape(
                          overlayRadius: 18,
                        ),
                        showValueIndicator:
                            ShowValueIndicator.never,
                      ),
                      child: Slider(
                        value: currentValue,
                        min: 0,
                        max: 1,
                        onChanged: (
                          value,
                        ) {
                          setSheetState(
                            () {
                              currentValue = value;
                            },
                          );

                          _visibleIntensity[filterName] =
                              value;

                          _selectedFilterName =
                              filterName;

                          // ===============================================
                          // MIDNIGHT
                          // ===============================================
                          //
                          // ProImageEditor stays on the identity matrix.
                          //
                          // Midnight's premium pixel processing happens
                          // during final export.
                          // ===============================================

                          if (isMidnight) {
                            setState(
                              () {},
                            );

                            return;
                          }

                          editor.setFilterOpacity(
                            _boostMatrixIntensity(
                              value,
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '0',
                            style: TextStyle(
                              color: _purpleLight.withValues(
                                alpha: 0.48,
                              ),
                              fontSize: 9,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '100',
                            style: TextStyle(
                              color: _purpleLight.withValues(
                                alpha: 0.48,
                              ),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // FILTER CARD
  // ===========================================================================

  Widget _buildFilterButton({
    required FilterModel filter,
    required bool isSelected,
    required double? scaleFactor,
    required dynamic onSelectFilter,
    required Widget editorImage,
    required Key filterKey,
  }) {
    final isNormal =
        filter.name.toLowerCase() == 'normal';

    final isMidnight = _isMidnightFilter(
      filter,
    );

    final premiumRecipe = _premiumRecipeByName(
      filter.name,
    );

    const double previewSize = 84;

    const double itemWidth = 96;

    const double itemHeight = 106;

    final intensity = isSelected
        ? _visibleIntensityFor(
            filter.name,
          )
        : 0.55;

    Widget preview = editorImage;

    // =====================================================================
    // PREMIUM THUMBNAIL LOOK
    // =====================================================================

    if (premiumRecipe != null && !isNormal) {
      preview = NeuroLensGradeWidget(
        recipe: premiumRecipe,
        intensity: intensity,
        child: preview,
      );
    }

    // =====================================================================
    // MIDNIGHT THUMBNAIL VIGNETTE
    // =====================================================================

    if (isMidnight) {
      preview = MidnightVignette(
        intensity: intensity,
        child: preview,
      );
    }

    return SizedBox(
      key: filterKey,
      width: itemWidth,
      height: itemHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  onSelectFilter();

                  _selectedFilterName =
                      filter.name;

                  final visible =
                      _visibleIntensityFor(
                    filter.name,
                  );

                  if (isMidnight) {
                    _activeFilterEditor
                        ?.setFilterOpacity(
                      1.0,
                    );

                    setState(
                      () {},
                    );

                    return;
                  }

                  if (!isNormal) {
                    _activeFilterEditor
                        ?.setFilterOpacity(
                      _boostMatrixIntensity(
                        visible,
                      ),
                    );
                  } else {
                    _selectedFilterName =
                        _normalFilterName;
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 150,
                  ),
                  width: previewSize,
                  height: previewSize,
                  padding: const EdgeInsets.all(
                    2,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? _purple
                          : _purple.withValues(
                              alpha: 0.18,
                            ),
                      width: isSelected
                          ? 2.5
                          : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      7,
                    ),
                    child: SizedBox.expand(
                      child: preview,
                    ),
                  ),
                ),
              ),

              if (isSelected && !isNormal)
                Positioned(
                  left: 5,
                  bottom: 5,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openIntensityPanel,
                    child: Container(
                      width: 29,
                      height: 29,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _surface,
                        border: Border.all(
                          color: _purple,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withValues(
                              alpha: 0.22,
                            ),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: _purpleLight,
                        size: 15,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          SizedBox(
            width: itemWidth,
            height: 17,
            child: Center(
              child: Text(
                filter.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? _purpleLight
                      : _textSecondary,
                  fontSize: 10,
                  height: 1,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // THEME
  // ===========================================================================

  ThemeData _editorTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: _background,
      canvasColor: _background,
      cardColor: _surface,
      dividerColor: _purple.withValues(
        alpha: 0.16,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.dark(
        primary: _purple,
        secondary: _purpleLight,
        surface: _surface,
        surfaceContainer: _surface,
        surfaceContainerHigh: _surfaceLight,
        onSurface: _textPrimary,
        onPrimary: Colors.white,
        onSecondary: _background,
        error: Color(
          0xFFF87171,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(
        color: _purpleLight,
      ),
      textTheme: ThemeData.dark()
          .textTheme
          .apply(
        bodyColor: _textPrimary,
        displayColor: _textPrimary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _purpleLight,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _purpleLight,
          side: const BorderSide(
            color: _purple,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _purple,
        inactiveTrackColor:
            _purpleLight.withValues(
          alpha: 0.18,
        ),
        thumbColor: _purpleLight,
        overlayColor: _purple.withValues(
          alpha: 0.16,
        ),
      ),
      bottomSheetTheme:
          const BottomSheetThemeData(
        backgroundColor: _surface,
        modalBackgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme:
          const PopupMenuThemeData(
        color: _surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme:
          const SnackBarThemeData(
        backgroundColor: _surfaceLight,
        contentTextStyle: TextStyle(
          color: _textPrimary,
        ),
      ),
    );
  }

  // ===========================================================================
  // EDITOR CONFIG
  // ===========================================================================

  ProImageEditorConfigs _editorConfigs() {
    return ProImageEditorConfigs(
      designMode:
          ImageEditorDesignMode.material,

      mainEditor: MainEditorConfigs(
        enableZoom: true,
        enableDoubleTapZoom: true,
        editorMaxScale: 5,
        tools: [
          SubEditorMode.cropRotate,
          SubEditorMode.tune,
          SubEditorMode.filter,
          SubEditorMode.text,
          SubEditorMode.paint,
          SubEditorMode.blur,
        ],
      ),

      cropRotateEditor:
          CropRotateEditorConfigs(
        enableKeepAspectRatioOnRotate:
            true,
        tools: [
          CropRotateTool.rotate,
          CropRotateTool.flip,
          CropRotateTool.aspectRatio,
          CropRotateTool.reset,
        ],
        aspectRatios: [
          AspectRatioItem(
            text: 'Free',
            value: -1,
          ),
          AspectRatioItem(
            text: 'Original',
            value: 0,
          ),
          AspectRatioItem(
            text: '1:1',
            value: 1,
          ),
          AspectRatioItem(
            text: '4:5',
            value: 4 / 5,
          ),
          AspectRatioItem(
            text: '5:4',
            value: 5 / 4,
          ),
          AspectRatioItem(
            text: '16:9',
            value: 16 / 9,
          ),
          AspectRatioItem(
            text: '9:16',
            value: 9 / 16,
          ),
        ],
      ),

      filterEditor: FilterEditorConfigs(
        enableMultiSelection: false,

        filterList:
            _buildNeuroLensFilters(),

        style: const FilterEditorStyle(
          background: _background,
          filterListSpacing: 10,
          filterListMargin:
              EdgeInsets.fromLTRB(
            8,
            0,
            8,
            0,
          ),
          previewTextColor:
              _textSecondary,
          previewSelectedTextColor:
              _purpleLight,
        ),

        widgets: FilterEditorWidgets(
          slider: (
            editorState,
            rebuildStream,
            value,
            onChanged,
            onChangeEnd,
          ) {
            _activeFilterEditor =
                editorState;

            return ReactiveWidget<Widget>(
              stream: rebuildStream,
              builder: (_) {
                return const SizedBox
                    .shrink();
              },
            );
          },

          filterButton: (
            filter,
            isSelected,
            scaleFactor,
            onSelectFilter,
            editorImage,
            filterKey,
          ) {
            return _buildFilterButton(
              filter: filter,
              isSelected: isSelected,
              scaleFactor: scaleFactor,
              onSelectFilter:
                  onSelectFilter,
              editorImage: editorImage,
              filterKey: filterKey,
            );
          },
        ),
      ),

      stateHistory: StateHistoryConfigs(
        stateHistoryLimit: 100,
      ),

      imageGeneration:
          ImageGenerationConfigs(
        outputFormat: OutputFormat.jpg,
        jpegQuality: 94,
      ),
    );
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,
      body: FutureBuilder<Uint8List?>(
        future: _imageFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const _LoadingView();
          }

          if (snapshot.hasError ||
              snapshot.data == null) {
            return _EditorErrorView(
              onClose: () {
                Navigator.of(
                  context,
                ).pop();
              },
            );
          }

          return Theme(
            data: _editorTheme(),
            child: ColoredBox(
              color: _background,
              child: ProImageEditor.memory(
                snapshot.data!,
                callbacks:
                    ProImageEditorCallbacks(
                  onImageEditingComplete:
                      _handleEditingComplete,
                ),
                configs: _editorConfigs(),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// LOADING
// =============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      backgroundColor: Color(
        0xFF050816,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(
                  0xFF8B5CF6,
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                'Preparing your editor...',
                style: TextStyle(
                  color: Color(
                    0xFFF8FAFC,
                  ),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 6,
              ),
              Text(
                'Everything stays on this device.',
                style: TextStyle(
                  color: Color(
                    0xFF94A3B8,
                  ),
                  fontSize: 12,
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

class _EditorErrorView extends StatelessWidget {
  const _EditorErrorView({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF050816,
      ),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF050816,
        ),
        foregroundColor: const Color(
          0xFFC4B5FD,
        ),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(
            28,
          ),
          child: Container(
            constraints:
                const BoxConstraints(
              maxWidth: 420,
            ),
            padding: const EdgeInsets.all(
              26,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFF0D1321,
              ),
              borderRadius:
                  BorderRadius.circular(
                26,
              ),
              border: Border.all(
                color: const Color(
                  0xFF8B5CF6,
                ).withValues(
                  alpha: 0.22,
                ),
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF8B5CF6,
                    ).withValues(
                      alpha: 0.14,
                    ),
                  ),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(
                      0xFFC4B5FD,
                    ),
                    size: 40,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Photo unavailable',
                  style: TextStyle(
                    color: Color(
                      0xFFF8FAFC,
                    ),
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 9,
                ),
                const Text(
                  'NeuroLens could not access the original photo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(
                      0xFF94A3B8,
                    ),
                    height: 1.45,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                    ),
                    label: const Text(
                      'Go back',
                    ),
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