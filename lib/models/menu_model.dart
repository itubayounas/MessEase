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

// One orderable item of a meal, e.g. "Chicken Biryani" at Rs 250.
// A price of 0 means "not set" (the default meal rate is used instead).
class MenuItem {
  final String name;
  final double price;

  const MenuItem({required this.name, this.price = 0});

  Map<String, dynamic> toMap() => {'name': name, 'price': price};

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

// The menu of one day. Each meal (breakfast / lunch / dinner) has a list
// of items, so lunch can offer both "Chicken Biryani" and "2 Roti + Salan",
// each with its own price. The Firestore document id is the lowercase day name.
class DayMenu {
  final String day;
  final List<MenuItem> breakfast;
  final List<MenuItem> lunch;
  final List<MenuItem> dinner;

  const DayMenu({
    required this.day,
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
  });

  List<MenuItem> itemsOf(String meal) {
    switch (meal) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      default:
        return dinner;
    }
  }

  Map<String, dynamic> toMap() => {
        'day': day,
        'breakfast': breakfast.map((i) => i.toMap()).toList(),
        'lunch': lunch.map((i) => i.toMap()).toList(),
        'dinner': dinner.map((i) => i.toMap()).toList(),
      };

  // Also understands the older format (one text per meal plus
  // "<meal>Price"), so menus saved earlier still show up.
  static List<MenuItem> _parse(Map<String, dynamic> map, String meal) {
    final v = map[meal];
    if (v is List) {
      return [
        for (final e in v)
          if (e is Map) MenuItem.fromMap(Map<String, dynamic>.from(e)),
      ].where((i) => i.name.isNotEmpty).toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      return [
        MenuItem(
          name: v.trim(),
          price: (map['${meal}Price'] as num?)?.toDouble() ?? 0,
        ),
      ];
    }
    return [];
  }

  factory DayMenu.fromMap(String day, Map<String, dynamic> map) {
    return DayMenu(
      day: day,
      breakfast: _parse(map, 'breakfast'),
      lunch: _parse(map, 'lunch'),
      dinner: _parse(map, 'dinner'),
    );
  }
}