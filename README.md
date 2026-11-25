# رُوح — ابدأ من الداخل

مشروع تطبيق رُوح للدكتور خالد علوش. تطبيق عربي للوعي وتطوير الذات والاسترخاء والتركيز وبناء العادات، مع برامج وكورسات ولوحة إدارة.

## الحالة الفعلية في فرع التطوير

الموجود حالياً في `feature/rooh-flutter-foundation`:

- شعار رُوح مستخدم داخل واجهة التطبيق.
- شاشة تسجيل الدخول وإنشاء الحساب واستعادة كلمة المرور.
- اختيار الاهتمامات والهدف الشخصي أثناء إنشاء الحساب.
- بوابة تربط عرض التطبيق بحالة جلسة Firebase.
- ملف شخصي يعرض الاسم والبريد والاهتمامات والهدف مع إمكانية تعديل البيانات المسموح بها.
- استكشاف التصنيفات والمحتوى المنشور، مع البحث والتصفية وصفحة تفاصيل نصية.
- كتالوج الكورسات المنشورة، وتسجيل مجاني، وقراءة الدروس للمسجلين، وحفظ إكمال الدروس والتقدم.
- قواعد Firestore أولية تحمي بيانات المستخدم وتمنع التسجيل الذاتي في الدورات المدفوعة.
- إعداد Android البرمجي موجود، مع Google Services وملف إعداد التطبيق المسجل.

**هذه ليست نسخة إطلاق نهائية بعد.** لم نتحقق من تفعيل Email/Password على Firebase Console، ولا من إنشاء Firestore أو نشر القواعد واختبارها على المشروع السحابي. كما أن لوحة الإدارة، والبرامج والتحديات، والإشعارات، وطلبات الدفع اليدوي، ودعم iOS الفعلي، واختبارات الأمان والتكامل ما زالت غير مكتملة.

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

- `docs/FIREBASE_SETUP.md` — حالة مشروع Firebase وخطوات تفعيل Auth وFirestore ونشر القواعد.
- `docs/FIRESTORE_SCHEMA.md` — شكل المستندات وحقول الدورات والتسجيل والتقدم.
- `docs/FREE_STACK.md` — الخدمات والحدود المجانية المعتمدة.
- `docs/PRODUCT_ROADMAP.md` — مراحل التطوير وما اكتمل وما بقي.

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
    widgets/
  features/
    auth/
    content/
    courses/
    home/
    profile/
test/
docs/
firestore.rules
firebase.json
```

## الفروع

التطوير يتم على فرع `feature/rooh-flutter-foundation`، ولا يُدمج في `master` قبل اجتياز المراجعة والاختبارات وقرار المالك.
