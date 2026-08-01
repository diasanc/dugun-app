import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/prefs/wedding_prefs.dart';
import 'core/services/join_code_service.dart';
import 'core/supabase/supabase_init.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/glass_card.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/bridal_guide/presentation/pages/bridal_guide_page.dart';
import 'features/budget/presentation/pages/budget_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/moodboard/presentation/pages/moodboard_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/timeline/presentation/controllers/timeline_controller.dart';
import 'features/timeline/presentation/pages/timeline_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await SupabaseInit.init();
  runApp(const WeddingApp());
}

class WeddingApp extends StatefulWidget {
  const WeddingApp({super.key});

  @override
  State<WeddingApp> createState() => _WeddingAppState();
}

class _WeddingAppState extends State<WeddingApp> {
  late final AuthController _authController;
  bool _onboardingDone = false;
  bool _checkingOnboarding = true;

  @override
  void initState() {
    super.initState();
    final datasource = AuthRemoteDatasourceImpl();
    final repository = AuthRepositoryImpl(datasource);
    _authController = AuthController(
      signIn: SignInUseCase(repository),
      signUp: SignUpUseCase(repository),
      signOut: SignOutUseCase(repository),
      getCurrentUser: GetCurrentUserUseCase(repository),
    );
    _checkOnboarding();
    _authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authController.status == AuthStatus.authenticated) {
      _processPendingJoinCode();
    }
  }

  Future<void> _processPendingJoinCode() async {
    final code = JoinCodeService.consumePendingCode();
    if (code == null) return;
    final userId = _authController.user?.id;
    if (userId == null) return;
    try {
      await JoinCodeService().joinByCode(code, userId);
    } catch (_) {
      // Sessizce devam et; kullanıcı dashboard'da
    }
  }

  Future<void> _checkOnboarding() async {
    final done = await WeddingPrefs.isOnboardingDone();
    if (mounted) {
      setState(() {
        _onboardingDone = done;
        _checkingOnboarding = false;
      });
    }
  }

  Future<void> _resetOnboarding() async {
    await WeddingPrefs.resetOnboarding();
    await _authController.signOut();
    if (mounted) setState(() => _onboardingDone = false);
  }

  void _goBackToOnboarding() {
    if (mounted) setState(() => _onboardingDone = false);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Düğün Planlayıcı',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // home her zaman _AppShell tipinde kalır; Flutter Navigator rotayı
      // yeniden oluşturmaz, sadece _AppShell.build() yeniden çalışır.
      home: _AppShell(
        checkingOnboarding: _checkingOnboarding,
        onboardingDone: _onboardingDone,
        authController: _authController,
        onOnboardingComplete: () {
          if (mounted) setState(() => _onboardingDone = true);
        },
        onResetOnboarding: _resetOnboarding,
        onBackToOnboarding: _goBackToOnboarding,
      ),
    );
  }
}

// _AppShell daima aynı tip widget olarak home'a verilir.
// İçerik, parametre değişimlerine göre _AppShell.build() içinde güncellenir.
class _AppShell extends StatelessWidget {
  final bool checkingOnboarding;
  final bool onboardingDone;
  final AuthController authController;
  final VoidCallback onOnboardingComplete;
  final VoidCallback onResetOnboarding;
  final VoidCallback onBackToOnboarding;

  const _AppShell({
    required this.checkingOnboarding,
    required this.onboardingDone,
    required this.authController,
    required this.onOnboardingComplete,
    required this.onResetOnboarding,
    required this.onBackToOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return _buildChild();
  }

  Widget _buildChild() {
    if (checkingOnboarding) {
      return const _SplashScreen(key: ValueKey('splash'));
    }

    if (!onboardingDone) {
      return OnboardingPage(
        key: const ValueKey('onboarding'),
        onComplete: onOnboardingComplete,
      );
    }

    return ListenableBuilder(
      key: const ValueKey('auth'),
      listenable: authController,
      builder: (context, _) {
        return switch (authController.status) {
          AuthStatus.authenticated => MainShell(
              key: const ValueKey('shell'),
              authController: authController,
              onResetOnboarding: onResetOnboarding,
            ),
          _ => LoginPage(
              key: const ValueKey('login'),
              controller: authController,
              onBackToOnboarding: onBackToOnboarding,
            ),
        };
      },
    );
  }
}

// ── Ana kabuk: IndexedStack + tek FloatingGlassNavBar ─────────────────────
class MainShell extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onResetOnboarding;

  const MainShell({
    super.key,
    required this.authController,
    required this.onResetOnboarding,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final TimelineController _timelineController;

  @override
  void initState() {
    super.initState();
    final userId = widget.authController.user?.id ?? '';
    _timelineController = TimelineController(userId: userId);
    _timelineController.load();
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.authController.user?.id ?? '';
    return SizedBox.expand(
      child: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              DashboardPage(
                authController: widget.authController,
                onResetOnboarding: widget.onResetOnboarding,
                onNavTap: _onNavTap,
                isActive: _currentIndex == 0,
                timelineController: _timelineController,
              ),
              TimelinePage(userId: userId, timelineController: _timelineController),
              BudgetPage(userId: userId),
              MoodboardPage(userId: userId),
              BridalGuidePage(userId: userId),
            ],
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: FloatingGlassNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Text(
          'LIERA',
          style: GoogleFonts.syne(
            color: AppTheme.primary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
          ),
        ),
      ),
    );
  }
}
