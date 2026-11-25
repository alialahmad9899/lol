import 'package:flutter_test/flutter_test.dart';
import 'package:rooh_app/features/programs/data/program_repository.dart';

void main() {
  group('RoohProgram', () {
    test('parses free program details', () {
      final RoohProgram program = RoohProgram.fromMap(
        'seven-days',
        <String, dynamic>{
          'title': '  تحدي 7 أيام  ',
          'summary': '  خطوة كل يوم  ',
          'description': 'برنامج عملي',
          'durationDays': 7,
          'price': 0,
          'currency': 'USD',
          'isFree': true,
          'sortOrder': 1,
        },
      );

      expect(program.id, 'seven-days');
      expect(program.title, 'تحدي 7 أيام');
      expect(program.summary, 'خطوة كل يوم');
      expect(program.durationDays, 7);
      expect(program.isFree, isTrue);
      expect(program.canEnrollForFree, isTrue);
      expect(program.sortOrder, 1);
    });

    test('does not treat a priced program as free', () {
      final RoohProgram program = RoohProgram.fromMap(
        'premium',
        <String, dynamic>{
          'title': 'برنامج متقدم',
          'durationDays': 14,
          'price': 25,
          'isFree': true,
        },
      );

      expect(program.isFree, isFalse);
      expect(program.canEnrollForFree, isFalse);
    });

    test('uses safe fallback values', () {
      final RoohProgram program = RoohProgram.fromMap(
        'untitled',
        <String, dynamic>{},
      );

      expect(program.title, 'برنامج بدون عنوان');
      expect(program.durationDays, 0);
      expect(program.currency, 'USD');
      expect(program.canEnrollForFree, isFalse);
    });
  });

  group('ProgramDay', () {
    test('parses a challenge day', () {
      final ProgramDay day = ProgramDay.fromMap(
        'day-1',
        <String, dynamic>{
          'dayNumber': 1,
          'title': '  راقب أفكارك  ',
          'description': 'خطوة أولى',
          'body': 'اكتب ثلاثة أفكار راودتك اليوم.',
          'sortOrder': 1,
        },
      );

      expect(day.id, 'day-1');
      expect(day.dayNumber, 1);
      expect(day.title, 'راقب أفكارك');
      expect(day.description, 'خطوة أولى');
      expect(day.body, 'اكتب ثلاثة أفكار راودتك اليوم.');
      expect(day.sortOrder, 1);
    });

    test('uses a safe title when day data is incomplete', () {
      final ProgramDay day = ProgramDay.fromMap(
        'day-x',
        <String, dynamic>{'dayNumber': 2},
      );

      expect(day.title, 'مهمة اليوم');
      expect(day.description, isEmpty);
      expect(day.body, isEmpty);
    });
  });
}
