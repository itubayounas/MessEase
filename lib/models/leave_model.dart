import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_helpers.dart';

// One leave / home application. Dates are "yyyy-MM-dd" keys.
// status: 'pending' | 'approved' | 'rejected'
class LeaveRequest {
  final String id;
  final String uid;
  final String username;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;

  // false after the admin decides, until the student opens the Leave tab.
  // Drives the notification badge (FR-5.6).
  final bool studentSeen;
  final DateTime? createdAt;

  const LeaveRequest({
    required this.id,
    required this.uid,
    required this.username,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.studentSeen,
    this.createdAt,
  });

  factory LeaveRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return LeaveRequest(
      id: doc.id,
      uid: m['uid'] as String? ?? '',
      username: m['username'] as String? ?? '',
      startDate: m['startDate'] as String? ?? '',
      endDate: m['endDate'] as String? ?? '',
      reason: m['reason'] as String? ?? '',
      status: m['status'] as String? ?? 'pending',
      studentSeen: m['studentSeen'] as bool? ?? true,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPending => status == 'pending';

  // True if this is an APPROVED leave that includes [key].
  bool covers(String key) =>
      status == 'approved' &&
      key.compareTo(startDate) >= 0 &&
      key.compareTo(endDate) <= 0;

  // Every date key from start to end, inclusive.
  List<String> get dates {
    final start = DateTime.tryParse(startDate);
    final end = DateTime.tryParse(endDate);
    if (start == null || end == null) return [];
    final out = <String>[];
    for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
      out.add(dateKey(d));
    }
    return out;
  }

  int get days => dates.length;
}