import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_category_ext.dart';
import '../../data/models/timeline_task.dart';
import '../../data/services/timeline_service.dart';

class SamplePlanSheet extends StatefulWidget {
  const SamplePlanSheet({
    super.key,
    required this.weddingId,
    required this.weddingDate,
  });

  final String weddingId;
  final DateTime weddingDate;

  static Future<bool?> show(
    BuildContext context, {
    required String weddingId,
    required DateTime weddingDate,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SamplePlanSheet(
        weddingId: weddingId,
        weddingDate: weddingDate,
      ),
    );
  }

  @override
  State<SamplePlanSheet> createState() => _SamplePlanSheetState();
}

class _SamplePlanSheetState extends State<SamplePlanSheet> {
  final Set<int> _added = {};
  final Set<int> _loadingSet = {};
  bool _anyAdded = false;
  TaskCategory? _selectedCategory;

  Future<void> _addTask(int index) async {
    if (_added.contains(index) || _loadingSet.contains(index)) return;
    setState(() => _loadingSet.add(index));

    final item = TimelineService.sampleItems[index];
    final due = widget.weddingDate.subtract(Duration(days: item.daysBefore));

    try {
      await TimelineService().create(
        TimelineTask(
          id: '',
          weddingId: widget.weddingId,
          title: item.title,
          category: TaskCategory.fromWire(item.category),
          dueDate: due,
          isTemplate: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) {
        setState(() {
          _added.add(index);
          _loadingSet.remove(index);
          _anyAdded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSet.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    const periodOrder = [
      '12 Ay Önce',
      '9 Ay Önce',
      '6 Ay Önce',
      '3 Ay Önce',
      '1 Ay Önce',
      '1 Hafta Önce',
    ];

    final grouped = <String, List<int>>{};
    for (var i = 0; i < TimelineService.sampleItems.length; i++) {
      final item = TimelineService.sampleItems[i];
      if (_selectedCategory != null &&
          TaskCategory.fromWire(item.category) != _selectedCategory) {
        continue;
      }
      grouped.putIfAbsent(item.period, () => []).add(i);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Örnek Plan',
                        style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'İstediğiniz görevleri planınıza ekleyin',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, _anyAdded),
                  icon: AppIcon(AppIcons.close, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SampleCategoryFilter(
            active: _selectedCategory,
            onSelect: (cat) => setState(() => _selectedCategory = cat),
          ),
          const Divider(height: 1),
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Eşleşen örnek görev yok',
                            style: GoogleFonts.syne(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectedCategory = null),
                            child: Text(
                              'Filtreyi kaldır',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                for (final period in periodOrder)
                  if (grouped.containsKey(period)) ...[
                    _PeriodHeader(period: period),
                    const SizedBox(height: 8),
                    for (final i in grouped[period]!)
                      _SampleTaskRow(
                        title: TimelineService.sampleItems[i].title,
                        category: TimelineService.sampleItems[i].category,
                        isAdded: _added.contains(i),
                        isLoading: _loadingSet.contains(i),
                        onAdd: () => _addTask(i),
                      ),
                    const SizedBox(height: 16),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.period});
  final String period;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          period,
          style: GoogleFonts.syne(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

class _SampleTaskRow extends StatelessWidget {
  const _SampleTaskRow({
    required this.title,
    required this.category,
    required this.isAdded,
    required this.isLoading,
    required this.onAdd,
  });

  final String title;
  final String category;
  final bool isAdded;
  final bool isLoading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cat = TaskCategory.fromWire(category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAdded
            ? AppTheme.primary.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAdded
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.50),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: isAdded ? AppTheme.textMuted : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cat.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cat.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primary),
            )
          else if (isAdded)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child:
                  AppIcon(AppIcons.check, size: 14, color: Colors.white),
            )
          else
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: AppIcon(AppIcons.add, size: 16, color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Örnek Plan kategori filtresi ──────────────────────────────────────────

class _SampleCategoryFilter extends StatelessWidget {
  final TaskCategory? active;
  final ValueChanged<TaskCategory?> onSelect;

  const _SampleCategoryFilter({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        children: [
          _SampleChip(
            label: 'Tümü',
            dot: null,
            selected: active == null,
            onTap: () => onSelect(null),
          ),
          ...TaskCategory.values.map(
            (cat) => _SampleChip(
              label: cat.label,
              dot: cat.color,
              selected: active == cat,
              onTap: () => onSelect(active == cat ? null : cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  final String label;
  final Color? dot;
  final bool selected;
  final VoidCallback onTap;

  const _SampleChip({
    required this.label,
    required this.dot,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null && !selected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
