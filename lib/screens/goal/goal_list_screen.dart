import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/providers/goal_provider.dart';
import 'package:tasknest/providers/task_provider.dart';
import 'package:tasknest/screens/goal/add_goal_screen.dart';
import 'package:tasknest/screens/task/add_task_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalListScreen extends StatefulWidget {
  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      Provider.of<GoalProvider>(context, listen: false).fetchGoalsForUser(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GoalProvider>(context);
    final tp = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "My Goals",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
      ),
      body: gp.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : gp.goals.isEmpty
          ? Center(
        child: Text(
          "No goals yet. Add your first goal!",
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gp.goals.length,
        itemBuilder: (context, idx) {
          final g = gp.goals[idx];
          final tasksOfGoal = tp.tasks.where((t) => t.goalId == g.id).toList();
          final completedTasks = tasksOfGoal.where((t) => t.isCompleted).length;

          double progress = tasksOfGoal.isEmpty
              ? 0
              : completedTasks / tasksOfGoal.length;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  builder: (_) => _goalDetailsSheet(context, g, tasksOfGoal),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTaskScreen(preselectedGoalId: g.id),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => gp.deleteGoal(g.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${tasksOfGoal.length} tasks",
                            style: const TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$completedTasks done",
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Goal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddGoalScreen()),
        ),
      ),
    );
  }

  Widget _goalDetailsSheet(BuildContext context, goal, List tasks) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Text(
              goal.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                goal.description,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
            const SizedBox(height: 18),
            const Text("Tasks", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 10),
            ...tasks.map<Widget>((t) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: CheckboxListTile(
                value: t.isCompleted,
                onChanged: (val) {
                  Provider.of<TaskProvider>(context, listen: false).toggleComplete(t);
                },
                title: Text(t.title),
                subtitle: Text(
                  t.priority,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                activeColor: Colors.blue,
              ),
            )),
          ],
        ),
      ),
    );
  }
}
