// lib/providers/team_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tasknest/models/user_model.dart';
import '../models/team_model.dart';

class TeamProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createTeam(TeamModel team) async {
    try {
      await _firestore.collection('teams').add(team.toMap());
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<List<TeamModel>> getTeamsForUser(String userId) async {
    try {
      final snapshot =
          await _firestore
              .collection('teams')
              .where('memberIds', arrayContains: userId)
              .get();
      return snapshot.docs
          .map((doc) => TeamModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await _firestore.collection('teams').doc(teamId).delete();
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Stream<List<TeamModel>> streamTeamsForUser(String userId) {
    return _firestore
        .collection('teams')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TeamModel.fromMap(doc.data(), id: doc.id))
                  .toList(),
        );
  }

  Future<void> addMemberToTeam(String teamId, String userId) async {
    try {
      final teamRef = _firestore.collection('teams').doc(teamId);
      await teamRef.update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print(e);
    }
  }

  Future<List<UserModel>> fetchAllUsers() async {
    final snap = await FirebaseFirestore.instance.collection('users').get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  Future<bool> addMemberByEmail(String teamId, String email) async {
    // Find user by email
    final userSnap =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (userSnap.docs.isEmpty) return false;
    final userId = userSnap.docs.first.id;

    // Add userId to team memberIds array
    await _firestore.collection('teams').doc(teamId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    notifyListeners();
    return true;
  }
}
