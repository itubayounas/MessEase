import 'package:flutter/material.dart';

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
    case 'resolved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    case 'in review':
      return Colors.blue;
    default:
      return Colors.orange; // pending
  }
}

// Small coloured pill used for leave and complaint statuses.
class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: statusColor(label),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}