/// Davetlinin hangi tarafa ait oldugu. DB enum: public.guest_side.
enum GuestSide {
  bride('bride'),
  groom('groom'),
  both('both');

  const GuestSide(this.wire);

  /// Veritabanindaki string karsiligi.
  final String wire;

  static GuestSide? fromWire(String? value) {
    if (value == null) return null;
    return GuestSide.values.firstWhere((e) => e.wire == value);
  }
}

/// Davetlinin katilim durumu (RSVP). DB enum: public.rsvp_status.
enum RsvpStatus {
  pending('pending'),
  attending('attending'),
  declined('declined'),
  maybe('maybe');

  const RsvpStatus(this.wire);

  final String wire;

  static RsvpStatus fromWire(String value) {
    return RsvpStatus.values.firstWhere((e) => e.wire == value);
  }
}

/// public.guests tablosunun bir satirini temsil eder.
///
/// Sunucu tarafindan uretilen alanlar (id, createdAt, updatedAt) yalnizca
/// okuma tarafindadir; yazma icin [toInsert] / [toUpdate] kullanilir.
class Guest {
  const Guest({
    required this.id,
    required this.weddingId,
    required this.fullName,
    this.phone,
    this.email,
    this.side,
    this.rsvpStatus = RsvpStatus.pending,
    this.companionCount = 0,
    this.groupLabel,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String weddingId;
  final String fullName;
  final String? phone;
  final String? email;
  final GuestSide? side;
  final RsvpStatus rsvpStatus;
  final int companionCount;
  final String? groupLabel;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Supabase'den gelen satiri modele cevirir.
  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] as String,
      weddingId: json['wedding_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      side: GuestSide.fromWire(json['side'] as String?),
      rsvpStatus: RsvpStatus.fromWire(json['rsvp_status'] as String),
      companionCount: json['companion_count'] as int,
      groupLabel: json['group_label'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// INSERT icin gonderilecek alanlar. Sunucu yonetimli alanlar (id,
  /// created_at, updated_at) ve varsayilani DB'de olan rsvp_status haric tutulur
  /// degil; aktif degeri gondeririz ki UI'da secilen deger korunsun.
  Map<String, dynamic> toInsert() {
    return {
      'wedding_id': weddingId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'side': side?.wire,
      'rsvp_status': rsvpStatus.wire,
      'companion_count': companionCount,
      'group_label': groupLabel,
      'notes': notes,
    };
  }

  /// UPDATE icin gonderilecek alanlar (degistirilebilir alanlar).
  Map<String, dynamic> toUpdate() => toInsert()..remove('wedding_id');

  Guest copyWith({
    String? fullName,
    String? phone,
    String? email,
    GuestSide? side,
    RsvpStatus? rsvpStatus,
    int? companionCount,
    String? groupLabel,
    String? notes,
  }) {
    return Guest(
      id: id,
      weddingId: weddingId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      side: side ?? this.side,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      companionCount: companionCount ?? this.companionCount,
      groupLabel: groupLabel ?? this.groupLabel,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
