import 'package:flutter/material.dart';
import '../models/meal_selection_model.dart';
import '../services/meal_service.dart';
import '../utils/date_helpers.dart';

// FR-3.4 / FR-3.6: live count of ordered plates per item and meal for a
// day, for kitchen planning.
class KitchenCountsPage extends StatefulWidget {
  const KitchenCountsPage({super.key});

  @override
  State<KitchenCountsPage> createState() => _KitchenCountsPageState();
}

class _KitchenCountsPageState extends State<KitchenCountsPage> {
  final _service = MealService();
  DateTime _date = dateOnly(DateTime.now());

  static const _icons = {
    'breakfast': Icons.free_breakfast,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
  };

  void _moveDay(int delta) {
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day + delta);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _moveDay(-1),
              ),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  '${capitalize(dayNameOf(_date))}, ${shortDate(_date)} ${_date.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _moveDay(1),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<Map<String, Map<String, int>>>(
            stream: _service.watchCounts(dateKey(_date)),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Counts error: ${snapshot.error}');
                return const Center(child: Text('Could not load counts.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final counts = snapshot.data!;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text(
                    'Plates ordered for each item',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  for (final meal in mealTypes)
                    _mealCard(meal, counts[meal] ?? {}),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _mealCard(String meal, Map<String, int> items) {
    // Most ordered first.
    final entries = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = items.values.fold<int>(0, (sum, n) => sum + n);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icons[meal], color: Colors.blue, size: 28),
                const SizedBox(width: 10),
                Text(
                  capitalize(meal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$total plate${total == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            if (entries.isEmpty)
              const Text(
                'No orders yet',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.key, style: const TextStyle(fontSize: 16)),
                      ),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}