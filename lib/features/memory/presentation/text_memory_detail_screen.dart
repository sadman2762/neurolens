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

  late final TextEditingController _controller;

  late String _currentContent;

  bool _isSharing = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _currentContent = widget.content;

    _controller = TextEditingController(
      text: widget.content,
    );

    _controller.addListener(
      _onTextChanged,
    );
  }

  void _onTextChanged() {
    if (!mounted) {
      return;
    }

    if (_isEditing) {
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // EDIT
  // ---------------------------------------------------------------------------

  void _startEditing() {
    if (_isDeleting ||
        _isSharing ||
        _isSaving) {
      return;
    }

    _controller.text = _currentContent;

    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );

    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    if (_isSaving) {
      return;
    }

    _controller.text = _currentContent;

    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveNote() async {
    if (_isSaving ||
        _isDeleting) {
      return;
    }

    final newContent =
        _controller.text.trim();

    if (newContent.isEmpty) {
      _showMessage(
        'Note cannot be empty.',
      );

      return;
    }

    if (newContent == _currentContent.trim()) {
      setState(() {
        _isEditing = false;
      });

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(
            memoryRepositoryProvider,
          )
          .updateMemoryContent(
        id: widget.memoryId,
        content: newContent,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentContent = newContent;
        _controller.text = newContent;
        _isEditing = false;
      });

      _showMessage(
        'Note updated successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not save this note: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SHARE
  // ---------------------------------------------------------------------------

  Future<void> _shareNote() async {
    if (_isSharing ||
        _isDeleting ||
        _isSaving ||
        _isEditing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final renderBox =
          context.findRenderObject()
              as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          text: _currentContent,
          subject: 'NeuroLens note',
          sharePositionOrigin:
              renderBox == null
                  ? null
                  : renderBox.localToGlobal(
                        Offset.zero,
                      ) &
                      renderBox.size,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not share this note: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete() async {
    if (_isDeleting ||
        _isSharing ||
        _isSaving ||
        _isEditing) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              _surfaceColor,
          surfaceTintColor:
              Colors.transparent,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color:
                Color(0xFFF87171),
            size: 32,
          ),
          title: const Text(
            'Delete this note?',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'This note will be permanently removed from NeuroLens.',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.62,
              ),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white
                      .withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFDC2626,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true ||
        !mounted) {
      return;
    }

    await _deleteNote();
  }

  Future<void> _deleteNote() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(
            memoryRepositoryProvider,
          )
          .deleteMemory(
            widget.memoryId,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      _showMessage(
        'Could not delete this note: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  String _formatDate(
    DateTime dateTime,
  ) {
    final localDate =
        dateTime.toLocal();

    final day =
        localDate.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final month =
        localDate.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final year =
        localDate.year;

    final hour =
        localDate.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        localDate.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

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
      margin:
          const EdgeInsets.only(
        left: 8,
      ),
      decoration:
          BoxDecoration(
        color: _surfaceColor,
        shape: BoxShape.circle,
        border:
            Border.all(
          color: Colors.white
              .withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: icon,
        color: Colors.white,
        padding:
            EdgeInsets.zero,
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(
      _onTextChanged,
    );

    _controller.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    final isBusy =
        _isSharing ||
        _isDeleting ||
        _isSaving;

    return PopScope(
      canPop:
          !_isEditing ||
          !_isSaving,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (didPop) {
          return;
        }

        if (_isEditing &&
            !_isSaving) {
          _cancelEditing();
        }
      },
      child: Scaffold(
        backgroundColor:
            _backgroundColor,
        appBar: AppBar(
          backgroundColor:
              _backgroundColor,
          foregroundColor:
              Colors.white,
          surfaceTintColor:
              Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          title: Text(
            _isEditing
                ? 'Edit note'
                : 'Text memory',
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          actions: _isEditing
              ? [
                  _buildActionButton(
                    onPressed:
                        _isSaving
                            ? null
                            : _cancelEditing,
                    tooltip:
                        'Cancel editing',
                    icon:
                        const Icon(
                      Icons.close_rounded,
                      size: 22,
                    ),
                  ),
                  _buildActionButton(
                    onPressed:
                        _isSaving
                            ? null
                            : _saveNote,
                    tooltip:
                        'Save note',
                    icon:
                        _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                                size: 23,
                                color:
                                    Color(
                                  0xFFC4B5FD,
                                ),
                              ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                ]
              : [
                  _buildActionButton(
                    onPressed:
                        isBusy
                            ? null
                            : _startEditing,
                    tooltip:
                        'Edit note',
                    icon:
                        const Icon(
                      Icons.edit_outlined,
                      size: 21,
                      color:
                          Color(
                        0xFFC4B5FD,
                      ),
                    ),
                  ),
                  _buildActionButton(
                    onPressed:
                        isBusy
                            ? null
                            : _shareNote,
                    tooltip:
                        'Share note',
                    icon:
                        _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.share_outlined,
                                size: 21,
                              ),
                  ),
                  _buildActionButton(
                    onPressed:
                        isBusy
                            ? null
                            : _confirmDelete,
                    tooltip:
                        'Delete note',
                    icon:
                        _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                size: 22,
                                color:
                                    Color(
                                  0xFFF87171,
                                ),
                              ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                ],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              18,
            ),
            child: Column(
              children: [
                Expanded(
                  child:
                      AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds: 180,
                    ),
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          _surfaceColor,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      border:
                          Border.all(
                        color:
                            _isEditing
                                ? _purple.withValues(
                                    alpha: 0.5,
                                  )
                                : Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                        width:
                            _isEditing
                                ? 1.4
                                : 1,
                      ),
                      boxShadow:
                          _isEditing
                              ? [
                                  BoxShadow(
                                    color:
                                        _purple.withValues(
                                      alpha: 0.10,
                                    ),
                                    blurRadius:
                                        24,
                                  ),
                                ]
                              : null,
                    ),
                    child:
                        _isEditing
                            ? TextField(
                                controller:
                                    _controller,
                                autofocus:
                                    true,
                                expands:
                                    true,
                                maxLines:
                                    null,
                                minLines:
                                    null,
                                textAlignVertical:
                                    TextAlignVertical.top,
                                keyboardType:
                                    TextInputType.multiline,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      17,
                                  height:
                                      1.6,
                                ),
                                cursorColor:
                                    _purple,
                                decoration:
                                    InputDecoration(
                                  border:
                                      InputBorder.none,
                                  hintText:
                                      'Write your note...',
                                  hintStyle:
                                      TextStyle(
                                    color:
                                        Colors.white.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                  contentPadding:
                                      EdgeInsets.zero,
                                ),
                              )
                            : SingleChildScrollView(
                                child:
                                    SelectableText(
                                  _currentContent,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        17,
                                    height:
                                        1.6,
                                  ),
                                ),
                              ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        _surfaceHighlightColor,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    border:
                        Border.all(
                      color: Colors.white
                          .withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isEditing
                            ? Icons.edit_note_rounded
                            : Icons.schedule_outlined,
                        size: 18,
                        color: _purple,
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child: Text(
                          _isEditing
                              ? 'Editing note'
                              : _formatDate(
                                  widget.createdAt,
                                ),
                          style:
                              TextStyle(
                            color: Colors.white
                                .withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),

                      if (_isEditing)
                        Text(
                          '${_controller.text.length} chars',
                          style:
                              TextStyle(
                            color: Colors.white
                                .withValues(
                              alpha: 0.35,
                            ),
                            fontSize: 11,
                          ),
                        )
                      else
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 17,
                          color: Colors.white
                              .withValues(
                            alpha: 0.35,
                          ),
                        ),
                    ],
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