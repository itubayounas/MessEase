import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../services/session_service.dart';
import '../widgets/weekly_menu_list.dart';
import 'charges_page.dart';
import 'complaints_page.dart';
import 'leave_page.dart';
import 'meal_history_page.dart';
import 'my_meals_page.dart';

class StudentDashboard extends StatefulWidget {
  final String username;

  const StudentDashboard({
    super.key,
    required this.username,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _index = 0;

  static const _titles = [
    'Weekly Menu',
    'My Meals',
    'Charges',
    'Leave',
    'Complaints',
  ];

  // Used only for the notification badge on the Leave tab (FR-5.6).
  late final _leaveStream = LeaveService()
      .watchMine(FirebaseAuth.instance.currentUser!.uid);

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Meal History'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          body: const MealHistoryPage(),
        ),
      ),
    );
  }

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
                'Welcome, ${widget.username}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Expanded(child: WeeklyMenuList(color: Colors.teal)),
        ],
      ),
      const MyMealsPage(),
      const ChargesPage(),
      LeavePage(username: widget.username),
      ComplaintsPage(username: widget.username),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('MessEase - ${_titles[_index]}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Meal history',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await SessionService.signOut();
              } catch (e) {
                debugPrint('Logout failed: $e');
                messenger.showSnackBar(const SnackBar(
                  content: Text('Could not log out. Check your internet and try again.'),
                  backgroundColor: Colors.red,
                ));
              }
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: StreamBuilder<List<LeaveRequest>>(
        stream: _leaveStream,
        builder: (context, snapshot) {
          final unseen =
              (snapshot.data ?? []).where((l) => !l.studentSeen).length;

          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Menu',
              ),
              const NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: 'Meals',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Charges',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unseen > 0,
                  label: Text('$unseen'),
                  child: const Icon(Icons.flight_takeoff_outlined),
                ),
                selectedIcon: const Icon(Icons.flight_takeoff),
                label: 'Leave',
              ),
              const NavigationDestination(
                icon: Icon(Icons.report_problem_outlined),
                selectedIcon: Icon(Icons.report_problem),
                label: 'Complaints',
              ),
            ],
          );
        },
      ),
    );
  }
}