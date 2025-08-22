import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tasknest/providers/task_provider.dart';
import 'package:tasknest/screens/task/add_task_screen.dart';
import 'package:tasknest/screens/task/edit_task_screen.dart';
import 'package:tasknest/screens/task/kanban_board_screen.dart';
import 'package:tasknest/screens/task/view_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool showKanban = false;
  final Color primaryBlue = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      Provider.of<TaskProvider>(
        context,
        listen: false,
      ).fetchTasksForUser(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          'My Tasks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              showKanban ? Icons.list_alt_rounded : Icons.view_kanban_rounded,
              color: Colors.white,
            ),
            tooltip: showKanban ? 'List View' : 'Kanban Board',
            onPressed: () => setState(() => showKanban = !showKanban),
          ),
        ],
      ),
      body:
          showKanban
              ? KanbanBoardScreen()
              : tp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  await tp.fetchTasksForUser(userId);
                },
                child:
                    tp.getFilteredSortedTasks().isEmpty
                        ? ListView(
                          children: [
                            SizedBox(height: 120),
                            Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                "No tasks yet",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: tp.getFilteredSortedTasks().length,
                          itemBuilder: (context, idx) {
                            final t = tp.getFilteredSortedTasks()[idx];

                            final isDone = t.isCompleted;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewTaskScreen(task: t),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      isDone ? Colors.grey[200] : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border:
                                      isDone
                                          ? null
                                          : Border(
                                            left: BorderSide(
                                              color: primaryBlue,
                                              width: 4,
                                            ),
                                          ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Check button
                                    GestureDetector(
                                      onTap:
                                          () => tp.toggleComplete(
                                            t,
                                            context: context,
                                          ),
                                      child: Container(
                                        height: 28,
                                        width: 28,
                                        decoration: BoxDecoration(
                                          color:
                                              isDone
                                                  ? Colors.green
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color:
                                                isDone
                                                    ? Colors.green
                                                    : Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child:
                                            isDone
                                                ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 18,
                                                )
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Task details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  isDone
                                                      ? Colors.grey[600]
                                                      : Colors.black87,
                                              decoration:
                                                  isDone
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${t.priority.toUpperCase()} • Due ${DateFormat.yMMMd().format(t.dueDate)} • ${t.status}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  isDone
                                                      ? Colors.grey[500]
                                                      : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Actions
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blueGrey[700],
                                          ),
                                          onPressed:
                                              () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => EditTaskScreen(
                                                        task: t,
                                                      ),
                                                ),
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () async {
                                            await tp.deleteTask(t.id);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Task deleted'),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Task",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTaskScreen()),
            ),
      ),
    );
  }
}
