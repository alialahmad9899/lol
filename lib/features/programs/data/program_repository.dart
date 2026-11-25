import 'package:cloud_firestore/cloud_firestore.dart';

class RoohProgram {
  const RoohProgram({
    required this.id,
    required this.title,
    required this.summary,
    required this.description,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.isFree,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String summary;
  final String description;
  final int durationDays;
  final num price;
  final String currency;
  final bool isFree;
  final int sortOrder;

  bool get canEnrollForFree => isFree;

  factory RoohProgram.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return RoohProgram.fromMap(snapshot.id, snapshot.data());
  }

  factory RoohProgram.fromMap(String id, Map<String, dynamic> data) {
    final Object? rawPrice = data['price'];
    final num price = rawPrice is num ? rawPrice : 0;
    return RoohProgram(
      id: id,
      title: _programString(data['title'], fallback: 'برنامج بدون عنوان'),
      summary: _programString(data['summary']),
      description: _programString(data['description']),
      durationDays: data['durationDays'] is int
          ? data['durationDays'] as int
          : 0,
      price: price,
      currency: _programString(data['currency'], fallback: 'USD'),
      isFree: data['isFree'] == true && price == 0,
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 0,
    );
  }
}

class ProgramDay {
  const ProgramDay({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.body,
    required this.sortOrder,
  });

  final String id;
  final int dayNumber;
  final String title;
  final String description;
  final String body;
  final int sortOrder;

  factory ProgramDay.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ProgramDay.fromMap(snapshot.id, snapshot.data());
  }

  factory ProgramDay.fromMap(String id, Map<String, dynamic> data) {
    return ProgramDay(
      id: id,
      dayNumber: data['dayNumber'] is int
          ? data['dayNumber'] as int
          : 0,
      title: _programString(data['title'], fallback: 'مهمة اليوم'),
      description: _programString(data['description']),
      body: _programString(data['body']),
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 0,
    );
  }
}

class ProgramRepository {
  ProgramRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _programs =>
      _firestore.collection('programs');

  Stream<List<RoohProgram>> watchPublishedPrograms() {
    return _programs
        .where('status', isEqualTo: 'published')
        .where('isFree', isEqualTo: true)
        .where('price', isEqualTo: 0)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<RoohProgram> programs = snapshot.docs
          .map(RoohProgram.fromSnapshot)
          .where((RoohProgram program) => program.canEnrollForFree)
          .toList(growable: true);
      programs.sort(
        (RoohProgram first, RoohProgram second) =>
            first.sortOrder.compareTo(second.sortOrder),
      );
      return programs;
    });
  }

  Stream<List<ProgramDay>> watchDays(String programId) {
    return _programs
        .doc(programId)
        .collection('days')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<ProgramDay> days = snapshot.docs
          .map(ProgramDay.fromSnapshot)
          .toList(growable: true);
      days.sort(
        (ProgramDay first, ProgramDay second) =>
            first.sortOrder.compareTo(second.sortOrder),
      );
      return days;
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchEnrollment({
    required String userId,
    required String programId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('programEnrollments')
        .doc(programId)
        .snapshots();
  }

  Future<void> enrollInFreeProgram({
    required String userId,
    required RoohProgram program,
  }) async {
    if (!program.canEnrollForFree) {
      throw StateError('لا يمكن التسجيل في برنامج مدفوع دون اعتماد الإدارة.');
    }

    final DocumentReference<Map<String, dynamic>> programReference =
        _programs.doc(program.id);
    final DocumentReference<Map<String, dynamic>> enrollmentReference =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('programEnrollments')
            .doc(program.id);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> programSnapshot =
          await transaction.get(programReference);
      if (!programSnapshot.exists ||
          programSnapshot.data()?['status'] != 'published') {
        throw StateError('هذا البرنامج غير منشور حالياً.');
      }

      final Map<String, dynamic> data = programSnapshot.data()!;
      final Object? rawPrice = data['price'];
      final bool isFree =
          data['isFree'] == true && rawPrice is num && rawPrice == 0;
      if (!isFree) {
        throw StateError('هذا البرنامج مدفوع ويحتاج إلى موافقة الإدارة.');
      }

      final DocumentSnapshot<Map<String, dynamic>> existing =
          await transaction.get(enrollmentReference);
      if (existing.exists) {
        if (existing.data()?['status'] == 'active') return;
        throw StateError('هذا التسجيل موقوف ويحتاج إلى مراجعة الإدارة.');
      }

      transaction.set(enrollmentReference, <String, Object>{
        'userId': userId,
        'programId': program.id,
        'status': 'active',
        'completedDayIds': <String>[],
        'progressPercent': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markDayCompleted({
    required String userId,
    required String programId,
    required String dayId,
    required int totalDays,
  }) async {
    if (totalDays <= 0) {
      throw ArgumentError.value(totalDays, 'totalDays');
    }

    final DocumentReference<Map<String, dynamic>> enrollmentReference =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('programEnrollments')
            .doc(programId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(enrollmentReference);
      if (!snapshot.exists || snapshot.data()?['status'] != 'active') {
        throw StateError('يجب التسجيل في البرنامج أولاً.');
      }

      final Object? rawIds = snapshot.data()?['completedDayIds'];
      final List<String> completedIds = rawIds is List
          ? rawIds.whereType<String>().toList(growable: true)
          : <String>[];
      if (!completedIds.contains(dayId)) completedIds.add(dayId);

      final int boundedCount =
          completedIds.length > totalDays ? totalDays : completedIds.length;
      final int progress = ((boundedCount / totalDays) * 100).round();

      transaction.update(enrollmentReference, <String, Object>{
        'completedDayIds': completedIds,
        'progressPercent': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

String _programString(Object? value, {String fallback = ''}) {
  if (value is! String) return fallback;
  final String normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}
