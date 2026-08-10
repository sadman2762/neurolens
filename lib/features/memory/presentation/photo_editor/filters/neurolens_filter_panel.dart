import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../widgets/filter_intensity_slider.dart';
import 'filter_thumbnail.dart';
import 'neurolens_filter.dart';
import 'neurolens_filters.dart';

class NeuroLensFilterPanel extends StatefulWidget {
  const NeuroLensFilterPanel({
    required this.imageBytes,
    required this.selectedFilter,
    required this.intensity,
    required this.onFilterChanged,
    required this.onIntensityChanged,
    super.key,
  });

  final Uint8List imageBytes;

  final NeuroLensFilter selectedFilter;

  /// 0.0 - 1.0
  final double intensity;

  final ValueChanged<NeuroLensFilter> onFilterChanged;
  final ValueChanged<double> onIntensityChanged;

  @override
  State<NeuroLensFilterPanel> createState() =>
      _NeuroLensFilterPanelState();
}

class _NeuroLensFilterPanelState
    extends State<NeuroLensFilterPanel> {
  bool _showIntensity = false;

  final ScrollController _scrollController =
      ScrollController();

  void _handleFilterTap(
    NeuroLensFilter filter,
  ) {
    // Normal does not need an intensity screen.
    if (filter.isNormal) {
      widget.onFilterChanged(filter);

      if (_showIntensity) {
        setState(() {
          _showIntensity = false;
        });
      }

      return;
    }

    // Instagram-like behaviour:
    // tapping the already selected filter opens intensity.
    if (filter.id == widget.selectedFilter.id) {
      setState(() {
        _showIntensity = true;
      });

      return;
    }

    // First tap selects the filter.
    widget.onFilterChanged(filter);
  }

  void _closeIntensity() {
    setState(() {
      _showIntensity = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: 180,
      ),
      child: _showIntensity
          ? FilterIntensitySlider(
              key: ValueKey(
                'intensity-${widget.selectedFilter.id}',
              ),
              filterName:
                  widget.selectedFilter.name,
              value: widget.intensity,
              onChanged:
                  widget.onIntensityChanged,
              onBack: _closeIntensity,
              onDone: _closeIntensity,
            )
          : _buildFilterCarousel(),
    );
  }

  Widget _buildFilterCarousel() {
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey(
          'filter-carousel',
        ),
        height: 128,
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 8,
        ),
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics:
              const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          itemCount:
              NeuroLensFilters.all.length,
          separatorBuilder: (
            context,
            index,
          ) {
            return const SizedBox(
              width: 4,
            );
          },
          itemBuilder: (
            context,
            index,
          ) {
            final filter =
                NeuroLensFilters.all[index];

            final selected =
                filter.id ==
                    widget.selectedFilter.id;

            return FilterThumbnail(
              imageBytes:
                  widget.imageBytes,
              filter: filter,
              selected: selected,
              intensity: selected
                  ? widget.intensity
                  : 1.0,
              onTap: () {
                _handleFilterTap(
                  filter,
                );
              },
            );
          },
        ),
      ),
    );
  }
}