import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/core/presentation/premium_splash_screen.dart';
import 'package:neurolens/features/auth/presentation/email_verification_screen.dart';
import 'package:neurolens/features/auth/presentation/login_screen.dart';
import 'package:neurolens/features/auth/providers/auth_providers.dart';
import 'package:neurolens/features/home/presentation/home_screen.dart';
import 'package:neurolens/features/subscription/data/revenuecat_service.dart';

class NeuroLensApp extends ConsumerWidget {
  const NeuroLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (!RevenueCatService.isConfigured) {
          return;
        }

        if (user != null) {
          unawaited(RevenueCatService.identifyUser(user.uid));
        } else {
          unawaited(RevenueCatService.logOut());
        }
      });
    });

    return MaterialApp(
      title: 'NeuroLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050816),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const _SplashGate(),
    );
  }
}

class _SplashGate extends ConsumerStatefulWidget {
  const _SplashGate();

  @override
  ConsumerState<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<_SplashGate> {
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
      return PremiumSplashScreen(onFinished: _finishSplash);
    }

    return const _AuthGate();
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () {
        return const _AuthLoadingScreen();
      },
      error: (error, stackTrace) {
        return _AuthErrorScreen(message: error.toString());
      },
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050816),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFF87171),
                  size: 42,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Could not load authentication',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.5,
                    fontSize: 13,
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
