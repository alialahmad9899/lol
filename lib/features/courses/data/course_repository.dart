import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.summary,
    required this.description,
    required this.instructorName,
    required this.level,
    required this.durationMinutes,
    required this.price,
    required this.currency,
    required this.isFree,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String summary;
  final String description;
  final String instructorName;
  final String level;
  final int? durationMinutes;
  final num price;
  final String currency;
  final bool isFree;
  final int sortOrder;

  bool get canEnrollForFree => isFree;

  factory Course.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Course.fromMap(snapshot.id, snapshot.data());
  }

  factory Course.fromMap(String id, Map<String, dynamic> data) {
    final Object? rawPrice = data['price'];
    final num price = rawPrice is num ? rawPrice : 0;
    return Course(
      id: id,
      title: _stringValue(data['title'], fallback: 'دورة بدون عنوان'),
      summary: _stringValue(data['summary']),
      description: _stringValue(data['description']),
      instructorName: _stringValue(data['instructorName']),
      level: _stringValue(data['level'], fallback: 'عام'),
      durationMinutes: data['durationMinutes'] is int
          ? data['durationMinutes'] as int
          : null,
      price: price,
      currency: _stringValue(data['currency'], fallback: 'USD'),
      isFree: data['isFree'] == true && price == 0,
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 0,
    );
  }
}

class CourseLesson {
  const CourseLesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.type,
    required this.durationMinutes,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String type;
  final int? durationMinutes;
  final int sortOrder;

  factory CourseLesson.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return CourseLesson.fromMap(snapshot.id, snapshot.data());
  }

  factory CourseLesson.fromMap(String id, Map<String, dynamic> data) {
    return CourseLesson(
      id: id,
      title: _stringValue(data['title'], fallback: 'درس بدون عنوان'),
      summary: _stringValue(data['summary']),
      body: _stringValue(data['body'] ?? data['content']),
      type: _stringValue(data['type'], fallback: 'text'),
      durationMinutes: data['durationMinutes'] is int
          ? data['durationMinutes'] as int
          : null,
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 0,
    );
  }
}

class CourseRepository {
  CourseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection('courses');

  Stream<List<Course>> watchPublishedCourses() {
    return _courses
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<Course> courses = snapshot.docs
          .map(Course.fromSnapshot)
          .toList(growable: true);
      courses.sort(
        (Course first, Course second) =>
            first.sortOrder.compareTo(second.sortOrder),
      );
      return courses;
    });
  }

  Stream<List<CourseLesson>> watchLessons(String courseId) {
    return _courses
        .doc(courseId)
        .collection('lessons')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<CourseLesson> lessons = snapshot.docs
          .map(CourseLesson.fromSnapshot)
          .toList(growable: true);
      lessons.sort(
        (CourseLesson first, CourseLesson second) =>
            first.sortOrder.compareTo(second.sortOrder),
      );
      return lessons;
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchEnrollment({
    required String userId,
    required String courseId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(courseId)
        .snapshots();
  }

  Future<void> enrollInFreeCourse({
    required String userId,
    required Course course,
  }) async {
    if (!course.canEnrollForFree) {
      throw StateError('لا يمكن التسجيل في دورة مدفوعة دون اعتماد الإدارة.');
    }

    final DocumentReference<Map<String, dynamic>> courseReference =
        _courses.doc(course.id);
    final DocumentReference<Map<String, dynamic>> enrollmentReference =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('enrollments')
            .doc(course.id);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> courseSnapshot =
          await transaction.get(courseReference);
      if (!courseSnapshot.exists ||
          courseSnapshot.data()?['status'] != 'published') {
        throw StateError('هذه الدورة غير منشورة حالياً.');
      }

      final Map<String, dynamic> courseData = courseSnapshot.data()!;
      final Object? rawPrice = courseData['price'];
      final bool isFree =
          courseData['isFree'] == true && rawPrice is num && rawPrice == 0;
      if (!isFree) {
        throw StateError('هذه الدورة مدفوعة وتحتاج إلى موافقة الإدارة.');
      }

      final DocumentSnapshot<Map<String, dynamic>> existingEnrollment =
          await transaction.get(enrollmentReference);
      if (existingEnrollment.exists) {
        if (existingEnrollment.data()?['status'] == 'active') return;
        throw StateError('هذا التسجيل موقوف ويحتاج إلى مراجعة الإدارة.');
      }

      transaction.set(enrollmentReference, <String, Object>{
        'userId': userId,
        'courseId': course.id,
        'status': 'active',
        'completedLessonIds': <String>[],
        'progressPercent': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markLessonCompleted({
    required String userId,
    required String courseId,
    required String lessonId,
    required int totalLessons,
  }) async {
    if (totalLessons <= 0) {
      throw ArgumentError.value(totalLessons, 'totalLessons');
    }

    final DocumentReference<Map<String, dynamic>> enrollmentReference =
        _firestore
            .collection('users')
            .doc(userId)
            .collection('enrollments')
            .doc(courseId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(enrollmentReference);
      if (!snapshot.exists || snapshot.data()?['status'] != 'active') {
        throw StateError('يجب التسجيل في الدورة أولاً.');
      }

      final Object? rawIds = snapshot.data()?['completedLessonIds'];
      final List<String> completedIds = rawIds is List
          ? rawIds.whereType<String>().toList(growable: true)
          : <String>[];
      if (!completedIds.contains(lessonId)) {
        completedIds.add(lessonId);
      }

      final int boundedCount = completedIds.length > totalLessons
          ? totalLessons
          : completedIds.length;
      final int progress = ((boundedCount / totalLessons) * 100).round();

      transaction.update(enrollmentReference, <String, Object>{
        'completedLessonIds': completedIds,
        'progressPercent': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is! String) return fallback;
  final String normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}
