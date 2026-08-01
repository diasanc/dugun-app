# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run                        # Run on connected device/simulator
flutter analyze                    # Lint & type-check
flutter test                       # Run unit tests
flutter test integration_test/     # Run integration tests
flutter build ios --release        # iOS release build
flutter build apk --release        # Android release build
```

## Architecture

### App entry & state routing (`lib/main.dart`)

`main()` initialises Supabase, then runs `WeddingApp` (StatefulWidget). The root widget owns `AuthController` and `_onboardingDone` state. A single `_AppShell` widget is kept as `home` permanently — Flutter never rebuilds the Navigator; only `_AppShell.build()` re-runs when state changes. The app routes through three states in order:

1. **Splash** — while checking SharedPreferences
2. **OnboardingPage** — first launch only; sets `_onboardingDone = true` on complete
3. **Auth subtree** — `ListenableBuilder` on `AuthController`: authenticated → `DashboardPage`, otherwise → `LoginPage`

### Navigation model

There is **no router package**. All navigation is plain `Navigator.push` / `Navigator.pushReplacement` / `Navigator.popUntil`. The main "tab" pages (Dashboard=0, Timeline=1, Budget=2, Moodboard=3, BridalGuide=4) use:
- `Navigator.pushReplacement` when switching between sibling tabs from a non-Dashboard page
- `Navigator.popUntil(context, (r) => r.isFirst)` to return to Dashboard (index 0)
- `Navigator.push` from Dashboard for all sub-pages; `.then((_) => _loadXxx())` to refresh on return

`FloatingGlassNavBar` is embedded as a `Stack` overlay (`Positioned(left: 24, right: 24, bottom: 24)`) inside every main page's `body`. Each page declares its own `_handleNavTap` / `_withNavBar` helper in its State class. Sub-pages (e.g. `NecklineDetailPage`) do **not** show the nav bar.

All main pages except `BridalGuidePage` require `userId: String`. `BridalGuidePage` carries `userId` so it can navigate to the other tabs.

### Feature structure

```
lib/features/<feature>/
  data/
    models/       # Plain Dart model classes with .fromJson()
    services/     # Supabase queries — thin wrappers around SupabaseInit.client
  domain/
    entities/     # (auth only) domain entity classes
    repositories/ # (auth only) abstract repository interfaces
    usecases/     # (auth only) single-method use-case classes
  presentation/
    controllers/  # (auth only) ChangeNotifier controller
    pages/        # StatefulWidget pages
    widgets/      # Bottom sheets, cards, helper widgets
```

Only the `auth` feature follows full Clean Architecture with entities/repositories/use-cases. All other features use a simplified pattern: `data/services/` → `presentation/pages/` directly.

### Supabase integration

`SupabaseInit.client` is the single access point (never `Supabase.instance` directly). Services accept an optional `SupabaseClient` in their constructor for testability. The `weddings` table is the anchor: `WeddingService.getOrCreateWedding(userId)` returns or creates a wedding record that all other features reference by `weddingId`.

Key tables: `weddings`, `wedding_members`, `timeline_tasks`, `expenses`, `moodboard_items`, `guests`.

### Theme & UI system (`lib/core/theme/`)

**`AppTheme`** — all colour constants:
- `primary` = `#5D3FD3` (deep violet)
- `textDark` = `#191C1D`, `textMuted` = `#8A8C8E`
- `primaryContainer` = `#EDE8FC`
- Background gradient: `#FFF0F3` → `#FFCDD8` (used via `AppBackground`)

**`GlassCard`** — frosted-glass card (`BackdropFilter` + gradient). Accepts `tint: Color` for coloured variants (used in category cards). Pass `onTap` to make it tappable.

**`AppBackground`** — wraps every page's `Scaffold` to apply the pink gradient background.

**`FloatingGlassNavBar`** — 5-item bottom nav bar positioned as a floating overlay.

**`DashedRectPainter`** — `CustomPainter` for dashed-border placeholder cards (radius 12 hardcoded).

Typography: **Syne** (headings/titles, `FontWeight.w700–w800`) + **DM Sans** (body text). Always applied via `GoogleFonts.syne(...)` / `GoogleFonts.dmSans(...)` directly on `Text` widgets rather than relying on the theme's text styles.

### Bridal Guide

Static content lives in `lib/bridal_guide_content.dart` as top-level `const List<Map<String, dynamic>>` (yakaModelleri, etekKesimleri, kolModelleri, kumaslar). Detail pages read these lists directly — no service or repository layer. SVG icons in `assets/icons/bridal/`, fabric PNGs in `assets/images/bridal/kumas/`. The shared bottom sheet (`bridal_item_sheet.dart`) accepts a `Widget imageWidget` so callers can pass either `SvgPicture.asset` or `Image.asset`.

### State management

Only `AuthController` is a `ChangeNotifier`. All other pages are `StatefulWidget` with local `setState`. Data is fetched in `initState` / named `_load()` / `_init()` methods and stored as fields on the State.

### Packages in use

`supabase_flutter`, `google_fonts`, `shared_preferences`, `url_launcher`, `image_picker`, `table_calendar`, `intl`, `flutter_svg`, `reicon_flutter`.
