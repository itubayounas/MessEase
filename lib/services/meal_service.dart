import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_selection_model.dart';
import '../utils/date_helpers.dart';
import 'menu_service.dart';
import 'settings_service.dart';

// Collection "meal_selections": one document per student per day,
// id = "<uid>_<yyyy-MM-dd>", fields: uid, date, breakfast, lunch, dinner,
// plus breakfastRate / lunchRate / dinnerRate (rate when ticked).
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

  // Tick (true) or untick (false) a single meal. merge:true leaves the
  // other meals of that day untouched. When ticking, the current meal rate
  // (the dish price, else the default rate) is saved with the meal so later price changes don't alter old charges.
  Future<void> setMeal({
    required String uid,
    required String date,
    required String meal,
    required bool ticked,
  }) async {
    // Price = the dish's price on that weekday; if the admin gave the dish
    // no price, fall back to the default meal rate.
    double? rate;
    if (ticked) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) {
        rate = await MenuService().getPrice(dayNameOf(parsed), meal);
      }
      rate ??= await SettingsService().getRate();
    }

    await _col.doc('${uid}_$date').set({
      'uid': uid,
      'date': date,
      meal: ticked,
      if (rate != null) '${meal}Rate': rate,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Admin / kitchen: how many students ticked each meal on [date].
  Stream<Map<String, int>> watchCounts(String date) {
    return _col.where('date', isEqualTo: date).snapshots().map((snap) {
      final counts = {for (final m in mealTypes) m: 0};
      for (final doc in snap.docs) {
        final sel = MealSelection.fromMap(doc.data());
        for (final m in mealTypes) {
          if (sel.isTicked(m)) counts[m] = counts[m]! + 1;
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