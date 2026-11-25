import 'package:cloud_firestore/cloud_firestore.dart';

class InitialLibrarySeedResult {
  const InitialLibrarySeedResult({
    required this.created,
    required this.skipped,
  });

  final int created;
  final int skipped;
}

class InitialSeedDocument {
  const InitialSeedDocument({
    required this.path,
    required this.data,
  });

  final String path;
  final Map<String, Object> data;
}

class InitialLibrarySeedRepository {
  InitialLibrarySeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<InitialSeedDocument> initialDocuments =
      <InitialSeedDocument>[
    InitialSeedDocument(
      path: 'categories/awareness',
      data: <String, Object>{
        'title': 'وعي',
        'description': 'مساحة لملاحظة أفكارك ومشاعرك واحتياجاتك بلطف',
        'sortOrder': 1,
      },
    ),
    InitialSeedDocument(
      path: 'categories/calm',
      data: <String, Object>{
        'title': 'استرخاء',
        'description': 'ممارسات قصيرة للتهدئة واستعادة الحضور',
        'sortOrder': 2,
      },
    ),
    InitialSeedDocument(
      path: 'categories/focus',
      data: <String, Object>{
        'title': 'تركيز',
        'description': 'خطوات عملية للانتباه وتقليل التشتت',
        'sortOrder': 3,
      },
    ),
    InitialSeedDocument(
      path: 'categories/development',
      data: <String, Object>{
        'title': 'تطوير',
        'description': 'خطوات صغيرة لبناء العادات والنمو الشخصي',
        'sortOrder': 4,
      },
    ),
    InitialSeedDocument(
      path: 'categories/daily',
      data: <String, Object>{
        'title': 'رُوح اليومية',
        'description': 'مساحات للتأمل والرفق بالنفس خلال اليوم',
        'sortOrder': 5,
      },
    ),
    InitialSeedDocument(
      path: 'categories/change',
      data: <String, Object>{
        'title': 'تغيير',
        'description': 'مساحة للتوقف واختيار استجابة وخطوة جديدة',
        'sortOrder': 6,
      },
    ),
    InitialSeedDocument(
      path: 'content_items/morning_check_in',
      data: <String, Object>{
        'title': 'دقيقة للعودة إلى نفسك',
        'summary': 'ثلاثة أسئلة قصيرة تساعدك على بدء يومك بوعي وهدوء',
        'body': 'خذ دقيقة واجلس بطريقة مريحة. ضع قدميك على الأرض، ودع كتفيك يسترخيان. لا تحتاج إلى تغيير أي شعور أو الوصول إلى إجابة مثالية.\n\nاسأل نفسك بهدوء:\n1. ما الشعور الأوضح لدي الآن؟\n2. ما الأمر الذي يحتاج انتباهي اليوم؟\n3. ما خطوة صغيرة أستطيع القيام بها دون أن أرهق نفسي؟\n\nاختر كلمة واحدة تصف ما تحتاجه اليوم، مثل: هدوء، ترتيب، راحة، أو شجاعة. احتفظ بها كتذكير لطيف، لا كالتزام إضافي.\n\nتذكير: هذه ممارسة للتأمل الذاتي وليست تشخيصاً أو علاجاً.',
        'categoryId': 'awareness',
        'type': 'exercise',
        'durationMinutes': 3,
        'tags': <String>['وعي الذات', 'بداية اليوم', 'تأمل'],
        'sortOrder': 1,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/name_the_feeling',
      data: <String, Object>{
        'title': 'سمِّ ما تشعر به',
        'summary': 'ملاحظة الشعور وتسميته دون محاكمة أو استعجال',
        'body': 'أحياناً يكون الشعور واضحاً، وأحياناً يظهر كمزيج يصعب وصفه. جرّب أن تتوقف للحظة وتسأل: ماذا ألاحظ الآن؟\n\nيمكنك الاختيار من كلمات بسيطة: قلق، حماس، حزن، ارتياح، غضب، امتنان، تعب، حيرة، أو لا أعرف بعد.\n\nأكمل الجملة: «ألاحظ أنني أشعر بـ...، وربما أحتاج إلى...». لا تبحث عن سبب نهائي، ولا تجبر نفسك على مشاركة الإجابة مع أحد.\n\nتسمية الشعور لا تعني أنك ضعيف أو أنك ملزم بالتصرف بناءً عليه؛ إنها مجرد مساحة لفهم ما يحدث داخلك.',
        'categoryId': 'awareness',
        'type': 'exercise',
        'durationMinutes': 5,
        'tags': <String>['المشاعر', 'وعي الذات', 'كتابة'],
        'sortOrder': 2,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/values_compass',
      data: <String, Object>{
        'title': 'بوصلة القيم الشخصية',
        'summary': 'اكتشف قيمة واحدة تريد أن تظهر في تصرفاتك اليوم',
        'body': 'القيم ليست قائمة مثالية يجب أن نحققها كلها. هي اتجاهات تساعدنا على اختيار ما نريد أن نمثله في حياتنا.\n\nاقرأ الكلمات التالية واختر واحدة تهمك اليوم: الصدق، الرحمة، التعلم، الشجاعة، الاتزان، العائلة، الإبداع، أو المسؤولية.\n\nاسأل نفسك: كيف يمكن أن تظهر هذه القيمة في فعل صغير خلال الساعات القادمة؟ قد تكون رسالة صادقة، أو استراحة تحترم حاجتك، أو خطوة تعلم قصيرة.\n\nاكتب الفعل الذي اخترته، واجعله واقعياً ومحدداً. لا تقِس قيمتك بمدى إنجازك له؛ استخدمه كبوصلة لا كحكم على نفسك.',
        'categoryId': 'awareness',
        'type': 'text',
        'durationMinutes': 6,
        'tags': <String>['القيم', 'اختيارات', 'وعي الذات'],
        'sortOrder': 3,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/breathing_pause',
      data: <String, Object>{
        'title': 'وقفة تنفّس هادئة',
        'summary': 'ثلاث دقائق لملاحظة النفس وإرخاء التوتر اليومي',
        'body': 'اجلس في وضع مريح، وأرخِ يديك. لاحظ حركة التنفس كما هي دون محاولة أخذ نفس عميق بالقوة.\n\nإذا كان ذلك مريحاً، اجعل الزفير أطول قليلاً من الشهيق، ثم اترك النفس يعود إلى إيقاعه الطبيعي. كرر بهدوء لعدة دورات.\n\nإذا شعرت بدوار أو انزعاج، توقف فوراً وتنفس بالطريقة الطبيعية. يمكنك بدلاً من ذلك ملاحظة قدميك على الأرض أو النظر إلى شيء ثابت أمامك.\n\nلا يوجد أداء صحيح أو خاطئ هنا؛ الهدف هو منح نفسك لحظة توقف قصيرة.',
        'categoryId': 'calm',
        'type': 'exercise',
        'durationMinutes': 3,
        'tags': <String>['تنفس', 'استرخاء', 'هدوء'],
        'sortOrder': 1,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/senses_grounding',
      data: <String, Object>{
        'title': 'العودة إلى الحواس',
        'summary': 'تمرين بسيط للانتباه إلى المكان المحيط بك',
        'body': 'انظر حولك واختر ما يناسبك من الخطوات التالية:\n\n• لاحظ خمسة أشياء تراها.\n• لاحظ أربعة أشياء تستطيع لمسها أو الإحساس بها.\n• انتبه إلى ثلاثة أصوات تسمعها.\n• لاحظ رائحتين إن كان ذلك مريحاً.\n• اختر مذاقاً واحداً أو خذ رشفة ماء.\n\nتحرك ببطء ودون إجبار. ليس ضرورياً إكمال كل الخطوات؛ يكفي أن تلاحظ شيئاً واحداً حولك. إذا زاد التمرين انزعاجك، توقف واختر طريقة أخرى تشعرك بالأمان.',
        'categoryId': 'calm',
        'type': 'exercise',
        'durationMinutes': 5,
        'tags': <String>['الحواس', 'الحضور', 'تهدئة'],
        'sortOrder': 2,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/body_relaxation',
      data: <String, Object>{
        'title': 'مسح لطيف للجسم',
        'summary': 'ملاحظة مناطق الراحة والتوتر دون محاولة إجبار الجسم',
        'body': 'اجلس أو استلقِ بطريقة مريحة. ابدأ بملاحظة القدمين، ثم الساقين، ثم اليدين والكتفين والوجه.\n\nفي كل منطقة اسأل: ماذا ألاحظ؟ دفء، برودة، شد، خفة، أو لا شيء واضح؟ لا تحاول تغيير الإحساس بالقوة. يمكنك فقط إرخاء الفك أو خفض الكتفين إذا كان ذلك مريحاً.\n\nتجاوز أي منطقة لا ترغب في التركيز عليها. افتح عينيك وتحرك ببطء عند الانتهاء. هذا التمرين دعوة للملاحظة وليس فحصاً طبياً للجسم.',
        'categoryId': 'calm',
        'type': 'exercise',
        'durationMinutes': 7,
        'tags': <String>['استرخاء', 'الجسم', 'وعي'],
        'sortOrder': 3,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/single_task',
      data: <String, Object>{
        'title': 'مهمة واحدة في كل مرة',
        'summary': 'خطوة عملية لتخفيف التشتت والانتقال بين المهام',
        'body': 'اختر مهمة صغيرة واحدة فقط. اكتب النتيجة التي تعني لك «أنجزت الحد الكافي»، مثل: قراءة صفحتين أو ترتيب سطح المكتب.\n\nأبعد ما لا تحتاجه الآن، وضع الهاتف على وضع صامت إن أمكن. اضبط مؤقتاً لعشر دقائق وابدأ. إذا ظهرت فكرة عن مهمة أخرى، اكتبها في ورقة وعد إلى المهمة الحالية.\n\nعند انتهاء الوقت، قرر بهدوء: هل أتابع قليلاً أم أتوقف؟ التقدم الصغير المتعمد أفضل من مطالبة نفسك بإنجاز كل شيء دفعة واحدة.',
        'categoryId': 'focus',
        'type': 'exercise',
        'durationMinutes': 10,
        'tags': <String>['تركيز', 'تشتت', 'إنتاجية متوازنة'],
        'sortOrder': 1,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/focus_reset',
      data: <String, Object>{
        'title': 'إعادة ضبط الانتباه',
        'summary': 'طريقة قصيرة للعودة إلى ما تفعله بعد المقاطعة',
        'body': 'عندما تلاحظ أنك تشتت، لا تبدأ بلوم نفسك. توقف لحظة وحدد ما قاطع انتباهك: إشعار، فكرة، صوت، أو تعب.\n\nاكتب كلمة واحدة عن المقاطعة، ثم اقرأ آخر خطوة كنت تعمل عليها. اسأل: ما الفعل التالي الأصغر؟\n\nابدأ بهذا الفعل لمدة خمس دقائق. إن كان التشتت بسبب الإرهاق، فقد تكون الاستراحة القصيرة هي الخطوة الأنسب. الانتباه مهارة تتأثر بالظروف، وليس اختباراً لقيمتك أو إرادتك.',
        'categoryId': 'focus',
        'type': 'text',
        'durationMinutes': 5,
        'tags': <String>['انتباه', 'تركيز', 'رفق بالنفس'],
        'sortOrder': 2,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/smallest_step',
      data: <String, Object>{
        'title': 'أصغر خطوة ممكنة',
        'summary': 'حوّل هدفاً كبيراً إلى بداية لا تبدو مرهقة',
        'body': 'اختر عادة ترغب في بنائها، ثم صغّرها إلى نسخة تستغرق دقيقتين أو أقل. بدلاً من «سأقرأ كتاباً»، جرّب «سأقرأ فقرة». وبدلاً من «سأمارس الرياضة»، جرّب «سأرتدي الحذاء وأمشي قليلاً» إذا كان ذلك مناسباً لك.\n\nحدد متى وأين ستبدأ. اجعل النجاح هو الحضور للمحاولة، لا الوصول إلى نتيجة كبيرة من أول يوم. يمكنك زيادة الخطوة لاحقاً عندما تصبح البداية مألوفة.',
        'categoryId': 'development',
        'type': 'exercise',
        'durationMinutes': 5,
        'tags': <String>['عادات', 'بداية صغيرة', 'استمرارية'],
        'sortOrder': 1,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/habit_anchor',
      data: <String, Object>{
        'title': 'اربط العادة بلحظة موجودة',
        'summary': 'استخدم حدثاً يومياً مألوفاً كتذكير لعادة جديدة',
        'body': 'اختر عادة صغيرة تريد تكرارها، ثم اربطها بشيء يحدث بالفعل. مثال: بعد إعداد الشاي، أكتب سطراً واحداً في دفتري. أو بعد إغلاق الحاسوب، أرتب المكتب لدقيقتين.\n\nاكتب الصيغة: «بعد أن أفعل ___، سأفعل ___ لمدة ___».\n\nاختر وقتاً واقعياً، وضع تذكيراً بسيطاً إن احتجت. إذا فاتتك مرة، لا تعاقب نفسك ولا تحاول تعويضها بمجهود مضاعف؛ عد إليها في الفرصة التالية.',
        'categoryId': 'development',
        'type': 'exercise',
        'durationMinutes': 4,
        'tags': <String>['عادات', 'تذكير', 'روتين'],
        'sortOrder': 2,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/evening_reflection',
      data: <String, Object>{
        'title': 'مراجعة هادئة لنهاية اليوم',
        'summary': 'ثلاث ملاحظات تساعدك على إنهاء اليوم دون جلد الذات',
        'body': 'قبل النوم أو عند انتهاء يومك، خذ لحظة واكتب:\n\n1. شيء واحد سار بشكل مقبول اليوم.\n2. شيء كان صعباً وأحتاج أن أتعامل معه برفق.\n3. شيء واحد أريد أن أبدأ به غداً.\n\nلا تحوّل المراجعة إلى قائمة أخطاء. إن لم تجد إنجازاً كبيراً، يكفي أنك واصلت يومك أو انتبهت إلى احتياجك. يمكنك ترك السؤال الذي لا ترغب في الإجابة عنه.',
        'categoryId': 'daily',
        'type': 'exercise',
        'durationMinutes': 5,
        'tags': <String>['تأمل يومي', 'توازن', 'كتابة'],
        'sortOrder': 1,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/kind_self_talk',
      data: <String, Object>{
        'title': 'تحدث إلى نفسك بلطف',
        'summary': 'استبدل النقد القاسي بجملة واقعية ومساندة',
        'body': 'تخيل أن شخصاً تحبه مرّ بالموقف نفسه. ما الكلمات التي ستقولها له؟ جرّب أن تمنح نفسك جزءاً من هذا اللطف.\n\nبدلاً من «أنا فاشل»، قل: «لم تسر الأمور كما أردت، ويمكنني أن أتعلم خطوة واحدة». وبدلاً من «يجب أن أنجز كل شيء»، قل: «سأختار ما أستطيع فعله الآن».\n\nاللطف لا يعني تجاهل المسؤولية؛ إنه طريقة لمواجهة الواقع دون إهانة نفسك.',
        'categoryId': 'daily',
        'type': 'text',
        'durationMinutes': 4,
        'tags': <String>['رفق بالنفس', 'توازن', 'حديث داخلي'],
        'sortOrder': 2,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'content_items/pause_before_reacting',
      data: <String, Object>{
        'title': 'مساحة بين الموقف ورد الفعل',
        'summary': 'وقفة قصيرة تساعدك على اختيار رد أكثر اتزاناً',
        'body': 'عندما يزعجك موقف، جرّب ألا ترد في اللحظة نفسها إن كان بإمكانك الانتظار بأمان. خذ نفساً طبيعياً، وحدد ما حدث كما لو أنك تصفه بكاميرا، دون تفسير نوايا الآخرين.\n\nاسأل نفسك: ما الذي أعرفه فعلاً؟ ما الذي أفترضه؟ ما النتيجة التي أريدها من ردي؟\n\nيمكنك قول: «أحتاج بضع دقائق لأفكر ثم نكمل الحديث». إذا كان الموقف يتضمن تهديداً أو إساءة، فالأولوية لسلامتك وطلب الدعم المناسب، لا لإطالة النقاش.',
        'categoryId': 'change',
        'type': 'text',
        'durationMinutes': 5,
        'tags': <String>['علاقات', 'تواصل', 'توازن'],
        'sortOrder': 3,
        'status': 'published',
      },
    ),
    InitialSeedDocument(
      path: 'courses/self_awareness_basics',
      data: <String, Object>{
        'title': 'أساسيات الوعي بالذات',
        'summary': 'مسار مجاني لفهم المشاعر والاحتياجات والاختيارات اليومية',
        'description': 'أربع وحدات قصيرة تساعدك على بناء عادة الملاحظة الذاتية وتحويل الفهم إلى خطوات صغيرة. يمكنك التقدم بالسرعة التي تناسبك.',
        'instructorName': 'محتوى رُوح',
        'level': 'مبتدئ',
        'durationMinutes': 60,
        'sortOrder': 1,
        'status': 'published',
        'isFree': true,
        'price': 0,
        'currency': 'EUR',
      },
    ),
    InitialSeedDocument(
      path: 'courses/self_awareness_basics/lessons/observe_without_judging',
      data: <String, Object>{
        'title': 'الملاحظة دون محاكمة',
        'summary': 'فرّق بين ما حدث وبين الحكم الذي أضفته عليه',
        'body': 'ابدأ بوصف واقعة صغيرة حدثت اليوم. اكتب ما يمكن للكاميرا تسجيله: الكلمات التي قيلت، الوقت، أو الفعل الذي حصل. بعد ذلك اكتب التفسير الذي ظهر في ذهنك.\n\nلاحظ الفرق بين «لم يرد على رسالتي» و«هو لا يهتم بي». الأول وصف، والثاني تفسير قد يحتاج إلى معلومات إضافية.\n\nلا يعني ذلك أن تتجاهل مشاعرك أو تتغاضى عن الأذى؛ بل أن تمنح نفسك فرصة لرؤية الموقف بوضوح قبل اتخاذ قرار.',
        'type': 'text',
        'durationMinutes': 12,
        'sortOrder': 1,
      },
    ),
    InitialSeedDocument(
      path: 'courses/self_awareness_basics/lessons/needs_and_emotions',
      data: <String, Object>{
        'title': 'المشاعر والاحتياجات',
        'summary': 'استخدم الشعور كبداية لسؤال أعمق عن احتياجك',
        'body': 'اختر شعوراً تكرر معك مؤخراً. اسأل: ما الحاجة التي قد تكون مرتبطة به؟ ربما تحتاج إلى راحة، وضوح، تقدير، مساحة، أو تواصل.\n\nهذه احتمالات وليست حقائق جاهزة. جرّب كتابة أكثر من احتمال، ثم اختر سؤالاً واحداً تستطيع طرحه على نفسك أو على شخص تثق به.',
        'type': 'exercise',
        'durationMinutes': 15,
        'sortOrder': 2,
      },
    ),
    InitialSeedDocument(
      path: 'courses/self_awareness_basics/lessons/values_into_actions',
      data: <String, Object>{
        'title': 'من القيمة إلى الفعل',
        'summary': 'حوّل قيمة شخصية إلى سلوك واضح في يومك',
        'body': 'اختر قيمة مهمة بالنسبة لك، ثم اكتب كيف يمكن ملاحظتها في سلوكك. إذا كانت القيمة «التعلم»، فقد يكون الفعل قراءة فقرة. وإذا كانت «الرحمة»، فقد يكون التحدث بلطف مع نفسك أو غيرك.\n\nحدد فعلاً صغيراً ووقتاً مناسباً له. اجعل الخطوة قابلة للتنفيذ حتى في يوم مزدحم.',
        'type': 'exercise',
        'durationMinutes': 15,
        'sortOrder': 3,
      },
    ),
    InitialSeedDocument(
      path: 'courses/self_awareness_basics/lessons/daily_reflection',
      data: <String, Object>{
        'title': 'مراجعة يومية من ثلاث دقائق',
        'summary': 'اجمع ما تعلمته دون تحويله إلى امتحان',
        'body': 'في نهاية اليوم، اكتب: ماذا لاحظت؟ ما الذي ساعدك؟ ما الذي تود تجربته غداً؟\n\nلا تبحث عن يوم مثالي. الهدف أن تبني علاقة أكثر وضوحاً مع خبرتك، وأن تتعامل مع التقدم والتعثر بقدر من الواقعية والرفق.',
        'type': 'text',
        'durationMinutes': 10,
        'sortOrder': 4,
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance',
      data: <String, Object>{
        'title': 'سبعة أيام من العناية المتوازنة',
        'summary': 'تحدٍ مجاني بخطوات يومية قصيرة لبناء مساحة لنفسك',
        'description': 'برنامج خفيف من سبعة أيام. كل يوم يتضمن مهمة اختيارية قصيرة. لا تحتاج إلى تنفيذ كل شيء؛ اختر ما يناسب ظروفك.',
        'durationDays': 7,
        'sortOrder': 1,
        'status': 'published',
        'isFree': true,
        'price': 0,
        'currency': 'EUR',
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance/days/day_01',
      data: <String, Object>{
        'dayNumber': 1,
        'title': 'لاحظ حالتك الحالية',
        'description': 'امنح نفسك ثلاث دقائق للملاحظة',
        'body': 'اكتب كلمة تصف شعورك الآن، وشيئاً واحداً تحتاجه اليوم. لا تحاول تغيير الإجابة.',
        'sortOrder': 1,
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance/days/day_02',
      data: <String, Object>{
        'dayNumber': 2,
        'title': 'خذ وقفة تنفس',
        'description': 'ثلاث دقائق من التنفس الطبيعي الهادئ',
        'body': 'اجلس براحة ولا تجبر النفس على العمق. لاحظ الشهيق والزفير، وتوقف إذا شعرت بانزعاج.',
        'sortOrder': 2,
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance/days/day_03',
      data: <String, Object>{
        'dayNumber': 3,
        'title': 'اختر مهمة واحدة',
        'description': 'عشر دقائق لمهمة صغيرة',
        'body': 'اكتب المهمة التالية فقط، وأبعد مشتتاً واحداً، ثم ابدأ لعشر دقائق.',
        'sortOrder': 3,
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance/days/day_04',
      data: <String, Object>{
        'dayNumber': 4,
        'title': 'أضف لحظة راحة',
        'description': 'استراحة قصيرة دون شعور بالذنب',
        'body': 'اختر استراحة مناسبة: ماء، تمدد لطيف، أو النظر من النافذة. لاحظ ما يناسبك.',
        'sortOrder': 4,
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance/days/day_05',
      data: <String, Object>{
        'dayNumber': 5,
        'title': 'خطوة نحو عادة صغيرة',
        'description': 'صغّر عادة ترغب في بنائها',
        'body': 'اختر فعلاً يستغرق دقيقتين وحدد متى ستجربه. يكفي أن تبدأ.',
        'sortOrder': 5,
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance/days/day_06',
      data: <String, Object>{
        'dayNumber': 6,
        'title': 'تواصل مع شخص ترتاح له',
        'description': 'رسالة بسيطة أو حديث قصير',
        'body': 'أرسل تحية أو شارك شيئاً لطيفاً مع شخص تثق به، إن كان ذلك مناسباً وآمناً لك.',
        'sortOrder': 6,
      },
    ),
    InitialSeedDocument(
      path: 'programs/seven_days_to_balance/days/day_07',
      data: <String, Object>{
        'dayNumber': 7,
        'title': 'راجع ما ناسبك',
        'description': 'اختر خطوة واحدة تريد الاحتفاظ بها',
        'body': 'اكتب ما كان مفيداً خلال الأيام السابقة، وما الذي ترغب في تعديله. اختر عادة واحدة صغيرة للاستمرار بها.',
        'sortOrder': 7,
      },
    ),
  ];

  Future<InitialLibrarySeedResult> seedIfMissing() async {
    final List<DocumentReference<Map<String, dynamic>>> references =
        initialDocuments
            .map((InitialSeedDocument item) => _firestore.doc(item.path))
            .toList(growable: false);
    final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait(references.map((reference) => reference.get()));

    final WriteBatch batch = _firestore.batch();
    int created = 0;
    for (int index = 0; index < initialDocuments.length; index += 1) {
      if (snapshots[index].exists) continue;
      final InitialSeedDocument item = initialDocuments[index];
      batch.set(references[index], <String, Object>{
        ...item.data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      created += 1;
    }

    if (created > 0) {
      await batch.commit();
    }
    return InitialLibrarySeedResult(
      created: created,
      skipped: initialDocuments.length - created,
    );
  }
}
