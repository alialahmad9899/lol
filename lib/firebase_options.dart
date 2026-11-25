// Temporary placeholder. Run flutterfire configure to generate real options.
// Never replace these values with guessed project identifiers.

import 'package:firebase_core/firebase_core.dart';

import 'core/firebase/firebase_configuration.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw const FirebaseConfigurationMissing();
  }
}
