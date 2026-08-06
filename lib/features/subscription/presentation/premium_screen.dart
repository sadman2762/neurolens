import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/subscription/data/revenuecat_service.dart';
import 'package:neurolens/features/subscription/providers/subscription_provider.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  static const Color _background = Color(0xFF050816);
  static const Color _surface = Color(0xFF0D1321);
  static const Color _surfaceHighlight = Color(0xFF141B2D);
  static const Color _purple = Color(0xFF8B5CF6);

  bool _isPurchasing = false;
  bool _isRestoring = false;

  Future<void> _purchasePremium() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      await ref.read(subscriptionProvider).purchasePremium();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to NeuroLens Premium!'),
        ),
      );

      Navigator.of(context).pop(true);
    } on RevenueCatPurchaseCancelledException {
      // The user closed the purchase dialog intentionally.
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      await ref.read(subscriptionProvider).restorePurchases();

      if (!mounted) {
        return;
      }

      final hasPremium = await RevenueCatService.hasPremiumAccess();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasPremium
                ? 'Premium purchase restored successfully.'
                : 'No active Premium purchase was found.',
          ),
        ),
      );

      if (hasPremium) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isPurchasing || _isRestoring;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'NeuroLens Premium',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Column(
                children: [
                  _PremiumHero(),
                  const SizedBox(height: 28),
                  const _PlanCard(),
                  const SizedBox(height: 22),
                  const _PriceSection(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isBusy ? null : _purchasePremium,
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _purple.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(
                          vertical: 17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Start Premium',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: isBusy ? null : _restorePurchases,
                    child: _isRestoring
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Restoring purchases...'),
                            ],
                          )
                        : const Text(
                            'Restore purchases',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your subscription renews automatically until cancelled. '
                    'You can manage or cancel it through your app-store account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 94,
          height: 94,
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
                  alpha: 0.38,
                ),
                blurRadius: 34,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 46,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Unlock more AI power',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Analyze more memories every month and enjoy a faster, cleaner NeuroLens experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.56),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _PremiumScreenState._surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Column(
        children: [
          _PremiumFeature(
            icon: Icons.auto_awesome_rounded,
            title: '500 AI credits every month',
            subtitle: 'Analyze up to 500 eligible images monthly.',
          ),
          _FeatureDivider(),
          _PremiumFeature(
            icon: Icons.speed_rounded,
            title: 'Priority AI processing',
            subtitle: 'Premium requests receive higher processing priority.',
          ),
          _FeatureDivider(),
          _PremiumFeature(
            icon: Icons.block_rounded,
            title: 'No advertisements',
            subtitle: 'Use NeuroLens without advertising interruptions.',
          ),
          _FeatureDivider(),
          _PremiumFeature(
            icon: Icons.new_releases_outlined,
            title: 'Early access',
            subtitle: 'Try selected new AI features before free users.',
          ),
        ],
      ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  const _PriceSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: _PremiumScreenState._surfaceHighlight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          Text(
            'PREMIUM MONTHLY',
            style: TextStyle(
              color: const Color(0xFFC4B5FD).withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            '€3.99',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            'per month',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cancel anytime',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  const _PremiumFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(
                alpha: 0.13,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFC4B5FD),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.46),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF4ADE80),
            size: 21,
          ),
        ],
      ),
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}