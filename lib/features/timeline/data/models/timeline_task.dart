enum TaskCategory {
  mekan('mekan'),
  gelinlik('gelinlik'),
  davetli('davetli'),
  organizasyon('organizasyon'),
  fotografci('fotografci'),
  catering('catering'),
  muzik('muzik'),
  diger('diger');

  const TaskCategory(this.wire);
  final String wire;

  static TaskCategory fromWire(String value) => TaskCategory.values
      .firstWhere((e) => e.wire == value, orElse: () => TaskCategory.diger);
}

class TimelineTask {
  const TimelineTask({
    required this.id,
    required this.weddingId,
    required this.title,
    this.category = TaskCategory.diger,
    this.dueDate,
    this.notes,
    this.isCompleted = false,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String weddingId;
  final String title;
  final TaskCategory category;
  final DateTime? dueDate;
  final String? notes;
  final bool isCompleted;
  final bool isTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TimelineTask.fromJson(Map<String, dynamic> json) {
    return TimelineTask(
      id: json['id'] as String,
      weddingId: json['wedding_id'] as String,
      title: json['title'] as String,
      category: TaskCategory.fromWire(json['category'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      notes: json['notes'] as String?,
      isCompleted: json['is_completed'] as bool,
      isTemplate: json['is_template'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsert() => {
        'wedding_id': weddingId,
        'title': title,
        'category': category.wire,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'notes': notes,
        'is_completed': isCompleted,
        'is_template': isTemplate,
      };

  TimelineTask copyWith({
    String? title,
    TaskCategory? category,
    DateTime? dueDate,
    String? notes,
    bool? isCompleted,
  }) {
    return TimelineTask(
      id: id,
      weddingId: weddingId,
      title: title ?? this.title,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      isTemplate: isTemplate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
