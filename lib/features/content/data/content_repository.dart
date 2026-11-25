import 'package:cloud_firestore/cloud_firestore.dart';

class ContentCategory {
  const ContentCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final int sortOrder;

  factory ContentCategory.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data();
    return ContentCategory(
      id: snapshot.id,
      title: _readString(data['title'], fallback: 'قسم جديد'),
      description: _readString(data['description']),
      sortOrder: _readInt(data['sortOrder']),
    );
  }
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.categoryId,
    required this.type,
    required this.durationMinutes,
    required this.tags,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String categoryId;
  final String type;
  final int? durationMinutes;
  final List<String> tags;
  final int sortOrder;

  factory ContentItem.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data();
    return ContentItem(
      id: snapshot.id,
      title: _readString(data['title'], fallback: 'محتوى بدون عنوان'),
      summary: _readString(data['summary'] ?? data['description']),
      body: _readString(data['body'] ?? data['content']),
      categoryId: _readString(data['categoryId']),
      type: _readString(data['type'], fallback: 'text'),
      durationMinutes: _readNullableInt(data['durationMinutes']),
      tags: _readStringList(data['tags']),
      sortOrder: _readInt(data['sortOrder']),
    );
  }
}

class ContentRepository {
  ContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ContentCategory>> watchCategories() {
    return _firestore.collection('categories').snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<ContentCategory> categories = snapshot.docs
            .map(ContentCategory.fromSnapshot)
            .toList(growable: false)
            .where((ContentCategory category) => category.title.isNotEmpty)
            .toList(growable: true);
        categories.sort(
          (ContentCategory a, ContentCategory b) =>
              a.sortOrder.compareTo(b.sortOrder),
        );
        return categories;
      },
    );
  }

  Stream<List<ContentItem>> watchPublishedContent() {
    return _firestore
        .collection('content_items')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<ContentItem> items = snapshot.docs
                .map(ContentItem.fromSnapshot)
                .toList(growable: true);
            items.sort(
              (ContentItem a, ContentItem b) =>
                  a.sortOrder.compareTo(b.sortOrder),
            );
            return items;
          },
        );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is! String) return fallback;
  return value.trim();
}

int _readInt(Object? value) => value is int ? value : 0;

int? _readNullableInt(Object? value) => value is int ? value : null;

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .whereType<String>()
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}
