import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/charge_model.dart';
import '../models/meal_selection_model.dart';
import '../services/meal_service.dart';
import '../services/settings_service.dart';
import '../utils/date_helpers.dart';

// FR-4.2 set the meal rate, FR-4.5 view / export every student's bill.
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

// One row of the bills list.
class _StudentBill {
  final String name;
  final Bill bill;
  const _StudentBill(this.name, this.bill);
}

class _BillingPageState extends State<BillingPage> {
  final _settings = SettingsService();
  final _meals = MealService();

  // Broadcast because the rate is read in two places on this screen.
  late final _rateStream = _settings.watchRate().asBroadcastStream();
  late final Future<Map<String, String>> _students = _loadStudents();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // uid -> username for every student, so bills can show names.
  Future<Map<String, String>> _loadStudents() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    return {
      for (final doc in snap.docs)
        doc.id: (doc.data()['username'] as String?) ??
            (doc.data()['email'] as String?) ??
            doc.id,
    };
  }

  void _moveMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _snack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _editRate(double current) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _RateDialog(initial: current),
    );
    if (value == null) return;

    try {
      await _settings.setRate(value);
      _snack('Meal rate updated to ${money(value)}', color: Colors.green);
    } catch (e) {
      debugPrint('Set rate failed: $e');
      _snack('Could not save the rate. Please try again.', color: Colors.red);
    }
  }

  // Turns every student's selections into rows: all students are listed,
  // including those with no meals (they have a bill of 0).
  List<_StudentBill> _buildRows(
    Map<String, String> students,
    List<MealSelection> selections,
    double rate,
  ) {
    final byUid = <String, List<MealSelection>>{};
    for (final s in selections) {
      byUid.putIfAbsent(s.uid, () => []).add(s);
    }

    final uids = {...students.keys, ...byUid.keys};
    final rows = [
      for (final uid in uids)
        _StudentBill(
          students[uid] ?? 'Unknown student',
          buildBill(byUid[uid] ?? const [], rate),
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return rows;
  }

  // Copies the month's bills as CSV text, ready to paste into Excel / Sheets.
  Future<void> _exportCsv(List<_StudentBill> rows) async {
    final buffer = StringBuffer()
      ..writeln('Student,Breakfast,Lunch,Dinner,Total meals,Total amount');
    for (final r in rows) {
      buffer.writeln([
        r.name,
        r.bill.countOf('breakfast'),
        r.bill.countOf('lunch'),
        r.bill.countOf('dinner'),
        r.bill.mealCount,
        r.bill.total,
      ].join(','));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    _snack(
      'Bills for ${monthLabel(_month)} copied. Paste them into Excel or Sheets.',
      color: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _rateCard(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
        Expanded(child: _billsList()),
      ],
    );
  }

  Widget _rateCard() {
    return StreamBuilder<double>(
      stream: _rateStream,
      builder: (context, snapshot) {
        final rate = snapshot.data ?? 0;
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ListTile(
            leading: const Icon(Icons.payments, color: Colors.blue, size: 32),
            title: const Text('Default rate per meal'),
            subtitle: Text(
              rate == 0 ? 'Not set yet' : money(rate),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: rate == 0 ? Colors.orange : Colors.blue,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Change rate',
              onPressed: () => _editRate(rate),
            ),
          ),
        );
      },
    );
  }

  Widget _billsList() {
    return FutureBuilder<Map<String, String>>(
      future: _students,
      builder: (context, studentsSnap) {
        if (studentsSnap.hasError) {
          debugPrint('Students error: ${studentsSnap.error}');
          return const Center(child: Text('Could not load students.'));
        }
        if (!studentsSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<double>(
          stream: _rateStream,
          builder: (context, rateSnap) {
            return StreamBuilder<List<MealSelection>>(
              stream: _meals.watchMonth(_month),
              builder: (context, monthSnap) {
                if (monthSnap.hasError) {
                  debugPrint('Month error: ${monthSnap.error}');
                  return const Center(child: Text('Could not load bills.'));
                }
                if (!monthSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rows = _buildRows(
                  studentsSnap.data!,
                  monthSnap.data!,
                  rateSnap.data ?? 0,
                );
                final grandTotal =
                    rows.fold<double>(0, (sum, r) => sum + r.bill.total);

                if (rows.isEmpty) {
                  return const Center(child: Text('No students yet.'));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            'Total: ${money(grandTotal)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => _exportCsv(rows),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Export CSV'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.blue),
                              title: Text(r.name),
                              subtitle: Text(
                                'Breakfast ${r.bill.countOf('breakfast')}  '
                                'Lunch ${r.bill.countOf('lunch')}  '
                                'Dinner ${r.bill.countOf('dinner')}',
                              ),
                              trailing: Text(
                                money(r.bill.total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
}

// Small dialog that asks for the new meal rate.
class _RateDialog extends StatefulWidget {
  final double initial;
  const _RateDialog({required this.initial});

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  late final _controller = TextEditingController(
    text: widget.initial == 0 ? '' : widget.initial.toString(),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Default rate per meal'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Amount (Rs)',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}