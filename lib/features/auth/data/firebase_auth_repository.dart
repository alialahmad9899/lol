import 'package:firebase_auth/firebase_auth.dart';

import '../../profile/data/firestore_profile_repository.dart';

class FirebaseAuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirestoreProfileRepository? profiles,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _profiles = profiles ?? FirestoreProfileRepository();

  final FirebaseAuth _auth;
  final FirestoreProfileRepository _profiles;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _syncProfile(credential.user, displayName: displayName);
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _syncProfile(credential.user);
    return credential;
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('لا يوجد مستخدم مسجّل لإرسال رسالة التحقق.');
    }
    await user.sendEmailVerification();
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _syncProfile(
    User? user, {
    String? displayName,
  }) async {
    if (user == null) return;

    try {
      await _profiles.ensureProfile(user, displayName: displayName);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AccountProfileSyncException(userId: user.uid, cause: error),
        stackTrace,
      );
    }
  }
}

class AccountProfileSyncException implements Exception {
  const AccountProfileSyncException({
    required this.userId,
    required this.cause,
  });

  final String userId;
  final Object cause;

  @override
  String toString() {
    return 'تم إنشاء/تسجيل الحساب، لكن تعذرت مزامنة الملف الشخصي '
        'للمستخدم $userId: $cause';
  }
}
