import 'package:flutter/material.dart';

class FilterIntensitySlider extends StatelessWidget {
  const FilterIntensitySlider({
    required this.filterName,
    required this.value,
    required this.onChanged,
    required this.onDone,
    required this.onBack,
    super.key,
  });

  final String filterName;

  /// Range: 0.0 - 1.0
  final double value;

  final ValueChanged<double> onChanged;
  final VoidCallback onDone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          12,
          18,
          14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===============================================================
            // HEADER
            // ===============================================================

            Row(
              children: [
                IconButton(
                  tooltip: 'Back to filters',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),

                Expanded(
                  child: Text(
                    filterName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                TextButton(
                  onPressed: onDone,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 2,
            ),

            // ===============================================================
            // VALUE
            // ===============================================================

            Text(
              '$percentage',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.72,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            // ===============================================================
            // INSTAGRAM-STYLE INTENSITY LINE
            // ===============================================================

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.5,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(
                  alpha: 0.22,
                ),

                thumbColor: Colors.white,

                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),

                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 16,
                ),

                overlayColor: Colors.white.withValues(
                  alpha: 0.10,
                ),

                trackShape:
                    const RoundedRectSliderTrackShape(),

                showValueIndicator:
                    ShowValueIndicator.never,
              ),
              child: Slider(
                value: value.clamp(
                  0.0,
                  1.0,
                ),
                min: 0,
                max: 1,
                onChanged: onChanged,
              ),
            ),

            // ===============================================================
            // 0 / 100
            // ===============================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
              ),
              child: Row(
                children: [
                  Text(
                    '0',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.34,
                      ),
                      fontSize: 9,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '100',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.34,
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
  }
}