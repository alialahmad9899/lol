import 'package:material_ui/material_ui.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_page.dart';

class RoohApp extends StatelessWidget {
  const RoohApp({super.key});

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
      home: const HomePage(),
    );
  }
}
