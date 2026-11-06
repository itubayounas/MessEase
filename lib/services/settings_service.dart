import 'package:cloud_firestore/cloud_firestore.dart';

// Mess-wide settings, stored in one document: settings/mess
// Field "mealRate" = amount charged per ticked meal (FR-4.2).
class SettingsService {
  final _doc = FirebaseFirestore.instance.collection('settings').doc('mess');

  // Live rate; 0 means the admin has not set one yet.
  Stream<double> watchRate() {
    return _doc.snapshots().map(
          (s) => (s.data()?['mealRate'] as num?)?.toDouble() ?? 0,
        );
  }

  // One-time read used when a meal is ticked. Returns null if no rate is
  // set or the read fails, so ticking never gets blocked by this.
  Future<double?> getRate() async {
    try {
      final s = await _doc.get().timeout(const Duration(seconds: 3));
      return (s.data()?['mealRate'] as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  // Admin only (enforced by Firestore rules).
  Future<void> setRate(double rate) {
    return _doc.set({'mealRate': rate}, SetOptions(merge: true));
  }
}