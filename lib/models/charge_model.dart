import 'meal_selection_model.dart';

// "Rs 150" or "Rs 12.50"
String money(double v) =>
    'Rs ${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';

// One charged item (FR-4.6: date, meal type, amount).
class ChargeItem {
  final String date;
  final String meal;
  final String item; // e.g. "Chicken Biryani"
  final double amount;

  const ChargeItem({
    required this.date,
    required this.meal,
    required this.item,
    required this.amount,
  });
}

// All charges of one student for a set of selections (e.g. one month).
class Bill {
  final List<ChargeItem> items;
  const Bill(this.items);

  double get total => items.fold<double>(0, (sum, i) => sum + i.amount);
  int get mealCount => items.length; // number of plates / items

  int countOf(String meal) => items.where((i) => i.meal == meal).length;

  double subtotalOf(String meal) => items
      .where((i) => i.meal == meal)
      .fold<double>(0, (sum, i) => sum + i.amount);
}

// FR-4.1: a charge exists only for items that are ticked.
// Each item costs the price saved when it was ticked; if that price is 0
// (the admin gave the item no price), the default meal rate is used.
Bill buildBill(Iterable<MealSelection> selections, double defaultRate) {
  final sorted = selections.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final items = <ChargeItem>[];
  for (final sel in sorted) {
    for (final meal in mealTypes) {
      for (final entry in sel.itemsOf(meal).entries) {
        items.add(ChargeItem(
          date: sel.date,
          meal: meal,
          item: entry.key,
          amount: entry.value > 0 ? entry.value : defaultRate,
        ));
      }
    }
  }
  return Bill(items);
}