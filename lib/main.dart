import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/app/app.dart';
import 'package:neurolens/features/subscription/data/revenuecat_service.dart';
import 'package:neurolens/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
  );

  await RevenueCatService.configure(
    apiKey: revenueCatApiKey,
    userId: FirebaseAuth.instance.currentUser?.uid,
  );

  runApp(
    const ProviderScope(
      child: NeuroLensApp(),
    ),
  );
}