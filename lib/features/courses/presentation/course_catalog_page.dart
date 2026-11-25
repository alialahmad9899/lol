import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../data/course_repository.dart';

class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key, required this.userId});
  final String userId;

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  late final CourseRepository _repository = CourseRepository();
  late final Stream<List<Course>> _courses = _repository.watchPublishedCourses();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الكورسات')),
      body: StreamBuilder<List<Course>>(
        stream: _courses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _CourseMessage(
              title: 'تعذر تحميل الكورسات',
              message: 'تحقق من إعداد Firestore وقواعد القراءة ثم حاول مجدداً.',
              icon: Icons.cloud_off_outlined,
            );
          }
          final courses = snapshot.data ?? const <Course>[];
          if (courses.isEmpty) {
            return const _CourseMessage(
              title: 'لا توجد كورسات منشورة بعد',
              message: 'ستظهر الدورات هنا بعد إضافتها ونشرها من لوحة الإدارة.',
              icon: Icons.school_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = courses[index];
              return _CourseCard(
                course: course,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CourseDetailsPage(
                      course: course,
                      userId: widget.userId,
                      repository: _repository,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CourseDetailsPage extends StatefulWidget {
  const CourseDetailsPage({
    super.key,
    required this.course,
    required this.userId,
    required this.repository,
  });
  final Course course;
  final String userId;
  final CourseRepository repository;

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  bool _busy = false;

  void _message(String value, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: error ? const Color(0xFF9B382B) : RoohTheme.primary,
      ),
    );
  }

  Future<void> _enroll() async {
    setState(() => _busy = true);
    try {
      await widget.repository.enrollInFreeCourse(
        userId: widget.userId,
        course: widget.course,
      );
      _message('تم تسجيلك في الكورس المجاني بنجاح.');
    } catch (_) {
      _message('تعذر التسجيل. تأكد أن الدورة مجانية ومنشورة.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الكورس')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: widget.repository.watchEnrollment(
          userId: widget.userId,
          courseId: course.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _CourseMessage(
              title: 'تعذر التحقق من التسجيل',
              message: 'تحقق من نشر قواعد قاعدة البيانات ثم أعد المحاولة.',
              icon: Icons.cloud_off_outlined,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final enrollment = snapshot.data?.data();
          final enrolled = enrollment != null && enrollment['status'] == 'active';
          final progress = enrollment?['progressPercent'] is int
              ? enrollment!['progressPercent'] as int
              : 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: <Color>[Color(0xFF88745D), Color(0xFF6E7866)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      course.isFree ? 'كورس مجاني' : 'كورس مدفوع',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (course.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        course.summary,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  Chip(label: Text(course.level)),
                  if (course.durationMinutes != null)
                    Chip(label: Text('${course.durationMinutes} دقيقة')),
                  Chip(
                    label: Text(
                      course.isFree
                          ? 'مجاني'
                          : '${course.price} ${course.currency}',
                    ),
                  ),
                ],
              ),
              if (course.instructorName.isNotEmpty)
                Text(
                  'تقديم: ${course.instructorName}',
                  style: const TextStyle(color: RoohTheme.mutedInk),
                ),
              if (course.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                Text(
                  course.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
                ),
              ],
              const SizedBox(height: 22),
              if (enrolled) ...<Widget>[
                const Text('تقدمك في الكورس'),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 100) / 100,
                    minHeight: 9,
                  ),
                ),
                const SizedBox(height: 6),
                Text('$progress% مكتمل'),
              ] else if (course.canEnrollForFree)
                FilledButton.icon(
                  onPressed: _busy ? null : _enroll,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.school_outlined),
                  label: Text(_busy ? 'جارٍ التسجيل...' : 'التحق بالكورس مجاناً'),
                )
              else
                const _CourseMessage(
                  title: 'هذا الكورس يتطلب اعتماداً من الإدارة',
                  message: 'بعد إتمام الدفع المعتمد، ستفعّل الإدارة وصولك إلى الدروس.',
                  icon: Icons.lock_outline_rounded,
                ),
              const SizedBox(height: 24),
              Text(
                'محتوى الكورس',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (!enrolled)
                const _CourseMessage(
                  title: 'الدروس مقفلة حالياً',
                  message: 'سجّل في الكورس المجاني أو انتظر اعتماد الإدارة للكورس المدفوع.',
                  icon: Icons.lock_outline_rounded,
                )
              else
                _CourseLessons(
                  course: course,
                  userId: widget.userId,
                  repository: widget.repository,
                  completedIds: _completedIds(enrollment),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CourseLessons extends StatelessWidget {
  const _CourseLessons({
    required this.course,
    required this.userId,
    required this.repository,
    required this.completedIds,
  });
  final Course course;
  final String userId;
  final CourseRepository repository;
  final Set<String> completedIds;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CourseLesson>>(
      stream: repository.watchLessons(course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _CourseMessage(
            title: 'تعذر تحميل الدروس',
            message: 'تحقق من صلاحيات الدورة والاتصال.',
            icon: Icons.cloud_off_outlined,
          );
        }
        final lessons = snapshot.data ?? const <CourseLesson>[];
        if (lessons.isEmpty) {
          return const _CourseMessage(
            title: 'لم تتم إضافة الدروس بعد',
            message: 'ستظهر الدروس هنا بعد إضافتها من لوحة الإدارة.',
            icon: Icons.menu_book_outlined,
          );
        }
        return Column(
          children: lessons.asMap().entries.map((entry) {
            final lesson = entry.value;
            final complete = completedIds.contains(lesson.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _LessonTile(
                number: entry.key + 1,
                lesson: lesson,
                complete: complete,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CourseLessonPage(
                      course: course,
                      lesson: lesson,
                      userId: userId,
                      repository: repository,
                      totalLessons: lessons.length,
                      initiallyComplete: complete,
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class CourseLessonPage extends StatefulWidget {
  const CourseLessonPage({
    super.key,
    required this.course,
    required this.lesson,
    required this.userId,
    required this.repository,
    required this.totalLessons,
    required this.initiallyComplete,
  });
  final Course course;
  final CourseLesson lesson;
  final String userId;
  final CourseRepository repository;
  final int totalLessons;
  final bool initiallyComplete;

  @override
  State<CourseLessonPage> createState() => _CourseLessonPageState();
}

class _CourseLessonPageState extends State<CourseLessonPage> {
  late bool _complete = widget.initiallyComplete;
  bool _saving = false;

  Future<void> _markComplete() async {
    setState(() => _saving = true);
    try {
      await widget.repository.markLessonCompleted(
        userId: widget.userId,
        courseId: widget.course.id,
        lessonId: widget.lesson.id,
        totalLessons: widget.totalLessons,
      );
      if (mounted) {
        setState(() => _complete = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ إنجاز الدرس.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ التقدم. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isText = lesson.type == 'text' || lesson.type == 'exercise';
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.course.title,
                style: const TextStyle(
                  color: RoohTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lesson.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (lesson.summary.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  lesson.summary,
                  style: const TextStyle(color: RoohTheme.mutedInk, height: 1.7),
                ),
              ],
              const SizedBox(height: 22),
              if (isText)
                SelectableText(
                  lesson.body.isEmpty ? 'لم يُضف نص هذا الدرس بعد.' : lesson.body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.9),
                )
              else
                const _CourseMessage(
                  title: 'تشغيل الوسائط غير مفعّل حالياً',
                  message: 'تم تأجيل الصوت والفيديو حتى اعتماد خدمة وسائط مجانية مناسبة.',
                  icon: Icons.perm_media_outlined,
                ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _complete || _saving ? null : _markComplete,
                icon: Icon(
                  _complete ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                ),
                label: Text(
                  _saving
                      ? 'جارٍ حفظ التقدم...'
                      : _complete
                          ? 'تم إكمال هذا الدرس'
                          : 'وضع علامة مكتمل',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});
  final Course course;
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: RoohTheme.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_outlined, color: RoohTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(course.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (course.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        course.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RoohTheme.mutedInk,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      course.isFree
                          ? 'مجاني · ${course.level}'
                          : '${course.price} ${course.currency} · ${course.level}',
                      style: const TextStyle(
                        color: RoohTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.number,
    required this.lesson,
    required this.complete,
    required this.onTap,
  });
  final int number;
  final CourseLesson lesson;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RoohTheme.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: RoohTheme.border),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFECEFE7),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: RoohTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (lesson.durationMinutes != null)
                      Text(
                        '${lesson.durationMinutes} دقيقة',
                        style: const TextStyle(
                          color: RoohTheme.mutedInk,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                complete ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                color: complete ? const Color(0xFF66805B) : RoohTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseMessage extends StatelessWidget {
  const _CourseMessage({
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
        padding: const EdgeInsets.all(22),
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

Set<String> _completedIds(Map<String, dynamic>? enrollment) {
  final Object? rawIds = enrollment?['completedLessonIds'];
  if (rawIds is! List) return <String>{};
  return rawIds.whereType<String>().toSet();
}
