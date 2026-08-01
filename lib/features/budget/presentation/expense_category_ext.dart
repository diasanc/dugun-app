import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

import '../data/models/expense.dart';

extension ExpenseCategoryUi on ExpenseCategory {
  Color get color {
    switch (this) {
      case ExpenseCategory.venue:
        return const Color(0xFF5D3FD3);
      case ExpenseCategory.catering:
        return const Color(0xFFE07B54);
      case ExpenseCategory.photoVideo:
        return const Color(0xFF3F8FD3);
      case ExpenseCategory.attire:
        return const Color(0xFFCE5EA0);
      case ExpenseCategory.music:
        return const Color(0xFF6BAD6B);
      case ExpenseCategory.flowers:
        return const Color(0xFFD3813F);
      case ExpenseCategory.invitation:
        return const Color(0xFF9B5EA0);
      case ExpenseCategory.transport:
        return const Color(0xFF4FA8A8);
      case ExpenseCategory.other:
        return const Color(0xFF8A8C8E);
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.venue:
        return Reicon.outline.building;
      case ExpenseCategory.catering:
        return Reicon.outline.plate;
      case ExpenseCategory.photoVideo:
        return Reicon.outline.camera;
      case ExpenseCategory.attire:
        return Reicon.outline.hanger;
      case ExpenseCategory.music:
        return Reicon.outline.music;
      case ExpenseCategory.flowers:
        return Reicon.outline.leaf;
      case ExpenseCategory.invitation:
        return Reicon.outline.envelope;
      case ExpenseCategory.transport:
        return Reicon.outline.car;
      case ExpenseCategory.other:
        return Reicon.outline.more;
    }
  }

  String get label {
    switch (this) {
      case ExpenseCategory.venue:
        return 'Mekan';
      case ExpenseCategory.catering:
        return 'Yemek & İkram';
      case ExpenseCategory.photoVideo:
        return 'Fotoğraf & Video';
      case ExpenseCategory.attire:
        return 'Kıyafet';
      case ExpenseCategory.music:
        return 'Müzik & DJ';
      case ExpenseCategory.flowers:
        return 'Çiçek & Dekor';
      case ExpenseCategory.invitation:
        return 'Davetiye';
      case ExpenseCategory.transport:
        return 'Ulaşım';
      case ExpenseCategory.other:
        return 'Diğer';
    }
  }
}
