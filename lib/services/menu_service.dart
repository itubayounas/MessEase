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
}