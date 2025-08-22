import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tasknest/providers/team_provider.dart';
import 'package:tasknest/models/team_model.dart';
import 'package:tasknest/models/user_model.dart';

class CreateTeamScreen extends StatefulWidget {
  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _nameController = TextEditingController();
  List<UserModel> _allUsers = [];
  List<String> _selectedUserIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    final users =
    await Provider.of<TeamProvider>(context, listen: false).fetchAllUsers();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    setState(() {
      _allUsers = users;
      _selectedUserIds = [currentUserId]; // Owner preselected
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(

      appBar: AppBar(
        centerTitle: true,
        title: Text('Create Team' ,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Team Name',
                    prefixIcon: Icon(Icons.group, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Select Members",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _allUsers.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final user = _allUsers[index];
                    final isOwner = user.uid == userId;
                    final isSelected =
                    _selectedUserIds.contains(user.uid);

                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: Colors.blueAccent,
                      title: Text(
                        isOwner
                            ? 'You (${user.name.isNotEmpty ? user.name : user.email})'
                            : user.name.isNotEmpty
                            ? user.name
                            : user.email,
                        style: TextStyle(
                          fontWeight:
                          isOwner ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      subtitle: isOwner
                          ? Text("Team Owner",
                          style: TextStyle(
                              color: Colors.blueGrey, fontSize: 12))
                          : null,
                      onChanged: isOwner
                          ? null
                          : (val) {
                        setState(() {
                          if (val == true) {
                            _selectedUserIds.add(user.uid);
                          } else {
                            _selectedUserIds.remove(user.uid);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.check_circle_outline),
                label: Text(
                  "Create Team",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Team name is required")),
                    );
                    return;
                  }

                  final team = TeamModel(
                    id: '',
                    name: _nameController.text.trim(),
                    ownerId: userId,
                    memberIds: _selectedUserIds,
                  );

                  await Provider.of<TeamProvider>(context, listen: false)
                      .createTeam(team);

                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
