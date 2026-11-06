import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_model.dart';

// Collection "leaves": one document per application.
class LeaveService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('leaves');

  // Newest first. Sorted here so no composite index is needed.
  List<LeaveRequest> _toList(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(LeaveRequest.fromDoc).toList();
    final now = DateTime.now();
    list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return list;
  }

  // Student: own applications (FR-5.7).
  Stream<List<LeaveRequest>> watchMine(String uid) =>
      _col.where('uid', isEqualTo: uid).snapshots().map(_toList);

  // Admin: all applications (FR-5.2).
  Stream<List<LeaveRequest>> watchAll() => _col.snapshots().map(_toList);

  // FR-5.1
  Future<void> apply({
    required String uid,
    required String username,
    required String startDate,
    required String endDate,
    required String reason,
  }) {
    return _col.add({
      'uid': uid,
      'username': username,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
      'status': 'pending',
      'studentSeen': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Student opened the Leave tab: clear the notification badge.
  Future<void> markSeen(List<LeaveRequest> list) async {
    final unseen = list.where((l) => !l.studentSeen).toList();
    if (unseen.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final l in unseen) {
        batch.update(_col.doc(l.id), {'studentSeen': true});
      }
      await batch.commit();
    } catch (_) {
      // Not important enough to bother the student with.
    }
  }

  // FR-5.3 + FR-5.4: approve or reject. On approval, every meal in the leave
  // period is unticked (written as false) in the same atomic batch. Unticked
  // meals are never charged, which also covers FR-5.5.
  Future<void> decide(LeaveRequest r, {required bool approve}) async {
    final batch = _db.batch();

    batch.update(_col.doc(r.id), {
      'status': approve ? 'approved' : 'rejected',
      'studentSeen': false, // triggers the student's notification
      'decidedAt': FieldValue.serverTimestamp(),
    });

    if (approve) {
      for (final date in r.dates) {
        batch.set(
          _db.collection('meal_selections').doc('${r.uid}_$date'),
          // No merge: this replaces the day's document, so every ticked
          // item is cleared.
          {
            'uid': r.uid,
            'date': date,
            'breakfastItems': <String, dynamic>{},
            'lunchItems': <String, dynamic>{},
            'dinnerItems': <String, dynamic>{},
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }
    }

    await batch.commit();
  }
}