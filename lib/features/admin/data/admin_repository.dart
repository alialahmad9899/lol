import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<bool> watchAdminStatus(String userId) {
    return _firestore
        .collection('admins')
        .doc(userId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) => snapshot.exists);
  }

  Future<bool> isAdmin(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('admins').doc(userId).get();
    return snapshot.exists;
  }
}
