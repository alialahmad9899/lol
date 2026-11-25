// Generated from the registered Firebase Android app.
// iOS and other platforms will be added after their Firebase app registrations.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase is configured for Android only. Register the iOS app '
      'and regenerate Firebase options before running on iOS.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQDCSJeKrxpqKr_Wo2Me3FjV_9UUtynmE',
    appId: '1:289917698507:android:b4e2f9083d8f2ad3adf64e',
    messagingSenderId: '289917698507',
    projectId: 'ali9899-59774',
    storageBucket: 'ali9899-59774.firebasestorage.app',
  );
}
