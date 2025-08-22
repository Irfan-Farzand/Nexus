import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tasknest/providers/team_provider.dart';
import 'package:tasknest/models/team_model.dart';

class TeamListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Your Teams",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TeamModel>>(
        stream: Provider.of<TeamProvider>(context, listen: false)
            .streamTeamsForUser(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data!;
          if (teams.isEmpty) {
            return Center(
              child: Text(
                "No teams found.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: teams.length,
            itemBuilder: (ctx, idx) {
              final team = teams[idx];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      team.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    team.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Members: ${team.memberIds.length}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "add") {
                        final email = await _showAddMemberDialog(context);
                        if (email != null && email.isNotEmpty) {
                          final added = await Provider.of<TeamProvider>(
                            context,
                            listen: false,
                          ).addMemberByEmail(team.id, email);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? "Member added!"
                                    : "No user found with this email.",
                              ),
                            ),
                          );
                        }
                      } else if (value == "delete") {
                        await Provider.of<TeamProvider>(
                          context,
                          listen: false,
                        ).deleteTeam(team.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Team deleted")),
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: "add",
                        child: Row(
                          children: [
                            Icon(Icons.person_add, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Add Member"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete Team"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-team'),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
        label: Text(
          "New Team",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<String?> _showAddMemberDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add Member by Email"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter email",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text("Add"),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
