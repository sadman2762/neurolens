import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';
import 'package:neurolens/features/auth/presentation/change_password_screen.dart';
import 'package:neurolens/features/auth/presentation/delete_account_screen.dart';

class AccountBottomSheet extends ConsumerWidget {
  const AccountBottomSheet({
    required this.onSignOut,
    required this.onUpgrade,
    super.key,
  });

  final Future<void> Function() onSignOut;
  final VoidCallback onUpgrade;

  static const Color _cardColor = Color(0xFF141B2D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(userProfileProvider);

    final email = user?.email ?? 'No email available';
    final displayName = user?.displayName?.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: profileState.when(
          loading: () => const SizedBox(
            height: 360,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            ),
          ),
          error: (error, stackTrace) {
            return SizedBox(
              height: 360,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load account information.\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            );
          },
          data: (profile) {
            final isPremium = profile?.isPremium == true;
            final planLabel = isPremium ? 'Premium' : 'Free';
            final creditsRemaining = profile?.creditsRemaining ?? 0;
            final creditsUsed = profile?.creditsUsed ?? 0;

            return Column(
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
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _accountInitial(displayName: displayName, email: email),
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
                        value: planLabel,
                        iconColor: const Color(0xFFC4B5FD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AccountStatCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI credits',
                        value: '$creditsRemaining remaining',
                        iconColor: const Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$creditsUsed AI credits used this month',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                      if (!isPremium)
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
                            Navigator.of(context).pop();
                            onUpgrade();
                          },
                        ),
                      ListTile(
                        leading: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF60A5FA),
                        ),
                        title: const Text(
                          'Change password',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever_rounded,
                          color: Color(0xFFF87171),
                        ),
                        title: const Text(
                          'Delete account',
                          style: TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Permanently remove your account and cloud data',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white38,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DeleteAccountScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      if (!isPremium)
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
                        onTap: () async {
                          Navigator.of(context).pop();
                          await onSignOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
        color: AccountBottomSheet._cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
