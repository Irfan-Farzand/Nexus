import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/models/task_model.dart';
import 'package:tasknest/providers/task_provider.dart';
import 'package:tasknest/models/comment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tasknest/providers/activity_provider.dart';
import 'package:tasknest/models/activity_model.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;
  const EditTaskScreen({required this.task, super.key});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _title;
  late TextEditingController _desc;
  DateTime? _due;
  String _priority = 'low';
  final _commentController = TextEditingController();

  // Cache for user names
  final Map<String, String> _userNameCache = {};

  @override
  void initState() {
    _title = TextEditingController(text: widget.task.title);
    _desc = TextEditingController(text: widget.task.description);
    _due = widget.task.dueDate;
    _priority = widget.task.priority;
    super.initState();
  }

  Future<String> _getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final name = doc.data()?['name'] ?? 'Unknown';
    _userNameCache[userId] = name;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TaskProvider>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Edit Task"),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              child: Column(
                children: [
                  TextField(
                    controller: _title,
                    decoration: _inputStyle("Title"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _desc,
                    maxLines: 3,
                    decoration: _inputStyle("Description"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _due == null
                              ? 'No due date set'
                              : DateFormat.yMMMd().add_jm().format(_due!),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.blue),
                        label: const Text("Pick Date"),
                        onPressed: _pickDue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: _inputStyle("Priority"),
                    items: ['low', 'medium', 'high']
                        .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.toUpperCase()),
                    ))
                        .toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Comments Section
            Text(
              "Comments",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 10),
            _buildCard(
              child: SizedBox(
                height: 250,
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<CommentModel>>(
                        stream: tp.streamCommentsForTask(widget.task.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text("Something went wrong!"));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text("No comments yet."));
                          }
                          return ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (ctx, idx) {
                              final comment = snapshot.data![idx];
                              return FutureBuilder<String>(
                                future: _getUserName(comment.userId),
                                builder: (context, userSnap) {
                                  final name = userSnap.data ?? '...';
                                  return Card(
                                    elevation: 0,
                                    color: Colors.grey.shade100,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: ListTile(
                                      title: Text(comment.text),
                                      subtitle: Text(
                                        "$name • ${DateFormat.yMMMd().add_jm().format(comment.timestamp)}",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: _inputStyle("Add a comment..."),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () async {
                            if (_commentController.text.trim().isNotEmpty) {
                              final comment = CommentModel(
                                text: _commentController.text.trim(),
                                timestamp: DateTime.now(),
                                userId: userId,
                              );
                              await tp.addComment(widget.task.id, comment);

                              // Log activity
                              final activity = ActivityModel(
                                action: 'comment_added',
                                description:
                                'Comment added to task "${widget.task.title}"',
                                userId: userId,
                                entityId: widget.task.id,
                                timestamp: DateTime.now(),
                              );
                              await Provider.of<ActivityProvider>(
                                context,
                                listen: false,
                              ).logActivity(activity);

                              _commentController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  final updated = TaskModel(
                    id: widget.task.id,
                    title: _title.text.trim(),
                    description: _desc.text.trim(),
                    dueDate: _due ?? DateTime.now(),
                    priority: _priority,
                    assignedUserId: widget.task.assignedUserId,
                    goalId: widget.task.goalId,
                    isCompleted: widget.task.isCompleted,
                    createdBy: widget.task.createdBy,
                  );
                  await tp.updateTask(updated);

                  // Log activity
                  final activity = ActivityModel(
                    action: 'task_updated',
                    description: 'Task "${updated.title}" updated.',
                    userId: userId,
                    entityId: updated.id,
                    timestamp: DateTime.now(),
                  );
                  await Provider.of<ActivityProvider>(
                    context,
                    listen: false,
                  ).logActivity(activity);

                  Navigator.pop(context);
                },
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      labelText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Future<void> _pickDue() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due ?? DateTime.now()),
    );
    if (t == null) return;
    setState(() => _due = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }
}
