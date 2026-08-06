import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

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

  late final Future<Uint8List?> _imageFuture;

  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<Uint8List?> _loadImage() async {
    final asset = await AssetEntity.fromId(widget.assetId);
    return asset?.originBytes;
  }

  void _rotateLeft() {
    setState(() {
      _quarterTurns = (_quarterTurns - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _reset() {
    setState(() {
      _brightness = 0;
      _contrast = 1;
      _saturation = 1;
      _quarterTurns = 0;
    });
  }

  void _showComingNext() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Image rendering and save-as-new-photo will be connected next.',
        ),
      ),
    );
  }

  List<double> _colorMatrix() {
    final saturation = _saturation;
    final inverseSaturation = 1 - saturation;

    final red = inverseSaturation * 0.2126;
    final green = inverseSaturation * 0.7152;
    final blue = inverseSaturation * 0.0722;

    final contrastTranslate = 128 * (1 - _contrast);
    final brightnessTranslate = _brightness * 255;

    return <double>[
      (red + saturation) * _contrast,
      green * _contrast,
      blue * _contrast,
      0,
      contrastTranslate + brightnessTranslate,
      red * _contrast,
      (green + saturation) * _contrast,
      blue * _contrast,
      0,
      contrastTranslate + brightnessTranslate,
      red * _contrast,
      green * _contrast,
      (blue + saturation) * _contrast,
      0,
      contrastTranslate + brightnessTranslate,
      0,
      0,
      0,
      1,
      0,
    ];
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
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('Reset'),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: _showComingNext,
            style: FilledButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _purple.withValues(alpha: 0.55),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FutureBuilder<Uint8List?>(
                    future: _imageFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: _purple,
                          ),
                        );
                      }

                      final imageBytes = snapshot.data;

                      if (snapshot.hasError || imageBytes == null) {
                        return const _EditorErrorView();
                      }

                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 5,
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: _quarterTurns,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(
                                _colorMatrix(),
                              ),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _EditorAction(
                          icon: Icons.rotate_left_rounded,
                          label: 'Rotate left',
                          onPressed: _rotateLeft,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditorAction(
                          icon: Icons.rotate_right_rounded,
                          label: 'Rotate right',
                          onPressed: _rotateRight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditorAction(
                          icon: Icons.crop_rounded,
                          label: 'Crop',
                          onPressed: _showComingNext,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditorAction(
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI edit',
                          isPremium: true,
                          onPressed: _showComingNext,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _AdjustmentSlider(
                    label: 'Brightness',
                    icon: Icons.brightness_6_outlined,
                    value: _brightness,
                    minimum: -0.5,
                    maximum: 0.5,
                    onChanged: (value) {
                      setState(() {
                        _brightness = value;
                      });
                    },
                  ),
                  _AdjustmentSlider(
                    label: 'Contrast',
                    icon: Icons.contrast_rounded,
                    value: _contrast,
                    minimum: 0.5,
                    maximum: 1.5,
                    onChanged: (value) {
                      setState(() {
                        _contrast = value;
                      });
                    },
                  ),
                  _AdjustmentSlider(
                    label: 'Saturation',
                    icon: Icons.color_lens_outlined,
                    value: _saturation,
                    minimum: 0,
                    maximum: 2,
                    onChanged: (value) {
                      setState(() {
                        _saturation = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorAction extends StatelessWidget {
  const _EditorAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPremium = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141B2D),
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 12,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isPremium
                        ? const Color(0xFFC4B5FD)
                        : Colors.white,
                    size: 23,
                  ),
                  if (isPremium)
                    const Positioned(
                      top: -7,
                      right: -9,
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFFBBF24),
                        size: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 10,
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

class _AdjustmentSlider extends StatelessWidget {
  const _AdjustmentSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double value;
  final double minimum;
  final double maximum;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFC4B5FD),
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: minimum,
            max: maximum,
            activeColor: const Color(0xFF8B5CF6),
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _EditorErrorView extends StatelessWidget {
  const _EditorErrorView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: Color(0xFFC084FC),
              size: 46,
            ),
            SizedBox(height: 14),
            Text(
              'This photo is no longer available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}