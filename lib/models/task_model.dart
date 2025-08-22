class TaskModel {
  String id;
  String title;
  String description;
  DateTime dueDate;
  String priority;
  String assignedUserId;
  String? assignedTeamId;
  String? goalId;
  bool isCompleted;
  String createdBy;
  String status;
  String updatedAt;
  String? fileUrl; // 👈 new field

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.assignedUserId,
    this.assignedTeamId,
    this.goalId,
    required this.isCompleted,
    required this.createdBy,
    this.status = 'todo',
    this.updatedAt = '',
    this.fileUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'priority': priority,
    'assignedUserId': assignedUserId,
    'assignedTeamId': assignedTeamId,
    'goalId': goalId,
    'isCompleted': isCompleted ? 1 : 0,
    'createdBy': createdBy,
    'status': status,
    'updatedAt': updatedAt,
    'fileUrl': fileUrl,
  };

  static TaskModel fromMap(String id, Map<String, dynamic> map) => TaskModel(
    id: id,
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    dueDate: DateTime.parse(map['dueDate']),
    priority: map['priority'] ?? 'low',
    assignedUserId: map['assignedUserId'] ?? '',
    assignedTeamId: map['assignedTeamId'],
    goalId: map['goalId'],
    isCompleted: (map['isCompleted'] ?? 0) == 1,
    createdBy: map['createdBy'] ?? '',
    status: map['status'] ?? 'todo',
    updatedAt: map['updatedAt'] ?? '',
    fileUrl: map['fileUrl'],
  );
}
