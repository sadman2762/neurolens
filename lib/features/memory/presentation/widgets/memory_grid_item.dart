import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/presentation/widgets/memory_thumbnail.dart';

class MemoryGridItem extends StatefulWidget {
  const MemoryGridItem({
    required this.memory,
    required this.onTap,
    super.key,
  });

  final Memory memory;
  final VoidCallback onTap;

  @override
  State<MemoryGridItem> createState() => _MemoryGridItemState();
}

class _MemoryGridItemState extends State<MemoryGridItem> {
  static const Color _surfaceColor = Color(0xFF0D1321);
  static const Color _purple = Color(0xFF8B5CF6);

  bool _isPressed = false;

  Memory get memory => widget.memory;

  Future<void> _handleTap() async {
    setState(() {
      _isPressed = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 90),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isPressed = false;
    });

    widget.onTap();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  Color get _typeColor {
    switch (memory.type) {
      case 'pdf':
        return const Color(0xFFF87171);
      case 'note':
        return const Color(0xFFFACC15);
      default:
        return _purple;
    }
  }

  IconData get _typeIcon {
    switch (memory.type) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'note':
        return Icons.note_alt_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  String get _typeLabel {
    switch (memory.type) {
      case 'pdf':
        return 'PDF';
      case 'note':
        return 'Note';
      default:
        return 'Image';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: _handleTapDown,
        onTapCancel: _handleTapCancel,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.06,
                ),
              ),
            ),
            child: memory.type == 'image'
                ? _ImageMemoryCard(
                    memory: memory,
                  )
                : _DocumentMemoryCard(
                    memory: memory,
                    icon: _typeIcon,
                    typeLabel: _typeLabel,
                    typeColor: _typeColor,
                  ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// IMAGE MEMORY
// =============================================================================

class _ImageMemoryCard extends StatelessWidget {
  const _ImageMemoryCard({
    required this.memory,
  });

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: Colors.transparent,
          child: MemoryThumbnail(
            assetId: memory.id,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Color(0xB3000000),
              ],
              stops: [
                0,
                0.58,
                1,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DOCUMENT MEMORY
// =============================================================================

class _DocumentMemoryCard extends StatelessWidget {
  const _DocumentMemoryCard({
    required this.memory,
    required this.icon,
    required this.typeLabel,
    required this.typeColor,
  });

  final Memory memory;
  final IconData icon;
  final String typeLabel;
  final Color typeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: typeColor.withValues(
                alpha: 0.13,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: typeColor,
              size: 21,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          Expanded(
            child: Text(
              memory.title,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                typeLabel,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.5,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}