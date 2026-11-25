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

### ما تم تأكيده في Firebase Console

- المستخدم فعّل Email/Password في Firebase Authentication.
- قاعدة Firestore موجودة باسم `(default)` وموقع `europe-west4`.
- الخطة الحالية Spark المجانية.

### ما لم يتم التحقق منه بعد

- نشر `firestore.rules` والفهارس `firestore.indexes.json` على المشروع الحقيقي.
- إنشاء مستند المدير الأول في `admins` بعد استخراج UID الصحيح.
- تجربة التسجيل وحفظ الملف الشخصي والمحتوى المجاني على Firebase الحقيقي.

طبقة Flutter البرمجية موجودة، لكننا لا نعتبر تدفق الحسابات والكورسات جاهزاً للإطلاق قبل إكمال هذه الخطوات واختبارها.

## 1. تفعيل تسجيل الدخول

من Firebase Console افتح المشروع `ali9899-59774` ثم:

1. افتح **Authentication → Sign-in method**.
2. فعّل **Email/Password** فقط.
3. لا تفعّل Phone/SMS أو مزوداً يتطلب خدمة مدفوعة.

## 2. قاعدة Firestore الموجودة

قاعدة المشروع الافتراضية موجودة بالفعل:
- Database ID: `(default)`
- Location: `europe-west4`

لا تحاول إنشاء قاعدة ثانية بالمعرّف نفسه ولا تنشئ قاعدة إضافية. لا تفعّل Storage أو Cloud Functions في هذه المرحلة.

## 3. تهيئة Firebase CLI ونشر القواعد

ثبّت Firebase CLI وسجّل الدخول بالحساب الذي يملك المشروع:

```bash
npm install -g firebase-tools
firebase login
firebase projects:list
```

من مجلد المشروع، وعلى فرع `feature/rooh-flutter-foundation`، تأكد أن `.firebaserc` يشير إلى `ali9899-59774` ثم نفّذ:

```bash
firebase deploy --project ali9899-59774 --only firestore:rules,firestore:indexes
```

القواعد الموجودة في `firestore.rules` تمنع المستخدم من تعديل بريده أو UID أو صلاحياته. كما تحمي دروس الكورسات بحيث لا يستطيع المستخدم قراءة الدروس دون تسجيل نشط، ولا يستطيع منح نفسه تسجيلاً في دورة مدفوعة.

بعد النشر يجب اختبار التسجيل والقراءة والتعديل باستخدام حساب مستخدم عادي وحساب مدير. لا تعتبر وجود ملف القواعد في GitHub دليلاً على نشره في Firebase.

## 5. إعداد المدير الأول

1. أنشئ حساب المدير من Firebase Authentication بعد تفعيل Email/Password.
2. انسخ UID الخاص بالحساب من صفحة Authentication.
3. من Firestore Console أنشئ مستنداً في مجموعة `admins` واجعل معرّف المستند هو UID نفسه.
4. لا تنشئ مستند المدير من تطبيق Flutter؛ القواعد تمنع ذلك عمداً.

يُتحقق من صلاحية المدير بوجود مستند مطابق في المجموعة المحمية. لا تخزّن الدور في ملف المستخدم الذي يملكه المستخدم.

## 6. إضافة مكتبة البداية العربية

بعد إنشاء مستند المدير الصحيح في `admins/{uid}`:
1. افتح تطبيق رُوح وسجّل الدخول ببريد المدير المعتمد.
2. افتح رمز لوحة الإدارة من الصفحة الرئيسية.
3. اختر **إعداد مكتبة البداية المجانية** وأكّد الإضافة.
4. تنشئ العملية التصنيفات والمواد والجلسات والكورس والبرنامج المجانيين التي لا توجد بعد. لا تستبدل أي مستند موجود، ويمكن إعادة تشغيلها بأمان.

تحتوي المكتبة الأولى على 6 تصنيفات، و13 مادة/جلسة، وكورس من أربعة دروس، وبرنامج من سبعة أيام.

## 6. شكل البيانات

راجع `docs/FIRESTORE_SCHEMA.md` قبل إضافة أي مستندات يدوياً. من المهم أن تتطابق الحقول وقيم الحالة مع ما تقرؤه واجهات التطبيق وقواعد الأمان، خصوصاً حقول الكورس:

- `status: "published"`
- `isFree: true` مع `price: 0` للدورة أو البرنامج المجاني.
- الإصدار الأول يعرض العناصر المجانية فقط؛ لا تنشر أي عنصر مدفوع للمستخدمين في المرحلة الحالية.
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
