import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/memory/data/gallery_permission_service.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/presentation/add_text_memory_screen.dart';
import 'package:neurolens/features/memory/presentation/memory_detail_screen.dart';
import 'package:neurolens/features/memory/presentation/pdf_viewer_screen.dart';
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
  static const Color _backgroundColor = Color(0xFF050816);
  static const Color _surfaceColor = Color(0xFF0D1321);
  static const Color _purple = Color(0xFFA855F7);

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
        const SnackBar(content: Text('Gallery access was not granted.')),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gallery sync failed: $error')));
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
              selection: TextSelection.collapsed(offset: words.length),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice search failed: $error')));
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
      backgroundColor: _surfaceColor,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import memory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: const Color(0xFF141B2D),
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFA78BFA),
                  ),
                  title: const Text(
                    'Sync full gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Scan and index photos stored on this phone',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _syncGallery(context);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: const Color(0xFF141B2D),
                  leading: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Color(0xFFF87171),
                  ),
                  title: const Text(
                    'PDF document',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Import a searchable PDF from this device',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);

                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
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
                        SnackBar(content: Text('PDF import failed: $error')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: const Color(0xFF141B2D),
                  leading: const Icon(
                    Icons.note_add_outlined,
                    color: Color(0xFF4ADE80),
                  ),
                  title: const Text(
                    'Text note',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Create a searchable text memory',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
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

  void _openMemory(BuildContext context, Memory memory) {
    if (memory.type == 'image') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              MemoryDetailScreen(assetId: memory.id, title: memory.title),
        ),
      );
      return;
    }

    if (memory.type == 'pdf') {
      final originalPath = memory.originalPath;

      if (originalPath == null || originalPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This PDF file is no longer available.'),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfViewerScreen(
            memoryId: memory.id,
            filePath: originalPath,
            title: memory.title,
          ),
        ),
      );
      return;
    }

    if (memory.type == 'note') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TextMemoryDetailScreen(
            memoryId: memory.id,
            content: memory.content ?? memory.title,
            createdAt: memory.createdAt,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${memory.type} memory details are not available yet.'),
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
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: _NeuroLensTitle()),
                      _AddMemoryButton(onTap: () => _openImportSheet(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      cursorColor: _purple,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (value) {
                        ref.read(memorySearchQueryProvider.notifier).state =
                            value;
                      },
                      decoration: InputDecoration(
                        hintText: isListening
                            ? 'Listening...'
                            : 'Ask NeuroLens...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (searchQuery.isNotEmpty)
                              IconButton(
                                onPressed: _clearSearch,
                                tooltip: 'Clear search',
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
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
                                color: isListening
                                    ? _purple
                                    : Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterButton(
                            label: 'All',
                            selected: selectedFilter == MemoryFilter.all,
                            onTap: () {
                              ref.read(memoryFilterProvider.notifier).state =
                                  MemoryFilter.all;
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterButton(
                            label: 'Images',
                            selected: selectedFilter == MemoryFilter.images,
                            onTap: () {
                              ref.read(memoryFilterProvider.notifier).state =
                                  MemoryFilter.images;
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterButton(
                            label: 'PDFs',
                            selected: selectedFilter == MemoryFilter.pdfs,
                            onTap: () {
                              ref.read(memoryFilterProvider.notifier).state =
                                  MemoryFilter.pdfs;
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterButton(
                            label: 'Notes',
                            selected: selectedFilter == MemoryFilter.notes,
                            onTap: () {
                              ref.read(memoryFilterProvider.notifier).state =
                                  MemoryFilter.notes;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(
                    searchQuery.isEmpty ? 'Memories' : 'Search results',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  timeline.maybeWhen(
                    data: (memories) => Text(
                      '${memories.length}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: timeline.when(
                data: (memories) {
                  if (memories.isEmpty) {
                    return _EmptyMemoriesView(
                      isSearching: searchQuery.isNotEmpty,
                      onImport: () => _openImportSheet(context),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 9,
                          mainAxisSpacing: 9,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: memories.length,
                    itemBuilder: (context, index) {
                      final memory = memories[index];

                      return RepaintBoundary(
                        child: MemoryGridItem(
                          memory: memory,
                          onTap: () {
                            _openMemory(context, memory);
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _purple),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load memories:\n$error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeuroLensTitle extends StatelessWidget {
  const _NeuroLensTitle();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [
              Colors.white,
              Colors.white,
              Color(0xFFC084FC),
              Color(0xFF22D3EE),
            ],
            stops: [0, 0.43, 0.68, 1],
          ).createShader(bounds);
        },
        child: const Text(
          'NeuroLens',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
      ),
    );
  }
}

class _AddMemoryButton extends StatelessWidget {
  const _AddMemoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF8B5CF6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 27),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF8B5CF6) : const Color(0xFF0D1321),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.68),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMemoriesView extends StatelessWidget {
  const _EmptyMemoriesView({required this.isSearching, required this.onImport});

  final bool isSearching;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.auto_awesome_outlined,
              size: 52,
              color: const Color(0xFFC084FC),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No matching memories' : 'No memories yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try another search term.'
                  : 'Import photos, PDFs, or notes to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Import memory'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
