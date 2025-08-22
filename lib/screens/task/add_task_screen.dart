import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import 'package:tasknest/models/activity_model.dart';
import 'package:tasknest/models/task_model.dart';
import 'package:tasknest/providers/activity_provider.dart';
import 'package:tasknest/providers/task_provider.dart';
import 'package:tasknest/providers/team_provider.dart';
import 'package:tasknest/models/user_model.dart';
import 'package:tasknest/models/team_model.dart';

class AddTaskScreen extends StatefulWidget {
  final String? preselectedGoalId;
  AddTaskScreen({this.preselectedGoalId});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  DateTime? _due;
  String _priority = 'low';

  late String _selectedAssignee;
  List<UserModel> _users = [];
  List<TeamModel> _teams = [];
  bool _loadingUsers = true;
  bool _loadingTeams = true;

  File? _selectedFile;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _selectedAssignee = FirebaseAuth.instance.currentUser?.uid ?? '';
    _fetchTeamsAndUsers();
  }

  void _fetchTeamsAndUsers() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final teams = await Provider.of<TeamProvider>(
        context,
        listen: false,
      ).getTeamsForUser(userId);

      final memberIds = <String>{};
      for (var team in teams) {
        memberIds.addAll(team.memberIds);
      }
      memberIds.add(userId);

      final users = await Provider.of<TeamProvider>(
        context,
        listen: false,
      ).fetchAllUsers();

      final filtered = users.where((u) => memberIds.contains(u.uid)).toList();

      setState(() {
        _users = filtered;
        _teams = teams;
        _loadingUsers = false;
        _loadingTeams = false;
        if (!_users.any((u) => u.uid == _selectedAssignee) && _users.isNotEmpty) {
          _selectedAssignee = _users.first.uid;
        }
      });
    } catch (e, s) {
      _logger.e('Error fetching teams/users', error: s);
    }
  }

  Future<void> _pickDue() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t == null) return;
    setState(() => _due = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadFileToLaravel(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://cscollaborators.online/ho/api/upload/file'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        final resString = await response.stream.bytesToString();
        final data = jsonDecode(resString);

        // ✅ CORRECT: 'url' field access karo, 'path' nahi
        return data['url'];
      } else {
        _logger.e("File upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e, s) {
      _logger.e("Exception uploading file", error: e, stackTrace: s);
      return null;
    }
  }
  void _save() async {
    if (_title.text.trim().isEmpty) {
      _logger.w('Task title is empty');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String assignedUserId = '';
    String? assignedTeamId;

    if (_selectedAssignee.startsWith('team:')) {
      assignedTeamId = _selectedAssignee.substring(5);
    } else {
      assignedUserId = _selectedAssignee;
    }

    String? fileUrl;
    if (_selectedFile != null) {
      fileUrl = await _uploadFileToLaravel(_selectedFile!);
    }

    final task = TaskModel(
      id: '',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      dueDate: _due ?? DateTime.now(),
      priority: _priority,
      assignedUserId: assignedUserId,
      assignedTeamId: assignedTeamId,
      goalId: widget.preselectedGoalId,
      isCompleted: false,
      createdBy: currentUserId,
      status: 'todo',
      updatedAt: '',
      fileUrl: fileUrl, // existing field from TaskModel
    );

    try {
      await Provider.of<TaskProvider>(context, listen: false).addTask(task);

      final activity = ActivityModel(
        action: 'task_created',
        description: 'Task "${task.title}" created and assigned.',
        userId: currentUserId,
        entityId: task.id,
        timestamp: DateTime.now(),
      );
      await Provider.of<ActivityProvider>(context, listen: false).logActivity(activity);

      Navigator.pop(context);
    } catch (e, s) {
      _logger.e('Error saving task', error: s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Create Task'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField(controller: _title, label: "Task Title", icon: Icons.title),
              SizedBox(height: 12),
              _buildInputField(controller: _desc, label: "Description", icon: Icons.description, maxLines: 3),
              SizedBox(height: 16),

              // Due date
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(_due == null ? 'Select Due Date' : DateFormat.yMMMd().add_jm().format(_due!)),
                  trailing: TextButton(child: Text("Pick"), onPressed: _pickDue),
                ),
              ),
              SizedBox(height: 16),

              // Priority Chips
              Text("Priority", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: ['low', 'medium', 'high'].map((p) {
                  final isSelected = _priority == p;
                  return ChoiceChip(
                    label: Text(p.toUpperCase()),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    onSelected: (_) => setState(() => _priority = p),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // File Upload
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.attach_file, color: Colors.blue),
                  title: Text(_selectedFile == null ? 'No file selected' : _selectedFile!.path.split('/').last),
                  trailing: TextButton(child: Text("Choose"), onPressed: _pickFile),
                ),
              ),
              SizedBox(height: 16),

              // Assignee Dropdown
              (_loadingUsers || _loadingTeams)
                  ? Center(child: CircularProgressIndicator())
                  : Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _selectedAssignee,
                    isExpanded: true,
                    underline: SizedBox(),
                    items: [
                      ..._users.map((user) => DropdownMenuItem(
                        value: user.uid,
                        child: Text(user.uid == FirebaseAuth.instance.currentUser?.uid
                            ? 'You (${user.name.isNotEmpty ? user.name : user.email})'
                            : user.name.isNotEmpty
                            ? user.name
                            : user.email),
                      )),
                      ..._teams.map((team) => DropdownMenuItem(
                        value: 'team:${team.id}',
                        child: Text('Team: ${team.name}'),
                      )),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedAssignee = v);
                    },
                  ),
                ),
              ),

              SizedBox(height: 24),
              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Create Task",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
