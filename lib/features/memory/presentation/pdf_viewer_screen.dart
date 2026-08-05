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
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(dialogContext).colorScheme.error,
          ),
          title: const Text('Remove this PDF?'),
          content: const Text(
            'This PDF will be removed from NeuroLens. '
            'The original document will remain on your device.',
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

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          IconButton(
            onPressed: _isSharing || _isDeleting ? null : _sharePdf,
            tooltip: 'Share PDF',
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
            tooltip: 'Remove from NeuroLens',
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
      body: Builder(
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
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}