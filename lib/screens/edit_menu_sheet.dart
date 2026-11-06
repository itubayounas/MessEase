import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

// Bottom sheet where the admin edits one day: for each meal, a list of
// items (name + price). Items can be added and removed.
Future<void> showEditMenuSheet(BuildContext context, DayMenu menu) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditMenuSheet(menu: menu),
  );
}

// The two text boxes of one item row.
class _Row {
  final TextEditingController name;
  final TextEditingController price;

  _Row({String name = '', double price = 0})
      : name = TextEditingController(text: name),
        price = TextEditingController(
          text: price <= 0
              ? ''
              : (price == price.roundToDouble()
                  ? price.toStringAsFixed(0)
                  : price.toString()),
        );

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _EditMenuSheet extends StatefulWidget {
  final DayMenu menu;
  const _EditMenuSheet({required this.menu});

  @override
  State<_EditMenuSheet> createState() => _EditMenuSheetState();
}

class _EditMenuSheetState extends State<_EditMenuSheet> {
  static const _meals = ['breakfast', 'lunch', 'dinner'];
  static const _icons = {
    'breakfast': Icons.free_breakfast,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
  };

  late final Map<String, List<_Row>> _rows = {
    for (final m in _meals)
      m: [
        for (final item in widget.menu.itemsOf(m))
          _Row(name: item.name, price: item.price),
        // Always start with at least one empty row to type into.
        if (widget.menu.itemsOf(m).isEmpty) _Row(),
      ],
  };

  // Removed rows are disposed together at the end, not while still on screen.
  final List<_Row> _removed = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final rows in _rows.values) {
      for (final r in rows) {
        r.dispose();
      }
    }
    for (final r in _removed) {
      r.dispose();
    }
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _addRow(String meal) => setState(() => _rows[meal]!.add(_Row()));

  void _removeRow(String meal, _Row row) {
    setState(() {
      _rows[meal]!.remove(row);
      _removed.add(row);
    });
  }

  // Turns the text boxes into items. Empty rows are skipped; every other row
  // needs a name and a price above 0. Returns null after showing an error.
  Map<String, List<MenuItem>>? _collect() {
    final result = <String, List<MenuItem>>{};

    for (final meal in _meals) {
      final items = <MenuItem>[];
      final seen = <String>{};

      for (final row in _rows[meal]!) {
        final name = row.name.text.trim();
        final priceText = row.price.text.trim();

        // A completely empty row is just skipped.
        if (name.isEmpty && priceText.isEmpty) continue;

        if (name.isEmpty) {
          _error('Enter an item name for the price you typed in $meal.');
          return null;
        }

        // Every item must have a price greater than 0.
        final price = double.tryParse(priceText);
        if (priceText.isEmpty) {
          _error('Enter a price for "$name".');
          return null;
        }
        if (price == null || price <= 0) {
          _error('Enter a valid price greater than 0 for "$name".');
          return null;
        }
        if (!seen.add(name.toLowerCase())) {
          _error('"$name" appears twice in $meal.');
          return null;
        }
        items.add(MenuItem(name: name, price: price));
      }
      result[meal] = items;
    }
    return result;
  }

  Future<void> _save() async {
    final items = _collect();
    if (items == null) return;

    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await MenuService().saveDay(DayMenu(
        day: widget.menu.day,
        breakfast: items['breakfast']!,
        lunch: items['lunch']!,
        dinner: items['dinner']!,
      ));
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Menu updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Save menu failed: $e');
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not save the menu. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _mealSection(String meal) {
    final label = meal[0].toUpperCase() + meal.substring(1);
    final rows = _rows[meal]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_icons[meal], color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addRow(meal),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add item'),
            ),
          ],
        ),
        for (final row in rows)
          Padding(
            key: ObjectKey(row),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: row.name,
                    decoration: InputDecoration(
                      labelText: 'Item',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price (Rs)',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Remove item',
                  onPressed: () => _removeRow(meal, row),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.menu.day;
    final title = day[0].toUpperCase() + day.substring(1);

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit $title menu',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add one line per orderable item, with its price per plate. '
              'Every item needs a price. Students tick the items they want.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            for (final m in _meals) _mealSection(m),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}