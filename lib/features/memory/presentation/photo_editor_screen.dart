import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({
    required this.assetId,
    required this.title,
    super.key,
  });

  final String assetId;
  final String title;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleLight = Color(0xFFC4B5FD);

  late final Future<Uint8List?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<Uint8List?> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);

    if (asset == null) {
      return null;
    }

    return asset.originBytes;
  }

  Future<void> _handleEditingComplete(Uint8List editedBytes) async {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop<Uint8List>(editedBytes);
  }

  ThemeData _editorTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: _background,
      canvasColor: _background,
      cardColor: _surface,
      dialogTheme: const DialogThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.dark(
        primary: _purple,
        secondary: _purpleLight,
        surface: _surface,
        error: Color(0xFFF87171),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _purpleLight),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _purple,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
        thumbColor: _purple,
        overlayColor: _purple.withValues(alpha: 0.14),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  ProImageEditorConfigs _editorConfigs() {
    return ProImageEditorConfigs(
      designMode: ImageEditorDesignMode.material,

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

      cropRotateEditor: CropRotateEditorConfigs(
        enableKeepAspectRatioOnRotate: true,
        tools: [
          CropRotateTool.rotate,
          CropRotateTool.flip,
          CropRotateTool.aspectRatio,
          CropRotateTool.reset,
        ],
        aspectRatios: [
          AspectRatioItem(text: 'Free', value: -1),
          AspectRatioItem(text: 'Original', value: 0),
          AspectRatioItem(text: '1:1', value: 1),
          AspectRatioItem(text: '4:5', value: 4 / 5),
          AspectRatioItem(text: '5:4', value: 5 / 4),
          AspectRatioItem(text: '16:9', value: 16 / 9),
          AspectRatioItem(text: '9:16', value: 9 / 16),
        ],
      ),

      filterEditor: FilterEditorConfigs(
        filterList: [
          PresetFilters.none,
          PresetFilters.clarendon,
          PresetFilters.juno,
          PresetFilters.lark,
          PresetFilters.valencia,
          PresetFilters.nashville,
          PresetFilters.moon,
          PresetFilters.inkwell,
          PresetFilters.willow,
          PresetFilters.xProII,
        ],
      ),

      stateHistory: StateHistoryConfigs(stateHistoryLimit: 100),

      imageGeneration: ImageGenerationConfigs(
        outputFormat: OutputFormat.jpg,
        jpegQuality: 92,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: FutureBuilder<Uint8List?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _EditorErrorView(
              onClose: () {
                Navigator.of(context).pop();
              },
            );
          }

          return Theme(
            data: _editorTheme(),
            child: ColoredBox(
              color: _background,
              child: ProImageEditor.memory(
                snapshot.data!,
                callbacks: ProImageEditorCallbacks(
                  onImageEditingComplete: _handleEditingComplete,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050816),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              SizedBox(height: 16),
              Text(
                'Preparing your editor...',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Everything stays on this device.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorErrorView extends StatelessWidget {
  const _EditorErrorView({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1321),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFC4B5FD),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Photo unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'NeuroLens could not access the original photo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go back'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
