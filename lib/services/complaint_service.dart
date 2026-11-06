import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

// Collection "complaints": one document per complaint.
class ComplaintService {
  final _col = FirebaseFirestore.instance.collection('complaints');

  List<Complaint> _toList(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(Complaint.fromDoc).toList();
    final now = DateTime.now();
    list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    return list;
  }

  Stream<List<Complaint>> watchMine(String uid) =>
      _col.where('uid', isEqualTo: uid).snapshots().map(_toList);

  Stream<List<Complaint>> watchAll() => _col.snapshots().map(_toList);

  // FR-6.1 / FR-6.2
  Future<void> submit({
    required String uid,
    required String username,
    required String category,
    required String description,
    String? photoBase64,
  }) {
    return _col.add({
      'uid': uid,
      'username': username,
      'category': category,
      'description': description,
      if (photoBase64 != null) 'photo': photoBase64,
      'status': 'Pending',
      'response': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // FR-6.3 / FR-6.4 (admin)
  Future<void> updateStatus({
    required String id,
    required String status,
    required String response,
  }) {
    return _col.doc(id).update({
      'status': status,
      'response': response,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}