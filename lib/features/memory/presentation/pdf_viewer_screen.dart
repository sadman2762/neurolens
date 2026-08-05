import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/providers/memory_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({
    required this.memoryId,
    required this.filePath,
    required this.title,
    super.key,
  });

  final String memoryId;
  final String filePath;
  final String title;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  static const Color _backgroundColor = Color(0xFF050816);
  static const Color _surfaceColor = Color(0xFF0D1321);

  final PdfViewerController _pdfViewerController = PdfViewerController();

  int _currentPage = 1;
  int _totalPages = 0;

  bool _hasLoadError = false;
  bool _isSharing = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _sharePdf() async {
    if (_isSharing || _isDeleting) return;

    final file = File(widget.filePath);

    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This PDF is no longer available.'),
        ),
      );
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final renderBox = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              widget.filePath,
              mimeType: 'application/pdf',
              name: widget.title,
            ),
          ],
          subject: widget.title,
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share this PDF: $error'),
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
    if (_isSharing || _isDeleting) return;

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
            'Remove this PDF?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This PDF will be removed from NeuroLens. '
            'The original document will remain on your device.',
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    await _deletePdfMemory();
  }

  Future<void> _deletePdfMemory() async {
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
          content: Text('Could not remove this PDF: $error'),
        ),
      );
    }
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
    final file = File(widget.filePath);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_totalPages > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _buildActionButton(
            onPressed: _isSharing || _isDeleting ? null : _sharePdf,
            tooltip: 'Share PDF',
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
            tooltip: 'Remove from NeuroLens',
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Builder(
              builder: (context) {
                if (!file.existsSync()) {
                  return const _PdfErrorView(
                    message: 'This PDF is no longer available.',
                  );
                }

                if (_hasLoadError) {
                  return const _PdfErrorView(
                    message: 'Could not open this PDF.',
                  );
                }

                return SfPdfViewer.file(
                  file,
                  controller: _pdfViewerController,
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  onDocumentLoaded: (details) {
                    if (!mounted) return;

                    setState(() {
                      _totalPages = details.document.pages.count;
                      _currentPage = 1;
                    });
                  },
                  onPageChanged: (details) {
                    if (!mounted) return;

                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                  onDocumentLoadFailed: (details) {
                    if (!mounted) return;

                    setState(() {
                      _hasLoadError = true;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PdfErrorView extends StatelessWidget {
  const _PdfErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 34,
                color: Color(0xFFF87171),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}