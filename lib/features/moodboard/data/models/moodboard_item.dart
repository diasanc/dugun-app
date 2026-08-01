enum MoodboardItemType {
  link('link'),
  note('note'),
  photo('photo');

  const MoodboardItemType(this.wire);
  final String wire;

  static MoodboardItemType fromWire(String value) =>
      MoodboardItemType.values.firstWhere((e) => e.wire == value);
}

const kMoodboardCategories = [
  'Tümü',
  'Gelinlik',
  'Mekan',
  'Çiçekler',
  'Makyaj',
  'Diğer',
];

class MoodboardItem {
  const MoodboardItem({
    required this.id,
    required this.weddingId,
    required this.type,
    this.title,
    required this.content,
    this.notes,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
  });

  final String id;
  final String weddingId;
  final MoodboardItemType type;
  final String? title;
  final String content;
  final String? notes;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  factory MoodboardItem.fromJson(Map<String, dynamic> json) {
    return MoodboardItem(
      id: json['id'] as String,
      weddingId: json['wedding_id'] as String,
      type: MoodboardItemType.fromWire(json['type'] as String),
      title: json['title'] as String?,
      content: json['content'] as String,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toInsert() => {
        'wedding_id': weddingId,
        'type': type.wire,
        'title': title,
        'content': content,
        'notes': notes,
        'category': category,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toUpdate() => toInsert()..remove('wedding_id');

  MoodboardItem copyWith({
    MoodboardItemType? type,
    String? title,
    String? content,
    String? notes,
    String? category,
    int? sortOrder,
  }) {
    return MoodboardItem(
      id: id,
      weddingId: weddingId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
