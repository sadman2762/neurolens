import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/data/gallery_permission_service.dart';
import 'package:neurolens/features/memory/presentation/add_text_memory_screen.dart';
import 'package:neurolens/features/memory/presentation/memory_detail_screen.dart';
import 'package:neurolens/features/memory/presentation/text_memory_detail_screen.dart';
import 'package:neurolens/features/memory/presentation/widgets/memory_grid_item.dart';
import 'package:neurolens/features/memory/providers/memory_filter_provider.dart';
import 'package:neurolens/features/memory/providers/memory_providers.dart';
import 'package:neurolens/features/search/providers/voice_search_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncGallery(BuildContext context) async {
    final permissionService = GalleryPermissionService();
    final hasAccess = await permissionService.requestPermission();

    if (!context.mounted) return;

    if (!hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery access was not granted.'),
        ),
      );
      return;
    }

    try {
      final syncService = ref.read(gallerySyncServiceProvider);
      final memoryRepository = ref.read(memoryRepositoryProvider);

      final syncedCount = await syncService.syncAllImages();
      final totalCount = await memoryRepository.getMemoryCount();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced $syncedCount images. '
            '$totalCount memories are stored locally.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Gallery sync error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery sync failed: $error'),
        ),
      );
    }
  }

  Future<void> _toggleVoiceSearch() async {
    FocusScope.of(context).unfocus();

    final service = ref.read(voiceSearchServiceProvider);
    final isListening = ref.read(voiceListeningProvider);

    if (isListening) {
      await service.stopListening();

      if (!mounted) return;

      ref.read(voiceListeningProvider.notifier).state = false;
      return;
    }

    try {
      ref.read(voiceListeningProvider.notifier).state = true;

      await service.startListening(
        onWords: (words) {
          if (!mounted) return;

          setState(() {
            _searchController.value = TextEditingValue(
              text: words,
              selection: TextSelection.collapsed(
                offset: words.length,
              ),
            );
          });

          ref.read(memorySearchQueryProvider.notifier).state = words;
        },
        onFinished: () {
          if (!mounted) return;

          ref.read(voiceListeningProvider.notifier).state = false;
        },
      );
    } catch (error) {
      if (!mounted) return;

      ref.read(voiceListeningProvider.notifier).state = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice search failed: $error'),
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(memorySearchQueryProvider.notifier).state = '';
  }

  void _openImportSheet(BuildContext context) {
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
                    await _syncGallery(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('PDF document'),
                  subtitle: const Text('Import a PDF from this device'),
                  onTap: () async {
                    await Navigator.of(bottomSheetContext).maybePop();

                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );

                    try {
                      final imported = await ref
                          .read(pdfImportServiceProvider)
                          .importPdf();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            imported
                                ? 'PDF imported successfully.'
                                : 'No PDF was selected.',
                          ),
                        ),
                      );
                    } catch (error, stackTrace) {
                      debugPrint('PDF import error: $error');
                      debugPrintStack(stackTrace: stackTrace);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF import failed: $error'),
                        ),
                      );
                    }
                  },
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

  void _openMemory(
    BuildContext context,
    String id,
    String title,
    String? content,
    String type,
    DateTime createdAt,
  ) {
    if (type == 'image') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemoryDetailScreen(
            assetId: id,
            title: title,
          ),
        ),
      );
      return;
    }

    if (type == 'note') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TextMemoryDetailScreen(
            content: content ?? title,
            createdAt: createdAt,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type memory details are not available yet.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(filteredMemoryTimelineProvider);
    final selectedFilter = ref.watch(memoryFilterProvider);
    final isListening = ref.watch(voiceListeningProvider);
    final searchQuery = ref.watch(memorySearchQueryProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'NeuroLens',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Your phone remembers everything you forget.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  ref.read(memorySearchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: isListening
                      ? 'Listening...'
                      : 'Ask NeuroLens...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: _clearSearch,
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                        ),
                      IconButton(
                        onPressed: _toggleVoiceSearch,
                        tooltip: isListening
                            ? 'Stop voice search'
                            : 'Start voice search',
                        icon: Icon(
                          isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                        ),
                      ),
                    ],
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openImportSheet(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Import memory'),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: selectedFilter == MemoryFilter.all,
                      onSelected: (_) {
                        ref.read(memoryFilterProvider.notifier).state =
                            MemoryFilter.all;
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Images'),
                      selected: selectedFilter == MemoryFilter.images,
                      onSelected: (_) {
                        ref.read(memoryFilterProvider.notifier).state =
                            MemoryFilter.images;
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Notes'),
                      selected: selectedFilter == MemoryFilter.notes,
                      onSelected: (_) {
                        ref.read(memoryFilterProvider.notifier).state =
                            MemoryFilter.notes;
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('PDFs'),
                      selected: selectedFilter == MemoryFilter.pdfs,
                      onSelected: (_) {
                        ref.read(memoryFilterProvider.notifier).state =
                            MemoryFilter.pdfs;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                searchQuery.isEmpty ? 'Memories' : 'Search results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: timeline.when(
                  data: (memories) {
                    if (memories.isEmpty) {
                      return Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'No memories yet.'
                              : 'No matching memories.',
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: memories.length,
                      itemBuilder: (context, index) {
                        final memory = memories[index];

                        return MemoryGridItem(
                          memory: memory,
                          onTap: () {
                            _openMemory(
                              context,
                              memory.id,
                              memory.title,
                              memory.content,
                              memory.type,
                              memory.createdAt,
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Could not load memories: $error',
                      textAlign: TextAlign.center,
                    ),
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