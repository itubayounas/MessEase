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

// FR-3.1 / 3.2 / 3.3 / 3.5: tick or untick the items you want for each day
// of this week. A meal can offer several items (e.g. Biryani and Salan), and
// each ticked item is charged at its own price.
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

  Future<void> _toggle(
    DateTime day,
    String meal,
    MenuItem item,
    bool ticked,
  ) async {
    // Re-check at tap time, in case the cutoff passed while the screen was open.
    if (isMealLocked(day)) {
      _snack('Selection for this day is locked.', Colors.red);
      setState(() {}); // refresh so the boxes show as locked
      return;
    }
    try {
      await _mealService.setItem(
        uid: _uid,
        date: dateKey(day),
        meal: meal,
        itemName: item.name,
        price: item.price,
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
                      'Tick the items you will eat. Each day closes at '
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

  static const _mealIcons = {
    'breakfast': Icons.free_breakfast,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
  };

  Widget _dayCard({
    required DateTime day,
    required bool isToday,
    required bool onLeave,
    required DayMenu menu,
    required MealSelection selection,
  }) {
    final locked = isMealLocked(day) || onLeave;
    const color = Colors.teal;

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
            for (final meal in mealTypes) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(_mealIcons[meal], size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      capitalize(meal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (menu.itemsOf(meal).isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(42, 2, 16, 4),
                  child: Text(
                    'Menu not set',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                for (final item in menu.itemsOf(meal))
                  CheckboxListTile(
                    dense: true,
                    activeColor: color,
                    value: selection.hasItem(meal, item.name),
                    onChanged: locked
                        ? null
                        : (v) => _toggle(day, meal, item, v ?? false),
                    title: Text(item.name),
                    subtitle: item.price > 0 ? Text(money(item.price)) : null,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}