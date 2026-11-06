import 'package:flutter/material.dart';
import '../models/charge_model.dart';
import '../models/menu_model.dart';

// One day's menu. Used by both dashboards; the admin passes onEdit,
// the student doesn't, so only the admin sees the edit button.
class MenuDayCard extends StatelessWidget {
  final DayMenu menu;
  final bool isToday;
  final Color color;
  final VoidCallback? onEdit;

  const MenuDayCard({
    super.key,
    required this.menu,
    required this.isToday,
    this.color = Colors.teal,
    this.onEdit,
  });

  String get _dayTitle => menu.day[0].toUpperCase() + menu.day.substring(1);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isToday ? 4 : 1,
      color: isToday ? color.withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isToday ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _dayTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Today'),
                    labelStyle:
                        const TextStyle(color: Colors.white, fontSize: 12),
                    backgroundColor: color,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit, color: color),
                    tooltip: 'Edit $_dayTitle',
                    onPressed: onEdit,
                  ),
              ],
            ),
            const Divider(),
            _mealSection(Icons.free_breakfast, 'Breakfast', menu.breakfast),
            _mealSection(Icons.lunch_dining, 'Lunch', menu.lunch),
            _mealSection(Icons.dinner_dining, 'Dinner', menu.dinner),
          ],
        ),
      ),
    );
  }

  // A meal heading followed by one line per item, with its price.
  Widget _mealSection(IconData icon, String label, List<MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 30, top: 2),
              child: Text(
                'Not set',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(item.name)),
                    if (item.price > 0)
                      Text(
                        money(item.price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}