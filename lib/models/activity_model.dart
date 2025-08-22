// lib/models/activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String action; // e.g., 'task_created', 'comment_added', 'task_assigned'
  final String description;
  final String userId;
  final String entityId; // e.g., taskId, goalId
  final DateTime timestamp;

  ActivityModel({
    required this.action,
    required this.description,
    required this.userId,
    required this.entityId,
    required this.timestamp,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      action: map['action'],
      description: map['description'],
      userId: map['userId'],
      entityId: map['entityId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'description': description,
      'userId': userId,
      'entityId': entityId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
