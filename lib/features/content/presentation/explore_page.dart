import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../data/content_repository.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    required this.userId,
    this.initialCategoryName,
  });

  final String userId;
  final String? initialCategoryName;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final ContentRepository _repository = ContentRepository();
  late final Stream<List<ContentCategory>> _categories =
      _repository.watchCategories();
  late final Stream<List<ContentItem>> _content =
      _repository.watchPublishedContent();

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _selectedCategoryName = widget.initialCategoryName;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContentItem> _filterItems(
    List<ContentItem> items,
    List<ContentCategory> categories,
  ) {
    Iterable<ContentItem> filtered = items;
    final String? selectedName = _selectedCategoryName;
    if (selectedName != null) {
      String? selectedId;
      for (final ContentCategory category in categories) {
        if (category.title == selectedName) {
          selectedId = category.id;
          break;
        }
      }
      if (selectedId != null) {
        filtered = filtered.where(
          (ContentItem item) => item.categoryId == selectedId,
        );
      }
    }

    final String query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((ContentItem item) {
        return item.title.toLowerCase().contains(query) ||
            item.summary.toLowerCase().contains(query) ||
            item.tags.any((String tag) => tag.toLowerCase().contains(query));
      });
    }
    return filtered.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استكشف'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ContentCategory>>(
          stream: _categories,
          builder: (
            BuildContext context,
            AsyncSnapshot<List<ContentCategory>> categorySnapshot,
          ) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (categorySnapshot.hasError) {
              return const _ExploreMessage(
                icon: Icons.cloud_off_outlined,
                title: 'تعذر تحميل التصنيفات',
                message:
                    'تحقق من إعداد قاعدة البيانات وقواعد القراءة ثم أعد المحاولة.',
              );
            }

            final List<ContentCategory> categories =
                categorySnapshot.data ?? const <ContentCategory>[];

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن جلسة أو موضوع...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'مسح البحث',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: const Text('الكل'),
                          selected: _selectedCategoryName == null,
                          onSelected: (_) => setState(
                            () => _selectedCategoryName = null,
                          ),
                        ),
                      ),
                      ...categories.map((ContentCategory category) {
                        return Padding(
                          padding:
                              const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(category.title),
                            selected:
                                _selectedCategoryName == category.title,
                            onSelected: (_) => setState(
                              () => _selectedCategoryName =
                                  category.title,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<List<ContentItem>>(
                    stream: _content,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<ContentItem>> contentSnapshot,
                    ) {
                      if (contentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (contentSnapshot.hasError) {
                        return const _ExploreMessage(
                          icon: Icons.cloud_off_outlined,
                          title: 'تعذر تحميل المحتوى',
                          message:
                              'لم نتمكن من قراءة المحتوى المنشور. تحقق من اتصال Firestore.',
                        );
                      }

                      final List<ContentItem> items = _filterItems(
                        contentSnapshot.data ?? const <ContentItem>[],
                        categories,
                      );
                      if (items.isEmpty) {
                        return _ExploreMessage(
                          icon: Icons.auto_stories_outlined,
                          title: _searchController.text.trim().isEmpty
                              ? 'لا يوجد محتوى منشور حالياً'
                              : 'لم نعثر على نتائج',
                          message: _searchController.text.trim().isEmpty
                              ? 'ستظهر هنا الجلسات والتمارين بعد إضافتها ونشرها من لوحة الإدارة.'
                              : 'جرّب كلمات بحث أخرى أو اختر تصنيفاً مختلفاً.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final ContentItem item = items[index];
                          String categoryName = 'رُوح';
                          for (final ContentCategory category in categories) {
                            if (category.id == item.categoryId) {
                              categoryName = category.title;
                              break;
                            }
                          }

                          return _ContentTile(
                            item: item,
                            categoryName: categoryName,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      ContentDetailsPage(
                                    item: item,
                                    categoryName: categoryName,
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  const _ContentTile({
    required this.item,
    required this.categoryName,
    required this.onTap,
  });

  final ContentItem item;
  final String categoryName;
  final VoidCallback onTap;

  String get _typeLabel => switch (item.type) {
        'audio' => 'جلسة صوتية',
        'video' => 'فيديو',
        'exercise' => 'تمرين',
        _ => 'محتوى نصي',
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RoohTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: RoohTheme.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFE7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  item.type == 'exercise'
                      ? Icons.self_improvement_rounded
                      : item.type == 'video'
                          ? Icons.play_circle_outline_rounded
                          : item.type == 'audio'
                              ? Icons.headphones_rounded
                              : Icons.menu_book_outlined,
                  color: RoohTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (item.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RoohTheme.mutedInk,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      item.durationMinutes == null
                          ? '$categoryName · $_typeLabel'
                          : '$categoryName · ${item.durationMinutes} دقيقة · $_typeLabel',
                      style: const TextStyle(
                        color: RoohTheme.mutedInk,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: RoohTheme.mutedInk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentDetailsPage extends StatelessWidget {
  const ContentDetailsPage({
    super.key,
    required this.item,
    required this.categoryName,
    required this.userId,
  });

  final ContentItem item;
  final String categoryName;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final String typeLabel = switch (item.type) {
      'audio' => 'جلسة صوتية',
      'video' => 'فيديو',
      'exercise' => 'تمرين عملي',
      _ => 'محتوى نصي',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المحتوى')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                categoryName,
                style: const TextStyle(
                  color: RoohTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
              ),
              if (item.summary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  item.summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: RoohTheme.mutedInk,
                        height: 1.7,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  Chip(label: Text(typeLabel)),
                  if (item.durationMinutes != null)
                    Chip(label: Text('${item.durationMinutes} دقيقة')),
                ],
              ),
              const SizedBox(height: 18),
              _ContentUserActions(
                userId: userId,
                item: item,
              ),
              const SizedBox(height: 24),
              if (item.body.isNotEmpty)
                SelectableText(
                  item.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.9,
                      ),
                )
              else
                const _ExploreMessage(
                  icon: Icons.article_outlined,
                  title: 'تفاصيل المحتوى قيد الإعداد',
                  message:
                      'أُضيف هذا العنصر إلى المكتبة، لكن نص الجلسة لم يُنشر بعد.',
                ),
              if (item.type == 'audio' || item.type == 'video') ...<Widget>[
                const SizedBox(height: 22),
                const _ExploreMessage(
                  icon: Icons.perm_media_outlined,
                  title: 'تشغيل الوسائط غير مفعّل بعد',
                  message:
                      'نعرض حالياً البيانات النصية فقط. سيتم تفعيل الصوت والفيديو بعد اعتماد خدمة وسائط تناسب الخطة المجانية.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentUserActions extends StatefulWidget {
  const _ContentUserActions({
    required this.userId,
    required this.item,
  });

  final String userId;
  final ContentItem item;

  @override
  State<_ContentUserActions> createState() => _ContentUserActionsState();
}

class _ContentUserActionsState extends State<_ContentUserActions> {
  late final ContentRepository _repository = ContentRepository();
  bool _saving = false;

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? const Color(0xFF9B382B) : RoohTheme.primary,
      ),
    );
  }

  Future<void> _toggleSaved(bool saved) async {
    setState(() => _saving = true);
    try {
      await _repository.setSaved(
        userId: widget.userId,
        item: widget.item,
        saved: !saved,
      );
      _showMessage(
        saved ? 'تمت إزالة المحتوى من محفوظاتك.' : 'تم حفظ المحتوى في مكتبتك.',
      );
    } catch (_) {
      _showMessage('تعذر تحديث المحفوظات. حاول مرة أخرى.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markCompleted() async {
    setState(() => _saving = true);
    try {
      await _repository.markCompleted(
        userId: widget.userId,
        contentId: widget.item.id,
      );
      _showMessage('أحسنت! تم تسجيل إكمال هذا المحتوى.');
    } catch (_) {
      _showMessage('تعذر تسجيل الإنجاز. حاول مرة أخرى.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StreamBuilder<bool>(
          stream: _repository.watchSavedStatus(
            userId: widget.userId,
            contentId: widget.item.id,
          ),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final bool saved = snapshot.data ?? false;
            return OutlinedButton.icon(
              onPressed: _saving || snapshot.hasError
                  ? null
                  : () => _toggleSaved(saved),
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              ),
              label: Text(saved ? 'إزالة من المحفوظات' : 'حفظ في مكتبتي'),
            );
          },
        ),
        const SizedBox(height: 8),
        StreamBuilder<bool>(
          stream: _repository.watchCompletedStatus(
            userId: widget.userId,
            contentId: widget.item.id,
          ),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final bool completed = snapshot.data ?? false;
            return FilledButton.icon(
              onPressed: _saving || completed || snapshot.hasError
                  ? null
                  : _markCompleted,
              icon: Icon(
                completed ? Icons.check_circle_rounded : Icons.task_alt_rounded,
              ),
              label: Text(
                completed ? 'تم إكمال هذا المحتوى' : 'وضع علامة مكتمل',
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExploreMessage extends StatelessWidget {
  const _ExploreMessage({
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
            Icon(icon, size: 42, color: RoohTheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
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
