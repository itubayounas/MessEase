import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/charge_model.dart';
import '../models/meal_selection_model.dart';
import '../services/meal_service.dart';
import '../services/settings_service.dart';
import '../utils/date_helpers.dart';

// FR-4.3 running total, FR-4.4 monthly bill summary, FR-4.6 charge breakdown.
class ChargesPage extends StatefulWidget {
  const ChargesPage({super.key});

  @override
  State<ChargesPage> createState() => _ChargesPageState();
}

class _ChargesPageState extends State<ChargesPage> {
  late final _mineStream = MealService()
      .watchMine(FirebaseAuth.instance.currentUser!.uid);
  late final _rateStream = SettingsService().watchRate();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _moveMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _moveMonth(-1),
              ),
              SizedBox(
                width: 170,
                child: Text(
                  monthLabel(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _moveMonth(1),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<double>(
            stream: _rateStream,
            builder: (context, rateSnap) {
              return StreamBuilder<Map<String, MealSelection>>(
                stream: _mineStream,
                builder: (context, mineSnap) {
                  if (mineSnap.hasError) {
                    debugPrint('Charges error: ${mineSnap.error}');
                    return const Center(
                      child: Text('Could not load your charges.'),
                    );
                  }
                  if (!mineSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rate = rateSnap.data ?? 0;
                  final prefix = monthPrefix(_month);
                  final selections = mineSnap.data!.values
                      .where((s) => s.date.startsWith(prefix));
                  final bill = buildBill(selections, rate);
                  final rateMissing =
                      bill.items.any((i) => i.amount == 0);

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _summaryCard(bill),
                      if (rateMissing)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'The meal rate has not been set by the admin yet, '
                            'so some meals show Rs 0.',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Charge breakdown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (bill.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('No charges for this month.'),
                          ),
                        )
                      else
                        for (final item in bill.items) _itemTile(item),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(Bill bill) {
    return Card(
      color: Colors.teal.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _isCurrentMonth ? 'Running total' : 'Monthly bill',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              money(bill.total),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            Text('${bill.mealCount} meals'),
            const Divider(height: 24),
            for (final meal in mealTypes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(capitalize(meal)),
                    const SizedBox(width: 8),
                    Text(
                      'x ${bill.countOf(meal)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    Text(money(bill.subtotalOf(meal))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(ChargeItem item) {
    final date = DateTime.tryParse(item.date);
    final title = date == null
        ? item.date
        : '${capitalize(dayNameOf(date))}, ${shortDate(date)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.restaurant, color: Colors.teal),
        title: Text(title),
        subtitle: Text('${capitalize(item.meal)} - ${item.item}'),
        trailing: Text(
          money(item.amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}