import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> complaintCategories = [
  'Food Quality',
  'Hygiene',
  'Service',
  'Facilities',
  'Other',
];

const List<String> complaintStatuses = ['Pending', 'In Review', 'Resolved'];

class Complaint {
  final String id;
  final String uid;
  final String username;
  final String category;
  final String description;
  final String? photo; // small compressed image, stored as base64 text
  final String status; // one of complaintStatuses
  final String response; // admin's note
  final DateTime? createdAt;

  const Complaint({
    required this.id,
    required this.uid,
    required this.username,
    required this.category,
    required this.description,
    this.photo,
    required this.status,
    required this.response,
    this.createdAt,
  });

  factory Complaint.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Complaint(
      id: doc.id,
      uid: m['uid'] as String? ?? '',
      username: m['username'] as String? ?? '',
      category: m['category'] as String? ?? 'Other',
      description: m['description'] as String? ?? '',
      photo: m['photo'] as String?,
      status: m['status'] as String? ?? 'Pending',
      response: m['response'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Uint8List? get photoBytes {
    final p = photo;
    if (p == null || p.isEmpty) return null;
    try {
      return base64Decode(p);
    } catch (_) {
      return null;
    }
  }
}