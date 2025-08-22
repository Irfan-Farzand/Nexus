// lib/models/team_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;

  TeamModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return TeamModel(
      id: id ?? map['id'],
      name: map['name'],
      ownerId: map['ownerId'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'ownerId': ownerId, 'memberIds': memberIds};
  }
}
