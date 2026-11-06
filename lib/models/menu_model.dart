// Days in the same order as DateTime.weekday (1 = Monday ... 7 = Sunday).
const List<String> weekDays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

// The menu of one day, with the price of each meal.
// A price of 0 means "not set" (the default meal rate is used instead).
// The Firestore document id is the lowercase day name.
class DayMenu {
  final String day;
  final String breakfast;
  final String lunch;
  final String dinner;
  final double breakfastPrice;
  final double lunchPrice;
  final double dinnerPrice;

  const DayMenu({
    required this.day,
    this.breakfast = '',
    this.lunch = '',
    this.dinner = '',
    this.breakfastPrice = 0,
    this.lunchPrice = 0,
    this.dinnerPrice = 0,
  });

  String dishOf(String meal) {
    switch (meal) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      default:
        return dinner;
    }
  }

  double priceOf(String meal) {
    switch (meal) {
      case 'breakfast':
        return breakfastPrice;
      case 'lunch':
        return lunchPrice;
      default:
        return dinnerPrice;
    }
  }

  Map<String, dynamic> toMap() => {
        'day': day,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'breakfastPrice': breakfastPrice,
        'lunchPrice': lunchPrice,
        'dinnerPrice': dinnerPrice,
      };

  factory DayMenu.fromMap(String day, Map<String, dynamic> map) {
    double price(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return DayMenu(
      day: day,
      breakfast: map['breakfast'] as String? ?? '',
      lunch: map['lunch'] as String? ?? '',
      dinner: map['dinner'] as String? ?? '',
      breakfastPrice: price('breakfastPrice'),
      lunchPrice: price('lunchPrice'),
      dinnerPrice: price('dinnerPrice'),
    );
  }
}