import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../data/content_repository.dart';
import 'explore_page.dart';

class ContentLibraryPage extends StatefulWidget {
  const ContentLibraryPage({super.key, required this.userId});

  final String userId;

  @override
  State<ContentLibraryPage> createState() => _ContentLibraryPageState();
}

class _ContentLibraryPageState extends State<ContentLibraryPage> {
  late final ContentRepository _repository = ContentRepository();
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final Stream<List<String>> contentIds = _showCompleted
        ? _repository.watchCompletedContentIds(widget.userId)
        : _repository.watchSavedContentIds(widget.userId);

    return Scaffold(
      appBar: AppBar(title: const Text('مكتبتي')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ChoiceChip(
                    label: const Text('المحفوظات'),
                    selected: !_showCompleted,
                    onSelected: (_) => setState(() => _showCompleted = false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('المكتمل'),
                    selected: _showCompleted,
                    onSelected: (_) => setState(() => _showCompleted = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: contentIds,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LibraryMessage(
                    title: 'تعذر تحميل مكتبتك',
                    message:
                        'تحقق من إعداد Firestore وقواعد الوصول ثم أعد المحاولة.',
                    icon: Icons.cloud_off_outlined,
                  );
                }

                final List<String> ids =
                    snapshot.data ?? const <String>[];
                if (ids.isEmpty) {
                  return _LibraryMessage(
                    title: _showCompleted
                        ? 'لم تكمل أي محتوى بعد'
                        : 'مكتبتك فارغة حالياً',
                    message: _showCompleted
                        ? 'عندما تنهي جلسة أو تمريناً، سيظهر هنا.'
                        : 'احفظ الجلسات والتمارين التي تريد العودة إليها لاحقاً.',
                    icon: _showCompleted
                        ? Icons.task_alt_rounded
                        : Icons.bookmark_border_rounded,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  itemCount: ids.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final String contentId = ids[index];
                    return FutureBuilder<ContentItem?>(
                      future: _repository.fetchPublishedItem(contentId),
                      builder: (context, itemSnapshot) {
                        if (itemSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        final ContentItem? item = itemSnapshot.data;
                        if (item == null) return const SizedBox.shrink();

                        return _LibraryContentCard(
                          item: item,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ContentDetailsPage(
                                item: item,
                                categoryName: 'مكتبتي',
                                userId: widget.userId,
                              ),
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
      ),
    );
  }
}

class _LibraryContentCard extends StatelessWidget {
  const _LibraryContentCard({
    required this.item,
    required this.onTap,
  });

  final ContentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RoohTheme.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: RoohTheme.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: RoohTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
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
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
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

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
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
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: RoohTheme.primary),
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
