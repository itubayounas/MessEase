import 'package:flutter/material.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/status_chip.dart';

// Admin: FR-5.2 see applications (pending first), FR-5.3 approve / reject.
class AdminLeavePage extends StatefulWidget {
  const AdminLeavePage({super.key});

  @override
  State<AdminLeavePage> createState() => _AdminLeavePageState();
}

class _AdminLeavePageState extends State<AdminLeavePage> {
  final _service = LeaveService();
  late final _stream = _service.watchAll();
  String? _busyId; // the application currently being processed

  Future<void> _decide(LeaveRequest r, bool approve) async {
    setState(() => _busyId = r.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _service.decide(r, approve: approve);
      messenger.showSnackBar(SnackBar(
        content: Text(approve
            ? 'Leave approved. Meals for those days were removed.'
            : 'Leave rejected.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      debugPrint('Decide leave failed: $e');
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not update the application. Please try again.'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaveRequest>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Admin leave error: ${snapshot.error}');
          return const Center(child: Text('Could not load applications.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data!;
        if (all.isEmpty) {
          return const Center(child: Text('No leave applications yet.'));
        }

        // Pending first; each group stays newest-first.
        final list = [
          ...all.where((l) => l.isPending),
          ...all.where((l) => !l.isPending),
        ];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, i) => _card(list[i]),
        );
      },
    );
  }

  Widget _card(LeaveRequest l) {
    final start = DateTime.tryParse(l.startDate);
    final end = DateTime.tryParse(l.endDate);
    final range = (start == null || end == null)
        ? '${l.startDate} to ${l.endDate}'
        : '${shortDate(start)} - ${shortDate(end)} ${end.year}';
    final busy = _busyId == l.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.username.isEmpty ? 'Student' : l.username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusChip(capitalize(l.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text('$range  (${l.days} day${l.days == 1 ? '' : 's'})'),
            const SizedBox(height: 6),
            Text(l.reason, style: const TextStyle(color: Colors.black87)),
            if (l.isPending) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: busy ? null : () => _decide(l, false),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: busy ? null : () => _decide(l, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}