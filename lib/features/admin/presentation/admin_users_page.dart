import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستخدمون')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل قائمة المستخدمين. تحقق من صلاحيات المدير واتصال Firestore.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> users =
              snapshot.data?.docs.toList(growable: true) ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          users.sort((a, b) {
            final String aName = (a.data()['displayName'] as String? ?? '')
                .toLowerCase();
            final String bName = (b.data()['displayName'] as String? ?? '')
                .toLowerCase();
            return aName.compareTo(bName);
          });

          if (users.isEmpty) {
            return const Center(
              child: Text('لا توجد حسابات مسجلة حتى الآن.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final QueryDocumentSnapshot<Map<String, dynamic>> document =
                  users[index];
              final Map<String, dynamic> data = document.data();
              final String name = data['displayName'] is String &&
                      (data['displayName'] as String).trim().isNotEmpty
                  ? (data['displayName'] as String).trim()
                  : 'مستخدم بدون اسم';
              final String email =
                  data['email'] is String ? data['email'] as String : '';
              final String city =
                  data['city'] is String ? data['city'] as String : '';
              final String country =
                  data['country'] is String ? data['country'] as String : '';
              final String location = <String>[city, country]
                  .where((String value) => value.trim().isNotEmpty)
                  .join('، ');
              final Object? rawInterests = data['interests'];
              final List<String> interests = rawInterests is List
                  ? rawInterests.whereType<String>().toList(growable: false)
                  : const <String>[];
              final String goal = data['primaryGoal'] is String
                  ? data['primaryGoal'] as String
                  : '';
              final int? age = data['age'] is int ? data['age'] as int : null;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RoohTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RoohTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const CircleAvatar(
                          child: Icon(Icons.person_outline_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: RoohTheme.mutedInk,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                'UID: ${document.id}',
                                style: const TextStyle(
                                  color: RoohTheme.mutedInk,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (age != null) Chip(label: Text('$age سنة')),
                        if (data['gender'] is String)
                          Chip(
                            label: Text(_adminGenderLabel(data['gender'] as String)),
                          ),
                        if (location.isNotEmpty) Chip(label: Text(location)),
                      ],
                    ),
                    if (goal.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text('الهدف: $goal'),
                    ],
                    if (interests.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text('الاهتمامات: ${interests.join('، ')}'),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _adminGenderLabel(String value) {
  switch (value) {
    case 'male':
      return 'ذكر';
    case 'female':
      return 'أنثى';
    case 'prefer_not_to_say':
      return 'أفضل عدم الإجابة';
    default:
      return 'غير محدد';
  }
}
