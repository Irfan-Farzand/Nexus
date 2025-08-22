import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tasknest/core/utils/network_utils.dart';
import 'package:tasknest/models/comment_model.dart';
import 'package:tasknest/providers/team_provider.dart';
import 'package:tasknest/services/local_db_service.dart';
import 'package:tasknest/services/notification_service.dart';
import '../models/task_model.dart';
import 'package:tasknest/providers/activity_provider.dart';
import 'package:tasknest/models/activity_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:logger/logger.dart';

class TaskProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<TaskModel> _tasks = [];
  bool isLoading = false;

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  // Local filter/sort state
  String filterPriority = 'all';
  String? filterAssignee;
  bool? filterCompleted; // null => all
  String sortBy = 'dueDate'; // 'dueDate' or 'priority' or 'title'
  bool sortAsc = true;
  String filterStatus = 'all'; // <-- Kanban status filter

  TaskProvider();

  // Kanban: Update status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    _logger.d("Updating task status: $taskId -> $newStatus");
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) {
      _logger.w("Task $taskId not found in local list");
      return;
    }
    _tasks[idx].status = newStatus;
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus,
      });
      _logger.i("Task status updated in Firestore for $taskId");
    } catch (e, s) {
      _logger.e("Error updating task status: $taskId", error: e, stackTrace: s);
    }
    notifyListeners();
  }

  // New method to fetch comments for a task
  Stream<List<CommentModel>> streamCommentsForTask(String taskId) {
    _logger.d("Streaming comments for task: $taskId");
    return _firestore
        .collection('tasks')
        .doc(taskId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => CommentModel.fromMap(d.data(), id: d.id))
              .toList();
        });
  }

  // Add comment
  Future<void> addComment(String taskId, CommentModel comment) async {
    _logger.d("Adding comment to task: $taskId");
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .add(comment.toMap());

      // Notify assigned user/team
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      final data = taskDoc.data();
      if (data != null) {
        final assignedUserId = data['assignedUserId'] ?? '';
        final assignedTeamId = data['assignedTeamId'];
        final title = data['title'] ?? 'Task';
        if (assignedUserId.isNotEmpty) {
          await NotificationService.sendPushToUser(
            userId: assignedUserId,
            title: 'New Comment',
            body: 'A new comment was added to "$title".',
          );
          _logger.i("Notification sent to user $assignedUserId for comment");
        }
        if (assignedTeamId != null && assignedTeamId != '') {
          final teamDoc =
              await FirebaseFirestore.instance
                  .collection('teams')
                  .doc(assignedTeamId)
                  .get();
          final memberIds = List<String>.from(
            teamDoc.data()?['memberIds'] ?? [],
          );
          for (final uid in memberIds) {
            await NotificationService.sendPushToUser(
              userId: uid,
              title: 'New Comment',
              body: 'A new comment was added to "$title".',
            );
          }
          _logger.i("Notifications sent to team $assignedTeamId members");
        }
      }
    } catch (e, s) {
      _logger.e(
        "Error adding comment to task: $taskId",
        error: e,
        stackTrace: s,
      );
    }
  }

  // Toggle completion with activity logging
  Future<void> toggleComplete(TaskModel task, {BuildContext? context}) async {
    _logger.d("Toggling completion for task: ${task.id}");
    task.isCompleted = !task.isCompleted;
    await updateTask(task);

    if (context != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final activity = ActivityModel(
        action: 'task_status_changed',
        description:
            'Task "${task.title}" marked as ${task.isCompleted ? "completed" : "incomplete"}.',
        userId: userId,
        entityId: task.id,
        timestamp: DateTime.now(),
      );
      await Provider.of<ActivityProvider>(
        context,
        listen: false,
      ).logActivity(activity);
      _logger.i("Activity logged for task status change: ${task.id}");
    }
  }

  // Filtering & sorting applied on local list
  List<TaskModel> getFilteredSortedTasks() {
    _logger.d("Applying filters & sorting on ${_tasks.length} tasks");
    var list = _tasks.toList();

    if (filterPriority != 'all') {
      list = list.where((t) => t.priority == filterPriority).toList();
    }
    if (filterAssignee != null && filterAssignee!.isNotEmpty) {
      list = list.where((t) => t.assignedUserId == filterAssignee).toList();
    }
    if (filterCompleted != null) {
      list = list.where((t) => t.isCompleted == filterCompleted).toList();
    }
    if (filterStatus != 'all') {
      list = list.where((t) => t.status == filterStatus).toList();
    }

    int comparePriority(TaskModel a, TaskModel b) {
      final order = {'high': 3, 'medium': 2, 'low': 1};
      return order[a.priority]!.compareTo(order[b.priority]!);
    }

    switch (sortBy) {
      case 'dueDate':
        list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'priority':
        list.sort(comparePriority);
        break;
      case 'title':
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
    }

    if (!sortAsc) list = list.reversed.toList();
    return list;
  }

  // Save task locally
  Future<void> saveTaskLocally(TaskModel task) async {
    final db = await LocalDbService.getDb();
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _logger.d("Task saved locally: ${task.id}");
  }

  // Fetch tasks from local DB
  Future<List<TaskModel>> fetchLocalTasks() async {
    final db = await LocalDbService.getDb();
    final maps = await db.query('tasks');
    _logger.d("Fetched ${maps.length} tasks from local DB");
    return maps.map((m) => TaskModel.fromMap(m['id'].toString(), m)).toList();
  }

  // Fetch tasks for user (offline/online)
  Future<void> fetchTasksForUser(String userId) async {
    isLoading = true;
    notifyListeners();
    _logger.d("Fetching tasks for user: $userId");

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      _tasks = await fetchLocalTasks();
      _logger.w("Offline: Loaded ${_tasks.length} tasks from local DB");
    } else {
      // 1. User ki teams fetch karo
      final teams = await TeamProvider().getTeamsForUser(userId);
      final teamIds = teams.map((t) => t.id).toList();

      // 2. Queries
      final assignedSnap =
          await _firestore
              .collection('tasks')
              .where('assignedUserId', isEqualTo: userId)
              .get();

      final createdSnap =
          await _firestore
              .collection('tasks')
              .where('createdBy', isEqualTo: userId)
              .get();

      List<QueryDocumentSnapshot<Map<String, dynamic>>> teamTasks = [];
      if (teamIds.isNotEmpty) {
        final teamSnap =
            await _firestore
                .collection('tasks')
                .where('assignedTeamId', whereIn: teamIds)
                .get();
        teamTasks = teamSnap.docs;
      }

      // 3. Merge + Filter
      final allDocs = [...assignedSnap.docs, ...teamTasks, ...createdSnap.docs];
      final uniqueTasks = <String, TaskModel>{};

      for (var d in allDocs) {
        final task = TaskModel.fromMap(d.id, d.data());

        // ✅ Only keep valid tasks
        if (task.assignedUserId == userId ||
            teamIds.contains(task.assignedTeamId) ||
            task.createdBy == userId) {
          uniqueTasks[d.id] = task;
        }
      }

      _tasks = uniqueTasks.values.toList();

      _logger.i("Loaded ${_tasks.length} filtered tasks");
      for (final t in _tasks) {
        await saveTaskLocally(t);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  // Add task (local + remote)
  Future<void> addTask(TaskModel task) async {
    _logger.d("Adding task: ${task.toMap()}");
    try {
      final online = await hasInternet();
      task.updatedAt = DateTime.now().toIso8601String();
      if (!online) {
        task.id = DateTime.now().millisecondsSinceEpoch.toString();
        await saveTaskLocally(task);
        _tasks.add(task);
        _logger.w("Offline: Task saved locally with id ${task.id}");
      } else {
        final docRef = await _firestore.collection('tasks').add(task.toMap());
        task.id = docRef.id;
        await _firestore.collection('tasks').doc(task.id).update({
          'id': task.id,
        });
        _tasks.add(task);
        await saveTaskLocally(task);
        _logger.i(
          "Task added successfully to Firestore & local DB: ${task.id}",
        );
      }
      notifyListeners();
    } catch (e, s) {
      _logger.e("Error while adding task", error: e, stackTrace: s);
      rethrow;
    }
  }

  // Update task (local + remote)
  Future<void> updateTask(TaskModel task) async {
    _logger.d("Updating task: ${task.id}");
    final connectivity = await Connectivity().checkConnectivity();
    task.updatedAt = DateTime.now().toIso8601String();

    try {
      if (connectivity == ConnectivityResult.none) {
        await saveTaskLocally(task);
        _logger.w("Offline: Task updated locally ${task.id}");
      } else {
        await _firestore.collection('tasks').doc(task.id).update(task.toMap());
        await saveTaskLocally(task);
        _logger.i("Task updated in Firestore & local DB: ${task.id}");
      }
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) _tasks[idx] = task;
      notifyListeners();
    } catch (e, s) {
      _logger.e("Error updating task ${task.id}", error: e, stackTrace: s);
    }
  }

  // Delete task (local + remote)
  Future<void> deleteTask(String id) async {
    _logger.d("Deleting task: $id");
    final connectivity = await Connectivity().checkConnectivity();
    try {
      final db = await LocalDbService.getDb();
      if (connectivity == ConnectivityResult.none) {
        await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
        _logger.w("Offline: Task deleted locally $id");
      } else {
        await _firestore.collection('tasks').doc(id).delete();
        await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
        _logger.i("Task deleted from Firestore & local DB $id");
      }
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e, s) {
      _logger.e("Error deleting task $id", error: e, stackTrace: s);
    }
  }
}
