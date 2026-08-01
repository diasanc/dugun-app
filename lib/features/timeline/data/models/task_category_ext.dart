import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

import 'timeline_task.dart';

extension TaskCategoryUi on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.mekan:       return 'Mekan';
      case TaskCategory.gelinlik:    return 'Gelinlik';
      case TaskCategory.davetli:     return 'Davetli';
      case TaskCategory.organizasyon:return 'Organizasyon';
      case TaskCategory.fotografci:  return 'Fotoğrafçı';
      case TaskCategory.catering:    return 'Catering';
      case TaskCategory.muzik:       return 'Müzik';
      case TaskCategory.diger:       return 'Diğer';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.mekan:       return const Color(0xFF7A9EB8);
      case TaskCategory.gelinlik:    return const Color(0xFF9B7EB8);
      case TaskCategory.davetli:     return const Color(0xFF7A9671);
      case TaskCategory.organizasyon:return const Color(0xFF775656);
      case TaskCategory.fotografci:  return const Color(0xFFB87A50);
      case TaskCategory.catering:    return const Color(0xFFB8A050);
      case TaskCategory.muzik:       return const Color(0xFF7AB8A0);
      case TaskCategory.diger:       return const Color(0xFF9E8B8B);
    }
  }

  String get icon {
    switch (this) {
      case TaskCategory.mekan:       return Reicon.outline.building;
      case TaskCategory.gelinlik:    return Reicon.outline.hanger;
      case TaskCategory.davetli:     return Reicon.outline.people;
      case TaskCategory.organizasyon:return Reicon.outline.document;
      case TaskCategory.fotografci:  return Reicon.outline.camera;
      case TaskCategory.catering:    return Reicon.outline.plate;
      case TaskCategory.muzik:       return Reicon.outline.music;
      case TaskCategory.diger:       return Reicon.outline.more;
    }
  }
}
