import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/prefs/wedding_prefs.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/services/wedding_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../budget/data/services/expense_service.dart';
import '../../../guests/data/services/guest_service.dart';
import '../../../guests/presentation/pages/guests_page.dart';
import '../../../moodboard/data/models/moodboard_item.dart';
import '../../../moodboard/data/services/moodboard_service.dart';
import '../../../timeline/data/models/timeline_task.dart';
import '../../../timeline/presentation/controllers/timeline_controller.dart';
import '../../../timeline/presentation/widgets/add_task_sheet.dart';
import '../widgets/invite_sheet.dart';

String _fmtAmount(double amount) {
  final s = amount.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()} ₺';
}

class DashboardPage extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onResetOnboarding;
  final void Function(int) onNavTap;
  final bool isActive;
  final TimelineController timelineController;

  const DashboardPage({
    super.key,
    required this.authController,
    required this.onResetOnboarding,
    required this.onNavTap,
    required this.timelineController,
    this.isActive = true,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _weddingDate;
  String? _weddingTitle;
  String? _brideName;
  String? _groomName;
  double _totalPaid = 0;
  double? _totalBudget;
  int _totalGuests = 0;
  List<MoodboardItem> _moodboardItems = [];

  @override
  void initState() {
    super.initState();
    _loadWeddingDate();
    _loadBrideInfo();
    _loadBudget();
    _loadGuests();
    _loadMoodboard();
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      widget.timelineController.silentRefresh();
      _loadBudget();
      _loadGuests();
      _loadMoodboard();
    }
  }

  Future<void> _loadWeddingDate() async {
    final date = await WeddingPrefs.getWeddingDate();
    if (date != null && mounted) setState(() => _weddingDate = date);
  }

  Future<void> _loadBrideInfo() async {
    final title = await WeddingPrefs.getWeddingTitle();
    final bride = await WeddingPrefs.getBrideName();
    final groom = await WeddingPrefs.getGroomName();
    if (mounted) setState(() {
      _weddingTitle = title;
      _brideName = bride;
      _groomName = groom;
    });
  }

  Future<void> _loadBudget() async {
    final userId = widget.authController.user?.id;
    if (userId == null) return;
    try {
      final wedding = await WeddingService().getOrCreateWedding(userId);
      final expenses = await ExpenseService().fetchByWedding(wedding.id);
      final paid = expenses
          .where((e) => e.isPaid)
          .fold<double>(0, (s, e) => s + (e.actualAmount ?? 0));
      if (mounted) {
        setState(() {
          _totalBudget = wedding.totalBudget;
          _totalPaid = paid;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadGuests() async {
    final userId = widget.authController.user?.id;
    if (userId == null) return;
    try {
      final wedding = await WeddingService().getOrCreateWedding(userId);
      final guests = await GuestService().fetchByWedding(wedding.id);
      if (mounted) {
        setState(() {
          _totalGuests = guests.length;
        });
      }
    } catch (_) {}
  }


  Future<void> _loadMoodboard() async {
    final userId = widget.authController.user?.id;
    if (userId == null) return;
    try {
      final wedding = await WeddingService().getOrCreateWedding(userId);
      final items = await MoodboardService().fetchByWedding(wedding.id);
      if (mounted) setState(() => _moodboardItems = items);
    } catch (_) {}
  }


  Future<void> _openEditSheet(TimelineTask task) async {
    final userId = widget.authController.user?.id ?? '';
    final result = await AddTaskSheet.show(
      context,
      userId: userId,
      existingTask: task,
    );
    if (result == true) await widget.timelineController.silentRefresh();
  }

  Future<void> _pickWeddingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _weddingDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
      helpText: 'Düğün Tarihini Seçin',
      confirmText: 'Kaydet',
      cancelText: 'Vazgeç',
    );
    if (picked != null) {
      setState(() => _weddingDate = picked);
      await WeddingPrefs.saveOnboardingData(weddingDate: picked);
    }
  }

  void _goToBridalGuide() => widget.onNavTap(4);

  void _goToMoodboard() => widget.onNavTap(3);

  void _goToBudget() => widget.onNavTap(2);

  void _goToGuests() {
    final userId = widget.authController.user?.id;
    if (userId == null) return;
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => GuestsPage(userId: userId)))
        .then((_) => _loadGuests());
  }

  void _goToTimeline() => widget.onNavTap(1);

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(
                  weddingTitle: _weddingTitle,
                  brideName: _brideName,
                  groomName: _groomName,
                  onInvite: () {
                    final userId = widget.authController.user?.id;
                    if (userId != null) InviteSheet.show(context, userId);
                  },
                  onReset: widget.onResetOnboarding,
                  onSignOut: widget.authController.signOut,
                ),
                const SizedBox(height: 32),
                _CountdownCard(
                  weddingDate: _weddingDate,
                  onSetDate: _pickWeddingDate,
                ),
                const SizedBox(height: 20),
                _QuickAccessGrid(
                  moodboardCount: _moodboardItems.length,
                  totalPaid: _totalPaid,
                  totalBudget: _totalBudget,
                  totalGuests: _totalGuests,
                  onBridalGuide: _goToBridalGuide,
                  onMoodboard: _goToMoodboard,
                  onBudget: _goToBudget,
                  onGuests: _goToGuests,
                ),
                const SizedBox(height: 20),
                ListenableBuilder(
                  listenable: widget.timelineController,
                  builder: (context, _) {
                    final ctrl = widget.timelineController;
                    return _PlanningCalendarCard(
                      totalTasks: ctrl.totalTasks,
                      completedTasks: ctrl.completedTasks,
                      upcomingTasks: ctrl.upcomingTasks,
                      onToggleTask: (t) => ctrl.toggle(t),
                      onEditTask: _openEditSheet,
                      onTap: _goToTimeline,
                      onAddTask: _goToTimeline,
                    );
                  },
                ),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final String? weddingTitle;
  final String? brideName;
  final String? groomName;
  final VoidCallback onInvite;
  final VoidCallback onReset;
  final VoidCallback onSignOut;

  const _HeaderSection({
    this.weddingTitle,
    this.brideName,
    this.groomName,
    required this.onInvite,
    required this.onReset,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LIERA',
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary.withValues(alpha: 0.55),
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 2),
              if (brideName != null && groomName != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        brideName!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.syne(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AppIcon(
                        AppIcons.heartLock,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        groomName!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.syne(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  weddingTitle ?? 'Düğününüz',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: weddingTitle != null
                        ? AppTheme.primary
                        : AppTheme.primary.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                    height: 1.15,
                  ),
                ),
            ],
          ),
        ),
        PopupMenuButton<int>(
          onSelected: (v) {
            if (v == 0) onInvite();
            if (v == 1) onReset();
            if (v == 2) onSignOut();
          },
          color: const Color(0xFFF5E6EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          icon: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.50),
              border: Border.all(color: Colors.white.withValues(alpha: 0.60)),
            ),
            child: AppIcon(AppIcons.moreH, size: 18, color: AppTheme.primary),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 0,
              child: Row(children: [
                AppIcon(AppIcons.userAdd, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 10),
                Text('Davet Et', style: GoogleFonts.syne(fontSize: 13)),
              ]),
            ),
            PopupMenuItem(
              value: 1,
              child: Row(children: [
                AppIcon(AppIcons.restart, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 10),
                Text('Onboarding\'i Sıfırla',
                    style: GoogleFonts.syne(fontSize: 13)),
              ]),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(children: [
                AppIcon(AppIcons.logout, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 10),
                Text('Çıkış Yap', style: GoogleFonts.syne(fontSize: 13)),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Geri Sayım ────────────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  final DateTime? weddingDate;
  final VoidCallback onSetDate;

  const _CountdownCard({required this.weddingDate, required this.onSetDate});

  int get _daysLeft {
    if (weddingDate == null) return -1;
    final today = DateTime.now();
    return weddingDate!
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysLeft;
    final hasDate = weddingDate != null;

    return GlassCard(
      onTap: onSetDate,
      tint: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: hasDate ? _dateContent(days) : _emptyContent(),
      ),
    );
  }

  Widget _dateContent(int days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              days == 0 ? 'Bugün!' : '$days',
              style: GoogleFonts.syne(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                height: 1,
              ),
            ),
            if (days != 0)
              Text(
                days < 0 ? 'gün geçti' : 'gün kaldı',
                style: GoogleFonts.syne(
                  fontSize: 14,
                  color: AppTheme.textDark.withValues(alpha: 0.55),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.heartFilled, size: 20, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(
              _formatDate(weddingDate!),
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark.withValues(alpha: 0.75),
              ),
            ),
            Text(
              'Değiştir',
              style: GoogleFonts.syne(
                fontSize: 11,
                color: AppTheme.primary.withValues(alpha: 0.75),
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emptyContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geri Sayım',
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Düğün tarihinizi belirleyin',
              style: GoogleFonts.syne(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              AppIcon(AppIcons.calendar, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Tarih Seç',
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Hızlı Erişim Grid ─────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  final int moodboardCount;
  final double totalPaid;
  final double? totalBudget;
  final int totalGuests;
  final VoidCallback onBridalGuide;
  final VoidCallback onMoodboard;
  final VoidCallback onBudget;
  final VoidCallback onGuests;

  const _QuickAccessGrid({
    required this.moodboardCount,
    required this.totalPaid,
    this.totalBudget,
    required this.totalGuests,
    required this.onBridalGuide,
    required this.onMoodboard,
    required this.onBudget,
    required this.onGuests,
  });

  String _budgetSubtitle() {
    if (totalBudget == null) return 'Bütçe belirlenmedi';
    return '${_fmtAmount(totalPaid)} / ${_fmtAmount(totalBudget!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickCard(
                  icon: AppIcons.hanger,
                  title: 'Gelinlik\nRehberi',
                  subtitle: 'Kesim, yaka & kumaş',
                  onTap: onBridalGuide,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  icon: AppIcons.imageSparkle,
                  title: 'İlham\nPanosu',
                  subtitle: moodboardCount == 0
                      ? 'Henüz öğe yok'
                      : '$moodboardCount öğe',
                  onTap: onMoodboard,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickCard(
                  icon: AppIcons.wallet,
                  title: 'Bütçe',
                  subtitle: _budgetSubtitle(),
                  onTap: onBudget,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  icon: AppIcons.people,
                  title: 'Davetliler',
                  subtitle: totalGuests == 0
                      ? 'Henüz davetli yok'
                      : '$totalGuests davetli',
                  onTap: onGuests,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 22, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.syne(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.syne(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Planlama Takvimi ──────────────────────────────────────────────────────

class _PlanningCalendarCard extends StatelessWidget {
  final int totalTasks;
  final int completedTasks;
  final List<TimelineTask> upcomingTasks;
  final ValueChanged<TimelineTask>? onToggleTask;
  final ValueChanged<TimelineTask>? onEditTask;
  final VoidCallback? onTap;
  final VoidCallback? onAddTask;

  const _PlanningCalendarCard({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.upcomingTasks = const [],
    this.onToggleTask,
    this.onEditTask,
    this.onTap,
    this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = totalTasks > 0 && completedTasks == totalTasks;
    final remaining = totalTasks - completedTasks;

    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcons.calendar, size: 20,
                        color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Planlama Takvimi',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                if (totalTasks > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: allDone
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedTasks/$totalTasks',
                      style: GoogleFonts.syne(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (totalTasks == 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Henüz görev eklenmedi.',
                    style: GoogleFonts.syne(
                        fontSize: 13, color: AppTheme.textMuted),
                  ),
                  GestureDetector(
                    onTap: onAddTask,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(AppIcons.add,
                              size: 13, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Görev ekle',
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 20),
              if (allDone)
                Row(
                  children: [
                    AppIcon(AppIcons.checkCircle,
                        size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Tüm görevler tamamlandı!',
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else ...[
                for (final task in upcomingTasks)
                  _TaskRow(
                    task: task,
                    onToggle: onToggleTask != null
                        ? () => onToggleTask!(task)
                        : null,
                    onEdit: onEditTask != null
                        ? () => onEditTask!(task)
                        : null,
                  ),
                if (remaining > upcomingTasks.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${remaining - upcomingTasks.length} görev daha',
                      style: GoogleFonts.syne(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TimelineTask task;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;

  const _TaskRow({required this.task, this.onToggle, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted
                          ? AppTheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                    child: task.isCompleted
                        ? AppIcon(AppIcons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.taskTitleStyle(
                      completed: task.isCompleted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
