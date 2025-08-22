import 'package:flutter/material.dart';
import 'package:tasknest/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/routes/app_routes.dart';
import 'package:tasknest/screens/goal/goal_list_screen.dart';
import 'package:tasknest/screens/task/task_list_screen.dart';
import 'package:tasknest/screens/team/team_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final Color primaryBlue = const Color(0xFF1565C0); // deep blue

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userEmail = authProvider.user?.displayName ?? "Unknown";

    final pages =  [
      TaskListScreen(),
      GoalListScreen(),
      TeamListScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryBlue,
        elevation: 0,
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome ",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              userEmail,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_index],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            elevation: 0,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryBlue,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline),
                activeIcon: Icon(Icons.check_circle),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag_outlined),
                activeIcon: Icon(Icons.flag),
                label: 'Goals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'Teams',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
