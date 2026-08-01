import 'package:flutter/foundation.dart';

import '../../../../core/services/wedding_service.dart';
import '../../data/models/timeline_task.dart';
import '../../data/services/timeline_service.dart';

class TimelineController extends ChangeNotifier {
  TimelineController({required this.userId});

  final String userId;

  List<TimelineTask> _tasks = [];
  bool loading = true;
  String? weddingId;

  List<TimelineTask> get tasks => _tasks;
  List<TimelineTask> get upcomingTasks =>
      _tasks.where((t) => !t.isCompleted).take(3).toList();
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      final wedding = await WeddingService().getOrCreateWedding(userId);
      weddingId = wedding.id;
      _tasks = await TimelineService().fetchByWedding(wedding.id);
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  /// Mevcut state'i koruyarak arka planda yeniler (tab geçişlerinde kullanılır).
  Future<void> silentRefresh() async {
    try {
      final wedding = await WeddingService().getOrCreateWedding(userId);
      weddingId = wedding.id;
      _tasks = await TimelineService().fetchByWedding(wedding.id);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggle(TimelineTask task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;
    _tasks[i] = task.copyWith(isCompleted: !task.isCompleted);
    notifyListeners();
    try {
      await TimelineService().update(task.id, isCompleted: !task.isCompleted);
    } catch (_) {
      await silentRefresh();
    }
  }

  Future<void> delete(TimelineTask task) async {
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
    try {
      await TimelineService().delete(task.id);
    } catch (_) {
      await silentRefresh();
    }
  }
}
