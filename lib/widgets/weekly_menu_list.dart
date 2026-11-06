import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';
import 'menu_day_card.dart';

// Live weekly menu (Mon-Sun). Shared by the student and admin dashboards.
// Pass onEditDay to show edit buttons (admin only).
class WeeklyMenuList extends StatelessWidget {
  final Color color;
  final void Function(DayMenu menu)? onEditDay;

  const WeeklyMenuList({
    super.key,
    this.color = Colors.teal,
    this.onEditDay,
  });

  @override
  Widget build(BuildContext context) {
    // DateTime.weekday: 1 = Monday ... 7 = Sunday
    final today = weekDays[DateTime.now().weekday - 1];

    return StreamBuilder<Map<String, DayMenu>>(
      stream: MenuService().watchWeek(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Menu error: ${snapshot.error}');
          return const Center(child: Text('Could not load the menu.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final week = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: weekDays.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final day = weekDays[i];
            final menu = week[day] ?? DayMenu(day: day);
            return MenuDayCard(
              menu: menu,
              isToday: day == today,
              color: color,
              onEdit: onEditDay == null ? null : () => onEditDay!(menu),
            );
          },
        );
      },
    );
  }
}