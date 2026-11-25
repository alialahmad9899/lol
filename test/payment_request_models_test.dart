import 'package:flutter_test/flutter_test.dart';
import 'package:rooh_app/features/payments/data/payment_request_repository.dart';

void main() {
  group('PaymentRequest', () {
    test('parses and normalizes pending transfer details', () {
      final PaymentRequest request = PaymentRequest.fromMap(
        'request-1',
        <String, dynamic>{
          'userId': 'user-1',
          'courseId': 'course-1',
          'courseTitle': '  الوعي بالذات  ',
          'amount': 35.5,
          'currency': 'USD',
          'transferReference': '  SC-2026-1125  ',
          'status': 'pending',
          'reviewNote': '  ',
        },
      );

      expect(request.id, 'request-1');
      expect(request.userId, 'user-1');
      expect(request.courseId, 'course-1');
      expect(request.courseTitle, 'الوعي بالذات');
      expect(request.amount, 35.5);
      expect(request.currency, 'USD');
      expect(request.transferReference, 'SC-2026-1125');
      expect(request.status, 'pending');
      expect(request.reviewNote, isEmpty);
    });

    test('keeps approved and rejected states with review notes', () {
      final PaymentRequest approved = PaymentRequest.fromMap(
        'approved-1',
        <String, dynamic>{
          'status': 'approved',
          'reviewNote': 'تمت المطابقة',
        },
      );
      final PaymentRequest rejected = PaymentRequest.fromMap(
        'rejected-1',
        <String, dynamic>{
          'status': 'rejected',
          'reviewNote': 'المرجع غير مطابق',
        },
      );

      expect(approved.status, 'approved');
      expect(approved.reviewNote, 'تمت المطابقة');
      expect(rejected.status, 'rejected');
      expect(rejected.reviewNote, 'المرجع غير مطابق');
    });

    test('uses safe defaults for incomplete documents', () {
      final PaymentRequest request = PaymentRequest.fromMap(
        'incomplete',
        <String, dynamic>{'amount': 'invalid'},
      );

      expect(request.userId, isEmpty);
      expect(request.courseId, isEmpty);
      expect(request.courseTitle, isEmpty);
      expect(request.amount, 0);
      expect(request.currency, 'USD');
      expect(request.transferReference, isEmpty);
      expect(request.status, 'pending');
    });
  });
}
