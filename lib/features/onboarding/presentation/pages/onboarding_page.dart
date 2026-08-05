import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/prefs/wedding_prefs.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _totalSteps = 6;
  static const _animDuration = Duration(milliseconds: 350);

  int _step = 0;
  bool _navigating = false;
  final _pageController = PageController();

  DateTime? _weddingDate;
  String? _selectedBudget;
  int _guestCount = 100;
  final _brideNameCtrl = TextEditingController();
  final _groomNameCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _brideNameCtrl.dispose();
    _groomNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_navigating) return;
    if (_step < _totalSteps - 1) {
      _navigating = true;
      setState(() => _step++);
      await _pageController.nextPage(
        duration: _animDuration,
        curve: Curves.easeInOut,
      );
      _navigating = false;
    } else {
      _finish();
    }
  }

  Future<void> _back() async {
    if (_navigating || _step == 0) return;
    _navigating = true;
    setState(() => _step--);
    await _pageController.previousPage(
      duration: _animDuration,
      curve: Curves.easeInOut,
    );
    _navigating = false;
  }

  Future<void> _finish() async {
    await WeddingPrefs.saveOnboardingData(
      weddingDate: _weddingDate,
      budget: _selectedBudget,
      guestCount: _guestCount,
      brideName: _brideNameCtrl.text.trim(),
      groomName: _groomNameCtrl.text.trim(),
    );
    if (!mounted) return;
    widget.onComplete();
  }

  Future<void> _skip() async {
    await WeddingPrefs.saveOnboardingData(
      weddingDate: _weddingDate,
      budget: _selectedBudget,
      guestCount: _guestCount,
      brideName: _brideNameCtrl.text.trim(),
      groomName: _groomNameCtrl.text.trim(),
    );
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildNavRow(),
              const SizedBox(height: 10),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Step1(onNext: _next),
                    _Step2(
                      selectedDate: _weddingDate,
                      onDateSelected: (d) => setState(() => _weddingDate = d),
                      onNext: _next,
                      brideController: _brideNameCtrl,
                      groomController: _groomNameCtrl,
                    ),
                    _Step3(
                      selectedBudget: _selectedBudget,
                      onSelected: (v) => setState(() => _selectedBudget = v),
                      onNext: _next,
                    ),
                    _Step4(
                      count: _guestCount,
                      onCountChanged: (v) =>
                          setState(() => _guestCount = max(0, v)),
                      onFinish: _next,
                    ),
                    _Step5(onNext: _next),
                    _Step6(onFinish: _finish),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (_step > 0)
            GestureDetector(
              onTap: _back,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.30),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.50),
                          width: 1),
                    ),
                    child: AppIcon(AppIcons.arrowLeft,
                        size: 14, color: AppTheme.textDark),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 36),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_totalSteps, (i) {
                  final active = i == _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  );
                }),
              ),
            ),
          ),
          GestureDetector(
            onTap: _skip,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.30),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.50),
                        width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Atla',
                    style: GoogleFonts.dmSans(
                        fontSize: 15, color: AppTheme.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_step + 1) / _totalSteps,
          backgroundColor: Colors.white.withValues(alpha: 0.35),
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          minHeight: 3,
        ),
      ),
    );
  }
}

// ── Ortak Adım Yapısı ─────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onNext;
  final Widget? content;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onNext,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    color: AppTheme.textDark,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF5C5E60),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
                if (content != null) ...[
                  const SizedBox(height: 36),
                  content!,
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              buttonLabel,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Adım 1 — Karşılama ────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final VoidCallback onNext;

  const _Step1({required this.onNext});

  static const _svgPath =
      'assets/images/onboarding/two-interlocking-wedding-rings--one-set-with-a-dia.svg';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Üst blok: başlık + alt yazı ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
          child: Column(
            children: [
              Text(
                'Senin İçin,\nSana Özel',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  color: AppTheme.textDark,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hoş geldin! Düğününün her detayı,\ntek bir yerde, kontrol tamamen sende.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF5C5E60),
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        // ── İllüstrasyon: kalan alanın ortasında ─────────────────────────
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SvgPicture.asset(
                _svgPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // ── Buton: en altta sabit ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'BAŞLA',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Adım 2 — Tarih ───────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onNext;
  final TextEditingController brideController;
  final TextEditingController groomController;

  const _Step2({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onNext,
    required this.brideController,
    required this.groomController,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          selectedDate ?? DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
      helpText: 'Düğün Tarihiniz',
      confirmText: 'Seç',
      cancelText: 'Vazgeç',
    );
    if (picked != null) onDateSelected(picked);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Büyük Gün\nNe Zaman?',
      subtitle: 'Tarihini gir,\ngeri sayım başlasın.',
      buttonLabel: 'DEVAM',
      onNext: onNext,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OnboardingTextField(
            controller: brideController,
            hint: 'Senin adın',
          ),
          const SizedBox(height: 12),
          _OnboardingTextField(
            controller: groomController,
            hint: 'Partnerinin adı',
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pick(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.50),
                        width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Tarih seç'
                              : _formatDate(selectedDate!),
                          style: GoogleFonts.dmSans(
                            color: selectedDate == null
                                ? AppTheme.textMuted
                                : AppTheme.textDark,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      AppIcon(AppIcons.calendar,
                          size: 16,
                          color: AppTheme.textMuted.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glassmorphism text field for onboarding ───────────────────────────────

class _OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _OnboardingTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.50), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.dmSans(color: AppTheme.textDark, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  GoogleFonts.dmSans(color: AppTheme.textMuted, fontSize: 15),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Adım 3 — Bütçe ───────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final String? selectedBudget;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;

  const _Step3({
    required this.selectedBudget,
    required this.onSelected,
    required this.onNext,
  });

  static const _options = [
    '500.000 TL altı',
    '500.000 - 1.000.000 TL',
    '1.000.000 - 2.000.000 TL',
    '2.000.000 TL üzeri',
    'Henüz bilmiyorum',
  ];

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Bütçe\nElinin Altında',
      subtitle: 'Hiçbir kuruşu gözden kaçırma.',
      buttonLabel: 'DEVAM',
      onNext: onNext,
      content: Column(
        children: _options
            .map((option) => _BudgetOption(
                  label: option,
                  selected: selectedBudget == option,
                  onTap: () => onSelected(option),
                ))
            .toList(),
      ),
    );
  }
}

class _BudgetOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BudgetOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.70)
                    : Colors.white.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.80)
                      : Colors.white.withValues(alpha: 0.50),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                  AppIcon(
                    selected ? AppIcons.checkCircle : AppIcons.record,
                    size: 18,
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Adım 4 — Davetli ─────────────────────────────────────────────────────

class _Step4 extends StatefulWidget {
  final int count;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onFinish;

  const _Step4({
    required this.count,
    required this.onCountChanged,
    required this.onFinish,
  });

  @override
  State<_Step4> createState() => _Step4State();
}

class _Step4State extends State<_Step4> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.count}');
  }

  @override
  void didUpdateWidget(_Step4 old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      final cursor = _ctrl.selection;
      _ctrl.text = '${widget.count}';
      // Cursor'ı sona taşı
      _ctrl.selection = cursor.copyWith(
        baseOffset: _ctrl.text.length,
        extentOffset: _ctrl.text.length,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commitText() {
    final parsed = int.tryParse(_ctrl.text.trim());
    if (parsed != null && parsed >= 0) {
      widget.onCountChanged(parsed);
    } else {
      _ctrl.text = '${widget.count}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Misafir\nListen',
      subtitle: 'Kaç kişiyi ağırlamayı\nplanlıyorsun?',
      buttonLabel: 'TAMAMLA',
      onNext: () {
        _commitText();
        widget.onFinish();
      },
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterButton(
                icon: AppIcons.minus,
                onTap: () {
                  _commitText();
                  widget.onCountChanged(max(0, widget.count - 10));
                },
              ),
              const SizedBox(width: 20),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 80,
                    maxWidth: 180,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.50),
                              width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: TextField(
                          controller: _ctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.syne(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                            height: 1,
                          ),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _commitText(),
                          onEditingComplete: _commitText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _CounterButton(
                icon: AppIcons.add,
                onTap: () {
                  _commitText();
                  widget.onCountChanged(widget.count + 10);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'kişi',
            style:
                GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.30),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55), width: 1.5),
            ),
            child: AppIcon(icon, size: 18, color: AppTheme.textDark),
          ),
        ),
      ),
    );
  }
}

// ── Adım 5 — Moodboard ───────────────────────────────────────────────────

class _Step5 extends StatelessWidget {
  final VoidCallback onNext;

  const _Step5({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Hayalini\nGörselleştir',
      subtitle:
          'Beğendiğin fotoğrafları ve notları moodboard\'una ekle,\ndüğün tarzını şimdiden yarat.',
      buttonLabel: 'DEVAM',
      onNext: onNext,
      content: const _PreviewCard(
        assetPath: 'assets/onboarding/moodboard_preview.png',
      ),
    );
  }
}

// ── Adım 6 — Gelinlik Rehberi ────────────────────────────────────────────

class _Step6 extends StatelessWidget {
  final VoidCallback onFinish;

  const _Step6({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Gelinlik\nRehberi',
      subtitle:
          'Yaka, etek, kol ve kumaş seçeneklerini tek tek incele,\ntarzını netleştir.',
      buttonLabel: 'BAŞLAYALIM',
      onNext: onFinish,
      content: const _PreviewCard(
        assetPath: 'assets/onboarding/gelinlik_rehberi_preview.png',
      ),
    );
  }
}

// ── Önizleme Kart ─────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final String assetPath;

  const _PreviewCard({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.85,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
