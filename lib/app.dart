import 'package:material_ui/material_ui.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

class RoohApp extends StatelessWidget {
  const RoohApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: RoohTheme.light,
      home: firebaseReady
          ? const AuthGate()
          : const _FirebaseUnavailablePage(),
    );
  }
}

class _FirebaseUnavailablePage extends StatelessWidget {
  const _FirebaseUnavailablePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: RoohTheme.primary,
              ),
              const SizedBox(height: 18),
              const Text(
                'رُوح',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'تعذر تهيئة خدمات التطبيق على هذا الجهاز. '
                'تحقق من إعداد Firebase ثم أعد تشغيل التطبيق.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: RoohTheme.mutedInk,
                      height: 1.6,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
