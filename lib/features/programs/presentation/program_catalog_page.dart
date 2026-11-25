import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../data/program_repository.dart';

class ProgramCatalogPage extends StatefulWidget {
  const ProgramCatalogPage({super.key, required this.userId});
  final String userId;

  @override
  State<ProgramCatalogPage> createState() => _ProgramCatalogPageState();
}

class _ProgramCatalogPageState extends State<ProgramCatalogPage> {
  late final ProgramRepository _repository = ProgramRepository();
  late final Stream<List<RoohProgram>> _programs =
      _repository.watchPublishedPrograms();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البرامج والتحديات')),
      body: StreamBuilder<List<RoohProgram>>(
        stream: _programs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ProgramMessage(
              title: 'تعذر تحميل البرامج',
              message: 'تحقق من إعداد Firestore وقواعد القراءة ثم حاول مجدداً.',
              icon: Icons.cloud_off_outlined,
            );
          }
          final programs = snapshot.data ?? const <RoohProgram>[];
          if (programs.isEmpty) {
            return const _ProgramMessage(
              title: 'لا توجد برامج منشورة حالياً',
              message: 'ستظهر هنا التحديات والبرامج بعد إضافتها من لوحة الإدارة.',
              icon: Icons.flag_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: programs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final program = programs[index];
              return _ProgramCard(
                program: program,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProgramDetailsPage(
                      program: program,
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

class ProgramDetailsPage extends StatefulWidget {
  const ProgramDetailsPage({
    super.key,
    required this.program,
    required this.userId,
    required this.repository,
  });
  final RoohProgram program;
  final String userId;
  final ProgramRepository repository;

  @override
  State<ProgramDetailsPage> createState() => _ProgramDetailsPageState();
}

class _ProgramDetailsPageState extends State<ProgramDetailsPage> {
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
      await widget.repository.enrollInFreeProgram(
        userId: widget.userId,
        program: widget.program,
      );
      _message('تم تسجيلك في البرنامج بنجاح.');
    } catch (_) {
      _message('تعذر التسجيل. تأكد أن البرنامج مجاني ومنشور.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل البرنامج')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: widget.repository.watchEnrollment(
          userId: widget.userId,
          programId: program.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _ProgramMessage(
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
                      program.isFree ? 'برنامج مجاني' : 'برنامج مدفوع',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      program.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (program.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        program.summary,
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
                  if (program.durationDays > 0)
                    Chip(label: Text('${program.durationDays} أيام')),
                  Chip(
                    label: Text(
                      program.isFree
                          ? 'مجاني'
                          : '${program.price} ${program.currency}',
                    ),
                  ),
                ],
              ),
              if (program.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  program.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                      ),
                ),
              ],
              const SizedBox(height: 22),
              if (enrolled) ...<Widget>[
                const Text('تقدمك في البرنامج'),
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
              ] else if (program.canEnrollForFree)
                FilledButton.icon(
                  onPressed: _busy ? null : _enroll,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.flag_outlined),
                  label: Text(_busy ? 'جارٍ التسجيل...' : 'ابدأ البرنامج مجاناً'),
                )
              else
                const _ProgramMessage(
                  title: 'هذا البرنامج يتطلب اعتماداً من الإدارة',
                  message: 'بعد إتمام الدفع المعتمد، ستفعّل الإدارة وصولك إلى مهام البرنامج.',
                  icon: Icons.lock_outline_rounded,
                ),
              const SizedBox(height: 24),
              Text(
                'مراحل البرنامج',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              if (!enrolled)
                const _ProgramMessage(
                  title: 'المهام مقفلة حالياً',
                  message: 'سجّل في البرنامج المجاني أو انتظر اعتماد الإدارة للبرنامج المدفوع.',
                  icon: Icons.lock_outline_rounded,
                )
              else
                _ProgramDays(
                  program: program,
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

class _ProgramDays extends StatelessWidget {
  const _ProgramDays({
    required this.program,
    required this.userId,
    required this.repository,
    required this.completedIds,
  });
  final RoohProgram program;
  final String userId;
  final ProgramRepository repository;
  final Set<String> completedIds;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProgramDay>>(
      stream: repository.watchDays(program.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _ProgramMessage(
            title: 'تعذر تحميل المهام',
            message: 'تحقق من صلاحيات البرنامج والاتصال.',
            icon: Icons.cloud_off_outlined,
          );
        }
        final days = snapshot.data ?? const <ProgramDay>[];
        if (days.isEmpty) {
          return const _ProgramMessage(
            title: 'لم تتم إضافة المهام بعد',
            message: 'ستظهر مهام البرنامج هنا بعد إضافتها من لوحة الإدارة.',
            icon: Icons.event_note_outlined,
          );
        }
        return Column(
          children: days.asMap().entries.map((entry) {
            final day = entry.value;
            final complete = completedIds.contains(day.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ProgramDayTile(
                number: day.dayNumber > 0 ? day.dayNumber : entry.key + 1,
                day: day,
                complete: complete,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProgramDayPage(
                      program: program,
                      day: day,
                      userId: userId,
                      repository: repository,
                      totalDays: days.length,
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

class ProgramDayPage extends StatefulWidget {
  const ProgramDayPage({
    super.key,
    required this.program,
    required this.day,
    required this.userId,
    required this.repository,
    required this.totalDays,
    required this.initiallyComplete,
  });
  final RoohProgram program;
  final ProgramDay day;
  final String userId;
  final ProgramRepository repository;
  final int totalDays;
  final bool initiallyComplete;

  @override
  State<ProgramDayPage> createState() => _ProgramDayPageState();
}

class _ProgramDayPageState extends State<ProgramDayPage> {
  late bool _complete = widget.initiallyComplete;
  bool _saving = false;

  Future<void> _markComplete() async {
    setState(() => _saving = true);
    try {
      await widget.repository.markDayCompleted(
        userId: widget.userId,
        programId: widget.program.id,
        dayId: widget.day.id,
        totalDays: widget.totalDays,
      );
      if (mounted) {
        setState(() => _complete = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ إنجاز اليوم.')),
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
    final day = widget.day;
    return Scaffold(
      appBar: AppBar(title: const Text('مهمة اليوم')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.program.title,
                style: const TextStyle(
                  color: RoohTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                day.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (day.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  day.description,
                  style: const TextStyle(color: RoohTheme.mutedInk, height: 1.7),
                ),
              ],
              const SizedBox(height: 22),
              SelectableText(
                day.body.isEmpty ? 'لم تتم إضافة تفاصيل المهمة بعد.' : day.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.9),
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
                          ? 'تم إكمال هذا اليوم'
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

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.onTap});
  final RoohProgram program;
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.flag_outlined, color: RoohTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(program.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (program.summary.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        program.summary,
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
                      program.isFree
                          ? 'مجاني · ${program.durationDays} أيام'
                          : '${program.price} ${program.currency}',
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

class _ProgramDayTile extends StatelessWidget {
  const _ProgramDayTile({
    required this.number,
    required this.day,
    required this.complete,
    required this.onTap,
  });
  final int number;
  final ProgramDay day;
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
                child: Text(day.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Icon(
                complete ? Icons.check_circle_rounded : Icons.chevron_left_rounded,
                color: complete ? const Color(0xFF66805B) : RoohTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramMessage extends StatelessWidget {
  const _ProgramMessage({
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
  final Object? rawIds = enrollment?['completedDayIds'];
  if (rawIds is! List) return <String>{};
  return rawIds.whereType<String>().toSet();
}
