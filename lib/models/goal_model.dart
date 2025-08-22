class GoalModel {
  String id;
  String title;
  String description;
  List<String> taskIds;
  String ownerId; // Add this

  GoalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.taskIds,
    required this.ownerId, // Add this
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'tasks': taskIds,
    'ownerId': ownerId, // Add this
  };

  factory GoalModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      taskIds: List<String>.from(map['tasks'] ?? []),
      ownerId: map['ownerId'] ?? '', // Add this
    );
  }
}
