import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onSignOut});

  final Future<void> Function()? onSignOut;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final Future<void> Function()? callback = onSignOut;
    if (callback == null) {
      _showMessage(context, 'خيار الحساب غير متاح حالياً.');
      return;
    }

    try {
      await callback();
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'تعذر تسجيل الخروج. حاول مرة أخرى.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _BrandMark(),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppConstants.appName,
                  style: TextStyle(fontWeight: FontWeight.w800, height: 1.1),
                ),
                Text(
                  AppConstants.tagline,
                  style: TextStyle(
                    fontSize: 11,
                    color: RoohTheme.mutedInk,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => _handleSignOut(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'أهلاً بك في رُوح',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'امنح نفسك مساحة هادئة، وخذ خطوة صغيرة نحو حياة أكثر توازناً.',
                style: textTheme.bodyLarge?.copyWith(
                  color: RoohTheme.mutedInk,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 24),
              _WelcomeCard(
                onTap: () => _showMessage(
                  context,
                  'سنضيف جلساتك وتمارينك الأولى هنا.',
                ),
              ),
              const SizedBox(height: 30),
              const _SectionTitle(
                title: 'اكتشف مساحتك',
                subtitle: 'اختر المجال الذي تحتاجه اليوم',
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double itemWidth = (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _CategoryCard(
                        width: itemWidth,
                        title: 'وعي',
                        subtitle: 'افهم ذاتك أكثر',
                        icon: Icons.lightbulb_outline_rounded,
                        onTap: () =>
                            _showMessage(context, 'قسم الوعي قيد التجهيز.'),
                      ),
                      _CategoryCard(
                        width: itemWidth,
                        title: 'استرخاء',
                        subtitle: 'استعد هدوءك',
                        icon: Icons.spa_outlined,
                        onTap: () =>
                            _showMessage(context, 'قسم الاسترخاء قيد التجهيز.'),
                      ),
                      _CategoryCard(
                        width: itemWidth,
                        title: 'تركيز',
                        subtitle: 'كن حاضراً',
                        icon: Icons.center_focus_strong_rounded,
                        onTap: () =>
                            _showMessage(context, 'قسم التركيز قيد التجهيز.'),
                      ),
                      _CategoryCard(
                        width: itemWidth,
                        title: 'تطوير',
                        subtitle: 'نمُ بخطوات ثابتة',
                        icon: Icons.trending_up_rounded,
                        onTap: () =>
                            _showMessage(context, 'قسم التطوير قيد التجهيز.'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              const _SectionTitle(
                title: 'وقتك مع نفسك',
                subtitle: 'عادة بسيطة تصنع فرقاً مع الاستمرار',
              ),
              const SizedBox(height: 14),
              _PracticeCard(
                onTap: () => _showMessage(
                  context,
                  'سنربط هذا التمرين بمكتبة الجلسات الصوتية.',
                ),
              ),
              const SizedBox(height: 30),
              const _SectionTitle(
                title: 'الكورسات والبرامج',
                subtitle: 'مسارات عملية للتعلم والتغيير',
              ),
              const SizedBox(height: 14),
              const _ComingSoonCard(
                icon: Icons.school_outlined,
                title: 'دورات رُوح',
                description:
                    'ستظهر هنا الدورات المجانية والمدفوعة بعد ربط لوحة الإدارة.',
              ),
              const SizedBox(height: 14),
              const _ComingSoonCard(
                icon: Icons.sensors_rounded,
                title: 'البث المباشر',
                description:
                    'مواعيد الجلسات المباشرة وروابط الدخول والتنبيهات.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const BrandLogo(size: 48);
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[
            Color(0xFF88745D),
            Color(0xFF6E7866),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'رحلتك تبدأ بخطوة',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'مساحتك الهادئة تبدأ من هنا',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جلسات قصيرة وتمارين عملية تساعدك على العودة إلى نفسك.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: RoohTheme.ink,
            ),
            child: const Text('ابدأ جلسة اليوم'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: RoohTheme.mutedInk),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: RoohTheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RoohTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, color: RoohTheme.primary, size: 26),
                const SizedBox(height: 13),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RoohTheme.mutedInk,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RoohTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RoohTheme.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDE3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Color(0xFF68765F),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'لحظة تنفّس',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تمرين استرخاء قصير — 5 دقائق',
                      style: TextStyle(
                        color: RoohTheme.mutedInk,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_outline, color: RoohTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: RoohTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoohTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: RoohTheme.primary, size: 25),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: RoohTheme.mutedInk,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
