import 'package:flutter_test/flutter_test.dart';
import 'package:rooh_app/features/content/data/content_repository.dart';

void main() {
  group('ContentCategory', () {
    test('normalizes category fields from Firestore data', () {
      final ContentCategory category = ContentCategory.fromMap(
        'relaxation',
        <String, dynamic>{
          'title': '  استرخاء  ',
          'description': '  استعد هدوءك  ',
          'sortOrder': 3,
        },
      );

      expect(category.id, 'relaxation');
      expect(category.title, 'استرخاء');
      expect(category.description, 'استعد هدوءك');
      expect(category.sortOrder, 3);
    });

    test('uses a safe title when the source is malformed', () {
      final ContentCategory category = ContentCategory.fromMap(
        'new-category',
        <String, dynamic>{'title': 42},
      );

      expect(category.title, 'قسم جديد');
      expect(category.sortOrder, 0);
    });
  });

  group('ContentItem', () {
    test('reads text content and normalizes tags', () {
      final ContentItem item = ContentItem.fromMap(
        'breathing',
        <String, dynamic>{
          'title': '  لحظة تنفّس  ',
          'summary': '  تمرين قصير  ',
          'body': '  خذ نفساً عميقاً.  ',
          'categoryId': 'relaxation',
          'type': 'exercise',
          'durationMinutes': 5,
          'tags': <Object>[' استرخاء ', 8, 'تنفّس', ''],
          'sortOrder': 2,
        },
      );

      expect(item.id, 'breathing');
      expect(item.title, 'لحظة تنفّس');
      expect(item.summary, 'تمرين قصير');
      expect(item.body, 'خذ نفساً عميقاً.');
      expect(item.categoryId, 'relaxation');
      expect(item.type, 'exercise');
      expect(item.durationMinutes, 5);
      expect(item.tags, <String>['استرخاء', 'تنفّس']);
      expect(item.sortOrder, 2);
    });

    test('provides safe defaults for optional content fields', () {
      final ContentItem item = ContentItem.fromMap(
        'untitled',
        <String, dynamic>{'durationMinutes': 'five'},
      );

      expect(item.title, 'محتوى بدون عنوان');
      expect(item.summary, isEmpty);
      expect(item.body, isEmpty);
      expect(item.type, 'text');
      expect(item.durationMinutes, isNull);
      expect(item.tags, isEmpty);
    });
  });
}
