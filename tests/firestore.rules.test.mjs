import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-rooh-rules';
let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  await testEnvironment.cleanup();
});

function signedIn(uid, email = \`\${uid}@example.com\`) {
  return testEnvironment.authenticatedContext(uid, { email }).firestore();
}

async function seed(path, data) {
  await testEnvironment.withSecurityRulesDisabled(async ({ firestore }) => {
    await setDoc(doc(firestore, path), data);
  });
}

function profileData(uid, email = \`\${uid}@example.com\`) {
  return {
    uid,
    email,
    displayName: uid,
    locale: 'ar',
    interests: ['وعي'],
    primaryGoal: 'فهم نفسي',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    schemaVersion: 1,
  };
}

function enrollmentData(userId, courseId) {
  return {
    userId,
    courseId,
    status: 'active',
    completedLessonIds: [],
    progressPercent: 0,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

test('users can read only their own profile and cannot elevate privileges', async () => {
  const alice = signedIn('alice');
  const bob = signedIn('bob');

  await seed('users/alice', profileData('alice'));
  await seed('users/bob', profileData('bob'));

  await assertSucceeds(getDoc(doc(alice, 'users/alice')));
  await assertFails(getDoc(doc(bob, 'users/alice')));
  await assertFails(getDocs(collection(alice, 'users')));

  await assertFails(
    updateDoc(doc(alice, 'users/alice'), {
      email: 'attacker@example.com',
      updatedAt: serverTimestamp(),
    }),
  );

  await assertFails(
    updateDoc(doc(alice, 'users/alice'), {
      isAdmin: true,
      updatedAt: serverTimestamp(),
    }),
  );
});

test('only an existing administrator can access admin-managed collections', async () => {
  const admin = signedIn('admin');
  const regularUser = signedIn('alice');

  await seed('admins/admin', { createdBy: 'owner' });

  await assertSucceeds(getDoc(doc(admin, 'admins/admin')));
  await assertFails(getDoc(doc(regularUser, 'admins/admin')));
  await assertFails(setDoc(doc(regularUser, 'admins/alice'), {}));

  await assertSucceeds(
    setDoc(doc(admin, 'categories/awareness'), {
      title: 'وعي',
      description: 'التصنيف الأساسي',
      sortOrder: 1,
    }),
  );
  await assertFails(
    setDoc(doc(regularUser, 'categories/unauthorized'), {
      title: 'غير مصرح',
      description: '',
      sortOrder: 2,
    }),
  );
});

test('users can save and complete published content only in their own library', async () => {
  const alice = signedIn('alice');
  const bob = signedIn('bob');

  await seed('content_items/published-item', {
    title: 'جلسة التنفس',
    status: 'published',
  });
  await seed('content_items/draft-item', {
    title: 'مسودة',
    status: 'draft',
  });

  await assertSucceeds(
    setDoc(doc(alice, 'users/alice/savedContent/published-item'), {
      contentId: 'published-item',
      createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(alice, 'users/alice/savedContent/draft-item'), {
      contentId: 'draft-item',
      createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    getDoc(doc(bob, 'users/alice/savedContent/published-item')),
  );

  await assertSucceeds(
    setDoc(doc(alice, 'users/alice/contentProgress/published-item'), {
      contentId: 'published-item',
      completed: true,
      completedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(alice, 'users/alice/contentProgress/draft-item'), {
      contentId: 'draft-item',
      completed: true,
      completedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('free courses permit self-enrollment while paid lessons require active access', async () => {
  const alice = signedIn('alice');
  const bob = signedIn('bob');

  await seed('courses/free-course', {
    title: 'مقدمة مجانية',
    status: 'published',
    isFree: true,
    price: 0,
    currency: 'USD',
  });
  await seed('courses/paid-course', {
    title: 'الكورس المتقدم',
    status: 'published',
    isFree: false,
    price: 40,
    currency: 'USD',
  });
  await seed('courses/paid-course/lessons/lesson-1', {
    title: 'الدرس الأول',
    body: 'نص الدرس',
  });

  await assertSucceeds(
    setDoc(doc(alice, 'users/alice/enrollments/free-course'), {
      ...enrollmentData('alice', 'free-course'),
    }),
  );
  await assertFails(
    setDoc(doc(alice, 'users/alice/enrollments/paid-course'), {
      ...enrollmentData('alice', 'paid-course'),
    }),
  );
  await assertFails(
    getDoc(doc(alice, 'courses/paid-course/lessons/lesson-1')),
  );

  await seed(
    'users/alice/enrollments/paid-course',
    enrollmentData('alice', 'paid-course'),
  );
  await assertSucceeds(
    getDoc(doc(alice, 'courses/paid-course/lessons/lesson-1')),
  );
  await assertFails(
    getDoc(doc(bob, 'courses/paid-course/lessons/lesson-1')),
  );
});

test('program days remain locked until the user enrolls in a free published program', async () => {
  const alice = signedIn('alice');

  await seed('programs/free-challenge', {
    title: 'تحدي 7 أيام',
    status: 'published',
    isFree: true,
    price: 0,
  });
  await seed('programs/free-challenge/days/day-1', {
    dayNumber: 1,
    title: 'راقب أفكارك',
  });
  await seed('programs/paid-challenge', {
    title: 'برنامج متقدم',
    status: 'published',
    isFree: false,
    price: 20,
  });

  await assertFails(
    getDoc(doc(alice, 'programs/free-challenge/days/day-1')),
  );
  await assertSucceeds(
    setDoc(doc(alice, 'users/alice/programEnrollments/free-challenge'), {
      userId: 'alice',
      programId: 'free-challenge',
      status: 'active',
      completedDayIds: [],
      progressPercent: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    getDoc(doc(alice, 'programs/free-challenge/days/day-1')),
  );
  await assertFails(
    setDoc(doc(alice, 'users/alice/programEnrollments/paid-challenge'), {
      userId: 'alice',
      programId: 'paid-challenge',
      status: 'active',
      completedDayIds: [],
      progressPercent: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('manual paid-course requests are validated and admin approval grants access atomically', async () => {
  const alice = signedIn('alice');
  const bob = signedIn('bob');
  const admin = signedIn('admin');

  await seed('admins/admin', { createdBy: 'owner' });
  await seed('courses/paid-course', {
    title: 'الكورس المتقدم',
    status: 'published',
    isFree: false,
    price: 40,
    currency: 'USD',
  });
  await seed('courses/paid-course/lessons/lesson-1', {
    title: 'الدرس الأول',
    body: 'محتوى الكورس المدفوع',
  });

  const validRequest = {
    userId: 'alice',
    courseId: 'paid-course',
    courseTitle: 'الكورس المتقدم',
    amount: 40,
    currency: 'USD',
    transferReference: 'SC-2026-1125',
    status: 'pending',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  await assertSucceeds(
    setDoc(doc(alice, 'paymentRequests/request-1'), validRequest),
  );
  await assertFails(
    getDoc(doc(bob, 'paymentRequests/request-1')),
  );
  await assertFails(
    updateDoc(doc(alice, 'paymentRequests/request-1'), {
      status: 'approved',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(alice, 'paymentRequests/request-wrong-amount'), {
      ...validRequest,
      amount: 1,
    }),
  );

  const pendingForOwner = query(
    collection(alice, 'paymentRequests'),
    where('userId', '==', 'alice'),
  );
  await assertSucceeds(getDocs(pendingForOwner));
  await assertFails(getDocs(collection(alice, 'paymentRequests')));

  const batch = writeBatch(admin);
  batch.set(
    doc(admin, 'users/alice/enrollments/paid-course'),
    enrollmentData('alice', 'paid-course'),
  );
  batch.update(doc(admin, 'paymentRequests/request-1'), {
    status: 'approved',
    reviewNote: 'تم التحقق من التحويل',
    reviewedBy: 'admin',
    reviewedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  await assertSucceeds(batch.commit());
  await assertSucceeds(
    getDoc(doc(alice, 'courses/paid-course/lessons/lesson-1')),
  );
});
