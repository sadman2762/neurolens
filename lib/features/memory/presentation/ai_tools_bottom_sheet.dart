import 'package:flutter/material.dart';

class AiToolsBottomSheet extends StatelessWidget {
  const AiToolsBottomSheet({
    required this.onObjectEraser,
    required this.onDoodles,
    super.key,
  });

  final VoidCallback onObjectEraser;
  final VoidCallback onDoodles;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0D1321);

    return SafeArea(
      child: Container(
        color: background,
        padding: const EdgeInsets.fromLTRB(
          18,
          6,
          18,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Creative and AI-powered editing tools.',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.48,
                ),
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ===============================================================
            // OBJECT ERASER
            // ===============================================================

            _AiToolTile(
              icon: Icons.auto_fix_high_rounded,
              title: 'Object Eraser',
              subtitle:
                  'Tap multiple objects or refine the selection with a brush',
              onTap: onObjectEraser,
            ),

            const SizedBox(
              height: 10,
            ),

            // ===============================================================
            // DOODLES
            // ===============================================================

            _AiToolTile(
              icon: Icons.draw_rounded,
              title: 'Doodles',
              subtitle:
                  'Draw, sketch and decorate your photo',
              onTap: onDoodles,
            ),

            const SizedBox(
              height: 10,
            ),

            // ===============================================================
            // COLLAGE
            // ===============================================================

            const _AiToolTile(
              icon: Icons.grid_view_rounded,
              title: 'Collage',
              subtitle:
                  'Combine multiple photos into one layout',
            ),

            const SizedBox(
              height: 10,
            ),

            // ===============================================================
            // NEUROLENS ULTRA
            // ===============================================================

            const _AiToolTile(
              icon: Icons.auto_awesome_rounded,
              title: 'NeuroLens Ultra',
              subtitle:
                  'Advanced AI photo editing',
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TOOL TILE
// =============================================================================

class _AiToolTile extends StatelessWidget {
  const _AiToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: const Color(
        0xFF141B2D,
      ),
      borderRadius: BorderRadius.circular(
        16,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          16,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(
                          0xFF8B5CF6,
                        ).withValues(
                          alpha: 0.14,
                        )
                      : Colors.white.withValues(
                          alpha: 0.04,
                        ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? const Color(
                          0xFFC4B5FD,
                        )
                      : Colors.white24,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled
                            ? Colors.white
                            : Colors.white38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      enabled
                          ? subtitle
                          : '$subtitle • Coming soon',
                      style: TextStyle(
                        color: enabled
                            ? Colors.white.withValues(
                                alpha: 0.46,
                              )
                            : Colors.white.withValues(
                                alpha: 0.25,
                              ),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              if (enabled)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 15,
                ),
            ],
          ),
        ),
      ),
    );
  }
}