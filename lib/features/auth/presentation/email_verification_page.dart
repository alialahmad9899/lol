import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../data/firebase_auth_repository.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.user,
    required this.repository,
  });

  final User user;
  final FirebaseAuthRepository repository;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _sending = false;
  bool _checking = false;
  String? _message;
  bool _messageIsError = false;

  void _setMessage(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = error;
    });
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await widget.repository.sendEmailVerification();
      _setMessage('أعدنا إرسال رسالة التحقق. افحص الوارد ومجلد الرسائل غير المرغوب فيها.');
    } on FirebaseAuthException catch (error) {
      final String message = switch (error.code) {
        'too-many-requests' => 'أرسلت طلبات كثيرة. انتظر قليلاً ثم حاول مجدداً.',
        'network-request-failed' => 'تعذر الاتصال بالإنترنت. تحقق من الشبكة.',
        'user-not-found' => 'لم نعد نعثر على هذا الحساب. سجّل الدخول مجدداً.',
        _ => 'تعذر إرسال رسالة التحقق حالياً. حاول مرة أخرى.',
      };
      _setMessage(message, error: true);
    } catch (_) {
      _setMessage('تعذر إرسال رسالة التحقق حالياً. حاول مرة أخرى.', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      final User? refreshed = await widget.repository.reloadCurrentUser();
      if (refreshed == null) {
        _setMessage('انتهت جلسة الحساب. سجّل الدخول مجدداً.', error: true);
      } else if (!refreshed.emailVerified) {
        _setMessage(
          'لم يتم تأكيد البريد بعد. افتح رسالة التحقق ثم اضغط على هذا الزر.',
          error: true,
        );
      }
      // userChanges() notifies AuthGate when the email becomes verified.
    } on FirebaseAuthException catch (error) {
      _setMessage(
        error.code == 'network-request-failed'
            ? 'تعذر تحديث حالة البريد بسبب الاتصال بالإنترنت.'
            : 'تعذر تحديث حالة الحساب. حاول مرة أخرى.',
        error: true,
      );
    } catch (_) {
      _setMessage('تعذر تحديث حالة الحساب. حاول مرة أخرى.', error: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.repository.signOut();
    } catch (_) {
      _setMessage('تعذر تسجيل الخروج. حاول مرة أخرى.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(child: BrandLogo(size: 108)),
                  const SizedBox(height: 22),
                  Text(
                    'تحقق من بريدك الإلكتروني',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: RoohTheme.ink,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'يحتاج حسابك إلى تأكيد البريد الإلكتروني قبل متابعة استخدام رُوح:',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: RoohTheme.mutedInk,
                        ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.user.email ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'افتح رسالة التحقق واضغط على رابط التأكيد، ثم ارجع إلى رُوح واضغط على زر التحقق. إذا لم تصلك الرسالة، يمكنك طلب إرسالها من جديد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: RoohTheme.mutedInk,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_message != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _messageIsError
                            ? const Color(0xFFFFF0ED)
                            : const Color(0xFFEAF2E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _messageIsError
                              ? const Color(0xFF9B382B)
                              : const Color(0xFF3D6540),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  FilledButton.icon(
                    onPressed: _checking ? null : _checkVerification,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(
                      _checking ? 'جارٍ التحقق...' : 'تحققت من بريدي',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _sending ? null : _resend,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.email_outlined),
                    label: Text(
                      _sending ? 'جارٍ الإرسال...' : 'إعادة إرسال رسالة التحقق',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _signOut,
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
