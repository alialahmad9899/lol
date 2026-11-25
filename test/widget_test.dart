import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rooh_app/core/widgets/brand_logo.dart';
import 'package:rooh_app/features/home/presentation/home_page.dart';

void main() {
  testWidgets('the Arabic home screen shows the Rooh identity', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('رُوح'), findsOneWidget);
    expect(find.text('ابدأ من الداخل'), findsOneWidget);
    expect(find.text('أهلاً بك في رُوح'), findsOneWidget);
    expect(find.text('اكتشف مساحتك'), findsOneWidget);
    expect(find.byType(BrandLogo), findsOneWidget);
  });
}
