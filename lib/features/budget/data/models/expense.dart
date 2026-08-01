/// Gider kalemi kategorisi. DB enum: public.expense_category.
enum ExpenseCategory {
  venue('venue'),
  catering('catering'),
  photoVideo('photo_video'),
  attire('attire'),
  music('music'),
  flowers('flowers'),
  invitation('invitation'),
  transport('transport'),
  other('other');

  const ExpenseCategory(this.wire);

  /// Veritabanindaki string karsiligi.
  final String wire;

  static ExpenseCategory fromWire(String value) {
    return ExpenseCategory.values.firstWhere((e) => e.wire == value);
  }
}

/// public.expenses tablosunun bir satirini temsil eder.
///
/// Para alanlari (estimatedAmount / actualAmount) numeric -> Dart'ta double.
/// Float ile para hesabi yapmaktan kacinilmali; gosterim/toplama tarafinda
/// uygun yuvarlama uygulanmali.
class Expense {
  const Expense({
    required this.id,
    required this.weddingId,
    required this.title,
    this.category = ExpenseCategory.other,
    this.estimatedAmount,
    this.actualAmount,
    this.isPaid = false,
    this.dueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String weddingId;
  final String title;
  final ExpenseCategory category;
  final double? estimatedAmount;
  final double? actualAmount;
  final bool isPaid;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      weddingId: json['wedding_id'] as String,
      title: json['title'] as String,
      category: ExpenseCategory.fromWire(json['category'] as String),
      estimatedAmount: _toDouble(json['estimated_amount']),
      actualAmount: _toDouble(json['actual_amount']),
      isPaid: json['is_paid'] as bool,
      dueDate: _toDate(json['due_date'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// INSERT icin gonderilecek alanlar.
  Map<String, dynamic> toInsert() {
    return {
      'wedding_id': weddingId,
      'title': title,
      'category': category.wire,
      'estimated_amount': estimatedAmount,
      'actual_amount': actualAmount,
      'is_paid': isPaid,
      // date alani: yalnizca tarih kismi (YYYY-MM-DD) gonderilir.
      'due_date': dueDate?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }

  /// UPDATE icin gonderilecek alanlar.
  Map<String, dynamic> toUpdate() => toInsert()..remove('wedding_id');

  Expense copyWith({
    String? title,
    ExpenseCategory? category,
    double? estimatedAmount,
    double? actualAmount,
    bool? isPaid,
    DateTime? dueDate,
    String? notes,
  }) {
    return Expense(
      id: id,
      weddingId: weddingId,
      title: title ?? this.title,
      category: category ?? this.category,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      actualAmount: actualAmount ?? this.actualAmount,
      isPaid: isPaid ?? this.isPaid,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// numeric Supabase'den num veya String gelebilir; ikisini de guvenle cevirir.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(String? value) {
    if (value == null) return null;
    return DateTime.parse(value);
  }
}
