import 'package:flutter/material.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}