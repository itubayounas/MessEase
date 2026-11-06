import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_selection_model.dart';
import '../services/meal_service.dart';
import '../utils/date_helpers.dart';

// FR-3.7: the student's own meal selection history, newest first.
class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({super.key});

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> {
  late final _stream = MealService()
      .watchMine(FirebaseAuth.instance.currentUser!.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, MealSelection>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('History error: ${snapshot.error}');
          return const Center(child: Text('Could not load your history.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Keep only days where at least one meal is ticked.
        // "yyyy-MM-dd" strings sort correctly as plain text.
        final entries = snapshot.data!.values
            .where((s) => s.tickedMeals.isNotEmpty)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        if (entries.isEmpty) {
          return const Center(child: Text('No meals ticked yet.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = entries[i];
            final date = DateTime.tryParse(e.date);
            final title = date == null
                ? e.date
                : '${capitalize(dayNameOf(date))}, ${shortDate(date)} ${date.year}';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant, color: Colors.teal),
                title: Text(title),
                subtitle: Wrap(
                  spacing: 6,
                  children: [
                    for (final m in e.tickedMeals)
                      for (final name in e.itemsOf(m).keys)
                      Chip(
                        label: Text('${capitalize(m)}: $name'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}