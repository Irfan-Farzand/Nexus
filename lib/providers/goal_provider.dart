import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:tasknest/core/utils/network_utils.dart';

import '../models/goal_model.dart';

class GoalProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  // Custom configured logger
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

  List<GoalModel> _goals = [];
  bool isLoading = false;

  List<GoalModel> get goals => List.unmodifiable(_goals);

  GoalProvider();

  Future<void> fetchGoalsForUser(String userId) async {
    isLoading = true;
    notifyListeners();

    _logger.d('Fetching goals for user: $userId');

    try {
      final snap =
          await _firestore
              .collection('goals')
              .where('ownerId', isEqualTo: userId)
              .get();

      _logger.d('Firestore returned ${snap.docs.length} documents');

      _goals = snap.docs.map((d) => GoalModel.fromMap(d.id, d.data())).toList();
      _logger.i('Fetched ${_goals.length} goals for user: $userId');
    } catch (e, s) {
      _logger.e(
        'Error fetching goals for user: $userId',
        error: e,
        stackTrace: s,
      );
    } finally {
      isLoading = false;
      notifyListeners();
      _logger.d('fetchGoalsForUser completed for user: $userId');
    }
  }

  Future<void> addGoal(GoalModel goal) async {
    _logger.d('Attempting to add goal: ${goal.toMap()}');

    final online = await hasInternet();
    if (!online) {
      _goals.add(goal);
      _logger.w('Offline mode: goal stored locally -> ${goal.toMap()}');
      notifyListeners();
      return;
    }

    try {
      final docRef = await _firestore.collection('goals').add(goal.toMap());
      goal.id = docRef.id;
      await _firestore.collection('goals').doc(goal.id).update({'id': goal.id});
      _goals.add(goal);
      _logger.i('Goal added successfully with id: ${goal.id}');
      notifyListeners();
    } catch (e, s) {
      _logger.e('Error adding goal', error: e, stackTrace: s);
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    _logger.d('Updating goal: ${goal.id}');
    try {
      await _firestore.collection('goals').doc(goal.id).update(goal.toMap());
      final idx = _goals.indexWhere((g) => g.id == goal.id);
      if (idx != -1) _goals[idx] = goal;
      _logger.i('Goal updated: ${goal.id}');
      notifyListeners();
    } catch (e, s) {
      _logger.e('Error updating goal: ${goal.id}', error: e, stackTrace: s);
    }
  }

  Future<void> deleteGoal(String id) async {
    _logger.d('Deleting goal: $id');
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.mobile &&
        connectivity != ConnectivityResult.wifi) {
      _goals.removeWhere((g) => g.id == id);
      _logger.w('Offline mode: goal removed locally -> $id');
      notifyListeners();
      return;
    }

    try {
      await _firestore.collection('goals').doc(id).delete();
      _goals.removeWhere((g) => g.id == id);
      _logger.i('Goal deleted: $id');
      notifyListeners();
    } catch (e, s) {
      _logger.e('Error deleting goal: $id', error: e, stackTrace: s);
    }
  }

  Future<void> attachTaskToGoal(String goalId, String taskId) async {
    _logger.d('Attaching task $taskId to goal $goalId');
    try {
      final g = _goals.firstWhere((x) => x.id == goalId);
      if (!g.taskIds.contains(taskId)) {
        g.taskIds.add(taskId);
        await updateGoal(g);
        _logger.i('Task $taskId attached to goal $goalId');
      } else {
        _logger.w('Task $taskId already attached to goal $goalId');
      }
    } catch (e, s) {
      _logger.e(
        'Error attaching task $taskId to goal $goalId',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> detachTaskFromGoal(String goalId, String taskId) async {
    _logger.d('Detaching task $taskId from goal $goalId');
    try {
      final g = _goals.firstWhere((x) => x.id == goalId);
      g.taskIds.removeWhere((id) => id == taskId);
      await updateGoal(g);
      _logger.i('Task $taskId detached from goal $goalId');
    } catch (e, s) {
      _logger.e(
        'Error detaching task $taskId from goal $goalId',
        error: e,
        stackTrace: s,
      );
    }
  }
}
