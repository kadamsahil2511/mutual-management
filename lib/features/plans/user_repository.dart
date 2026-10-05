import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_models.dart';

class UserRepository {
  UserRepository(FirebaseFirestore firestore, String uid)
    : _firestore = firestore,
      _uid = uid;

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _firestore.collection('mutualManagementUsers/$_uid/$name');

  Stream<List<T>> _watch<T>(
    String name,
    T Function(String, Map<String, dynamic>) decode,
  ) => _collection(name).snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => decode(doc.id, doc.data()))
        .toList(growable: false),
  );

  Stream<List<Goal>> watchGoals() => _watch('goals', Goal.fromMap);
  Stream<List<Sip>> watchSips() => _watch('sips', Sip.fromMap);
  Stream<List<Contribution>> watchContributions() =>
      _watch('contributions', Contribution.fromMap);

  Future<void> saveGoal(Goal goal) =>
      _collection('goals').doc(goal.id).set(goal.toMap());

  Future<void> saveSip(Sip sip) =>
      _collection('sips').doc(sip.id).set(sip.toMap());

  Future<void> cancelSip(String id) =>
      _collection('sips').doc(id).update({'isActive': false});

  Future<bool> recordContribution(Contribution contribution) async {
    final id = contribution.sipId == null
        ? contribution.id
        : '${contribution.sipId}_${_dateKey(contribution.effectiveDate)}';
    final ref = _collection('contributions').doc(id);
    return _firestore.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) return false;
      transaction.set(ref, contribution.toMap());
      return true;
    });
  }

  Future<void> saveProfile(String name) => _firestore
      .collection('mutualManagementUsers')
      .doc(_uid)
      .set({'name': name.trim()}, SetOptions(merge: true));

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
