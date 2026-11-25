# إعداد Firebase Spark لتطبيق رُوح

## الحالة الحالية

مشروع Firebase أُنشئ يدوياً على حساب المالك، والتفاصيل المؤكدة هي:
- Project name: `ali9899`
- Project ID: `ali9899-59774`
- Project number: `289917698507`
- Billing plan الظاهر في لوحة التحكم: Spark (مجاني)
- حالة المنصات عند آخر مراجعة: لا توجد تطبيقات Android أو iOS مسجلة بعد.

بدأنا إضافة طبقة Firebase داخل Flutter: تهيئة Firebase، تسجيل الدخول بالبريد وكلمة المرور، ملف المستخدم في Firestore، وقواعد أمان أولية. لا يزال ملف `lib/firebase_options.dart` مؤقتاً، ولم يتم ربط تطبيقات Android/iOS بعد؛ لذلك لا تعمل المصادقة أو عمليات البيانات الحقيقية قبل إكمال التسجيل والتهيئة.

معرّفات التطبيقات التي يجب استخدامها عند تسجيل المنصات:
- Android applicationId: `com.rooh.rooh_app`
- iOS bundle identifier: `com.rooh.roohApp`

لا تنشئ تطبيقاً ثالثاً أو تستخدم معرّفاً مختلفاً دون تحديث ملفات المنصة في المستودع أيضاً.

## 1. إنشاء مشروع مجاني

1. افتح [Firebase Console](https://console.firebase.google.com/).
2. أنشئ مشروعاً جديداً باسم رُوح.
3. أبقِ الخطة **Spark**. لا تضف بطاقة ولا تربط Billing.
4. لا تنشئ Storage ولا تفعّل Cloud Functions.

## 2. تفعيل تسجيل الدخول

من Firebase Console افتح **Authentication → Sign-in method** وفعّل **Email/Password** فقط. لا نستخدم SMS في النسخة التجريبية.

## 3. إنشاء Firestore

1. افتح **Firestore Database** ثم **Create database**.
2. اختر **Production mode** وليس Test Mode.
3. اختر موقع قاعدة البيانات بعناية بناءً على موقع أغلب المستخدمين؛ اختيار الموقع قرار طويل الأمد.
4. اترك بقية المنتجات التي تتطلب خطة مدفوعة غير مفعّلة.

## 4. ربط Flutter بالمشروع

ثبّت الأدوات على جهاز التطوير:

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

من مجلد المشروع نفّذ:

```bash
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID> --platforms=android,ios
```

اختر تطبيقات Android وiOS الصحيحة بحسب Bundle ID الظاهر في إعدادات المنصات. سيولّد FlutterFire CLI الملف `lib/firebase_options.dart` بإعدادات مشروعك، ويستبدل الملف المؤقت الموجود حالياً.

ثم نفّذ:

```bash
flutter pub get
flutter run
```

ملف إعدادات Firebase يحتوي معرّفات تطبيق عامة لازمة للاتصال، وليس مفتاح خدمة إدارية. لا تضع Service Account JSON أو مفاتيح Admin SDK في تطبيق Flutter أو GitHub.

## 5. نشر قواعد الأمان

بعد إنشاء قاعدة Firestore وتسجيل الدخول عبر Firebase CLI:

```bash
firebase deploy --project <YOUR_FIREBASE_PROJECT_ID> --only firestore:rules
```

توجد القواعد في `firestore.rules`. وهي تمنع المستخدم من قراءة ملف مستخدم آخر أو تعديله، وتحصر تعديل الملف الشخصي بالاسم واللغة والاهتمامات. لا تسمح للمستخدم بإضافة دور إداري أو تعديل البريد أو UID. المجموعات غير المذكورة مرفوضة افتراضياً.

## 6. إعداد المدير الأول

1. أنشئ حساب المدير من Firebase Authentication بعد ربط التطبيق.
2. انسخ UID الخاص بالحساب من صفحة Authentication.
3. من Firestore Console أنشئ مستنداً في مجموعة `admins` واجعل معرّف المستند هو UID نفسه.
4. لا تنشئ مستند المدير من تطبيق Flutter؛ قواعد الأمان تمنع ذلك عمداً.

يُتحقق من صلاحية المدير بوجود مستند مطابق في المجموعة المحمية. لا تخزّن الدور في ملف المستخدم الذي يملكه المستخدم.

## 7. الاختبار

```bash
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

يمكن تشغيل المحاكيات محلياً بعد تثبيت Firebase CLI:

```bash
firebase emulators:start --only auth,firestore
```

## حدود النسخة التجريبية

- Firebase Spark فقط؛ لا بطاقة ولا Billing ولا ترقية تلقائية إلى Blaze.
- Auth بالبريد وكلمة المرور؛ لا SMS.
- Firestore للبيانات النصية والملفات الشخصية والبيانات الوصفية.
- Firebase Storage وCloud Functions خارج النطاق.
- الفيديو وYouTube والبث المباشر ورفع الملفات مؤجلة.
- Cloud Messaging سيضاف في مرحلة الإشعارات بعد اختبار الحسابات وقواعد البيانات.

راجع [خطة Firebase الرسمية](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans) و[دليل Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started) قبل أي توسعة.
