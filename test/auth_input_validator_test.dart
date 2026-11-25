import 'package:flutter_test/flutter_test.dart';
import 'package:rooh_app/features/auth/domain/auth_input_validator.dart';

void main() {
  group('AuthInputValidator', () {
    test('accepts valid email and surrounding spaces', () {
      expect(
        AuthInputValidator.validateEmail('  person@example.com  '),
        isNull,
      );
    });

    test('rejects malformed email addresses', () {
      expect(AuthInputValidator.validateEmail('not-an-email'), isNotNull);
    });

    test('requires a password of at least six characters', () {
      expect(AuthInputValidator.validatePassword('12345'), isNotNull);
      expect(AuthInputValidator.validatePassword('123456'), isNull);
    });

    test('trims and validates display names', () {
      expect(AuthInputValidator.validateDisplayName('  رُوح  '), isNull);
      expect(AuthInputValidator.validateDisplayName('   '), isNotNull);
    });
  });
}
