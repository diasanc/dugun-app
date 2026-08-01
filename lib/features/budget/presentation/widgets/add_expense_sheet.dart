import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/expense.dart';
import '../../data/services/expense_service.dart';
import '../expense_category_ext.dart';

class AddExpenseSheet extends StatefulWidget {
  final String weddingId;

  /// Düzenleme modunda mevcut harcama; null ise ekleme modu.
  final Expense? expense;

  const AddExpenseSheet({
    super.key,
    required this.weddingId,
    this.expense,
  });

  /// Returns true if something was saved or deleted.
  static Future<bool> show(
    BuildContext context, {
    required String weddingId,
    Expense? expense,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddExpenseSheet(weddingId: weddingId, expense: expense),
    );
    return result == true;
  }

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _estimatedController = TextEditingController();
  final _actualController = TextEditingController();

  late ExpenseCategory _category;
  late bool _isPaid;
  bool _saving = false;
  bool _categoryExpanded = false;
  String? _error;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _titleController.text = e.title;
      _category = e.category;
      if (e.estimatedAmount != null) {
        _estimatedController.text = e.estimatedAmount!.round().toString();
      }
      if (e.actualAmount != null) {
        _actualController.text = e.actualAmount!.round().toString();
      }
      _isPaid = e.isPaid;
    } else {
      _category = ExpenseCategory.other;
      _isPaid = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _estimatedController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_isEditing) {
        final updated = Expense(
          id: widget.expense!.id,
          weddingId: widget.expense!.weddingId,
          title: _titleController.text.trim(),
          category: _category,
          estimatedAmount: _parseAmount(_estimatedController.text),
          actualAmount: _parseAmount(_actualController.text),
          isPaid: _isPaid,
          dueDate: widget.expense!.dueDate,
          notes: widget.expense!.notes,
          createdAt: widget.expense!.createdAt,
          updatedAt: DateTime.now(),
        );
        await ExpenseService().update(updated);
      } else {
        final expense = Expense(
          id: '',
          weddingId: widget.weddingId,
          title: _titleController.text.trim(),
          category: _category,
          estimatedAmount: _parseAmount(_estimatedController.text),
          actualAmount: _parseAmount(_actualController.text),
          isPaid: _isPaid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ExpenseService().create(expense);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Kaydedilemedi. Lütfen tekrar deneyin.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Harcamayı Sil',
          style: GoogleFonts.syne(
              fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
        content: Text(
          '"${widget.expense!.title}" silinecek. Emin misiniz?',
          style:
              GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB00020)),
            child: Text('Sil',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ExpenseService().delete(widget.expense!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Silinemedi. Lütfen tekrar deneyin.';
        });
      }
    }
  }

  /// "1.250.000" → 1250000.0  |  "1,5" → 1.5
  static double? _parseAmount(String text) {
    final cleaned =
        text.trim().replaceAll('.', '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5E6EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 32),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Harcamayı Düzenle' : 'Harcama Ekle',
                      style: GoogleFonts.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        icon: AppIcon(AppIcons.trash, color: const Color(0xFFB00020), size: 22),
                        tooltip: 'Sil',
                        onPressed: _saving ? null : _delete,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Başlık ────────────────────────────────────────────────
              _Label('Başlık'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppTheme.textDark),
                decoration: _dec('Örn: Mekan depozitosu'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Başlık gerekli'
                    : null,
              ),
              const SizedBox(height: 22),

              // ── Kategori ──────────────────────────────────────────────
              _CategoryPicker(
                selected: _category,
                expanded: _categoryExpanded,
                onToggle: () =>
                    setState(() => _categoryExpanded = !_categoryExpanded),
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 22),

              // ── Tutarlar ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Tahmini Tutar (₺)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _estimatedController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]')),
                          ],
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppTheme.textDark),
                          decoration: _dec('0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Gerçek Tutar (₺)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _actualController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]')),
                          ],
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _saving ? null : _save,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppTheme.textDark),
                          decoration: _dec('0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Ödendi ────────────────────────────────────────────────
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v ?? false),
                  title: Text(
                    'Ödendi',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  activeColor: AppTheme.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: GoogleFonts.dmSans(
                      color: const Color(0xFFB00020), fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),

              // ── Kaydet / Güncelle ──────────────────────────────────────
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary),
                      )
                    : Text(
                        _isEditing ? 'Güncelle' : 'Kaydet',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textMuted),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.90),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFB00020), width: 1.5),
        ),
      );
}

// ── Yardımcı widget'lar ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
        ),
      );
}

class _CategoryPicker extends StatelessWidget {
  final ExpenseCategory selected;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<ExpenseCategory> onChanged;

  const _CategoryPicker({
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: selected.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Kategori: ${selected.label}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: AppIcon(AppIcons.chevronDown, size: 18, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = cat == selected;
                  return GestureDetector(
                    onTap: () => onChanged(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: 0.15)
                            : AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? cat.color
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        cat.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? cat.color
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
        ),
      ),
    );
  }
}
