import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/wedding_service.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import '../../data/models/expense.dart';
import '../../data/services/expense_service.dart';
import '../expense_category_ext.dart';
import '../widgets/add_expense_sheet.dart';

// Binlik nokta formatlayıcı: 1250000 → "1.250.000 ₺"
String _fmt(double amount) {
  if (!amount.isFinite) return '—';
  final s = amount.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf.toString()} ₺';
}

class BudgetPage extends StatefulWidget {
  final String userId;

  const BudgetPage({super.key, required this.userId});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _weddingService = WeddingService();
  final _expenseService = ExpenseService();

  String? _weddingId;
  double? _totalBudget;
  List<Expense> _expenses = [];
  bool _loading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final wedding =
          await _weddingService.getOrCreateWedding(widget.userId);
      final expenses = await _expenseService.fetchByWedding(wedding.id);
      if (mounted) {
        setState(() {
          _weddingId = wedding.id;
          _totalBudget = wedding.totalBudget;
          _expenses = expenses;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('BudgetPage._load error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = 'Veriler yüklenemedi. Lütfen tekrar deneyin.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openAddSheet() async {
    final weddingId = _weddingId;
    if (weddingId == null) return;
    final changed =
        await AddExpenseSheet.show(context, weddingId: weddingId);
    if (changed && mounted) _load();
  }

  Future<void> _editBudget() async {
    final initialText = (_totalBudget != null && _totalBudget!.isFinite)
        ? _totalBudget!.round().toString()
        : '';
    final ctrl = TextEditingController(text: initialText);
    double? result;
    try {
      result = await showDialog<double?>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Toplam Bütçeyi Güncelle',
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            autofocus: true,
            style: GoogleFonts.dmSans(
                fontSize: 16, color: AppTheme.textDark),
            decoration: InputDecoration(
              hintText: 'Örn: 500000',
              hintStyle:
                  GoogleFonts.dmSans(color: AppTheme.textMuted),
              suffixText: '₺',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Vazgeç',
                  style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
            ),
            FilledButton(
              onPressed: () {
                final text = ctrl.text
                    .trim()
                    .replaceAll('.', '')
                    .replaceAll(',', '.');
                final amount = double.tryParse(text);
                Navigator.pop(ctx, amount);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7056C8)),
              child:
                  Text('Güncelle', style: GoogleFonts.dmSans()),
            ),
          ],
        ),
      );
    } finally {
      // Dialog elementi unmount olduktan sonra dispose et;
      // erken dispose EditableText cleanup sırasında assertion'a yol açar.
      WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    }
    if (result == null || !mounted) return;
    try {
      await _weddingService.updateTotalBudget(widget.userId, result);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe güncellenemedi')),
        );
      }
    }
  }

  Future<void> _openEditSheet(Expense expense) async {
    final weddingId = _weddingId;
    if (weddingId == null) return;
    final changed = await AddExpenseSheet.show(
      context,
      weddingId: weddingId,
      expense: expense,
    );
    if (changed && mounted) _load();
  }

  /// Optimistic silme: listeyi anında güncelle, arka planda DB'den sil.
  Future<void> _deleteExpense(Expense expense) async {
    setState(() {
      _expenses = List.from(_expenses)
        ..removeWhere((e) => e.id == expense.id);
    });
    try {
      await _expenseService.delete(expense.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silinemedi. Tekrar deneyin.'),
            backgroundColor: Color(0xFFB00020),
          ),
        );
        _load();
      }
    }
  }

  // Sadece ödenen kalemlerin actual_amount toplamı
  double get _totalPaid => _expenses
      .where((e) => e.isPaid)
      .fold(0, (s, e) => s + (e.actualAmount ?? 0));

  double get _totalEstimated =>
      _expenses.fold(0, (s, e) => s + (e.estimatedAmount ?? 0));

  Map<ExpenseCategory, List<Expense>> get _grouped {
    final map = <ExpenseCategory, List<Expense>>{};
    for (final e in _expenses) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Bütçe',
          style: GoogleFonts.syne(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ),
      floatingActionButton: _weddingId != null && !_loading
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton(
                heroTag: 'budget_fab',
                onPressed: _openAddSheet,
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                child: AppIcon(AppIcons.add, size: 26, color: Colors.white),
              ),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary, strokeWidth: 2))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      if (_expenses.isEmpty)
                        _buildEmptyState()
                      else
                        ..._buildCategorySection(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.warning, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _load,
            child: Text('Tekrar Dene',
                style: GoogleFonts.dmSans(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final paid = _totalPaid;
    final budget = _totalBudget;
    final remaining = budget != null ? budget - paid : null;
    final isOver = remaining != null && remaining < 0;
    final progress = budget != null && budget > 0
        ? (paid / budget).clamp(0.0, 1.0)
        : 0.0;

    return GlassCard(
      tint: AppTheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIcon(AppIcons.wallet, size: 22, color: AppTheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Toplam Bütçe',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4A4060),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _editBudget,
                          child: AppIcon(AppIcons.edit, size: 15, color: const Color(0xFF7056C8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget != null ? _fmt(budget) : 'Belirlenmemiş',
                      style: GoogleFonts.syne(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: budget != null
                            ? const Color(0xFF1E1040)
                            : AppTheme.textMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (budget != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation(
                    isOver
                        ? const Color(0xFFB00020)
                        : AppTheme.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOver
                  ? (budget > 0
                      ? 'Bütçe %${((paid / budget - 1) * 100).round()} aşıldı'
                      : 'Bütçe aşıldı')
                  : '${(progress * 100).round()}% ödendi',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: isOver
                    ? const Color(0xFFB00020)
                    : AppTheme.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppTheme.border, height: 1, thickness: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Harcanan',
                  value: paid > 0 ? _fmt(paid) : '—',
                  color: paid > 0
                      ? const Color(0xFFB00020)
                      : AppTheme.textMuted,
                ),
              ),
              if (remaining != null)
                Expanded(
                  child: _StatItem(
                    label: isOver ? 'Aşım' : 'Kalan',
                    value: _fmt(remaining.abs()),
                    color: isOver
                        ? const Color(0xFFB00020)
                        : const Color(0xFF7A9671),
                  ),
                ),
              Expanded(
                child: _StatItem(
                  label: 'Tahmini',
                  value: _totalEstimated > 0
                      ? _fmt(_totalEstimated)
                      : '—',
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            AppIcon(AppIcons.receipt, size: 52, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Henüz gider kalemi yok',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sağ alttaki + butonuyla harcama ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategorySection() {
    final grouped = _grouped;
    final sorted = grouped.entries.toList()
      ..sort((a, b) {
        final aSum = a.value
            .fold<double>(0, (s, e) => s + (e.actualAmount ?? 0));
        final bSum = b.value
            .fold<double>(0, (s, e) => s + (e.actualAmount ?? 0));
        return bSum.compareTo(aSum);
      });

    return [
      Text(
        'KATEGORİLER',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark.withValues(alpha: 0.45),
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 12),
      ...sorted.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CategoryCard(
              category: entry.key,
              expenses: entry.value,
              onExpenseTap: _openEditSheet,
              onExpenseDelete: _deleteExpense,
            ),
          )),
    ];
  }
}

// ── Stat Item ─────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final ExpenseCategory category;
  final List<Expense> expenses;
  final void Function(Expense) onExpenseTap;
  final void Function(Expense) onExpenseDelete;

  const _CategoryCard({
    required this.category,
    required this.expenses,
    required this.onExpenseTap,
    required this.onExpenseDelete,
  });

  @override
  Widget build(BuildContext context) {
    final estimated =
        expenses.fold<double>(0, (s, e) => s + (e.estimatedAmount ?? 0));
    final actual =
        expenses.fold<double>(0, (s, e) => s + (e.actualAmount ?? 0));
    final isOver = estimated > 0 && actual > estimated;
    final progress =
        estimated > 0 ? (actual / estimated).clamp(0.0, 1.0) : 0.0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: AppIcon(category.icon, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                category.label,
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          // Kalem satırları
          const SizedBox(height: 8),
          ...expenses.map((e) => _ExpenseRow(
                expense: e,
                onTap: () => onExpenseTap(e),
                onDelete: () => onExpenseDelete(e),
              )),
          // Özet
          const SizedBox(height: 4),
          const Divider(color: AppTheme.border, height: 1, thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LineItem(
                  label: 'Tahmini',
                  value: estimated > 0 ? _fmt(estimated) : '—',
                  color: AppTheme.textMuted,
                ),
              ),
              Expanded(
                child: _LineItem(
                  label: 'Gerçek',
                  value: actual > 0 ? _fmt(actual) : '—',
                  color: isOver
                      ? const Color(0xFFB00020)
                      : actual > 0
                          ? const Color(0xFF7A9671)
                          : AppTheme.textMuted,
                ),
              ),
            ],
          ),
          if (estimated > 0 || actual > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppTheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation(
                    isOver
                        ? const Color(0xFFB00020)
                        : AppTheme.primary),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

// ── Expense Row ───────────────────────────────────────────────────────────
// Tüm kart kaydırılabilir (Dismissible). Sola kaydırınca kırmızı Sil alanı
// açılır. Tıklayınca düzenleme sheet'i açılır.
// Kalem ikonu Stack+Positioned ile kartın sağ üst köşesine sabitlenmiştir.

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseRow({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final amount = expense.actualAmount ?? expense.estimatedAmount;
    final isEstimated = expense.actualAmount == null && amount != null;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Harcamayı Sil',
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                fontSize: 18,
              ),
            ),
            content: Text(
              '"${expense.title}" silinecek. Emin misiniz?',
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppTheme.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('İptal',
                    style:
                        GoogleFonts.dmSans(color: AppTheme.textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB00020)),
                child: Text('Sil',
                    style:
                        GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
        // Dialog kapandıktan sonra context geçerliyse onay ver
        if (!context.mounted) return false;
        return result == true;
      },
      onDismissed: (_) => onDelete(),
      // Sola kaydırınca sağdan açılan kırmızı silme alanı
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sil',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB00020),
              ),
            ),
            const SizedBox(width: 5),
            AppIcon(AppIcons.trash, color: const Color(0xFFB00020), size: 18),
          ],
        ),
      ),
      // Tüm kart tıklanabilir; kalem ikonu sağ üst köşede
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
                  ),
                  child: Padding(
                    // Sağda kalem ikonu için alan bırakılır
                    padding:
                        const EdgeInsets.fromLTRB(12, 11, 36, 11),
                    child: Row(
                    children: [
                      AppIcon(
                        expense.isPaid
                            ? AppIcons.checkCircle
                            : AppIcons.record,
                        size: 15,
                        color: expense.isPaid
                            ? const Color(0xFF7A9671)
                            : AppTheme.border,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          expense.title,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppTheme.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (amount != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${isEstimated ? "~ " : ""}${_fmt(amount)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isEstimated
                                ? AppTheme.textMuted
                                : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ),
          // Kalem ikonu — sağ üst köşeye sabitlenmiş, dokunuşu InkWell'e aktarır
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: AppIcon(AppIcons.edit, size: 13, color: AppTheme.border),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Line Item ─────────────────────────────────────────────────────────────

class _LineItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LineItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}
