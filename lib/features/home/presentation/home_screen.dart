import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/data/gallery_permission_service.dart';
import 'package:neurolens/features/memory/presentation/add_text_memory_screen.dart';
import 'package:neurolens/features/memory/providers/memory_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _syncGallery(BuildContext context, WidgetRef ref) async {
    final permissionService = GalleryPermissionService();
    final hasAccess = await permissionService.requestPermission();

    if (!context.mounted) return;

    if (!hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery access was not granted.')),
      );
      return;
    }

    try {
      final syncService = ref.read(gallerySyncServiceProvider);
      final memoryRepository = ref.read(memoryRepositoryProvider);

      final savedCount = await syncService.syncAllImages();
      final totalCount = await memoryRepository.getMemoryCount();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved $savedCount images. '
            '$totalCount memories are now stored locally.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Gallery sync error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openImportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import memory',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Sync full gallery'),
                  subtitle: const Text(
                    'Scan and index photos stored on this phone',
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _syncGallery(context, ref);
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('PDF or document'),
                ),
                ListTile(
                  leading: const Icon(Icons.note_add_outlined),
                  title: const Text('Text note'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AddTextMemoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'NeuroLens',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your phone remembers everything you forget.',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openImportSheet(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Import memory'),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
