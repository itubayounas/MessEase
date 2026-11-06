import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_selection_model.dart';
import '../utils/date_helpers.dart';

// Collection "meal_selections": one document per student per day,
// id = "<uid>_<yyyy-MM-dd>", fields: uid, date and, per meal, a map of
// the ticked items with their price:
//   lunchItems: { "Chicken Biryani": 250, "2 Roti + Salan": 200 }
class MealService {
  final _col = FirebaseFirestore.instance.collection('meal_selections');

  // All of one student's selections, keyed by date. Used for the weekly
  // ticking screen, the history screen and the student's charges.
  // Filtering on uid only means no composite index is needed.
  Stream<Map<String, MealSelection>> watchMine(String uid) {
    return _col.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final result = <String, MealSelection>{};
      for (final doc in snap.docs) {
        final sel = MealSelection.fromMap(doc.data());
        result[sel.date] = sel;
      }
      return result;
    });
  }

  // Tick (true) or untick (false) one item of one meal. merge:true leaves
  // all other items and meals of that day untouched. The price is saved
  // with the item so later price changes don't alter old charges.
  Future<void> setItem({
    required String uid,
    required String date,
    required String meal,
    required String itemName,
    required double price,
    required bool ticked,
  }) {
    return _col.doc('${uid}_$date').set({
      'uid': uid,
      'date': date,
      '${meal}Items': {
        itemName: ticked ? price : FieldValue.delete(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Admin / kitchen: how many plates of each item were ticked on [date].
  // Result: meal -> {item name: number of students}.
  Stream<Map<String, Map<String, int>>> watchCounts(String date) {
    return _col.where('date', isEqualTo: date).snapshots().map((snap) {
      final counts = {for (final m in mealTypes) m: <String, int>{}};
      for (final doc in snap.docs) {
        final sel = MealSelection.fromMap(doc.data());
        for (final m in mealTypes) {
          for (final name in sel.itemsOf(m).keys) {
            counts[m]![name] = (counts[m]![name] ?? 0) + 1;
          }
        }
      }
      return counts;
    });
  }

  // Admin billing: every student's selections for one month.
  // A range on the single field "date", so no composite index is needed.
  Stream<List<MealSelection>> watchMonth(DateTime month) {
    return _col
        .where('date', isGreaterThanOrEqualTo: monthStartKey(month))
        .where('date', isLessThan: nextMonthStartKey(month))
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MealSelection.fromMap(d.data())).toList());
  }
}