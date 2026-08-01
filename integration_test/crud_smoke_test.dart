// End-to-end dogrulama: gercek Supabase'e karsi guests + expenses CRUD.
//
// RLS oturum gerektirir; bu yuzden test once bir test kullanicisiyla giris
// yapar, kendi adina bir dugun olusturur (trigger onu admin uye yapar), sonra
// davetli ve gider uzerinde create/read/update/delete dener. Sonunda dugunu
// siler (cascade -> guest/expense/uyelikler de gider) ve cikis yapar.
//
// Kimlik bilgileri koda GOMULMEZ; calistirma aninda --dart-define ile verilir:
//
//   flutter test integration_test/crud_smoke_test.dart \
//     -d <device-id> \
//     --dart-define=TEST_EMAIL=... \
//     --dart-define=TEST_PASSWORD=...

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ilk_projem/core/supabase/supabase_init.dart';
import 'package:ilk_projem/features/guests/data/models/guest.dart';
import 'package:ilk_projem/features/guests/data/services/guest_service.dart';
import 'package:ilk_projem/features/budget/data/models/expense.dart';
import 'package:ilk_projem/features/budget/data/services/expense_service.dart';

const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;
  String? weddingId;

  setUpAll(() async {
    expect(
      _email.isNotEmpty && _password.isNotEmpty,
      isTrue,
      reason: 'TEST_EMAIL ve TEST_PASSWORD --dart-define ile verilmeli.',
    );

    // Onceki oturumu SharedPreferences'tan temizle.
    // recoverSession() arka planda calisirken eski token ile
    // yeni signInWithPassword oturumunun uzerine yazmasi engellenir.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sb-vwcochhjzdgiiczdvico-auth-token');

    await SupabaseInit.init();
    client = SupabaseInit.client;

    final auth = await client.auth
        .signInWithPassword(email: _email, password: _password);
    expect(auth.session, isNotNull, reason: 'Giris basarisiz (oturum yok).');
  });

  tearDownAll(() async {
    // Test verisini temizle: dugunu silmek cascade ile guest/expense'i de siler.
    if (weddingId != null) {
      await client.from('weddings').delete().eq('id', weddingId!);
    }
    await client.auth.signOut();
  });

  test('weddings: olusturma ve owner -> admin uye trigger', () async {
    final uid = client.auth.currentUser!.id;

    final row = await client
        .from('weddings')
        .insert({'owner_id': uid, 'title': 'CRUD Smoke Test'})
        .select()
        .single();
    weddingId = row['id'] as String;

    // Trigger owner'i admin uye yapmis olmali (yoksa RLS yazmaya izin vermez).
    final member = await client
        .from('wedding_members')
        .select()
        .eq('wedding_id', weddingId!)
        .eq('user_id', uid)
        .single();
    expect(member['role'], 'admin');
  });

  test('guests: create / read / update / delete', () async {
    final service = GuestService(client: client);

    final created = await service.create(Guest(
      id: '',
      weddingId: weddingId!,
      fullName: 'Test Davetli',
      side: GuestSide.bride,
      companionCount: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    expect(created.id, isNotEmpty);
    expect(created.rsvpStatus, RsvpStatus.pending);
    expect(created.companionCount, 2);

    final list = await service.fetchByWedding(weddingId!);
    expect(list.any((g) => g.id == created.id), isTrue);

    final updated = await service.update(
      created.copyWith(rsvpStatus: RsvpStatus.attending, companionCount: 3),
    );
    expect(updated.rsvpStatus, RsvpStatus.attending);
    expect(updated.companionCount, 3);

    await service.delete(created.id);
    final after = await service.fetchByWedding(weddingId!);
    expect(after.any((g) => g.id == created.id), isFalse);
  });

  test('expenses: create / read / update / delete', () async {
    final service = ExpenseService(client: client);

    final created = await service.create(Expense(
      id: '',
      weddingId: weddingId!,
      title: 'Mekan kaparosu',
      category: ExpenseCategory.venue,
      estimatedAmount: 50000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    expect(created.id, isNotEmpty);
    expect(created.category, ExpenseCategory.venue);
    expect(created.estimatedAmount, 50000);
    expect(created.isPaid, isFalse);

    final updated = await service.update(
      created.copyWith(actualAmount: 48000, isPaid: true),
    );
    expect(updated.actualAmount, 48000);
    expect(updated.isPaid, isTrue);

    await service.delete(created.id);
    final after = await service.fetchByWedding(weddingId!);
    expect(after.any((e) => e.id == created.id), isFalse);
  });
}
