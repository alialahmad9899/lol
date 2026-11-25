import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../data/admin_repository.dart';

enum _AdminFieldKind {
  text,
  multiline,
  integer,
  decimal,
  boolean,
  choice,
  stringList,
}

class _AdminFieldSpec {
  const _AdminFieldSpec(
    this.key,
    this.label, {
    this.kind = _AdminFieldKind.text,
    this.required = false,
    this.defaultValue,
    this.options = const <String>[],
  });

  final String key;
  final String label;
  final _AdminFieldKind kind;
  final bool required;
  final Object? defaultValue;
  final List<String> options;
}

class _AdminSectionSpec {
  const _AdminSectionSpec({
    required this.title,
    required this.description,
    required this.collectionPath,
    required this.fields,
    this.hasStatus = false,
    this.childCollection,
    this.childTitle,
    this.childFields,
  });

  final String title;
  final String description;
  final String collectionPath;
  final List<_AdminFieldSpec> fields;
  final bool hasStatus;
  final String? childCollection;
  final String? childTitle;
  final List<_AdminFieldSpec>? childFields;
}

const _categoryFields = <_AdminFieldSpec>[
  _AdminFieldSpec('title', 'اسم التصنيف', required: true),
  _AdminFieldSpec('description', 'الوصف', kind: _AdminFieldKind.multiline),
  _AdminFieldSpec('sortOrder', 'ترتيب العرض',
      kind: _AdminFieldKind.integer, defaultValue: 0),
];

const _contentFields = <_AdminFieldSpec>[
  _AdminFieldSpec('title', 'عنوان المحتوى', required: true),
  _AdminFieldSpec('summary', 'وصف مختصر'),
  _AdminFieldSpec('body', 'النص الكامل', kind: _AdminFieldKind.multiline),
  _AdminFieldSpec('categoryId', 'معرّف التصنيف', required: true),
  _AdminFieldSpec('type', 'نوع المحتوى',
      kind: _AdminFieldKind.choice,
      defaultValue: 'text',
      options: <String>['text', 'exercise', 'audio', 'video']),
  _AdminFieldSpec('durationMinutes', 'المدة بالدقائق',
      kind: _AdminFieldKind.integer, defaultValue: 0),
  _AdminFieldSpec('tags', 'وسوم البحث (افصل بينها بفاصلة)',
      kind: _AdminFieldKind.stringList),
  _AdminFieldSpec('sortOrder', 'ترتيب العرض',
      kind: _AdminFieldKind.integer, defaultValue: 0),
  _AdminFieldSpec('status', 'حالة النشر',
      kind: _AdminFieldKind.choice,
      defaultValue: 'draft',
      options: <String>['draft', 'published']),
];

const _courseFields = <_AdminFieldSpec>[
  _AdminFieldSpec('title', 'اسم الكورس', required: true),
  _AdminFieldSpec('summary', 'وصف مختصر'),
  _AdminFieldSpec('description', 'الوصف التفصيلي',
      kind: _AdminFieldKind.multiline),
  _AdminFieldSpec('instructorName', 'اسم المدرب'),
  _AdminFieldSpec('level', 'المستوى', defaultValue: 'عام'),
  _AdminFieldSpec('durationMinutes', 'المدة بالدقائق',
      kind: _AdminFieldKind.integer, defaultValue: 0),
  _AdminFieldSpec('price', 'السعر (0 للمجاني)',
      kind: _AdminFieldKind.decimal, defaultValue: 0),
  _AdminFieldSpec('currency', 'العملة', defaultValue: 'USD'),
  _AdminFieldSpec('isFree', 'كورس مجاني',
      kind: _AdminFieldKind.boolean, defaultValue: true),
  _AdminFieldSpec('sortOrder', 'ترتيب العرض',
      kind: _AdminFieldKind.integer, defaultValue: 0),
  _AdminFieldSpec('status', 'حالة النشر',
      kind: _AdminFieldKind.choice,
      defaultValue: 'draft',
      options: <String>['draft', 'published']),
];

const _lessonFields = <_AdminFieldSpec>[
  _AdminFieldSpec('title', 'عنوان الدرس', required: true),
  _AdminFieldSpec('summary', 'وصف مختصر'),
  _AdminFieldSpec('body', 'نص الدرس', kind: _AdminFieldKind.multiline),
  _AdminFieldSpec('type', 'نوع الدرس',
      kind: _AdminFieldKind.choice,
      defaultValue: 'text',
      options: <String>['text', 'exercise', 'audio', 'video']),
  _AdminFieldSpec('durationMinutes', 'المدة بالدقائق',
      kind: _AdminFieldKind.integer, defaultValue: 0),
  _AdminFieldSpec('sortOrder', 'ترتيب الدرس',
      kind: _AdminFieldKind.integer, defaultValue: 0),
];

const _programFields = <_AdminFieldSpec>[
  _AdminFieldSpec('title', 'اسم البرنامج', required: true),
  _AdminFieldSpec('summary', 'وصف مختصر'),
  _AdminFieldSpec('description', 'الوصف التفصيلي',
      kind: _AdminFieldKind.multiline),
  _AdminFieldSpec('durationDays', 'عدد الأيام',
      kind: _AdminFieldKind.integer, defaultValue: 7, required: true),
  _AdminFieldSpec('price', 'السعر (0 للمجاني)',
      kind: _AdminFieldKind.decimal, defaultValue: 0),
  _AdminFieldSpec('currency', 'العملة', defaultValue: 'USD'),
  _AdminFieldSpec('isFree', 'برنامج مجاني',
      kind: _AdminFieldKind.boolean, defaultValue: true),
  _AdminFieldSpec('sortOrder', 'ترتيب العرض',
      kind: _AdminFieldKind.integer, defaultValue: 0),
  _AdminFieldSpec('status', 'حالة النشر',
      kind: _AdminFieldKind.choice,
      defaultValue: 'draft',
      options: <String>['draft', 'published']),
];

const _programDayFields = <_AdminFieldSpec>[
  _AdminFieldSpec('dayNumber', 'رقم اليوم',
      kind: _AdminFieldKind.integer, required: true, defaultValue: 1),
  _AdminFieldSpec('title', 'عنوان المهمة', required: true),
  _AdminFieldSpec('description', 'وصف مختصر'),
  _AdminFieldSpec('body', 'تفاصيل المهمة', kind: _AdminFieldKind.multiline),
  _AdminFieldSpec('sortOrder', 'ترتيب اليوم',
      kind: _AdminFieldKind.integer, defaultValue: 0),
];

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.userId});
  final String userId;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final Future<bool> _adminCheck =
      AdminRepository().isAdmin(widget.userId);

  static const List<_AdminSectionSpec> _sections = <_AdminSectionSpec>[
    _AdminSectionSpec(
      title: 'التصنيفات',
      description: 'إنشاء تصنيفات الوعي والاسترخاء والتركيز وغيرها',
      collectionPath: 'categories',
      fields: _categoryFields,
    ),
    _AdminSectionSpec(
      title: 'المحتوى والجلسات',
      description: 'إضافة النصوص والتمارين والجلسات',
      collectionPath: 'content_items',
      fields: _contentFields,
      hasStatus: true,
    ),
    _AdminSectionSpec(
      title: 'الكورسات',
      description: 'إدارة الدورات وإضافة الدروس التابعة لها',
      collectionPath: 'courses',
      fields: _courseFields,
      hasStatus: true,
      childCollection: 'lessons',
      childTitle: 'دروس الكورس',
      childFields: _lessonFields,
    ),
    _AdminSectionSpec(
      title: 'البرامج والتحديات',
      description: 'إدارة البرامج وأيام التحديات ومهامها',
      collectionPath: 'programs',
      fields: _programFields,
      hasStatus: true,
      childCollection: 'days',
      childTitle: 'أيام البرنامج',
      childFields: _programDayFields,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data != true) {
          return const Scaffold(
            body: _AdminMessage(
              title: 'لا تملك صلاحية الدخول',
              message: 'هذه الصفحة متاحة لحسابات الإدارة المعتمدة فقط.',
              icon: Icons.lock_outline_rounded,
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('لوحة إدارة رُوح')),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'مرحباً بك في إدارة رُوح',
                      style: TextStyle(
                        color: RoohTheme.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'أضف المحتوى والدورات والبرامج، ثم انشرها لتظهر للمستخدمين.',
                      style: TextStyle(
                        color: RoohTheme.mutedInk,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ..._sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdminSectionCard(
                    spec: section,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _AdminRecordsPage(spec: section),
                      ),
                    ),
                  ),
                ),
              ),
              const _AdminMessage(
                title: 'الوسائط والبث والدفع الإلكتروني',
                message:
                    'رفع الملفات والصوت والفيديو والبث المباشر وبوابات الدفع ليست مفعّلة في النسخة المجانية الحالية.',
                icon: Icons.info_outline_rounded,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminRecordsPage extends StatefulWidget {
  const _AdminRecordsPage({
    super.key,
    required this.spec,
    this.collectionPath,
    this.title,
  });

  final _AdminSectionSpec spec;
  final String? collectionPath;
  final String? title;

  @override
  State<_AdminRecordsPage> createState() => __AdminRecordsPageState();
}

class __AdminRecordsPageState extends State<_AdminRecordsPage> {
  late final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(
    widget.collectionPath ?? widget.spec.collectionPath,
  );

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFF9B382B) : RoohTheme.primary,
      ),
    );
  }

  Future<Map<String, dynamic>?> _editDialog({
    Map<String, dynamic> initialData = const <String, dynamic>{},
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AdminEditorDialog(
        title: initialData.isEmpty ? 'إضافة سجل جديد' : 'تعديل السجل',
        fields: widget.spec.fields,
        initialData: initialData,
      ),
    );
  }

  void _validatePricing(Map<String, dynamic> data) {
    if (!data.containsKey('isFree') || !data.containsKey('price')) return;
    final bool isFree = data['isFree'] == true;
    final Object? rawPrice = data['price'];
    final num price = rawPrice is num ? rawPrice : -1;
    if (isFree && price != 0) {
      throw StateError('السجل المجاني يجب أن يكون سعره صفراً.');
    }
    if (!isFree && price <= 0) {
      throw StateError('أدخل سعراً أكبر من صفر للسجل المدفوع.');
    }
  }

  Future<void> _addRecord() async {
    final Map<String, dynamic>? data = await _editDialog();
    if (data == null) return;

    try {
      _validatePricing(data);
      await _collection.add(<String, dynamic>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showMessage('تمت إضافة السجل.');
    } catch (_) {
      _showMessage('تعذرت الإضافة. تحقق من الحقول والصلاحيات.', error: true);
    }
  }

  Future<void> _updateRecord(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic>? data = await _editDialog(
      initialData: document.data() ?? const <String, dynamic>{},
    );
    if (data == null) return;

    try {
      _validatePricing(data);
      await document.reference.update(<String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showMessage('تم حفظ التعديلات.');
    } catch (_) {
      _showMessage('تعذر حفظ التعديلات. تحقق من الحقول والصلاحيات.', error: true);
    }
  }

  Future<void> _toggleStatus(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final String currentStatus = document.data()?['status'] is String
        ? document.data()!['status'] as String
        : 'draft';
    final String nextStatus =
        currentStatus == 'published' ? 'draft' : 'published';
    try {
      await document.reference.update(<String, Object>{
        'status': nextStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showMessage(
        nextStatus == 'published' ? 'تم نشر المحتوى.' : 'تم إلغاء النشر.',
      );
    } catch (_) {
      _showMessage('تعذر تغيير حالة النشر.', error: true);
    }
  }

  void _openChildren(DocumentSnapshot<Map<String, dynamic>> document) {
    final String? childCollection = widget.spec.childCollection;
    final List<_AdminFieldSpec>? childFields = widget.spec.childFields;
    if (childCollection == null || childFields == null) return;

    final _AdminSectionSpec childSpec = _AdminSectionSpec(
      title: widget.spec.childTitle ?? 'العناصر التابعة',
      description: '',
      collectionPath: '',
      fields: childFields,
    );
    final String parentTitle = document.data()?['title']?.toString() ??
        document.id;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AdminRecordsPage(
          spec: childSpec,
          collectionPath: widget.spec.collectionPath +
              '/' +
              document.id +
              '/' +
              childCollection,
          title: (widget.spec.childTitle ?? 'العناصر التابعة') +
              ': ' +
              parentTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? widget.spec.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'إضافة',
            onPressed: _addRecord,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _collection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _AdminMessage(
              title: 'تعذر تحميل السجلات',
              message: 'تحقق من صلاحيات الإدارة واتصال قاعدة البيانات.',
              icon: Icons.cloud_off_outlined,
            );
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> records =
              snapshot.data?.docs.toList(growable: true) ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          records.sort((first, second) {
            final Object? firstOrder = first.data()['sortOrder'];
            final Object? secondOrder = second.data()['sortOrder'];
            final num firstValue = firstOrder is num ? firstOrder : 0;
            final num secondValue = secondOrder is num ? secondOrder : 0;
            return firstValue.compareTo(secondValue);
          });

          if (records.isEmpty) {
            return _AdminMessage(
              title: 'لا توجد سجلات بعد',
              message:
                  'استخدم زر الإضافة لإنشاء أول سجل في ' + widget.spec.title + '.',
              icon: Icons.inbox_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final document = records[index];
              final Map<String, dynamic> data = document.data();
              final String recordTitle = data['title'] is String
                  ? data['title'] as String
                  : document.id;
              final String status = data['status'] is String
                  ? data['status'] as String
                  : '';

              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: RoohTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: RoohTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            recordTitle,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'تعديل',
                          onPressed: () => _updateRecord(document),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    if (status.isNotEmpty)
                      Text(
                        status == 'published' ? 'منشور' : 'مسودة',
                        style: const TextStyle(
                          color: RoohTheme.mutedInk,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        if (widget.spec.hasStatus)
                          OutlinedButton.icon(
                            onPressed: () => _toggleStatus(document),
                            icon: Icon(
                              status == 'published'
                                  ? Icons.visibility_off_outlined
                                  : Icons.publish_outlined,
                            ),
                            label: Text(
                              status == 'published' ? 'إلغاء النشر' : 'نشر',
                            ),
                          ),
                        if (widget.spec.childCollection != null)
                          OutlinedButton.icon(
                            onPressed: () => _openChildren(document),
                            icon: const Icon(Icons.account_tree_outlined),
                            label: Text(
                              widget.spec.childTitle ?? 'إدارة العناصر التابعة',
                            ),
                          ),
                      ],
                    ),
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

class _AdminEditorDialog extends StatefulWidget {
  const _AdminEditorDialog({
    required this.title,
    required this.fields,
    required this.initialData,
  });

  final String title;
  final List<_AdminFieldSpec> fields;
  final Map<String, dynamic> initialData;

  @override
  State<_AdminEditorDialog> createState() => _AdminEditorDialogState();
}

class _AdminEditorDialogState extends State<_AdminEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{
    for (final _AdminFieldSpec field in widget.fields)
      if (field.kind != _AdminFieldKind.boolean &&
          field.kind != _AdminFieldKind.choice)
        field.key: TextEditingController(text: _initialText(field)),
  };

  late final Map<String, bool> _booleans = <String, bool>{
    for (final _AdminFieldSpec field in widget.fields)
      if (field.kind == _AdminFieldKind.boolean)
        field.key: _initialBool(field),
  };

  late final Map<String, String?> _choices = <String, String?>{
    for (final _AdminFieldSpec field in widget.fields)
      if (field.kind == _AdminFieldKind.choice)
        field.key: _initialChoice(field),
  };

  String _initialText(_AdminFieldSpec field) {
    final Object? value = widget.initialData[field.key] ?? field.defaultValue;
    if (value == null) return '';
    if (value is List) return value.whereType<String>().join(', ');
    return value.toString();
  }

  bool _initialBool(_AdminFieldSpec field) {
    return (widget.initialData[field.key] ?? field.defaultValue) == true;
  }

  String? _initialChoice(_AdminFieldSpec field) {
    final Object? value = widget.initialData[field.key] ?? field.defaultValue;
    if (value is! String) return null;
    return field.options.contains(value) ? value : null;
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(_AdminFieldSpec field, String? value) {
    final String normalized = (value ?? '').trim();
    if (field.required && normalized.isEmpty) return 'هذا الحقل مطلوب.';
    if (normalized.isEmpty) return null;
    if (field.kind == _AdminFieldKind.integer &&
        int.tryParse(normalized) == null) {
      return 'أدخل رقماً صحيحاً.';
    }
    if (field.kind == _AdminFieldKind.decimal &&
        num.tryParse(normalized) == null) {
      return 'أدخل رقماً صالحاً.';
    }
    return null;
  }

  Map<String, dynamic>? _collect() {
    if (!_formKey.currentState!.validate()) return null;
    final Map<String, dynamic> result = <String, dynamic>{};

    for (final _AdminFieldSpec field in widget.fields) {
      switch (field.kind) {
        case _AdminFieldKind.boolean:
          result[field.key] = _booleans[field.key] ?? false;
          break;
        case _AdminFieldKind.choice:
          final String? value = _choices[field.key];
          if (field.required && value == null) return null;
          if (value != null) result[field.key] = value;
          break;
        case _AdminFieldKind.integer:
          final String value = _controllers[field.key]!.text.trim();
          result[field.key] = value.isEmpty ? null : int.parse(value);
          break;
        case _AdminFieldKind.decimal:
          final String value = _controllers[field.key]!.text.trim();
          result[field.key] = value.isEmpty ? null : num.parse(value);
          break;
        case _AdminFieldKind.stringList:
          result[field.key] = _controllers[field.key]!.text
              .split(',')
              .map((String item) => item.trim())
              .where((String item) => item.isNotEmpty)
              .toList(growable: false);
          break;
        case _AdminFieldKind.text:
        case _AdminFieldKind.multiline:
          final String value = _controllers[field.key]!.text.trim();
          result[field.key] = value;
          break;
      }
    }
    return result;
  }

  Widget _buildField(_AdminFieldSpec field) {
    switch (field.kind) {
      case _AdminFieldKind.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.label),
          value: _booleans[field.key] ?? false,
          onChanged: (bool value) =>
              setState(() => _booleans[field.key] = value),
        );
      case _AdminFieldKind.choice:
        return DropdownButtonFormField<String>(
          initialValue: _choices[field.key],
          decoration: InputDecoration(labelText: field.label),
          items: field.options
              .map(
                (String option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(_choiceLabel(option)),
                ),
              )
              .toList(growable: false),
          onChanged: (String? value) =>
              setState(() => _choices[field.key] = value),
          validator: (String? value) =>
              field.required && value == null ? 'اختر قيمة.' : null,
        );
      case _AdminFieldKind.integer:
      case _AdminFieldKind.decimal:
        return TextFormField(
          controller: _controllers[field.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: field.label),
          validator: (String? value) => _validate(field, value),
        );
      case _AdminFieldKind.multiline:
        return TextFormField(
          controller: _controllers[field.key],
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(labelText: field.label),
          validator: (String? value) => _validate(field, value),
        );
      case _AdminFieldKind.stringList:
      case _AdminFieldKind.text:
        return TextFormField(
          controller: _controllers[field.key],
          decoration: InputDecoration(labelText: field.label),
          validator: (String? value) => _validate(field, value),
        );
    }
  }

  String _choiceLabel(String value) {
    switch (value) {
      case 'draft':
        return 'مسودة';
      case 'published':
        return 'منشور';
      case 'exercise':
        return 'تمرين';
      case 'text':
        return 'نصي';
      case 'audio':
        return 'صوتي';
      case 'video':
        return 'فيديو';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.fields
                  .map(
                    (_AdminFieldSpec field) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildField(field),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final Map<String, dynamic>? data = _collect();
            if (data != null) Navigator.of(context).pop(data);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({required this.spec, required this.onTap});
  final _AdminSectionSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RoohTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: RoohTheme.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.folder_open_outlined,
                color: RoohTheme.primary,
                size: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      spec.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spec.description,
                      style: const TextStyle(
                        color: RoohTheme.mutedInk,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded, color: RoohTheme.mutedInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMessage extends StatelessWidget {
  const _AdminMessage({
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: RoohTheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RoohTheme.mutedInk,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
