import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tasknest/services/get_server_key.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Local notifications setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _localPlugin.initialize(settings);

    // Timezone setup for scheduling
    tz.initializeTimeZones();

    // Firebase Messaging setup
    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show local notification when app is in foreground
      if (message.notification != null) {
        showSimpleNotification(
          title: message.notification!.title ?? 'TaskNest',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    await _localPlugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'General',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
    String? assignedUserId,
    String? assignedTeamId,
  }) async {
    final scheduledTime = dueDate.subtract(Duration(hours: 1));
    final now = DateTime.now();

    if (scheduledTime.isBefore(now)) return;

    await _localPlugin.zonedSchedule(
      taskId.hashCode,
      'Task Reminder',
      'Task "$title" is due soon!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Push notification to assigned user or team
    if (assignedUserId != null && assignedUserId.isNotEmpty) {
      await sendPushToUser(
        userId: assignedUserId,
        title: 'Task Due Soon',
        body: 'Task "$title" is due in 1 hour.',
      );
    }
    if (assignedTeamId != null && assignedTeamId.isNotEmpty) {
      final teamDoc =
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(assignedTeamId)
              .get();
      final memberIds = List<String>.from(teamDoc.data()?['memberIds'] ?? []);
      for (final uid in memberIds) {
        await sendPushToUser(
          userId: uid,
          title: 'Task Due Soon',
          body: 'Task "$title" is due in 1 hour.',
        );
      }
    }
  }

  static Future<void> sendPushToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    // Get FCM token from Firestore
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final token = doc.data()?['fcmToken'];
    if (token == null) return;

    // Your Firebase server key (for demo only, don't use in app for production)
    GetServerKey serverKey = GetServerKey();

    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/task-nest-549f6/messages:send');

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $serverKey', // v1 uses Bearer token
    };
    final payload = {
      'to': token,
      'notification': {'title': title, 'body': body},
      'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
    };

    await http.post(url, headers: headers, body: jsonEncode(payload));
  }

  // Call this after login/signup to save FCM token
  static Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
