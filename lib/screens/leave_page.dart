import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/status_chip.dart';

// Student: FR-5.1 apply for leave, FR-5.7 status + history,
// FR-5.6 shows which applications just changed status.
class LeavePage extends StatefulWidget {
  final String username;
  const LeavePage({super.key, required this.username});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _service = LeaveService();
  late final _stream = _service.watchMine(_uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<LeaveRequest>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Leave error: ${snapshot.error}');
            return const Center(child: Text('Could not load your leave applications.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;

          // Opening this tab counts as reading the notifications.
          if (list.any((l) => !l.studentSeen)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _service.markSeen(list);
            });
          }

          if (list.isEmpty) {
            return const Center(child: Text('No leave applications yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            itemBuilder: (context, i) => _card(list[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Apply for leave'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ApplyLeavePage(uid: _uid, username: widget.username),
          ),
        ),
      ),
    );
  }

  Widget _card(LeaveRequest l) {
    final start = DateTime.tryParse(l.startDate);
    final end = DateTime.tryParse(l.endDate);
    final range = (start == null || end == null)
        ? '${l.startDate} to ${l.endDate}'
        : '${shortDate(start)} - ${shortDate(end)} ${end.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    range,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusChip(capitalize(l.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${l.days} day${l.days == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(l.reason),
            if (!l.studentSeen)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Status updated by the warden',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            if (l.status == 'approved')
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Your meals for these days were removed and will not be charged.',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// The application form.
class _ApplyLeavePage extends StatefulWidget {
  final String uid;
  final String username;
  const _ApplyLeavePage({required this.uid, required this.username});

  @override
  State<_ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<_ApplyLeavePage> {
  final _reason = TextEditingController();
  DateTimeRange? _range;
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year, today.month + 3, today.day),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submit() async {
    final range = _range;
    final reason = _reason.text.trim();
    if (range == null) return _error('Please choose the start and end dates.');
    if (reason.length < 3) return _error('Please enter a reason.');
    final days = range.end.difference(range.start).inDays + 1;
    if (days > 30) return _error('A leave can be at most 30 days.');

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await LeaveService().apply(
        uid: widget.uid,
        username: widget.username,
        startDate: dateKey(range.start),
        endDate: dateKey(range.end),
        reason: reason,
      );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Apply leave failed: $e');
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not submit. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for leave'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            label: Text(
              range == null
                  ? 'Choose start and end date'
                  : '${shortDate(range.start)} - ${shortDate(range.end)} ${range.end.year}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Reason',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}