import 'package:flutter_test/flutter_test.dart';
import 'package:rooh_app/features/admin/data/initial_library_seed_repository.dart';

void main() {
  group('InitialLibrarySeedRepository', () {
    test('contains unique stable document paths', () {
      final List<String> paths = InitialLibrarySeedRepository.initialDocuments
          .map((InitialSeedDocument item) => item.path)
          .toList(growable: false);

      expect(paths.toSet().length, paths.length);
      expect(paths.length, greaterThanOrEqualTo(25));
    });

    test('publishes original content under valid category identifiers', () {
      const documents = InitialLibrarySeedRepository.initialDocuments;
      final Set<String> categoryIds = documents
          .where((InitialSeedDocument item) =>
              item.path.startsWith('categories/'))
          .map((InitialSeedDocument item) => item.path.split('/').last)
          .toSet();
      final contentItems = documents.where(
        (InitialSeedDocument item) =>
            item.path.startsWith('content_items/'),
      );

      expect(categoryIds, containsAll(<String>[
        'awareness',
        'calm',
        'focus',
        'development',
        'change',
        'daily',
      ]));
      expect(contentItems.length, greaterThanOrEqualTo(10));

      for (final InitialSeedDocument item in contentItems) {
        expect(item.data['status'], 'published');
        expect(categoryIds, contains(item.data['categoryId']));
        expect(item.data['body'], isA<String>());
        expect((item.data['body'] as String).length, greaterThan(100));
      }
    });

    test('seed course and program are free and published', () {
      const documents = InitialLibrarySeedRepository.initialDocuments;
      final course = documents.firstWhere(
        (InitialSeedDocument item) =>
            item.path == 'courses/self_awareness_basics',
      );
      final program = documents.firstWhere(
        (InitialSeedDocument item) =>
            item.path == 'programs/seven_days_to_balance',
      );

      for (final document in <InitialSeedDocument>[course, program]) {
        expect(document.data['status'], 'published');
        expect(document.data['isFree'], isTrue);
        expect(document.data['price'], 0);
      }
    });
  });
}
