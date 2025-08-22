import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/providers/task_provider.dart';
import 'package:tasknest/models/task_model.dart';

class KanbanBoardScreen extends StatelessWidget {
  final List<String> statuses = ['todo', 'inprogress', 'blocked', 'done'];

  final Map<String, String> statusLabels = {
    'todo': 'To-Do',
    'inprogress': 'In Progress',
    'blocked': 'Blocked',
    'done': 'Done',
  };

  final Map<String, Color> statusColors = {
    'todo': Colors.blue,
    'inprogress': Colors.orange,
    'blocked': Colors.red,
    'done': Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TaskProvider>(context);
    final tasks = tp.getFilteredSortedTasks();

    Map<String, List<TaskModel>> columns = {
      for (var s in statuses) s: tasks.where((t) => t.status == s).toList(),
    };

    return Row(
      children: statuses.map((status) {
        final columnTasks = columns[status]!;
        return Expanded(
          child: DragTarget<TaskModel>(
            onAccept: (task) {
              tp.updateTaskStatus(task.id, status);
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Column Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: statusColors[status]!.withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          statusLabels[status]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Column Content
                    Expanded(
                      child: columnTasks.isEmpty
                          ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            candidateData.isEmpty
                                ? "No tasks"
                                : "Drop here",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                          : ListView(
                        padding: const EdgeInsets.all(8),
                        children: columnTasks.map((task) {
                          return Draggable<TaskModel>(
                            data: task,
                            feedback: Material(
                              color: Colors.transparent,
                              child: _buildTaskCard(task,
                                  highlight: true),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.4,
                              child: _buildTaskCard(task),
                            ),
                            child: _buildTaskCard(task),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  // Custom Task Card
  Widget _buildTaskCard(TaskModel task, {bool highlight = false}) {
    return Card(
      elevation: highlight ? 8 : 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: highlight ? Colors.blue[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
