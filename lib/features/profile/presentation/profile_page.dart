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
    final String currentGoal = profile['primaryGoal'] is String
        ? profile['primaryGoal'] as String
        : '';
    final int? currentAge = profile['age'] is int ? profile['age'] as int : null;
    final String? currentGender =
        profile['gender'] is String ? profile['gender'] as String : null;
    final String currentCity =
        profile['city'] is String ? profile['city'] as String : '';
    final String currentCountry =
        profile['country'] is String ? profile['country'] as String : '';
    final String? currentContentStyle = profile['preferredContentStyle'] is String
        ? profile['preferredContentStyle'] as String
        : null;
    final int? currentDailyMinutes =
        profile['dailyTimeMinutes'] is int ? profile['dailyTimeMinutes'] as int : null;
    final String? currentPreferredTime = profile['preferredTime'] is String
        ? profile['preferredTime'] as String
        : null;

    final _ProfileEditResult? result =
        await showDialog<_ProfileEditResult>(
      context: context,
      builder: (BuildContext context) => _ProfileEditDialog(
        initialName: currentName,
        initialInterests: currentInterests,
        initialGoal: currentGoal,
        initialAge: currentAge,
        initialGender: currentGender,
        initialCity: currentCity,
        initialCountry: currentCountry,
        initialContentStyle: currentContentStyle,
        initialDailyMinutes: currentDailyMinutes,
        initialPreferredTime: currentPreferredTime,
      ),
    );
    if (result == null) return;

    try {
      await _repository.updateProfile(
        user: widget.user,
        displayName: result.displayName,
        interests: result.interests,
        primaryGoal: result.primaryGoal,
        age: result.age,
        gender: result.gender,
        city: result.city,
        country: result.country,
        preferredContentStyle: result.preferredContentStyle,
        dailyTimeMinutes: result.dailyTimeMinutes,
        preferredTime: result.preferredTime,
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
          final int? age =
              profile['age'] is int ? profile['age'] as int : null;
          final String gender = _genderLabel(profile['gender'] as String?);
          final String city =
              profile['city'] is String ? (profile['city'] as String).trim() : '';
          final String country = profile['country'] is String
              ? (profile['country'] as String).trim()
              : '';
          final String location =
              <String>[city, country].where((String item) => item.isNotEmpty).join('، ');

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
                    const Divider(height: 22),
                    _ProfileInfoRow(
                      icon: Icons.cake_outlined,
                      label: 'العمر',
                      value: age == null ? 'لم تحدد بعد' : '$age سنة',
                    ),
                    const Divider(height: 22),
                    _ProfileInfoRow(
                      icon: Icons.person_pin_outlined,
                      label: 'الجنس',
                      value: gender,
                    ),
                    const Divider(height: 22),
                    _ProfileInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'مكان السكن',
                      value: location.isEmpty ? 'لم تحدد بعد' : location,
                    ),
                    const Divider(height: 22),
                    _ProfileInfoRow(
                      icon: Icons.flag_outlined,
                      label: 'الهدف الأساسي',
                      value: profile['primaryGoal'] is String &&
                              (profile['primaryGoal'] as String).isNotEmpty
                          ? profile['primaryGoal'] as String
                          : 'لم تحدد هدفك بعد',
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
              const SizedBox(height: 16),
              _ProfileSection(
                title: 'تفضيلات رحلتك',
                child: Column(
                  children: <Widget>[
                    _ProfileInfoRow(
                      icon: Icons.menu_book_outlined,
                      label: 'نوع المحتوى المفضل',
                      value: _contentStyleLabel(
                        profile['preferredContentStyle'] as String?,
                      ),
                    ),
                    const Divider(height: 22),
                    _ProfileInfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'وقتك اليومي',
                      value: profile['dailyTimeMinutes'] is int
                          ? 'undefined دقيقة'
                          : 'لم تحدد بعد',
                    ),
                    const Divider(height: 22),
                    _ProfileInfoRow(
                      icon: Icons.wb_twilight_outlined,
                      label: 'الوقت المفضل',
                      value: _preferredTimeLabel(
                        profile['preferredTime'] as String?,
                      ),
                    ),
                  ],
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
    required this.primaryGoal,
    this.age,
    this.gender,
    this.city,
    this.country,
    this.preferredContentStyle,
    this.dailyTimeMinutes,
    this.preferredTime,
  });

  final String displayName;
  final List<String> interests;
  final String primaryGoal;
  final int? age;
  final String? gender;
  final String? city;
  final String? country;
  final String? preferredContentStyle;
  final int? dailyTimeMinutes;
  final String? preferredTime;
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({
    required this.initialName,
    required this.initialInterests,
    required this.initialGoal,
    required this.initialAge,
    required this.initialGender,
    required this.initialCity,
    required this.initialCountry,
    required this.initialContentStyle,
    required this.initialDailyMinutes,
    required this.initialPreferredTime,
  });

  final String initialName;
  final List<String> initialInterests;
  final String initialGoal;
  final int? initialAge;
  final String? initialGender;
  final String initialCity;
  final String initialCountry;
  final String? initialContentStyle;
  final int? initialDailyMinutes;
  final String? initialPreferredTime;

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
  static const List<String> _goalOptions = <String>[
    'فهم نفسي بشكل أعمق',
    'تقليل التوتر واستعادة الهدوء',
    'تحسين التركيز والانتباه',
    'بناء عادات إيجابية',
    'إحداث تغيير شخصي',
  ];

  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  late final TextEditingController _ageController =
      TextEditingController(text: widget.initialAge?.toString() ?? '');
  late final TextEditingController _cityController =
      TextEditingController(text: widget.initialCity);
  late final TextEditingController _countryController =
      TextEditingController(text: widget.initialCountry);
  late final Set<String> _selectedInterests =
      widget.initialInterests.toSet();
  String? _selectedGoal =
      widget.initialGoal.isEmpty ? null : widget.initialGoal;
  String? _selectedGender = widget.initialGender;
  String? _preferredContentStyle = widget.initialContentStyle;
  int? _dailyTimeMinutes = widget.initialDailyMinutes;
  String? _preferredTime = widget.initialPreferredTime;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _nameController.text.trim();
    if (name.isEmpty || name.length > 100) return;
    final String ageText = _ageController.text.trim();
    final int? age = ageText.isEmpty ? null : int.tryParse(ageText);
    if (ageText.isNotEmpty && (age == null || age < 13 || age > 120)) return;

    Navigator.of(context).pop(
      _ProfileEditResult(
        displayName: name,
        interests: _selectedInterests.toList(growable: false),
        primaryGoal: _selectedGoal ?? '',
        age: age,
        gender: _selectedGender,
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        preferredContentStyle: _preferredContentStyle,
        dailyTimeMinutes: _dailyTimeMinutes,
        preferredTime: _preferredTime,
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
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'العمر',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(labelText: 'الجنس'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'male', child: Text('ذكر')),
                        DropdownMenuItem(value: 'female', child: Text('أنثى')),
                        DropdownMenuItem(
                          value: 'prefer_not_to_say',
                          child: Text('أفضل عدم الإجابة'),
                        ),
                      ],
                      onChanged: (String? value) =>
                          setState(() => _selectedGender = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'المدينة',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'الدولة',
                  prefixIcon: Icon(Icons.public_outlined),
                ),
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
              const SizedBox(height: 18),
              const Text(
                'هدفك الأساسي',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goalOptions.map((String goal) {
                  return ChoiceChip(
                    label: Text(goal),
                    selected: _selectedGoal == goal,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedGoal = selected ? goal : null;
                      });
                    },
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 18),
              const Text(
                'تفضيلاتك',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('أي نوع من المحتوى تفضّل؟'),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('محتوى قصير'),
                    selected: _preferredContentStyle == 'short',
                    onSelected: (value) => setState(
                      () => _preferredContentStyle = value ? 'short' : null,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('جلسات متعمقة'),
                    selected: _preferredContentStyle == 'deep',
                    onSelected: (value) => setState(
                      () => _preferredContentStyle = value ? 'deep' : null,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('مزيج بينهما'),
                    selected: _preferredContentStyle == 'mixed',
                    onSelected: (value) => setState(
                      () => _preferredContentStyle = value ? 'mixed' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('كم دقيقة تخصص لنفسك يومياً؟'),
              Wrap(
                spacing: 8,
                children: <int>[5, 10, 15, 20, 30, 45, 60]
                    .map((minutes) => ChoiceChip(
                          label: Text('$minutes دقيقة'),
                          selected: _dailyTimeMinutes == minutes,
                          onSelected: (value) => setState(
                            () => _dailyTimeMinutes = value ? minutes : null,
                          ),
                        ))
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              const Text('متى يناسبك وقت رُوح؟'),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('الصباح'),
                    selected: _preferredTime == 'morning',
                    onSelected: (value) => setState(
                      () => _preferredTime = value ? 'morning' : null,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('المساء'),
                    selected: _preferredTime == 'evening',
                    onSelected: (value) => setState(
                      () => _preferredTime = value ? 'evening' : null,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('حسب يومي'),
                    selected: _preferredTime == 'flexible',
                    onSelected: (value) => setState(
                      () => _preferredTime = value ? 'flexible' : null,
                    ),
                  ),
                ],
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


String _genderLabel(String? value) {
  switch (value) {
    case 'male':
      return 'ذكر';
    case 'female':
      return 'أنثى';
    case 'prefer_not_to_say':
      return 'أفضل عدم الإجابة';
    default:
      return 'لم تحدد بعد';
  }
}

String _contentStyleLabel(String? value) {
  switch (value) {
    case 'short':
      return 'محتوى قصير';
    case 'deep':
      return 'جلسات متعمقة';
    case 'mixed':
      return 'مزيج بينهما';
    default:
      return 'لم تحدد بعد';
  }
}

String _preferredTimeLabel(String? value) {
  switch (value) {
    case 'morning':
      return 'الصباح';
    case 'evening':
      return 'المساء';
    case 'flexible':
      return 'حسب اليوم';
    default:
      return 'لم تحدد بعد';
  }
}
