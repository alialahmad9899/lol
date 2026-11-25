import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../data/firestore_profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.user,
    this.onSignOut,
    FirestoreProfileRepository? repository,
  }) : repository = repository;

  final User user;
  final Future<void> Function()? onSignOut;
  final FirestoreProfileRepository? repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final FirestoreProfileRepository _repository =
      widget.repository ?? FirestoreProfileRepository();

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFF9B382B) : RoohTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _editProfile(Map<String, dynamic> profile) async {
    final String currentName = profile['displayName'] is String
        ? profile['displayName'] as String
        : widget.user.displayName ?? '';
    final Object? rawInterests = profile['interests'];
    final List<String> currentInterests = rawInterests is List
        ? rawInterests.whereType<String>().toList(growable: false)
        : const <String>[];

    final _ProfileEditResult? result =
        await showDialog<_ProfileEditResult>(
      context: context,
      builder: (BuildContext context) => _ProfileEditDialog(
        initialName: currentName,
        initialInterests: currentInterests,
      ),
    );
    if (result == null) return;

    try {
      await _repository.updateProfile(
        user: widget.user,
        displayName: result.displayName,
        interests: result.interests,
      );
      _showMessage('تم تحديث ملفك الشخصي بنجاح.');
    } catch (_) {
      _showMessage(
        'تعذر حفظ التعديلات. تحقق من اتصال قاعدة البيانات وحاول مجدداً.',
        isError: true,
      );
    }
  }

  Future<void> _signOut() async {
    final Future<void> Function()? callback = widget.onSignOut;
    if (callback == null) {
      _showMessage('تسجيل الخروج غير متاح حالياً.', isError: true);
      return;
    }

    try {
      await callback();
    } catch (_) {
      _showMessage('تعذر تسجيل الخروج. حاول مرة أخرى.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: <Widget>[
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _repository.watchProfile(widget.user.uid),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ProfileMessage(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر تحميل الملف الشخصي',
              message:
                  'تأكد من تفعيل قاعدة Firestore ونشر قواعد الأمان، ثم أعد المحاولة.',
            );
          }

          final Map<String, dynamic>? profile = snapshot.data;
          if (profile == null) {
            return const _ProfileMessage(
              icon: Icons.person_off_outlined,
              title: 'ملفك الشخصي غير مكتمل',
              message:
                  'لم نعثر على بيانات الملف الشخصي لهذا الحساب. سجّل الخروج ثم حاول الدخول مجدداً بعد إعداد قاعدة البيانات.',
            );
          }

          final String displayName = profile['displayName'] is String &&
                  (profile['displayName'] as String).trim().isNotEmpty
              ? (profile['displayName'] as String).trim()
              : 'لم تضف اسمك بعد';
          final String email = profile['email'] is String
              ? profile['email'] as String
              : widget.user.email ?? '';
          final Object? rawInterests = profile['interests'];
          final List<String> interests = rawInterests is List
              ? rawInterests.whereType<String>().toList(growable: false)
              : const <String>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: <Widget>[
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE7DF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 48,
                    color: RoohTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: RoohTheme.mutedInk,
                    ),
              ),
              const SizedBox(height: 26),
              _ProfileSection(
                title: 'معلومات الحساب',
                child: Column(
                  children: <Widget>[
                    _ProfileInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'الاسم',
                      value: displayName,
                    ),
                    const Divider(height: 22),
                    _ProfileInfoRow(
                      icon: Icons.email_outlined,
                      label: 'البريد الإلكتروني',
                      value: email,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: 'اهتماماتك',
                child: interests.isEmpty
                    ? const Text(
                        'لم تحدد اهتماماتك بعد.',
                        style: TextStyle(color: RoohTheme.mutedInk),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: interests
                            .map(
                              (String interest) => Chip(
                                label: Text(interest),
                                backgroundColor: const Color(0xFFF0EEE8),
                                side: BorderSide.none,
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _editProfile(profile),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل الملف الشخصي'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 46, color: RoohTheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: RoohTheme.mutedInk,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: RoohTheme.surface,
        border: Border.all(color: RoohTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: RoohTheme.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: RoohTheme.mutedInk,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileEditResult {
  const _ProfileEditResult({
    required this.displayName,
    required this.interests,
  });

  final String displayName;
  final List<String> interests;
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({
    required this.initialName,
    required this.initialInterests,
  });

  final String initialName;
  final List<String> initialInterests;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  static const List<String> _options = <String>[
    'وعي',
    'تطوير الذات',
    'استرخاء',
    'تركيز',
    'تغيير',
    'بناء العادات',
    'رُوح اليومية',
  ];

  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  late final Set<String> _selectedInterests =
      widget.initialInterests.toSet();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _nameController.text.trim();
    if (name.isEmpty || name.length > 100) return;

    Navigator.of(context).pop(
      _ProfileEditResult(
        displayName: name,
        interests: _selectedInterests.toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل الملف الشخصي'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _nameController,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 16),
              const Text(
                'اهتماماتك',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.map((String interest) {
                  return FilterChip(
                    label: Text(interest),
                    selected: _selectedInterests.contains(interest),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
