import '../models/menu_model.dart';

// Meal selection for a day closes at this hour (24h clock) on the PREVIOUS day,
// so the kitchen can plan. Change these two values to change the cutoff.
const int cutoffHour = 21;
const String cutoffLabel = '9:00 PM';

// "2025-03-14": used as the date part of Firestore document ids.
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// Monday..Sunday of the current week (FR-3.2: tick within the current week).
List<DateTime> currentWeek() {
  final now = dateOnly(DateTime.now());
  final monday = now.subtract(Duration(days: now.weekday - 1));
  return List.generate(
    7,
    (i) => DateTime(monday.year, monday.month, monday.day + i),
  );
}

// FR-3.3: true once the cutoff time before [day] has passed.
// Today and past days are therefore always locked.
bool isMealLocked(DateTime day) {
  final cutoff = DateTime(day.year, day.month, day.day - 1, cutoffHour);
  return !DateTime.now().isBefore(cutoff);
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String dayNameOf(DateTime d) => weekDays[d.weekday - 1];

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// "14 Mar"
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

const _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// "March 2025"
String monthLabel(DateTime d) => '${_monthsFull[d.month - 1]} ${d.year}';

// "2025-03": every date key of that month starts with this.
String monthPrefix(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

// First day of the month and of the next month, as date keys.
// Used for range queries: date >= start && date < next.
String monthStartKey(DateTime d) => '${monthPrefix(d)}-01';
String nextMonthStartKey(DateTime d) =>
    monthStartKey(DateTime(d.year, d.month + 1, 1));