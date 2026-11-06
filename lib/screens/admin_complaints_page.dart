import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/status_chip.dart';

// Admin: FR-6.3 view + update status, FR-6.4 add a response note.
class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  late final _stream = ComplaintService().watchAll();
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (final f in ['All', ...complaintStatuses])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Complaint>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Admin complaints error: ${snapshot.error}');
                return const Center(child: Text('Could not load complaints.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snapshot.data!
                  .where((c) => _filter == 'All' || c.status == _filter)
                  .toList();
              if (list.isEmpty) {
                return const Center(child: Text('No complaints here.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: list.length,
                itemBuilder: (context, i) => _card(list[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(Complaint c) {
    final created = c.createdAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openDetail(c),
        title: Text('${c.category} - ${c.username.isEmpty ? 'Student' : c.username}'),
        subtitle: Text(
          '${created == null ? '' : '${shortDate(created)} ${created.year}\n'}'
          '${c.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: StatusChip(c.status),
      ),
    );
  }

  Future<void> _openDetail(Complaint c) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ComplaintSheet(complaint: c),
    );
  }
}

class _ComplaintSheet extends StatefulWidget {
  final Complaint complaint;
  const _ComplaintSheet({required this.complaint});

  @override
  State<_ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends State<_ComplaintSheet> {
  late String _status = widget.complaint.status;
  late final _response = TextEditingController(text: widget.complaint.response);
  bool _saving = false;

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ComplaintService().updateStatus(
        id: widget.complaint.id,
        status: _status,
        response: _response.text.trim(),
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Complaint updated'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      debugPrint('Update complaint failed: $e');
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not save. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final photo = c.photoBytes;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.category} - ${c.username.isEmpty ? 'Student' : c.username}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(c.description),
            if (photo != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(photo, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: [
                for (final s in complaintStatuses)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _response,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Response note',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}