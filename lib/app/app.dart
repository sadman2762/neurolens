import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          unawaited(
            RevenueCatService.identifyUser(user.uid),
          );
        } else {
          unawaited(
            RevenueCatService.logOut(),
          );
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
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
      loading: () => const _AuthLoadingScreen(),
      error: (error, stackTrace) {
        return _AuthErrorScreen(
          message: error.toString(),
        );
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
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load authentication:\n$message',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}