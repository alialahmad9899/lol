import 'package:flutter_test/flutter_test.dart';
import 'package:rooh_app/features/courses/data/course_repository.dart';

void main() {
  group('Course', () {
    test('parses published course metadata and free price consistently', () {
      final Course course = Course.fromMap(
        'mindfulness',
        <String, dynamic>{
          'title': '  الوعي بالذات  ',
          'summary': '  مدخل لفهم النفس  ',
          'description': 'محتوى الدورة',
          'instructorName': 'د. خالد علوش',
          'level': 'مبتدئ',
          'durationMinutes': 120,
          'price': 0,
          'currency': 'USD',
          'isFree': true,
          'sortOrder': 2,
        },
      );

      expect(course.id, 'mindfulness');
      expect(course.title, 'الوعي بالذات');
      expect(course.summary, 'مدخل لفهم النفس');
      expect(course.instructorName, 'د. خالد علوش');
      expect(course.durationMinutes, 120);
      expect(course.price, 0);
      expect(course.isFree, isTrue);
      expect(course.canEnrollForFree, isTrue);
      expect(course.sortOrder, 2);
    });

    test('does not treat a non-zero course as free even if flagged free', () {
      final Course course = Course.fromMap(
        'premium',
        <String, dynamic>{'title': 'متقدم', 'price': 50, 'isFree': true},
      );

      expect(course.isFree, isFalse);
      expect(course.canEnrollForFree, isFalse);
      expect(course.price, 50);
    });

    test('uses safe values for missing optional metadata', () {
      final Course course = Course.fromMap('untitled', <String, dynamic>{});

      expect(course.title, 'دورة بدون عنوان');
      expect(course.level, 'عام');
      expect(course.currency, 'USD');
      expect(course.durationMinutes, isNull);
      expect(course.canEnrollForFree, isFalse);
    });
  });

  group('CourseLesson', () {
    test('normalizes lesson text and metadata', () {
      final CourseLesson lesson = CourseLesson.fromMap(
        'lesson-1',
        <String, dynamic>{
          'title': '  التنفس الواعي  ',
          'summary': '  تمرين بسيط  ',
          'content': '  خذ نفساً ببطء.  ',
          'type': 'exercise',
          'durationMinutes': 5,
          'sortOrder': 1,
        },
      );

      expect(lesson.id, 'lesson-1');
      expect(lesson.title, 'التنفس الواعي');
      expect(lesson.summary, 'تمرين بسيط');
      expect(lesson.body, 'خذ نفساً ببطء.');
      expect(lesson.type, 'exercise');
      expect(lesson.durationMinutes, 5);
      expect(lesson.sortOrder, 1);
    });

    test('uses a safe lesson title and text type', () {
      final CourseLesson lesson = CourseLesson.fromMap(
        'lesson-x',
        <String, dynamic>{'title': 7},
      );

      expect(lesson.title, 'درس بدون عنوان');
      expect(lesson.body, isEmpty);
      expect(lesson.type, 'text');
    });
  });
}
