import 'package:flutter/material.dart';

class AiToolsBottomSheet extends StatelessWidget {
  const AiToolsBottomSheet({
    required this.onObjectEraser,
    super.key,
  });

  final VoidCallback onObjectEraser;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0D1321);

    return SafeArea(
      child: Container(
        color: background,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
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
              'Powerful cloud editing tools.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            _AiToolTile(
              icon: Icons.auto_fix_high_rounded,
              title: 'Object Eraser',
              subtitle: 'Remove unwanted people or objects',
              onTap: onObjectEraser,
            ),
            const SizedBox(height: 10),
            const _AiToolTile(
              icon: Icons.person_remove_alt_1_rounded,
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
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? const Color(0xFFC4B5FD)
                      : Colors.white24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 12,
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