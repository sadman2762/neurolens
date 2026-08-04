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
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: MemoryThumbnail(
            assetId: memory.id,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.note_alt_outlined,
              size: 28,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                memory.title,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}