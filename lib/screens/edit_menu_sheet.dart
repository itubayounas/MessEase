import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

// Bottom sheet where the admin edits one day's dishes and their prices.
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

  late final Map<String, TextEditingController> _dish = {
    for (final m in _meals)
      m: TextEditingController(text: widget.menu.dishOf(m)),
  };

  // Empty box when no price is set yet; whole numbers shown without ".0".
  late final Map<String, TextEditingController> _price = {
    for (final m in _meals)
      m: TextEditingController(text: _priceText(widget.menu.priceOf(m))),
  };

  bool _saving = false;

  static String _priceText(double v) {
    if (v <= 0) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  }

  @override
  void dispose() {
    for (final c in [..._dish.values, ..._price.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _save() async {
    // Empty price = not set (0). Anything else must be a number >= 0.
    final prices = <String, double>{};
    for (final m in _meals) {
      final text = _price[m]!.text.trim();
      if (text.isEmpty) {
        prices[m] = 0;
        continue;
      }
      final v = double.tryParse(text);
      if (v == null || v < 0) {
        _error('Enter a valid price for $m, or leave it empty.');
        return;
      }
      prices[m] = v;
    }

    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await MenuService().saveDay(DayMenu(
        day: widget.menu.day,
        breakfast: _dish['breakfast']!.text.trim(),
        lunch: _dish['lunch']!.text.trim(),
        dinner: _dish['dinner']!.text.trim(),
        breakfastPrice: prices['breakfast']!,
        lunchPrice: prices['lunch']!,
        dinnerPrice: prices['dinner']!,
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

  Widget _mealFields(String meal) {
    final label = meal[0].toUpperCase() + meal.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _dish[meal],
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(_icons[meal]),
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
              controller: _price[meal],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price (Rs)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
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
              'Price is per plate. If left empty, the default meal rate is used.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            for (final m in _meals) _mealFields(m),
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