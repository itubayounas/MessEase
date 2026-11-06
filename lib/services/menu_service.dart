import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class MenuService {
  final _col = FirebaseFirestore.instance.collection('menu');

  // Live stream of the whole week: {'monday': DayMenu, ...}.
  // Days the admin hasn't filled in yet are simply missing from the map.
  Stream<Map<String, DayMenu>> watchWeek() {
    return _col.snapshots().map((snap) {
      return {
        for (final doc in snap.docs) doc.id: DayMenu.fromMap(doc.id, doc.data()),
      };
    });
  }

  // Admin only (enforced by Firestore rules). Creates or overwrites one day.
  Future<void> saveDay(DayMenu menu) {
    return _col.doc(menu.day).set(menu.toMap());
  }

  // The price of one meal on one weekday, or null if none is set.
  // Used when a student ticks a meal, so ticking never gets blocked.
  Future<double?> getPrice(String day, String meal) async {
    try {
      final s = await _col.doc(day).get().timeout(const Duration(seconds: 3));
      final v = (s.data()?['${meal}Price'] as num?)?.toDouble();
      return (v != null && v > 0) ? v : null;
    } catch (_) {
      return null;
    }
  }
}