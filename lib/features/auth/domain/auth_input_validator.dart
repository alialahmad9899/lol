abstract final class AuthInputValidator {
  static String? validateEmail(String value) {
    final String email = value.trim();
    if (email.isEmpty) return 'أدخل البريد الإلكتروني.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'أدخل بريداً إلكترونياً صحيحاً.';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.isEmpty) return 'أدخل كلمة المرور.';
    if (value.length < 6) return 'يجب ألا تقل كلمة المرور عن 6 محارف.';
    return null;
  }

  static String? validateDisplayName(String value) {
    final String name = value.trim();
    if (name.isEmpty) return 'أدخل الاسم.';
    if (name.length > 100) return 'يجب ألا يتجاوز الاسم 100 محرف.';
    return null;
  }
}
