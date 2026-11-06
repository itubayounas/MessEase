import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/weekly_menu_list.dart';
import 'admin_complaints_page.dart';
import 'admin_leave_page.dart';
import 'billing_page.dart';
import 'edit_menu_sheet.dart';
import 'kitchen_counts_page.dart';

class AdminDashboard extends StatefulWidget {
  final String username;

  const AdminDashboard({
    super.key,
    required this.username,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  static const _titles = [
    'Weekly Menu',
    'Kitchen Counts',
    'Billing',
    'Leave Requests',
    'Complaints',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Welcome, ${widget.username}! Tap the pencil to edit a day.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: WeeklyMenuList(
              color: Colors.blue,
              onEditDay: (menu) => showEditMenuSheet(context, menu),
            ),
          ),
        ],
      ),
      const KitchenCountsPage(),
      const BillingPage(),
      const AdminLeavePage(),
      const AdminComplaintsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('MessEase - ${_titles[_index]}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.soup_kitchen_outlined),
            selectedIcon: Icon(Icons.soup_kitchen),
            label: 'Kitchen',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff),
            label: 'Leave',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Complaints',
          ),
        ],
      ),
    );
  }
}