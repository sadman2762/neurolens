import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';
import 'package:neurolens/features/auth/presentation/change_password_screen.dart';
import 'package:neurolens/features/auth/presentation/delete_account_screen.dart';

class AccountBottomSheet extends ConsumerWidget {
  const AccountBottomSheet({
    required this.onSignOut,
    super.key,
  });

  final Future<void> Function() onSignOut;

  static const Color _cardColor = Color(0xFF141B2D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    final email = user?.email ?? 'No email available';
    final displayName = user?.displayName?.trim();

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
                    color: const Color(
                      0xFF8B5CF6,
                    ).withValues(alpha: 0.28),
                    blurRadius: 22,
                    spreadRadius: 1,
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

            const SizedBox(height: 26),

            Container(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF60A5FA,
                        ).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF60A5FA),
                        size: 21,
                      ),
                    ),
                    title: const Text(
                      'Change password',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Update your account password',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white30,
                      size: 15,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();

                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    indent: 72,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),

                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF87171,
                        ).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFF87171),
                        size: 21,
                      ),
                    ),
                    title: const Text(
                      'Delete account',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently remove your account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white30,
                      size: 15,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();

                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const DeleteAccountScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onSignOut();
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                ),
                label: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFCA5A5),
                  side: BorderSide(
                    color: const Color(
                      0xFFF87171,
                    ).withValues(alpha: 0.22),
                  ),
                  backgroundColor: const Color(
                    0xFFF87171,
                  ).withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _accountInitial({
    required String? displayName,
    required String email,
  }) {
    if (displayName != null &&
        displayName.trim().isNotEmpty) {
      return displayName.trim()[0].toUpperCase();
    }

    if (email.trim().isNotEmpty) {
      return email.trim()[0].toUpperCase();
    }

    return 'N';
  }
}