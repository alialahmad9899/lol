import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> ensureProfile(
    User user, {
    String? displayName,
    List<String> interests = const <String>[],
    String? primaryGoal,
  }) async {
    final String? email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('يجب أن يحتوي الحساب على بريد إلكتروني صالح.');
    }

    final String safeDisplayName =
        (displayName ?? user.displayName ?? '').trim();
    if (safeDisplayName.length > 100) {
      throw ArgumentError.value(
        safeDisplayName,
        'displayName',
        'يجب ألا يتجاوز الاسم 100 محرف.',
      );
    }

    final List<String> normalizedInterests = interests
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedInterests.length > 20) {
      throw ArgumentError.value(
        interests,
        'interests',
        'لا يمكن حفظ أكثر من 20 اهتماماً.',
      );
    }

    final String normalizedGoal = (primaryGoal ?? '').trim();
    if (normalizedGoal.length > 120) {
      throw ArgumentError.value(
        primaryGoal,
        'primaryGoal',
        'يجب ألا يتجاوز الهدف 120 محرفاً.',
      );
    }

    final DocumentReference<Map<String, dynamic>> userDocument =
        _users.doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userDocument.get();

    // Never overwrite an existing profile when the user signs in.
    if (snapshot.exists) return;

    await userDocument.set(<String, Object>{
      'uid': user.uid,
      'email': email,
      'displayName': safeDisplayName,
      'locale': 'ar',
      'interests': normalizedInterests,
      'primaryGoal': normalizedGoal,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    });
  }

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _users.doc(uid).get();
    return snapshot.data();
  }

  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.data(),
        );
  }

  Future<void> updateProfile({
    required User user,
    String? displayName,
    String? locale,
    List<String>? interests,
    String? primaryGoal,
  }) async {
    final Map<String, Object> changes = <String, Object>{};

    if (displayName != null) {
      final String normalizedName = displayName.trim();
      if (normalizedName.isEmpty || normalizedName.length > 100) {
        throw ArgumentError.value(
          displayName,
          'displayName',
          'يجب إدخال اسم لا يتجاوز 100 محرف.',
        );
      }
      changes['displayName'] = normalizedName;
    }

    if (locale != null) {
      if (locale != 'ar' && locale != 'en') {
        throw ArgumentError.value(locale, 'locale');
      }
      changes['locale'] = locale;
    }

    if (interests != null) {
      final List<String> normalizedInterests = interests
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false);
      if (normalizedInterests.length > 20) {
        throw ArgumentError.value(
          interests,
          'interests',
          'لا يمكن حفظ أكثر من 20 اهتماماً.',
        );
      }
      changes['interests'] = normalizedInterests;
    }

    if (primaryGoal != null) {
      final String normalizedGoal = primaryGoal.trim();
      if (normalizedGoal.length > 120) {
        throw ArgumentError.value(
          primaryGoal,
          'primaryGoal',
          'يجب ألا يتجاوز الهدف 120 محرفاً.',
        );
      }
      changes['primaryGoal'] = normalizedGoal;
    }

    if (changes.isEmpty) return;

    changes['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(user.uid).update(changes);
  }
}
