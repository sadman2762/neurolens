import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';

class WelcomeNameScreen extends ConsumerStatefulWidget {
  const WelcomeNameScreen({super.key});

  @override
  ConsumerState<WelcomeNameScreen> createState() =>
      _WelcomeNameScreenState();
}

class _WelcomeNameScreenState
    extends ConsumerState<WelcomeNameScreen> {
  static const Color _backgroundColor =
      Color(0xFF050816);

  static const Color _surfaceColor =
      Color(0xFF0D1321);

  static const Color _purple =
      Color(0xFF8B5CF6);

  final TextEditingController _nameController =
      TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty || _isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(localProfileProvider.notifier)
          .saveName(name);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save your name: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue =
        _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
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
                        color: _purple.withValues(
                          alpha: 0.32,
                        ),
                        blurRadius: 34,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 32),

                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFFB1D1E8),
                        Color(0xFF5983DC),
                        Color(0xFF9A5CDC),
                        Color(0xFF5D22E6),
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'Welcome to NeuroLens',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your private memory space.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.58,
                    ),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 42),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What should we call you?',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.88,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 11),

                Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.18,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    enabled: !_isSaving,
                    maxLength: 40,
                    textCapitalization:
                        TextCapitalization.words,
                    textInputAction:
                        TextInputAction.done,
                    cursorColor: _purple,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      if (canContinue) {
                        _continue();
                      }
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Your name',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.32,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white.withValues(
                          alpha: 0.52,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed:
                        canContinue && !_isSaving
                        ? _continue
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _purple,
                      disabledBackgroundColor:
                          _purple.withValues(
                            alpha: 0.28,
                          ),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: Colors.white.withValues(
                        alpha: 0.38,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Your name stays on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              Colors.white.withValues(
                            alpha: 0.38,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}