import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';

class AccountBottomSheet extends ConsumerWidget {
  const AccountBottomSheet({
    super.key,
  });

  static const Color _cardColor =
      Color(0xFF141B2D);

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final profileState =
        ref.watch(localProfileProvider);

    final name = profileState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    final displayName =
        name?.trim().isNotEmpty == true
        ? name!.trim()
        : 'NeuroLens';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          4,
          20,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    const LinearGradient(
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
                    color: const Color(
                      0xFF8B5CF6,
                    ).withValues(
                      alpha: 0.28,
                    ),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _profileInitial(
                    displayName,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Local profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Colors.white.withValues(
                  alpha: 0.48,
                ),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color:
                      Colors.white.withValues(
                    alpha: 0.35,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Stored only on this device',
                  style: TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha: 0.35,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color:
                      Colors.white.withValues(
                    alpha: 0.06,
                  ),
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF60A5FA,
                    ).withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color:
                        Color(0xFF60A5FA),
                    size: 21,
                  ),
                ),
                title: const Text(
                  'Edit name',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Change how NeuroLens addresses you',
                  style: TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha: 0.42,
                    ),
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 15,
                ),
                onTap: () async {
                  final newName =
                      await _showEditNameDialog(
                    context,
                    displayName,
                  );

                  if (newName == null ||
                      newName.trim().isEmpty) {
                    return;
                  }

                  try {
                    await ref
                        .read(
                          localProfileProvider
                              .notifier,
                        )
                        .saveName(
                          newName,
                        );

                    if (context.mounted) {
                      Navigator.of(context)
                          .pop();
                    }
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not update name: $error',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'No NeuroLens account is required.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Colors.white.withValues(
                  alpha: 0.30,
                ),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String?>
  _showEditNameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final controller =
        TextEditingController(
      text: currentName,
    );

    final result =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF0D1321),
          surfaceTintColor:
              Colors.transparent,
          title: const Text(
            'Edit name',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization:
                TextCapitalization.words,
            textInputAction:
                TextInputAction.done,
            cursorColor:
                const Color(0xFF8B5CF6),
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration:
                InputDecoration(
              counterText: '',
              hintText: 'Your name',
              hintStyle: TextStyle(
                color:
                    Colors.white.withValues(
                  alpha: 0.35,
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide(
                  color:
                      Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    const BorderSide(
                  color:
                      Color(0xFF8B5CF6),
                ),
              ),
            ),
            onSubmitted: (value) {
              final trimmed =
                  value.trim();

              if (trimmed.isEmpty) {
                return;
              }

              Navigator.of(
                dialogContext,
              ).pop(trimmed);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(value);
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                      0xFF8B5CF6,
                    ),
              ),
              child:
                  const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  static String _profileInitial(
    String displayName,
  ) {
    final name =
        displayName.trim();

    if (name.isEmpty) {
      return 'N';
    }

    return name[0].toUpperCase();
  }
}