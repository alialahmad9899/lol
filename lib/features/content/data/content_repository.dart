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
    return ContentCategory.fromMap(snapshot.id, snapshot.data());
  }

  factory ContentCategory.fromMap(String id, Map<String, dynamic> data) {
    return ContentCategory(
      id: id,
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
    return ContentItem.fromMap(snapshot.id, snapshot.data());
  }

  factory ContentItem.fromMap(String id, Map<String, dynamic> data) {
    return ContentItem(
      id: id,
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

  CollectionReference<Map<String, dynamic>> _userCollection(
    String userId,
    String collection,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collection);
  }

  Stream<bool> watchSavedStatus({
    required String userId,
    required String contentId,
  }) {
    return _userCollection('savedContent', userId)
        .doc(contentId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) => snapshot.exists);
  }

  Stream<bool> watchCompletedStatus({
    required String userId,
    required String contentId,
  }) {
    return _userCollection('contentProgress', userId)
        .doc(contentId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.data()?['completed'] == true);
  }

  Stream<List<String>> watchSavedContentIds(String userId) {
    return _userCollection('savedContent', userId).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final docs = snapshot.docs.toList(growable: true);
        docs.sort((first, second) {
          final Object? firstValue = first.data()['createdAt'];
          final Object? secondValue = second.data()['createdAt'];
          final int firstTime =
              firstValue is Timestamp ? firstValue.millisecondsSinceEpoch : 0;
          final int secondTime =
              secondValue is Timestamp ? secondValue.millisecondsSinceEpoch : 0;
          return secondTime.compareTo(firstTime);
        });
        return docs.map((doc) => doc.id).toList(growable: false);
      },
    );
  }

  Stream<List<String>> watchCompletedContentIds(String userId) {
    return _userCollection('contentProgress', userId).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final docs = snapshot.docs
            .where((doc) => doc.data()['completed'] == true)
            .toList(growable: true);
        docs.sort((first, second) {
          final Object? firstValue = first.data()['completedAt'];
          final Object? secondValue = second.data()['completedAt'];
          final int firstTime =
              firstValue is Timestamp ? firstValue.millisecondsSinceEpoch : 0;
          final int secondTime =
              secondValue is Timestamp ? secondValue.millisecondsSinceEpoch : 0;
          return secondTime.compareTo(firstTime);
        });
        return docs.map((doc) => doc.id).toList(growable: false);
      },
    );
  }

  Future<ContentItem?> fetchPublishedItem(String contentId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('content_items').doc(contentId).get();
    if (!snapshot.exists || snapshot.data()?['status'] != 'published') {
      return null;
    }
    return ContentItem.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<void> setSaved({
    required String userId,
    required ContentItem item,
    required bool saved,
  }) async {
    final DocumentReference<Map<String, dynamic>> reference =
        _userCollection('savedContent', userId).doc(item.id);
    if (!saved) {
      await reference.delete();
      return;
    }
    await reference.set(<String, Object>{
      'contentId': item.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCompleted({
    required String userId,
    required String contentId,
  }) async {
    final DocumentReference<Map<String, dynamic>> reference =
        _userCollection('contentProgress', userId).doc(contentId);
    await reference.set(<String, Object>{
      'contentId': contentId,
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
