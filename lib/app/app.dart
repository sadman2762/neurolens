import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/core/presentation/premium_splash_screen.dart';
import 'package:neurolens/features/auth/presentation/welcome_name_screen.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';
import 'package:neurolens/features/home/presentation/home_screen.dart';

class NeuroLensApp extends StatelessWidget {
  const NeuroLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor:
            const Color(0xFF050816),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() =>
      _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _splashFinished = false;

  void _finishSplash() {
    if (!mounted || _splashFinished) {
      return;
    }

    setState(() {
      _splashFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashFinished) {
      return PremiumSplashScreen(
        onFinished: _finishSplash,
      );
    }

    return const _LocalProfileGate();
  }
}

class _LocalProfileGate extends ConsumerWidget {
  const _LocalProfileGate();

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final profile =
        ref.watch(localProfileProvider);

    return profile.when(
      loading: () {
        return const _ProfileLoadingScreen();
      },
      error: (error, stackTrace) {
        return _ProfileErrorScreen(
          message: error.toString(),
          onRetry: () {
            ref
                .read(localProfileProvider.notifier)
                .reload();
          },
        );
      },
      data: (name) {
        if (name == null ||
            name.trim().isEmpty) {
          return const WelcomeNameScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

class _ProfileLoadingScreen
    extends StatelessWidget {
  const _ProfileLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050816),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}

class _ProfileErrorScreen
    extends StatelessWidget {
  const _ProfileErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF050816),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFF87171),
                  size: 42,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Could not load your profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.white.withValues(
                      alpha: 0.6,
                    ),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label:
                      const Text('Try again'),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(
                          0xFF8B5CF6,
                        ),
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