import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';
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

  Future<void> _importPhotos() async {
    try {
      final selectedAssets = await ref
          .read(photoPickerServiceProvider)
          .pickPhotos(context: context);

      if (!mounted) {
        return;
      }

      if (selectedAssets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No photos selected.'),
          ),
        );
        return;
      }

      final importedCount = await ref
          .read(photoImportServiceProvider)
          .importPhotos(selectedAssets: selectedAssets);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            importedCount == 1
                ? '1 photo imported successfully.'
                : '$importedCount photos imported successfully.',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Photo import error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo import failed: $error'),
        ),
      );
    }
  }

  Future<void> _importPdf() async {
    try {
      final imported = await ref.read(pdfImportServiceProvider).importPdf();

      if (!mounted) {
        return;
      }

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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF import failed: $error'),
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

      if (!mounted) {
        return;
      }

      ref.read(voiceListeningProvider.notifier).state = false;
      return;
    }

    try {
      ref.read(voiceListeningProvider.notifier).state = true;

      await service.startListening(
        onWords: (words) {
          if (!mounted) {
            return;
          }

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
          if (!mounted) {
            return;
          }

          ref.read(voiceListeningProvider.notifier).state = false;
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

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

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          title: const Text(
            'Sign out?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Your memories remain stored locally on this device.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.5,
            ),
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
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    try {
      await ref.read(authServiceProvider).signOut();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not sign out: $error'),
        ),
      );
    }
  }

  void _openAccountSheet() {
    final user = ref.read(currentUserProvider);
    final email = user?.email ?? 'No email available';
    final displayName = user?.displayName?.trim();

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
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF60A5FA),
                        Color(0xFF8B5CF6),
                        Color(0xFFC084FC),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _accountInitial(
                        displayName: displayName,
                        email: email,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName?.isNotEmpty == true
                      ? displayName!
                      : 'NeuroLens account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _AccountStatCard(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Current plan',
                        value: 'Free',
                        iconColor: const Color(0xFFC4B5FD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _AccountStatCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI credits',
                        value: '20 / month',
                        iconColor: Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141B2D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFFC4B5FD),
                        ),
                        title: const Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '500 AI credits and no ads',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Premium subscriptions will be added next.',
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFF87171),
                        ),
                        title: const Text(
                          'Sign out',
                          style: TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(bottomSheetContext).pop();
                          _signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _accountInitial({
    required String? displayName,
    required String email,
  }) {
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim()[0].toUpperCase();
    }

    if (email.trim().isNotEmpty) {
      return email.trim()[0].toUpperCase();
    }

    return 'N';
  }

  void _openImportSheet() {
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
                    'Import Photos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Select one or more photos from your gallery',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _importPhotos();
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
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _importPdf();
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

  void _openMemory(Memory memory) {
    if (memory.type == 'image') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemoryDetailScreen(
            assetId: memory.id,
            title: memory.title,
          ),
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
        content: Text(
          '${memory.type} memory details are not available yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = ref.watch(filteredMemoryTimelineProvider);
    final selectedFilter = ref.watch(memoryFilterProvider);
    final isListening = ref.watch(voiceListeningProvider);
    final searchQuery = ref.watch(memorySearchQueryProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: _AddMemoryButton(
        onTap: _openImportSheet,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: _NeuroLensTitle(),
                      ),
                      _AccountButton(
                        displayName: currentUser?.displayName,
                        email: currentUser?.email,
                        onTap: _openAccountSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: 1,
                    ),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (
                      context,
                      animationValue,
                      child,
                    ) {
                      return Opacity(
                        opacity: animationValue,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            18 * (1 - animationValue),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        onChanged: (value) {
                          ref
                              .read(memorySearchQueryProvider.notifier)
                              .state = value;
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
                            selected:
                                selectedFilter == MemoryFilter.all,
                            onTap: () {
                              ref
                                  .read(memoryFilterProvider.notifier)
                                  .state = MemoryFilter.all;
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterButton(
                            label: 'Images',
                            selected:
                                selectedFilter == MemoryFilter.images,
                            onTap: () {
                              ref
                                  .read(memoryFilterProvider.notifier)
                                  .state = MemoryFilter.images;
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterButton(
                            label: 'PDFs',
                            selected:
                                selectedFilter == MemoryFilter.pdfs,
                            onTap: () {
                              ref
                                  .read(memoryFilterProvider.notifier)
                                  .state = MemoryFilter.pdfs;
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterButton(
                            label: 'Notes',
                            selected:
                                selectedFilter == MemoryFilter.notes,
                            onTap: () {
                              ref
                                  .read(memoryFilterProvider.notifier)
                                  .state = MemoryFilter.notes;
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
                    searchQuery.isEmpty
                        ? 'Memories'
                        : 'Search results',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  timeline.maybeWhen(
                    data: (memories) {
                      return Text(
                        '${memories.length}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                      );
                    },
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
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (
                      child,
                      animation,
                    ) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.98,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: GridView.builder(
                      key: ValueKey<String>(
                        '${selectedFilter.name}-'
                        '${searchQuery.trim()}-'
                        '${memories.length}',
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        90,
                      ),
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
                              _openMemory(memory);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: _purple,
                  ),
                ),
                error: (error, stackTrace) {
                  return Center(
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
                  );
                },
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
              Color.fromARGB(255, 177, 209, 232),
              Color.fromARGB(255, 89, 131, 220),
              Color.fromARGB(255, 154, 92, 220),
              Color.fromARGB(255, 93, 34, 230),
            ],
            stops: [
              0,
              0.43,
              0.68,
              1,
            ],
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

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.displayName,
    required this.email,
    required this.onTap,
  });

  final String? displayName;
  final String? email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim();
    final address = email?.trim();

    final initial = name != null && name.isNotEmpty
        ? name[0].toUpperCase()
        : address != null && address.isNotEmpty
            ? address[0].toUpperCase()
            : 'N';

    return Tooltip(
      message: 'Account',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF60A5FA),
                  Color(0xFF8B5CF6),
                  Color(0xFFC084FC),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountStatCard extends StatelessWidget {
  const _AccountStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF141B2D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemoryButton extends StatefulWidget {
  const _AddMemoryButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_AddMemoryButton> createState() => _AddMemoryButtonState();
}

class _AddMemoryButtonState extends State<_AddMemoryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(
      begin: 0.18,
      end: 0.42,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(
                    alpha: _glowAnimation.value,
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: const Color(0xFF8B5CF6),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF8B5CF6)
            : const Color(0xFF0D1321),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: selected
              ? const Color(0xFF8B5CF6)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 19 : 17,
              vertical: 9,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.68),
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMemoriesView extends StatelessWidget {
  const _EmptyMemoriesView({
    required this.isSearching,
  });

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 100),
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
              isSearching
                  ? 'No matching memories'
                  : 'No memories yet',
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
                  : 'Tap the + button to import photos, PDFs, or notes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}