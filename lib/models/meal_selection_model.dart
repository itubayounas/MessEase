const List<String> mealTypes = ['breakfast', 'lunch', 'dinner'];

// What one student ticked for one date.
// For each meal it stores the ticked items and the price each item had
// when it was ticked, e.g. lunch -> {'Chicken Biryani': 250, 'Salan': 200}.
// Saving the price means a later menu price change does not alter charges
// that were already earned.
class MealSelection {
  final String uid;
  final String date; // "yyyy-MM-dd"
  final Map<String, Map<String, double>> items; // meal -> {item name: price}

  const MealSelection({
    this.uid = '',
    required this.date,
    this.items = const {},
  });

  Map<String, double> itemsOf(String meal) => items[meal] ?? const {};

  bool hasItem(String meal, String name) => itemsOf(meal).containsKey(name);

  // A meal counts as ticked when at least one of its items is ticked.
  bool isTicked(String meal) => itemsOf(meal).isNotEmpty;

  List<String> get tickedMeals => mealTypes.where(isTicked).toList();

  factory MealSelection.fromMap(Map<String, dynamic> map) {
    final items = <String, Map<String, double>>{};

    for (final m in mealTypes) {
      final raw = map['${m}Items'];
      if (raw is Map) {
        items[m] = {
          for (final e in raw.entries)
            e.key.toString(): (e.value as num?)?.toDouble() ?? 0,
        };
      } else if (map[m] == true) {
        // Older data from before items existed: one generic "Meal" item.
        items[m] = {'Meal': (map['${m}Rate'] as num?)?.toDouble() ?? 0};
      }
    }

    return MealSelection(
      uid: map['uid'] as String? ?? '',
      date: map['date'] as String? ?? '',
      items: items,
    );
  }
}