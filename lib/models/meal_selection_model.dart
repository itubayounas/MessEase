const List<String> mealTypes = ['breakfast', 'lunch', 'dinner'];

// What one student ticked for one date.
class MealSelection {
  final String uid;
  final String date; // "yyyy-MM-dd"
  final bool breakfast;
  final bool lunch;
  final bool dinner;

  // The meal rate that was in force when each meal was ticked, e.g.
  // {'lunch': 150}. Saving it means a later rate change does not alter
  // charges that were already earned.
  final Map<String, double> rates;

  const MealSelection({
    this.uid = '',
    required this.date,
    this.breakfast = false,
    this.lunch = false,
    this.dinner = false,
    this.rates = const {},
  });

  bool isTicked(String meal) {
    switch (meal) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      default:
        return dinner;
    }
  }

  List<String> get tickedMeals => mealTypes.where(isTicked).toList();

  double? rateFor(String meal) => rates[meal];

  factory MealSelection.fromMap(Map<String, dynamic> map) {
    return MealSelection(
      uid: map['uid'] as String? ?? '',
      date: map['date'] as String? ?? '',
      breakfast: map['breakfast'] as bool? ?? false,
      lunch: map['lunch'] as bool? ?? false,
      dinner: map['dinner'] as bool? ?? false,
      rates: {
        for (final m in mealTypes)
          if (map['${m}Rate'] is num) m: (map['${m}Rate'] as num).toDouble(),
      },
    );
  }
}