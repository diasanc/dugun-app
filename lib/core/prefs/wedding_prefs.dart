import 'package:shared_preferences/shared_preferences.dart';

class WeddingPrefs {
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyWeddingDate = 'wedding_date';
  static const _keyBudget = 'budget';
  static const _keyGuestCount = 'guest_count';
  static const _keyBrideName = 'bride_name';
  static const _keyGroomName = 'groom_name';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<void> saveOnboardingData({
    DateTime? weddingDate,
    String? budget,
    int? guestCount,
    String? brideName,
    String? groomName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
    if (weddingDate != null) {
      await prefs.setString(_keyWeddingDate, weddingDate.toIso8601String());
    }
    if (budget != null && budget.isNotEmpty) {
      await prefs.setString(_keyBudget, budget);
    }
    if (guestCount != null) {
      await prefs.setInt(_keyGuestCount, guestCount);
    }
    if (brideName != null) {
      await prefs.setString(_keyBrideName, brideName);
    }
    if (groomName != null) {
      await prefs.setString(_keyGroomName, groomName);
    }
  }

  static Future<String?> getBudgetString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBudget);
  }

  static Future<DateTime?> getWeddingDate() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyWeddingDate);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  static Future<String?> getBrideName() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyBrideName);
    return (v != null && v.isNotEmpty) ? v : null;
  }

  static Future<String?> getGroomName() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyGroomName);
    return (v != null && v.isNotEmpty) ? v : null;
  }

  /// Returns "GELİN & DAMAT" (uppercase) if at least one name is set, else null.
  static Future<String?> getWeddingTitle() async {
    final prefs = await SharedPreferences.getInstance();
    final bride = prefs.getString(_keyBrideName);
    final groom = prefs.getString(_keyGroomName);
    final b = (bride != null && bride.isNotEmpty) ? bride.toUpperCase() : null;
    final g = (groom != null && groom.isNotEmpty) ? groom.toUpperCase() : null;
    if (b == null && g == null) return null;
    if (b != null && g != null) return '$b & $g';
    return b ?? g;
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingDone);
  }
}
