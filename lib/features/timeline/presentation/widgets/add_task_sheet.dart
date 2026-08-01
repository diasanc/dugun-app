import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/wedding_service.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_category_ext.dart';
import '../../data/models/timeline_task.dart';
import '../../data/services/timeline_service.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({
    super.key,
    required this.userId,
    this.existingTask,
  });

  final String userId;
  final TimelineTask? existingTask;

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    TimelineTask? existingTask,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(userId: userId, existingTask: existingTask),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late TaskCategory _category;
  DateTime? _dueDate;
  bool _loading = false;
  bool _categoryExpanded = false;

  bool get _isEdit => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _notesCtrl = TextEditingController(text: task?.notes ?? '');
    _category = task?.category ?? TaskCategory.organizasyon;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
      helpText: 'Son Tarih',
      confirmText: 'Seç',
      cancelText: 'Vazgeç',
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen görev başlığı girin')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        final task = widget.existingTask!;
        final dueDateCleared = task.dueDate != null && _dueDate == null;
        await TimelineService().update(
          task.id,
          title: _titleCtrl.text.trim(),
          category: _category,
          notes: _notesCtrl.text.trim(),
          dueDate: _dueDate,
          removeDueDate: dueDateCleared,
        );
      } else {
        final wedding = await WeddingService().getOrCreateWedding(widget.userId);
        await TimelineService().create(
          TimelineTask(
            id: '',
            weddingId: wedding.id,
            title: _titleCtrl.text.trim(),
            category: _category,
            dueDate: _dueDate,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            isTemplate: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5E6EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _isEdit ? 'Görevi Düzenle' : 'Yeni Görev',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              autofocus: !_isEdit,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textDark),
              decoration: InputDecoration(
                hintText: 'Görev başlığı',
                hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textMuted),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.90),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textDark),
              decoration: InputDecoration(
                hintText: 'Notlar (opsiyonel)',
                hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textMuted),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.90),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              ),
            ),
            const SizedBox(height: 12),
            _CategoryPicker(
              selected: _category,
              expanded: _categoryExpanded,
              onToggle: () =>
                  setState(() => _categoryExpanded = !_categoryExpanded),
              onSelect: (cat) => setState(() {
                _category = cat;
                _categoryExpanded = false;
              }),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    AppIcon(AppIcons.calendar, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? _formatDate(_dueDate!)
                          : 'Son tarih seç (opsiyonel)',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: _dueDate != null
                            ? AppTheme.textDark
                            : AppTheme.textMuted,
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: AppIcon(AppIcons.close, size: 16, color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary),
                    )
                  : Text(
                      _isEdit ? 'Güncelle' : 'Kaydet',
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
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
  });

  final TaskCategory selected;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<TaskCategory> onSelect;

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: selected.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      selected.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              const Divider(height: 1, indent: 14, endIndent: 14),
              ...TaskCategory.values.map((cat) => InkWell(
                    onTap: () => onSelect(cat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cat.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: cat == selected
                                  ? AppTheme.primary
                                  : AppTheme.textDark,
                              fontWeight: cat == selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (cat == selected) ...[
                            const Spacer(),
                            AppIcon(AppIcons.check,
                                size: 14, color: AppTheme.primary),
                          ],
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
