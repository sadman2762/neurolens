import 'package:flutter/material.dart';

class AiToolsBottomSheet extends StatelessWidget {
  const AiToolsBottomSheet({
    required this.onObjectEraser,
    required this.onManualEraser,
    super.key,
  });

  final VoidCallback onObjectEraser;
  final VoidCallback onManualEraser;

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
              'AI Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Powerful AI editing tools.',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.48,
                ),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),

            _AiToolTile(
              icon: Icons.auto_fix_high_rounded,
              title: 'Object Eraser',
              subtitle:
                  'Tap an object and let AI select it automatically',
              onTap: onObjectEraser,
            ),

            const SizedBox(height: 10),

            _AiToolTile(
              icon: Icons.brush_rounded,
              title: 'Manual Eraser',
              subtitle:
                  'Paint over anything you want to remove',
              onTap: onManualEraser,
            ),

            const SizedBox(height: 10),

            const _AiToolTile(
              icon:
                  Icons.person_remove_alt_1_rounded,
              title: 'Background Remover',
              subtitle: 'Coming soon',
            ),

            const SizedBox(height: 10),

            const _AiToolTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Enhance Photo',
              subtitle: 'Coming soon',
            ),

            const SizedBox(height: 10),

            const _AiToolTile(
              icon: Icons.crop_free_rounded,
              title: 'Expand Image',
              subtitle: 'Coming soon',
            ),
          ],
        ),
      ),
    );
  }
}

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
      color: const Color(0xFF141B2D),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? const Color(0xFFC4B5FD)
                      : Colors.white24,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
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