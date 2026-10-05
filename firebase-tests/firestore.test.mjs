import { after, before, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, Timestamp, runTransaction, onSnapshot } from 'firebase/firestore';

let env;
const day = (date) => Timestamp.fromDate(new Date(`${date}T00:00:00.000Z`));
const goal = { name: 'Home', targetPaise: 10000000, targetDate: day('2030-01-01'), assumedAnnualReturn: 7.5 };
const sip = { schemeCode: '118955', amountPaise: 50000, startDate: day('2026-01-31'), intervalMonths: 1, goalId: null, isActive: true };
const investment = { schemeCode: '118955', amountPaise: 50000, units: 20, nav: 25, navDate: day('2026-02-27'), effectiveDate: day('2026-02-28'), sipId: null, goalId: null };
const record = (db, uid, path) => doc(db, `mutualManagementUsers/${uid}/${path}`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-mutual-management',
    firestore: { rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(() => env.clearFirestore());
after(async () => env?.cleanup());

test('each account starts empty and only its owner can read or write its records', async () => {
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  const guest = env.unauthenticatedContext().firestore();
  assert.equal((await getDocs(collection(alice, 'mutualManagementUsers/alice/goals'))).size, 0);
  await assertSucceeds(setDoc(record(alice, 'alice', 'goals/home'), goal));
  assert.equal((await getDocs(collection(bob, 'mutualManagementUsers/bob/goals'))).size, 0);
  for (const outsider of [bob, guest]) {
    await assertFails(getDoc(record(outsider, 'alice', 'goals/home')));
    await assertFails(getDocs(collection(outsider, 'mutualManagementUsers/alice/goals')));
    await assertFails(setDoc(record(outsider, 'alice', 'goals/stolen'), goal));
    await assertFails(updateDoc(record(outsider, 'alice', 'goals/home'), { name: 'Changed' }));
  }
  await assertFails(setDoc(doc(alice, 'unrelated/example'), { visible: true }));
  await assertFails(setDoc(record(alice, 'alice', 'arbitrary/example'), { visible: true }));
});

test('money and goal dates require the expected shape and positive integer paise', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = record(db, 'alice', 'goals/home');
  await assertSucceeds(setDoc(ref, goal));
  for (const bad of [
    { targetPaise: -1 }, { targetPaise: 100.5 }, { name: '' },
    { targetDate: '2030-01-01' }, { assumedAnnualReturn: -101 }, { owner: 'bob' },
  ]) await assertFails(setDoc(ref, { ...goal, ...bad }));
});

test('SIPs permit monthly or quarterly schedules and owner cancellation', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertSucceeds(setDoc(record(db, 'alice', 'sips/monthly'), sip));
  await assertSucceeds(setDoc(record(db, 'alice', 'sips/quarterly'), { ...sip, intervalMonths: 3 }));
  await assertSucceeds(updateDoc(record(db, 'alice', 'sips/monthly'), { isActive: false }));
  for (const bad of [{ intervalMonths: 2 }, { amountPaise: 0 }, { schemeCode: 'unknown' }, { schemeCode: '123456' }, { goalId: 'missing' }]) {
    await assertFails(setDoc(record(db, 'alice', 'sips/invalid'), { ...sip, ...bad }));
  }
});

test('contributions are immutable and reject invented units or future NAV', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = record(db, 'alice', 'contributions/once');
  await assertSucceeds(setDoc(ref, investment));
  await assertFails(updateDoc(ref, { amountPaise: 60000 }));
  await assertFails(deleteDoc(ref));
  for (const bad of [{ units: 999 }, { nav: 0 }, { navDate: day('2026-03-01') }, { amountPaise: 0 }, { goalId: 'missing' }, { schemeCode: '123456' }]) {
    await assertFails(setDoc(record(db, 'alice', 'contributions/invalid'), { ...investment, ...bad }));
  }
});

test('SIP contribution IDs bind the exact due date, schedule, and SIP fields', async () => {
  const db = env.authenticatedContext('alice').firestore();
  await setDoc(record(db, 'alice', 'goals/home'), goal);
  await setDoc(record(db, 'alice', 'goals/other'), { ...goal, name: 'Other' });
  await setDoc(record(db, 'alice', 'sips/monthly'), { ...sip, goalId: 'home' });
  await setDoc(record(db, 'alice', 'sips/quarterly'), { ...sip, startDate: day('2026-01-31'), intervalMonths: 3 });
  const valid = { ...investment, sipId: 'monthly', goalId: 'home' };
  await assertSucceeds(setDoc(record(db, 'alice', 'contributions/monthly_2026-02-28'), valid));
  // Same date under another ID and a plausible but incorrect date suffix both fail.
  await assertFails(setDoc(record(db, 'alice', 'contributions/monthly_copy_2026-02-28'), valid));
  await assertFails(setDoc(record(db, 'alice', 'contributions/monthly_2026-02-27'), valid));
  await assertFails(setDoc(record(db, 'alice', 'contributions/monthly_2026-03-28'), {
    ...valid, effectiveDate: day('2026-03-28'), navDate: day('2026-03-27'),
  }));
  await assertFails(setDoc(record(db, 'alice', 'contributions/monthly_2030-02-28'), {
    ...valid, effectiveDate: day('2030-02-28'), navDate: day('2030-02-27'),
  }));
  await assertFails(setDoc(record(db, 'alice', 'contributions/monthly_wrong-goal_2026-02-28'), {
    ...valid, goalId: 'other',
  }));
  await assertSucceeds(setDoc(record(db, 'alice', 'contributions/quarterly_2026-04-30'), {
    ...investment, sipId: 'quarterly', effectiveDate: day('2026-04-30'), navDate: day('2026-04-29'),
  }));
  await assertFails(setDoc(record(db, 'alice', 'contributions/quarterly_2026-02-28'), {
    ...investment, sipId: 'quarterly', effectiveDate: day('2026-02-28'), navDate: day('2026-02-27'),
  }));
  await assertFails(setDoc(record(db, 'alice', 'contributions/missing_2026-02-28'), { ...valid, sipId: 'missing' }));
  await assertFails(setDoc(record(db, 'alice', 'contributions/monthly_2026-03-31'), { ...valid, amountPaise: 75000, units: 30, effectiveDate: day('2026-03-31') }));
  await updateDoc(record(db, 'alice', 'sips/monthly'), { isActive: false });
  await assertFails(setDoc(record(db, 'alice', 'contributions/monthly_2026-03-31'), { ...valid, effectiveDate: day('2026-03-31') }));
});

test('two clients atomically deduplicate an installment and both receive the saved record', async () => {
  const first = env.authenticatedContext('alice').firestore();
  const second = env.authenticatedContext('alice').firestore();
  await setDoc(record(first, 'alice', 'sips/monthly'), sip);
  const saved = new Promise((resolve, reject) => {
    const timer = setTimeout(() => { stop(); reject(new Error('Second client never received the contribution')); }, 10000);
    const stop = onSnapshot(record(second, 'alice', 'contributions/monthly_2026-02-28'), (snapshot) => {
      if (snapshot.exists() && !snapshot.metadata.hasPendingWrites) {
        clearTimeout(timer); stop(); resolve(snapshot.data());
      }
    }, reject);
  });
  const add = (db) => runTransaction(db, async (transaction) => {
    const ref = record(db, 'alice', 'contributions/monthly_2026-02-28');
    if ((await transaction.get(ref)).exists()) return false;
    transaction.set(ref, { ...investment, sipId: 'monthly' });
    return true;
  });
  const outcomes = await Promise.all([add(first), add(second)]);
  assert.deepEqual(outcomes.sort(), [false, true]);
  assert.equal((await saved).amountPaise, 50000);
  assert.equal((await getDocs(collection(second, 'mutualManagementUsers/alice/contributions'))).size, 1);
});
