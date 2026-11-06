import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/charge_model.dart';
import '../models/leave_model.dart';
import '../models/meal_selection_model.dart';
import '../models/menu_model.dart';
import '../services/leave_service.dart';
import '../services/meal_service.dart';
import '../services/menu_service.dart';
import '../utils/date_helpers.dart';

// FR-3.1 / 3.2 / 3.3 / 3.5: tick or untick meals for each day of this week.
// Days inside an approved leave are locked ("On leave").
class MyMealsPage extends StatefulWidget {
  const MyMealsPage({super.key});

  @override
  State<MyMealsPage> createState() => _MyMealsPageState();
}

class _MyMealsPageState extends State<MyMealsPage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _mealService = MealService();

  // Created once so the streams aren't re-subscribed on every rebuild.
  late final _menuStream = MenuService().watchWeek();
  late final _mineStream = _mealService.watchMine(_uid);
  late final _leaveStream = LeaveService().watchMine(_uid);

  Future<void> _toggle(DateTime day, String meal, bool ticked) async {
    // Re-check at tap time, in case the cutoff passed while the screen was open.
    if (isMealLocked(day)) {
      _snack('Selection for this day is locked.', Colors.red);
      setState(() {}); // refresh so the boxes show as locked
      return;
    }
    try {
      await _mealService.setMeal(
        uid: _uid,
        date: dateKey(day),
        meal: meal,
        ticked: ticked,
      );
    } catch (e) {
      debugPrint('Tick failed: $e');
      _snack('Could not save your selection. Please try again.', Colors.red);
    }
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final week = currentWeek();
    final today = dateOnly(DateTime.now());

    return StreamBuilder<Map<String, DayMenu>>(
      stream: _menuStream,
      builder: (context, menuSnap) {
        return StreamBuilder<Map<String, MealSelection>>(
          stream: _mineStream,
          builder: (context, mineSnap) {
            if (mineSnap.hasError) {
              debugPrint('Meals error: ${mineSnap.error}');
              return const Center(child: Text('Could not load your meals.'));
            }
            if (!mineSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final menus = menuSnap.data ?? {};
            final mine = mineSnap.data!;

            return StreamBuilder<List<LeaveRequest>>(
              stream: _leaveStream,
              builder: (context, leaveSnap) {
                final leaves = (leaveSnap.data ?? [])
                    .where((l) => l.status == 'approved')
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Tick the meals you will eat. Each day closes at '
                      '$cutoffLabel the evening before.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    for (final day in week)
                      _dayCard(
                        day: day,
                        isToday: day == today,
                        onLeave: leaves.any((l) => l.covers(dateKey(day))),
                        menu: menus[dayNameOf(day)] ??
                            DayMenu(day: dayNameOf(day)),
                        selection: mine[dateKey(day)] ??
                            MealSelection(date: dateKey(day)),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _dayCard({
    required DateTime day,
    required bool isToday,
    required bool onLeave,
    required DayMenu menu,
    required MealSelection selection,
  }) {
    final locked = isMealLocked(day) || onLeave;
    const color = Colors.teal;

    String dish(String meal) {
      final v = meal == 'breakfast'
          ? menu.breakfast
          : meal == 'lunch'
              ? menu.lunch
              : menu.dinner;
      if (v.isEmpty) return 'Menu not set';
      final p = menu.priceOf(meal);
      return p > 0 ? '$v - ${money(p)}' : v;
    }

    final statusColor = onLeave
        ? Colors.blue
        : locked
            ? Colors.red
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isToday ? color.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${capitalize(dayNameOf(day))}, ${shortDate(day)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    const Text('(Today)',
                        style: TextStyle(color: color, fontSize: 13)),
                  ],
                  const Spacer(),
                  Icon(
                    onLeave
                        ? Icons.flight_takeoff
                        : locked
                            ? Icons.lock
                            : Icons.lock_open,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    onLeave
                        ? 'On leave'
                        : locked
                            ? 'Locked'
                            : 'Open',
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                ],
              ),
            ),
            for (final meal in mealTypes)
              CheckboxListTile(
                dense: true,
                activeColor: color,
                value: selection.isTicked(meal),
                onChanged:
                    locked ? null : (v) => _toggle(day, meal, v ?? false),
                title: Text(capitalize(meal)),
                subtitle: Text(dish(meal)),
              ),
          ],
        ),
      ),
    );
  }
}