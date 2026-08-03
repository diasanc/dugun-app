import 'package:flutter/foundation.dart';

import '../../../../core/services/wedding_service.dart';
import '../../data/models/guest.dart';
import '../../data/services/guest_service.dart';

class GuestListController extends ChangeNotifier {
  GuestListController({required this.userId});

  final String userId;

  List<Guest> _guests = [];
  bool loading = true;
  String? error;
  String? weddingId;

  List<Guest> get guests => _guests;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final wedding = await WeddingService().getOrCreateWedding(userId);
      weddingId = wedding.id;
      _guests = await GuestService().fetchByWedding(wedding.id);
    } catch (_) {
      error = 'Veriler yüklenemedi. Lütfen tekrar deneyin.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> silentRefresh() async {
    final id = weddingId;
    if (id == null) return;
    try {
      _guests = await GuestService().fetchByWedding(id);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addGuest(Guest guest) async {
    try {
      final created = await GuestService().create(guest);
      _guests = [..._guests, created]
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      notifyListeners();
    } catch (_) {
      await silentRefresh();
    }
  }

  Future<void> updateGuest(Guest guest) async {
    try {
      final updated = await GuestService().update(guest);
      final i = _guests.indexWhere((g) => g.id == guest.id);
      if (i != -1) {
        _guests = List.from(_guests)..[i] = updated;
        _guests.sort((a, b) => a.fullName.compareTo(b.fullName));
      }
      notifyListeners();
    } catch (_) {
      await silentRefresh();
    }
  }

  Future<void> removeGuest(String id) async {
    _guests = List.from(_guests)..removeWhere((g) => g.id == id);
    notifyListeners();
    try {
      await GuestService().delete(id);
    } catch (_) {
      await silentRefresh();
    }
  }
}
