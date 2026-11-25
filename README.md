# رُوح — ابدأ من الداخل

مشروع تطبيق رُوح للدكتور خالد علوش. تطبيق عربي للوعي وتطوير الذات والاسترخاء والتركيز وبناء العادات، مع برامج وكورسات ولوحة إدارة.

## الحالة الحالية

النسخة الحالية تتضمن هوية رُوح الأولية وشعار المشروع، شاشة عربية لتسجيل الدخول وإنشاء الحساب واستعادة كلمة المرور، بوابة تتحقق من جلسة Firebase، وشاشة رئيسية أولية. توجد طبقة Firebase Authentication وCloud Firestore ومستودعات للحساب والملف الشخصي وقواعد أمان أولية. أقسام المحتوى والكورسات والبرامج ولوحة الإدارة ما زالت قيد التنفيذ. لم يكتمل الاتصال السحابي الفعلي بعد؛ يلزم تفعيل مزوّد البريد وإنشاء Firestore ونشر القواعد واختبار تدفقات المستخدم وفق `docs/FIREBASE_SETUP.md`.

## المتطلبات المحلية

- Flutter SDK (Dart 3.12 أو أحدث).
- Android Studio أو Android SDK لتشغيل وبناء Android.
- Xcode على macOS فقط لبناء وتشغيل iOS.
- Node.js لاستخدام Firebase CLI أثناء إعداد المشروع.

## التشغيل

بعد تثبيت Flutter:

```bash
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test
flutter run
```

## ربط Firebase

نعتمد Firebase Spark فقط دون بطاقة أو Billing أو Storage أو Cloud Functions. راجع:
- `docs/FIREBASE_SETUP.md` — إنشاء المشروع وربط تطبيقات Android/iOS ونشر قواعد الأمان.
- `docs/FREE_STACK.md` — الخدمات والحدود المجانية المعتمدة.
- `docs/PRODUCT_ROADMAP.md` — مراحل التطوير.

قبل تنفيذ FlutterFire CLI، تبقى الشاشة الرئيسية قابلة للتشغيل؛ ملف Firebase الموجود حالياً placeholder ولن يتصل بخادم إلى أن يتم توليد ملف الإعداد الحقيقي.

لا تضع Service Account JSON أو مفاتيح Admin SDK داخل التطبيق أو GitHub.

## بنية المشروع

```text
lib/
  app.dart
  main.dart
  core/
    constants/
    firebase/
    theme/
  features/
    auth/
    home/presentation/
    profile/
test/
docs/
firestore.rules
firebase.json
```

## الفروع

التطوير يتم على فرع `feature/rooh-flutter-foundation`، ولا يُدمج في `master` قبل اجتياز المراجعة والاختبارات.
