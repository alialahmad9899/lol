import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_input_validator.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.repository});

  final FirebaseAuthRepository repository;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  static const List<String> _interestOptions = <String>[
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
  final Set<String> _selectedInterests = <String>{};
  String? _selectedGoal;
  String? _selectedGender;
  String? _preferredContentStyle;
  int? _dailyTimeMinutes;
  String? _preferredTime;

  bool _isCreatingAccount = false;
  bool _isBusy = false;
  bool _hidePassword = true;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isCreatingAccount && _selectedInterests.isEmpty) {
      _setFeedback('اختر مجالاً واحداً على الأقل حتى نخصص تجربتك في رُوح.');
      return;
    }
    if (_isCreatingAccount && _selectedGoal == null) {
      _setFeedback('اختر هدفك الأساسي من استخدام رُوح.');
      return;
    }

    setState(() {
      _isBusy = true;
      _feedback = null;
    });

    try {
      if (_isCreatingAccount) {
        await widget.repository.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          interests: _selectedInterests.toList(growable: false),
          primaryGoal: _selectedGoal!,
          age: _ageController.text.trim().isEmpty
              ? null
              : int.parse(_ageController.text.trim()),
          gender: _selectedGender,
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          country: _countryController.text.trim().isEmpty
              ? null
              : _countryController.text.trim(),
          preferredContentStyle: _preferredContentStyle,
          dailyTimeMinutes: _dailyTimeMinutes,
          preferredTime: _preferredTime,
        );
      } else {
        await widget.repository.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      _setFeedback(_authErrorMessage(error), isError: true);
    } on AccountProfileSyncException {
      _setFeedback(
        'تم التعامل مع الحساب، لكن تعذرت مزامنة ملفك الشخصي. '
        'تحقق من اتصال قاعدة البيانات ثم أعد المحاولة.',
        isError: true,
      );
    } catch (_) {
      _setFeedback(
        'تعذر إكمال العملية حالياً. تحقق من اتصال الإنترنت وحاول مجدداً.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final String? validationError =
        AuthInputValidator.validateEmail(_emailController.text);
    if (validationError != null) {
      _setFeedback(validationError, isError: true);
      return;
    }

    setState(() {
      _isBusy = true;
      _feedback = null;
    });

    try {
      await widget.repository.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _setFeedback(
        'أرسلنا رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.',
      );
    } on FirebaseAuthException catch (error) {
      _setFeedback(_authErrorMessage(error), isError: true);
    } catch (_) {
      _setFeedback('تعذر إرسال الرابط حالياً. حاول مرة أخرى.', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _setFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _feedback = message;
      _feedbackIsError = isError;
    });
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'هذا البريد مسجّل مسبقاً. سجّل الدخول بدلاً من إنشاء حساب جديد.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة. استخدم كلمة مرور أقوى.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب. تواصل مع الإدارة.';
      case 'too-many-requests':
        return 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بالبريد وكلمة المرور غير مفعّل في إعدادات Firebase بعد.';
      default:
        return 'تعذر تسجيل الدخول حالياً. حاول مجدداً لاحقاً.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Center(child: BrandLogo(size: 116)),
                    const SizedBox(height: 18),
                    Text(
                      'رُوح',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: RoohTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ابدأ من الداخل',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: RoohTheme.mutedInk,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _isCreatingAccount ? 'أنشئ حسابك' : 'أهلاً بعودتك',
                      textAlign: TextAlign.start,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCreatingAccount
                          ? 'خطوتك الأولى نحو مساحة أقرب إلى نفسك.'
                          : 'سجّل الدخول وتابع رحلتك مع رُوح.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: RoohTheme.mutedInk,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_isCreatingAccount) ...<Widget>[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'الاسم',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (String? value) =>
                            AuthInputValidator.validateDisplayName(value ?? ''),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'العمر (اختياري)',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              validator: (String? value) {
                                final String text = (value ?? '').trim();
                                if (text.isEmpty) return null;
                                final int? age = int.tryParse(text);
                                if (age == null || age < 13 || age > 120) {
                                  return 'أدخل عمراً بين 13 و120';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: const InputDecoration(
                                labelText: 'الجنس (اختياري)',
                              ),
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
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'المدينة (اختياري)',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'الدولة (اختياري)',
                                prefixIcon: Icon(Icons.public_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'أسئلة بسيطة لتجربة تناسبك',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text('اختيارية ويمكنك تخطيها'),
                        children: <Widget>[
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text('أي نوع من المحتوى تفضّل؟'),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              ChoiceChip(
                                label: const Text('محتوى قصير'),
                                selected: _preferredContentStyle == 'short',
                                onSelected: (selected) => setState(
                                  () => _preferredContentStyle = selected ? 'short' : null,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('جلسات متعمقة'),
                                selected: _preferredContentStyle == 'deep',
                                onSelected: (selected) => setState(
                                  () => _preferredContentStyle = selected ? 'deep' : null,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('مزيج بينهما'),
                                selected: _preferredContentStyle == 'mixed',
                                onSelected: (selected) => setState(
                                  () => _preferredContentStyle = selected ? 'mixed' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text('كم دقيقة تستطيع تخصيصها لنفسك يومياً؟'),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: <int>[5, 10, 15, 20, 30, 45, 60]
                                .map((minutes) => ChoiceChip(
                                      label: Text('$minutes دقيقة'),
                                      selected: _dailyTimeMinutes == minutes,
                                      onSelected: (selected) => setState(
                                        () => _dailyTimeMinutes = selected ? minutes : null,
                                      ),
                                    ))
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text('متى تفضّل تخصيص وقت لرُوح؟'),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              ChoiceChip(
                                label: const Text('الصباح'),
                                selected: _preferredTime == 'morning',
                                onSelected: (selected) => setState(
                                  () => _preferredTime = selected ? 'morning' : null,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('المساء'),
                                selected: _preferredTime == 'evening',
                                onSelected: (selected) => setState(
                                  () => _preferredTime = selected ? 'evening' : null,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('حسب يومي'),
                                selected: _preferredTime == 'flexible',
                                onSelected: (selected) => setState(
                                  () => _preferredTime = selected ? 'flexible' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'ما المجالات التي تهمك؟',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interestOptions.map((String interest) {
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
                      const SizedBox(height: 14),
                      const Text(
                        'ما هدفك الأساسي من استخدام رُوح؟',
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
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (String? value) =>
                          AuthInputValidator.validateEmail(value ?? ''),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isBusy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'إظهار كلمة المرور'
                              : 'إخفاء كلمة المرور',
                          onPressed: () => setState(
                            () => _hidePassword = !_hidePassword,
                          ),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (String? value) =>
                          AuthInputValidator.validatePassword(value ?? ''),
                    ),
                    if (!_isCreatingAccount)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isBusy ? null : _sendPasswordReset,
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                    if (_feedback != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _feedbackIsError
                              ? const Color(0xFFFFF0ED)
                              : const Color(0xFFEAF2E8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _feedback!,
                          style: TextStyle(
                            color: _feedbackIsError
                                ? const Color(0xFF9B382B)
                                : const Color(0xFF3D6540),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    FilledButton(
                      onPressed: _isBusy ? null : _submit,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isCreatingAccount ? 'إنشاء الحساب' : 'تسجيل الدخول',
                            ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isBusy
                          ? null
                          : () {
                              setState(() {
                                _isCreatingAccount = !_isCreatingAccount;
                                _feedback = null;
                              });
                            },
                      child: Text(
                        _isCreatingAccount
                            ? 'لديك حساب؟ سجّل الدخول'
                            : 'ليس لديك حساب؟ أنشئ حساباً',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
