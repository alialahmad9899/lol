import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
    required this.currency,
    required this.transferReference,
    required this.status,
    required this.reviewNote,
  });

  final String id;
  final String userId;
  final String courseId;
  final String courseTitle;
  final num amount;
  final String currency;
  final String transferReference;
  final String status;
  final String reviewNote;

  factory PaymentRequest.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return PaymentRequest.fromMap(snapshot.id, snapshot.data());
  }

  factory PaymentRequest.fromMap(String id, Map<String, dynamic> data) {
    final Object? rawAmount = data['amount'];
    return PaymentRequest(
      id: id,
      userId: _paymentString(data['userId']),
      courseId: _paymentString(data['courseId']),
      courseTitle: _paymentString(data['courseTitle']),
      amount: rawAmount is num ? rawAmount : 0,
      currency: _paymentString(data['currency'], fallback: 'USD'),
      transferReference: _paymentString(data['transferReference']),
      status: _paymentString(data['status'], fallback: 'pending'),
      reviewNote: _paymentString(data['reviewNote']),
    );
  }
}

class PaymentRequestRepository {
  PaymentRequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('paymentRequests');

  Stream<PaymentRequest?> watchCourseRequest({
    required String userId,
    required String courseId,
  }) {
    return _requests
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final matching = snapshot.docs
          .where((doc) => doc.data()['courseId'] == courseId)
          .toList(growable: true);
      if (matching.isEmpty) return null;
      matching.sort((first, second) {
        final Object? firstTime = first.data()['createdAt'];
        final Object? secondTime = second.data()['createdAt'];
        final int firstMillis =
            firstTime is Timestamp ? firstTime.millisecondsSinceEpoch : 0;
        final int secondMillis =
            secondTime is Timestamp ? secondTime.millisecondsSinceEpoch : 0;
        return secondMillis.compareTo(firstMillis);
      });
      return PaymentRequest.fromSnapshot(matching.first);
    });
  }

  Stream<List<PaymentRequest>> watchPendingRequests() {
    return _requests
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<PaymentRequest> requests = snapshot.docs
          .map(PaymentRequest.fromSnapshot)
          .toList(growable: true);
      requests.sort((first, second) => first.courseTitle.compareTo(second.courseTitle));
      return requests;
    });
  }

  Future<void> submitCourseReference({
    required String userId,
    required String courseId,
    required String courseTitle,
    required num amount,
    required String currency,
    required String transferReference,
  }) async {
    final String reference = transferReference.trim();
    if (reference.length < 4 || reference.length > 120) {
      throw ArgumentError.value(
        transferReference,
        'transferReference',
        'يجب أن يكون مرجع التحويل بين 4 و120 محرفاً.',
      );
    }
    if (amount <= 0) {
      throw StateError('لا يمكن إرسال طلب دفع لدورة مجانية.');
    }

    final QuerySnapshot<Map<String, dynamic>> existingRequests =
        await _requests.where('userId', isEqualTo: userId).get();
    final bool alreadyPending = existingRequests.docs.any(
      (doc) =>
          doc.data()['courseId'] == courseId &&
          doc.data()['status'] == 'pending',
    );
    if (alreadyPending) {
      throw StateError('لديك طلب قيد المراجعة لهذا الكورس بالفعل.');
    }

    await _requests.add(<String, Object>{
      'userId': userId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'amount': amount,
      'currency': currency,
      'transferReference': reference,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reviewRequest({
    required String requestId,
    required String reviewerUid,
    required bool approve,
    String reviewNote = '',
  }) async {
    final String note = reviewNote.trim();
    if (note.length > 500) {
      throw ArgumentError.value(reviewNote, 'reviewNote');
    }

    final DocumentReference<Map<String, dynamic>> requestReference =
        _requests.doc(requestId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> requestSnapshot =
          await transaction.get(requestReference);
      if (!requestSnapshot.exists) {
        throw StateError('طلب الدفع غير موجود.');
      }

      final Map<String, dynamic> requestData = requestSnapshot.data()!;
      if (requestData['status'] != 'pending') {
        throw StateError('تمت مراجعة هذا الطلب مسبقاً.');
      }

      final String userId = requestData['userId'] as String;
      final String courseId = requestData['courseId'] as String;
      final DocumentReference<Map<String, dynamic>> courseReference =
          _firestore.collection('courses').doc(courseId);
      final DocumentReference<Map<String, dynamic>> enrollmentReference =
          _firestore
              .collection('users')
              .doc(userId)
              .collection('enrollments')
              .doc(courseId);

      final DocumentSnapshot<Map<String, dynamic>> courseSnapshot =
          await transaction.get(courseReference);
      final DocumentSnapshot<Map<String, dynamic>> enrollmentSnapshot =
          await transaction.get(enrollmentReference);

      if (approve) {
        final Map<String, dynamic>? courseData = courseSnapshot.data();
        if (!courseSnapshot.exists ||
            courseData?['status'] != 'published' ||
            courseData?['isFree'] == true ||
            courseData?['price'] is! num ||
            (courseData?['price'] as num) <= 0) {
          throw StateError('لم تعد الدورة مؤهلة لاعتماد الدفع.');
        }

        if (enrollmentSnapshot.data()?['status'] != 'active') {
          transaction.set(enrollmentReference, <String, Object>{
            'userId': userId,
            'courseId': courseId,
            'status': 'active',
            'completedLessonIds': <String>[],
            'progressPercent': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.update(requestReference, <String, Object>{
        'status': approve ? 'approved' : 'rejected',
        'reviewNote': note,
        'reviewedBy': reviewerUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

String _paymentString(Object? value, {String fallback = ''}) {
  if (value is! String) return fallback;
  final String normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}
