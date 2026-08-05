import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    required this.filePath,
    required this.title,
    super.key,
  });

  final String filePath;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  int _currentPage = 1;
  int _totalPages = 0;
  bool _hasLoadError = false;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
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
              if (!mounted) {
                return;
              }

              setState(() {
                _totalPages = details.document.pages.count;
                _currentPage = 1;
              });
            },
            onPageChanged: (details) {
              if (!mounted) {
                return;
              }

              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoadFailed: (details) {
              if (!mounted) {
                return;
              }

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