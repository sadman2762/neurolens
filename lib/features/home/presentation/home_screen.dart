import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/presentation/account_bottom_sheet.dart';
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
import 'package:neurolens/features/subscription/presentation/premium_screen.dart';

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
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(memoryFilterProvider.notifier).state = MemoryFilter.all;
    });
  }

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
        _showMessage('No photos selected.');
        return;
      }

      final importedCount = await ref
          .read(photoImportServiceProvider)
          .importPhotos(selectedAssets: selectedAssets);

      if (!mounted) {
        return;
      }

      _showMessage(
        importedCount == 1
            ? '1 photo imported successfully.'
            : '$importedCount photos imported successfully.',
      );
    } catch (error, stackTrace) {
      debugPrint('Photo import error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage('Photo import failed: $error');
    }
  }

  Future<void> _importPdf() async {
    try {
      final imported = await ref.read(pdfImportServiceProvider).importPdf();

      if (!mounted) {
        return;
      }

      _showMessage(
        imported ? 'PDF imported successfully.' : 'No PDF was selected.',
      );
    } catch (error, stackTrace) {
      debugPrint('PDF import error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage('PDF import failed: $error');
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
              selection: TextSelection.collapsed(offset: words.length),
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
      _showMessage('Voice search failed: $error');
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
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Sign out?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Your locally imported memories remain stored on this device.',
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
      _showMessage('Could not sign out: $error');
    }
  }

  Future<void> _openPremiumScreen() async {
    final purchased = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PremiumScreen()),
    );

    if (!mounted || purchased != true) {
      return;
    }

    _showMessage('Premium activated successfully.');
  }

  void _openAccountSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      builder: (_) {
        return AccountBottomSheet(
          onSignOut: _signOut,
          onUpgrade: _openPremiumScreen,
        );
      },
    );
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
                  'Add memory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Import photos and PDFs, or create a searchable note.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _ImportTile(
                  icon: Icons.photo_library_outlined,
                  iconColor: const Color(0xFFA78BFA),
                  title: 'Photos',
                  subtitle: 'Import and index photos locally',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _importPhotos();
                  },
                ),
                const SizedBox(height: 10),
                _ImportTile(
                  icon: Icons.picture_as_pdf_outlined,
                  iconColor: const Color(0xFFF87171),
                  title: 'PDF document',
                  subtitle: 'Import a searchable PDF from this device',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _importPdf();
                  },
                ),
                const SizedBox(height: 10),
                _ImportTile(
                  icon: Icons.note_add_outlined,
                  iconColor: const Color(0xFFFACC15),
                  title: 'Text note',
                  subtitle: 'Create a searchable personal note',
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
    switch (memory.type) {
      case 'image':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MemoryDetailScreen(assetId: memory.id, title: memory.title),
          ),
        );
        return;

      case 'pdf':
        final originalPath = memory.originalPath;

        if (originalPath == null || originalPath.isEmpty) {
          _showMessage('This PDF file is no longer available.');
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

      case 'note':
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

      default:
        _showMessage('${memory.type} memory details are unavailable.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      floatingActionButton: _AddMemoryButton(onTap: _openImportSheet),
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
                      const Expanded(child: _NeuroLensTitle()),
                      _AccountButton(
                        displayName: currentUser?.displayName,
                        email: currentUser?.email,
                        onTap: _openAccountSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SearchBar(
                    controller: _searchController,
                    isListening: isListening,
                    searchQuery: searchQuery,
                    onChanged: (value) {
                      ref.read(memorySearchQueryProvider.notifier).state =
                          value;
                    },
                    onClear: _clearSearch,
                    onVoicePressed: _toggleVoiceSearch,
                  ),
                  const SizedBox(height: 14),
                  _MemoryFilters(
                    selectedFilter: selectedFilter,
                    onSelected: (filter) {
                      ref.read(memoryFilterProvider.notifier).state = filter;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: timeline.when(
                data: (memories) {
                  final favorites = memories
                      .where((memory) => memory.isFavorite)
                      .toList(growable: false);

                  final regularMemories = memories
                      .where((memory) => !memory.isFavorite)
                      .toList(growable: false);

                  if (memories.isEmpty) {
                    return _EmptyMemoriesView(
                      isSearching: searchQuery.isNotEmpty,
                      onAddPressed: _openImportSheet,
                    );
                  }

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      if (favorites.isNotEmpty &&
                          searchQuery.trim().isEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Favorite memories',
                            count: favorites.length,
                            icon: Icons.auto_awesome_rounded,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 173,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                10,
                                18,
                                18,
                              ),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: favorites.length,
                              separatorBuilder: (_, _) {
                                return const SizedBox(width: 3);
                              },
                              itemBuilder: (context, index) {
                                final memory = favorites[index];

                                return _FavoriteMemoryCard(
                                  memory: memory,
                                  onTap: () => _openMemory(memory),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: _SectionHeader(
                          title: searchQuery.isEmpty
                              ? 'Your memories'
                              : 'Search results',
                          count: regularMemories.length,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final memory = regularMemories[index];

                            return RepaintBoundary(
                              child: MemoryGridItem(
                                memory: memory,
                                onTap: () => _openMemory(memory),
                              ),
                            );
                          }, childCount: regularMemories.length),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 3,
                                mainAxisSpacing: 3,
                                childAspectRatio: 1.0,
                              ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _purple),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isListening,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    required this.onVoicePressed,
  });

  final TextEditingController controller;
  final bool isListening;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onVoicePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1321),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        cursorColor: const Color(0xFFA855F7),
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: isListening
              ? 'Listening...'
              : 'Search photos, PDFs and notes...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.42)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searchQuery.isNotEmpty)
                IconButton(
                  onPressed: onClear,
                  tooltip: 'Clear search',
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              IconButton(
                onPressed: onVoicePressed,
                tooltip: isListening
                    ? 'Stop voice search'
                    : 'Start voice search',
                icon: Icon(
                  isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: isListening
                      ? const Color(0xFFA855F7)
                      : Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _MemoryFilters extends StatelessWidget {
  const _MemoryFilters({
    required this.selectedFilter,
    required this.onSelected,
  });

  final MemoryFilter selectedFilter;
  final ValueChanged<MemoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _FilterButton(
              label: 'All',
              icon: Icons.grid_view_rounded,
              selected: selectedFilter == MemoryFilter.all,
              onTap: () => onSelected(MemoryFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: 'Photos',
              icon: Icons.image_outlined,
              selected: selectedFilter == MemoryFilter.images,
              onTap: () => onSelected(MemoryFilter.images),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: 'PDFs',
              icon: Icons.picture_as_pdf_outlined,
              selected: selectedFilter == MemoryFilter.pdfs,
              onTap: () => onSelected(MemoryFilter.pdfs),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              label: 'Notes',
              icon: Icons.sticky_note_2_outlined,
              selected: selectedFilter == MemoryFilter.notes,
              onTap: () => onSelected(MemoryFilter.notes),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count, this.icon});

  final String title;
  final int count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFFC084FC)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141B2D),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.52),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteMemoryCard extends StatelessWidget {
  const _FavoriteMemoryCard({required this.memory, required this.onTap});

  final Memory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      height: 145,
      decoration: BoxDecoration(
        color: const Color(0xFF101729),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: MemoryGridItem(memory: memory, onTap: onTap),
          ),

          // Small favorite indicator only.
          const Positioned(
            top: 7,
            right: 7,
            child: Icon(Icons.star, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  const _ImportTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141B2D),
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 12,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white38,
            size: 15,
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [
                  Color(0xFFB1D1E8),
                  Color(0xFF5983DC),
                  Color(0xFF9A5CDC),
                  Color(0xFF5D22E6),
                ],
                stops: [0, 0.43, 0.68, 1],
              ).createShader(bounds);
            },
            child: const Text(
              'NeuroLens',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Your memories, searchable.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 12,
            ),
          ),
        ],
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
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

class _AddMemoryButton extends StatefulWidget {
  const _AddMemoryButton({required this.onTap});

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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.18,
      end: 0.42,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
                  color: const Color(
                    0xFF8B5CF6,
                  ).withValues(alpha: _glowAnimation.value),
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
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 31),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8B5CF6) : const Color(0xFF0D1321),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: selected
              ? const Color(0xFF8B5CF6)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.62),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.68),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
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
    required this.onAddPressed,
  });

  final bool isSearching;
  final VoidCallback onAddPressed;

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
              size: 54,
              color: const Color(0xFFC084FC),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? 'No matching memories'
                  : 'Your memory collection is empty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try another keyword or phrase.'
                  : 'Import photos, PDFs or notes to start building your private memory library.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add memory'),
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
