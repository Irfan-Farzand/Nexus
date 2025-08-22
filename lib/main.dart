import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/providers/activity_provider.dart';
import 'package:tasknest/providers/auth_provider.dart';
import 'package:tasknest/providers/goal_provider.dart';
import 'package:tasknest/providers/profile_provider.dart';
import 'package:tasknest/providers/task_provider.dart';
import 'package:tasknest/providers/team_provider.dart';
import 'package:tasknest/routes/app_routes.dart';
import 'package:tasknest/services/notification_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tasknest/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await NotificationService.init();

  Connectivity().onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      SyncService.syncTasks();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskNest',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
