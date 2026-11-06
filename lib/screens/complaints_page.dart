import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/status_chip.dart';

// Student: FR-6.1 / 6.2 submit a complaint (optional photo) and track it.
class ComplaintsPage extends StatefulWidget {
  final String username;
  const ComplaintsPage({super.key, required this.username});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  late final _stream = ComplaintService().watchMine(_uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Complaint>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Complaints error: ${snapshot.error}');
            return const Center(child: Text('Could not load your complaints.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return const Center(child: Text('No complaints submitted.'));
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
        icon: const Icon(Icons.add_comment),
        label: const Text('New complaint'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _NewComplaintPage(uid: _uid, username: widget.username),
          ),
        ),
      ),
    );
  }

  Widget _card(Complaint c) {
    final photo = c.photoBytes;
    final created = c.createdAt;
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
                    c.category,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusChip(c.status),
              ],
            ),
            if (created != null)
              Text(
                '${shortDate(created)} ${created.year}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(height: 8),
            Text(c.description),
            if (photo != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(photo, height: 140, fit: BoxFit.cover),
              ),
            ],
            if (c.response.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Warden: ${c.response}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewComplaintPage extends StatefulWidget {
  final String uid;
  final String username;
  const _NewComplaintPage({required this.uid, required this.username});

  @override
  State<_NewComplaintPage> createState() => _NewComplaintPageState();
}

class _NewComplaintPageState extends State<_NewComplaintPage> {
  final _description = TextEditingController();
  String _category = complaintCategories.first;
  String? _photoBase64;
  bool _saving = false;

  // Firestore documents are limited to 1 MB, so the photo must stay small.
  static const _maxPhotoBytes = 600 * 1024;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _error(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 60,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxPhotoBytes) {
        _error('That photo is too large. Please choose a smaller one.');
        return;
      }
      setState(() => _photoBase64 = base64Encode(bytes));
    } catch (e) {
      debugPrint('Pick photo failed: $e');
      _error('Could not load the photo.');
    }
  }

  Future<void> _submit() async {
    final text = _description.text.trim();
    if (text.length < 5) return _error('Please describe the problem.');

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ComplaintService().submit(
        uid: widget.uid,
        username: widget.username,
        category: _category,
        description: text,
        photoBase64: _photoBase64,
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Complaint submitted'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      debugPrint('Submit complaint failed: $e');
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not submit. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photoBase64;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New complaint'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: [
              for (final c in complaintCategories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          if (photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(base64Decode(photo), height: 180, fit: BoxFit.cover),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _photoBase64 = null),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove photo'),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Photo is optional.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
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