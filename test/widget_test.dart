import 'package:flutter_test/flutter_test.dart';
import 'package:rooh_app/app.dart';

void main() {
  testWidgets('the Arabic home screen shows the Rooh identity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RoohApp());

    expect(find.text('رُوح'), findsOneWidget);
    expect(find.text('ابدأ من الداخل'), findsOneWidget);
    expect(find.text('أهلاً بك في رُوح'), findsOneWidget);
    expect(find.text('اكتشف مساحتك'), findsOneWidget);
  });
}
