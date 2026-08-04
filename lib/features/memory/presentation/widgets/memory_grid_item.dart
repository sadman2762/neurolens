import 'package:flutter/material.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/presentation/widgets/memory_thumbnail.dart';

class MemoryGridItem extends StatelessWidget {
  const MemoryGridItem({
    required this.memory,
    required this.onTap,
    super.key,
  });

  final Memory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (memory.type == 'image') {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MemoryThumbnail(
            assetId: memory.id,
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.note_alt_outlined),
            const Spacer(),
            Text(
              memory.title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}