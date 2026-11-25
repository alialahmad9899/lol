import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FirebaseBootstrapResult firebaseResult =
      await FirebaseBootstrap.initialize();
  if (firebaseResult.error != null) {
    debugPrint('Firebase initialization failed: ${firebaseResult.error}');
  }

  runApp(RoohApp(firebaseReady: firebaseResult.isConfigured));
}
