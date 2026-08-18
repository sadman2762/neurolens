import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState
    extends ConsumerState<DeleteAccountScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _fieldColor = Color(0xFF141B2D);
  static const Color _danger = Color(0xFFEF4444);

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _hidePassword = true;
  bool _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await _showFinalConfirmation();

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Verify the user's identity before performing
      // the sensitive account deletion operation.
      await authService.reauthenticate(
        password: _passwordController.text,
      );

      // Permanently delete the Firebase Authentication account.
      await authService.deleteAccount();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account was deleted successfully.',
          ),
        ),
      );

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        _cleanErrorMessage(error.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<bool?> _showFinalConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFCA5A5),
            size: 46,
          ),
          title: const Text(
            'Delete account permanently?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Your NeuroLens account and authentication '
            'information will be permanently deleted. '
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
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
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete permanently',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _cleanErrorMessage(String message) {
    const exceptionPrefix = 'AuthServiceException: ';

    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length);
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Delete account',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            18,
            22,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _danger.withValues(
                          alpha: 0.12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _danger.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 26,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFFFCA5A5),
                        size: 42,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Permanently delete account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Your NeuroLens account and authentication '
                      'information will be permanently deleted. '
                      'This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.54,
                        ),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 26),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _danger.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _hidePassword,
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType:
                                TextInputType.visiblePassword,
                            textInputAction:
                                TextInputAction.next,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'Enter your password.';
                              }

                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Current password',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _hidePassword =
                                        !_hidePassword;
                                  });
                                },
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons
                                          .visibility_off_outlined,
                                  color:
                                      Colors.white.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              filled: true,
                              fillColor: _fieldColor,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color:
                                      Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                ),
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(
                                  color: _danger,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller:
                                _confirmationController,
                            textInputAction:
                                TextInputAction.done,
                            textCapitalization:
                                TextCapitalization.characters,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            onFieldSubmitted: (_) {
                              if (!_isDeleting) {
                                _deleteAccount();
                              }
                            },
                            validator: (value) {
                              if (value?.trim() != 'DELETE') {
                                return 'Type DELETE exactly.';
                              }

                              return null;
                            },
                            decoration: InputDecoration(
                              labelText:
                                  'Type DELETE to confirm',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              filled: true,
                              fillColor: _fieldColor,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color:
                                      Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                ),
                              ),
                              focusedBorder:
                                  OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(
                                  color: _danger,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isDeleting
                            ? null
                            : _deleteAccount,
                        icon: _isDeleting
                            ? const SizedBox.shrink()
                            : const Icon(
                                Icons.delete_forever_rounded,
                              ),
                        label: _isDeleting
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
                                'Delete account permanently',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _danger.withValues(
                            alpha: 0.45,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}