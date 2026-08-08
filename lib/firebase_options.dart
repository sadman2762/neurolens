import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXola3WShHf2SitK01hFXWPp6BNdoUuJA',
    appId: '1:892958864201:android:9cf4c996872071d9f7a098',
    messagingSenderId: '892958864201',
    projectId: 'neurolens-fbe61',
    storageBucket: 'neurolens-fbe61.firebasestorage.app',
  );
}
