# إعداد Firebase Spark لتطبيق رُوح

## المشروع المعتمد والحالة الحالية

المشروع موجود بالفعل على Firebase Console:

- Project name: `ali9899`
- Project ID: `ali9899-59774`
- Project number: `289917698507`
- الخطة الظاهرة في لوحة التحكم: **Spark — مجانية**.

لا تنشئ مشروعاً جديداً ولا تضف بطاقة ولا تربط Billing أو Blaze.

### إعداد Android

- تطبيق Android مسجّل بمعرّف الحزمة `com.rooh.rooh_app`.
- ملف `android/app/google-services.json` موجود في فرع التطوير ويطابق رقم المشروع ومعرّفه.
- Google Services Gradle Plugin مضاف في إعدادات Android.
- `lib/firebase_options.dart` يحتوي إعداد تطبيق Android المسجل.
- بناء Android التجريبي نجح في تشغيل CI سابق، لكن ذلك لا يثبت أن Auth وFirestore يعملان على السحابة.

### ما لم يتم التحقق منه بعد

- تفعيل Email/Password في Firebase Authentication.
- إنشاء Firestore Database فعلياً واختيار موقعها.
- نشر `firestore.rules` واختبار قواعدها.
- إنشاء حساب المدير الأول ومستنده في `admins`.
- تسجيل تطبيق iOS وإضافة ملف إعداداته.
- اختبار إنشاء الحساب والملف الشخصي والتسجيل في الكورس على Firebase الحقيقي.

طبقة Flutter البرمجية موجودة، لكننا لا نعتبر تدفق الحسابات والكورسات جاهزاً للإطلاق قبل إكمال هذه الخطوات واختبارها.

## 1. تفعيل تسجيل الدخول

من Firebase Console افتح المشروع `ali9899-59774` ثم:

1. افتح **Authentication → Sign-in method**.
2. فعّل **Email/Password** فقط.
3. لا تفعّل Phone/SMS أو مزوداً يتطلب خدمة مدفوعة.

## 2. إنشاء قاعدة Firestore

1. افتح **Firestore Database** ثم **Create database**.
2. اختر **Production mode** وليس Test Mode.
3. اختر موقع قاعدة البيانات بعناية؛ هذا الاختيار طويل الأمد ولا يغيّر بسهولة.
4. لا تنشئ Storage ولا تفعّل Cloud Functions.

## 3. تهيئة Firebase CLI ونشر القواعد

ثبّت Firebase CLI وسجّل الدخول بالحساب الذي يملك المشروع:

```bash
npm install -g firebase-tools
firebase login
firebase projects:list
```

من مجلد المشروع، وعلى فرع `feature/rooh-flutter-foundation`، تأكد أن `.firebaserc` يشير إلى `ali9899-59774` ثم نفّذ:

```bash
firebase deploy --project ali9899-59774 --only firestore:rules
```

القواعد الموجودة في `firestore.rules` تمنع المستخدم من تعديل بريده أو UID أو صلاحياته. كما تحمي دروس الكورسات بحيث لا يستطيع المستخدم قراءة الدروس دون تسجيل نشط، ولا يستطيع منح نفسه تسجيلاً في دورة مدفوعة.

بعد النشر يجب اختبار التسجيل والقراءة والتعديل باستخدام حساب مستخدم عادي وحساب مدير. لا تعتبر وجود ملف القواعد في GitHub دليلاً على نشره في Firebase.

## 4. إعداد iOS لاحقاً

معرّف iOS في مشروع Flutter هو `com.rooh.roohApp`، لكنه لم يُسجّل بعد في Firebase.

بعد تسجيل تطبيق iOS بهذا المعرّف في Firebase Console، يمكن تشغيل FlutterFire CLI من مجلد المشروع لتوليد إعدادات Android وiOS معاً:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=ali9899-59774 --platforms=android,ios
```

تحقق بعد ذلك من بقاء إعداد Android وإضافة إعداد iOS إلى `lib/firebase_options.dart`. لا تشغّل هذا الأمر قبل تسجيل تطبيق iOS فعلياً.

## 5. إعداد المدير الأول

1. أنشئ حساب المدير من Firebase Authentication بعد تفعيل Email/Password.
2. انسخ UID الخاص بالحساب من صفحة Authentication.
3. من Firestore Console أنشئ مستنداً في مجموعة `admins` واجعل معرّف المستند هو UID نفسه.
4. لا تنشئ مستند المدير من تطبيق Flutter؛ القواعد تمنع ذلك عمداً.

يُتحقق من صلاحية المدير بوجود مستند مطابق في المجموعة المحمية. لا تخزّن الدور في ملف المستخدم الذي يملكه المستخدم.

## 6. شكل البيانات

راجع `docs/FIRESTORE_SCHEMA.md` قبل إضافة أي مستندات يدوياً. من المهم أن تتطابق الحقول وقيم الحالة مع ما تقرؤه واجهات التطبيق وقواعد الأمان، خصوصاً حقول الكورس:

- `status: "published"`
- `isFree: true` مع `price: 0` للدورة المجانية.
- `isFree: false` وسعر أكبر من صفر للدورة المدفوعة.
- الدروس تحت `courses/{courseId}/lessons/{lessonId}`.

## 7. اختبار قواعد الأمان

توجد اختبارات للمحاكي لا تحتاج إلى الاتصال بمشروع Firebase الحقيقي ولا إلى إضافة بطاقة:

```bash
npm install
npm run test:rules
```

هذه الاختبارات تستخدم مشروعاً تجريبياً باسم `demo-rooh-rules` ولا تنشئ أو تغيّر بيانات مشروع `ali9899-59774`.

## 8. اختبارات التطبيق والبناء

بعد إعداد الخدمات ونشر القواعد:

```bash
flutter pub get
dart format lib test
flutter analyze --fatal-infos
flutter test
flutter build apk --debug
```

يمكن استخدام المحاكيات محلياً بعد تثبيت Firebase CLI:

```bash
firebase emulators:start --only auth,firestore
```

## حدود النسخة المجانية

- Firebase Spark فقط؛ لا بطاقة ولا Billing ولا ترقية تلقائية إلى Blaze.
- Auth بالبريد وكلمة المرور؛ لا SMS.
- Firestore للبيانات النصية والبيانات المنظمة.
- Firebase Storage وCloud Functions خارج النطاق الحالي.
- الفيديو وYouTube والبث المباشر ورفع الملفات مؤجلة.
- Cloud Messaging سيضاف بعد إتمام إعداد Auth وFirestore واختبارهما.

لا تضع Service Account JSON أو مفاتيح Admin SDK في Flutter أو GitHub.

راجع [خطة Firebase الرسمية](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans) و[دليل Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started) قبل أي توسعة.
