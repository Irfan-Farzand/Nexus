// lib/providers/activity_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';

class ActivityProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  Future<void> logActivity(ActivityModel activity) async {
    try {
      await _firestore.collection('activities').add(activity.toMap());
    } catch (e) {
      print(e);
    }
  }

  Stream<List<ActivityModel>> streamActivitiesForTeam(String teamId) {
    // This is a simplified approach. In a real app, you would need
    // to query activities related to tasks/goals within a specific team.
    // For now, this streams all activities and filters them in-app.
    return _firestore
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ActivityModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  Stream<List<ActivityModel>> streamActivitiesForUser(String userId) {
    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ActivityModel.fromMap(doc.data()))
                  .toList(),
        );
  }
}
