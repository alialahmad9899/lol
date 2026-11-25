import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../admin/data/admin_repository.dart';
import '../../home/presentation/home_page.dart';
import '../data/firebase_auth_repository.dart';
import 'auth_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  FirebaseAuthRepository? _repository;
  AdminRepository? _adminRepository;
  Stream<User?>? _authState;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    try {
      _repository = FirebaseAuthRepository();
      _adminRepository = AdminRepository();
      _authState = _repository!.authStateChanges;
    } catch (_) {
      _initializationError =
          'تعذرت تهيئة خدمة الحسابات. تحقق من إعداد Firebase للمنصة.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuthRepository? repository = _repository;
    final Stream<User?>? authState = _authState;

    if (repository == null || authState == null) {
      return _AuthStatusPage(
        message: _initializationError ??
            'خدمة الحسابات غير متاحة حالياً على هذا الجهاز.',
      );
    }

    return StreamBuilder<User?>(
      stream: authState,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingPage();
        }
        if (snapshot.hasError) {
          return const _AuthStatusPage(
            message: 'تعذر التحقق من جلسة الحساب. أعد تشغيل التطبيق وحاول مجدداً.',
          );
        }

        final User? user = snapshot.data;
        if (user == null) {
          return AuthPage(repository: repository);
        }

        // Email verification is intentionally not a gate for the first release.
        final AdminRepository? adminRepository = _adminRepository;
        if (adminRepository == null) {
          return HomePage(user: user, onSignOut: repository.signOut);
        }

        return StreamBuilder<bool>(
          stream: adminRepository.watchAdminStatus(user.uid),
          builder: (BuildContext context, AsyncSnapshot<bool> adminSnapshot) {
            return HomePage(
              user: user,
              onSignOut: repository.signOut,
              isAdmin: adminSnapshot.data ?? false,
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AuthStatusPage extends StatelessWidget {
  const _AuthStatusPage({required this.message});

  final String message;

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
                'تعذر الاتصال بخدمة الحسابات',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
