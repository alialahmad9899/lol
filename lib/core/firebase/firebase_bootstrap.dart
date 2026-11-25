import 'package:firebase_core/firebase_core.dart';
import 'package:rooh_app/firebase_options.dart';

import 'firebase_configuration.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult.ready()
      : isConfigured = true,
        error = null,
        stackTrace = null;

  const FirebaseBootstrapResult.notConfigured()
      : isConfigured = false,
        error = null,
        stackTrace = null;

  const FirebaseBootstrapResult.failed(this.error, this.stackTrace)
      : isConfigured = false;

  final bool isConfigured;
  final Object? error;
  final StackTrace? stackTrace;
}

abstract final class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return const FirebaseBootstrapResult.ready();
    } on FirebaseConfigurationMissing {
      return const FirebaseBootstrapResult.notConfigured();
    } catch (error, stackTrace) {
      return FirebaseBootstrapResult.failed(error, stackTrace);
    }
  }
}
