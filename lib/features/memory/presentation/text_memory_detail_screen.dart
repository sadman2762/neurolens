import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/providers/memory_providers.dart';
import 'package:share_plus/share_plus.dart';

class TextMemoryDetailScreen extends ConsumerStatefulWidget {
  const TextMemoryDetailScreen({
    required this.memoryId,
    required this.content,
    required this.createdAt,
    super.key,
  });

  final String memoryId;
  final String content;
  final DateTime createdAt;

  @override
  ConsumerState<TextMemoryDetailScreen> createState() =>
      _TextMemoryDetailScreenState();
}

class _TextMemoryDetailScreenState
    extends ConsumerState<TextMemoryDetailScreen> {
  bool _isSharing = false;
  bool _isDeleting = false;

  Future<void> _shareNote() async {
    if (_isSharing || _isDeleting) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final renderBox = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          text: widget.content,
          subject: 'NeuroLens note',
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share this note: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting || _isSharing) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Delete this note?'),
          content: const Text(
            'This note will be permanently removed from NeuroLens.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor:
                    Theme.of(dialogContext).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    await _deleteNote();
  }

  Future<void> _deleteNote() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(memoryRepositoryProvider)
          .deleteMemory(widget.memoryId);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete this note: $error'),
        ),
      );
    }
  }

  String _formatDate(DateTime dateTime) {
    final localDate = dateTime.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text memory'),
        actions: [
          IconButton(
            onPressed: _isSharing || _isDeleting ? null : _shareNote,
            tooltip: 'Share note',
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: _isSharing || _isDeleting ? null : _confirmDelete,
            tooltip: 'Delete note',
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              widget.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}