// lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String text;
  final String userId;
  final DateTime timestamp;

  CommentModel({
    this.id = '',
    required this.text,
    required this.userId,
    required this.timestamp,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CommentModel(
      id: id ?? map['id'] ?? '',
      text: map['text'] as String,
      userId: map['userId'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
