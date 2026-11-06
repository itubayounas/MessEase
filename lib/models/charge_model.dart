import 'meal_selection_model.dart';

// "Rs 150" or "Rs 12.50"
String money(double v) =>
    'Rs ${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';

// One charged meal (FR-4.6: date, meal type, amount).
class ChargeItem {
  final String date;
  final String meal;
  final double amount;

  const ChargeItem({
    required this.date,
    required this.meal,
    required this.amount,
  });
}

// All charges of one student for a set of selections (e.g. one month).
class Bill {
  final List<ChargeItem> items;
  const Bill(this.items);

  double get total => items.fold<double>(0, (sum, i) => sum + i.amount);
  int get mealCount => items.length;

  int countOf(String meal) => items.where((i) => i.meal == meal).length;

  double subtotalOf(String meal) => items
      .where((i) => i.meal == meal)
      .fold<double>(0, (sum, i) => sum + i.amount);
}

// FR-4.1: a charge exists only for meals that are ticked.
// Each meal costs the rate saved when it was ticked; if none was saved
// (older data), the current rate is used instead.
Bill buildBill(Iterable<MealSelection> selections, double currentRate) {
  final sorted = selections.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final items = <ChargeItem>[];
  for (final sel in sorted) {
    for (final meal in mealTypes) {
      if (sel.isTicked(meal)) {
        items.add(ChargeItem(
          date: sel.date,
          meal: meal,
          amount: sel.rateFor(meal) ?? currentRate,
        ));
      }
    }
  }
  return Bill(items);
}