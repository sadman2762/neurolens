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
  static const Color _backgroundColor = Color(0xFF050816);
  static const Color _surfaceColor = Color(0xFF0D1321);
  static const Color _surfaceHighlightColor = Color(0xFF141B2D);
  static const Color _purple = Color(0xFF8B5CF6);

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
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFF87171),
            size: 32,
          ),
          title: const Text(
            'Delete this note?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This note will be permanently removed from NeuroLens.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
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

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String tooltip,
  }) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: icon,
        color: Colors.white,
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Text memory',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          _buildActionButton(
            onPressed: _isSharing || _isDeleting ? null : _shareNote,
            tooltip: 'Share note',
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.share_outlined,
                    size: 21,
                  ),
          ),
          _buildActionButton(
            onPressed: _isSharing || _isDeleting ? null : _confirmDelete,
            tooltip: 'Delete note',
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    size: 22,
                    color: Color(0xFFF87171),
                  ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _surfaceHighlightColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: _purple,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _formatDate(widget.createdAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 17,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}