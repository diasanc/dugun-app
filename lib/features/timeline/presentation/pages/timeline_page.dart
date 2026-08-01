import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/prefs/wedding_prefs.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import '../../data/models/task_category_ext.dart';
import '../../data/models/timeline_task.dart';
import '../controllers/timeline_controller.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/sample_plan_sheet.dart';

enum CompletionFilter { tumu, tamamlanan, tamamlanmayan }

class TimelinePage extends StatefulWidget {
  const TimelinePage({
    super.key,
    required this.userId,
    required this.timelineController,
  });
  final String userId;
  final TimelineController timelineController;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  DateTime _weddingDate = DateTime.now().add(const Duration(days: 365));

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TaskCategory? _selectedCategory;
  CompletionFilter _completionFilter = CompletionFilter.tumu;
  bool _categoryFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadWeddingDate();
  }

  Future<void> _loadWeddingDate() async {
    final date = await WeddingPrefs.getWeddingDate();
    if (date != null && mounted) {
      setState(() => _weddingDate = date);
    }
  }

  Future<void> _editTask(TimelineTask task) async {
    final result = await AddTaskSheet.show(
      context,
      userId: widget.userId,
      existingTask: task,
    );
    if (result == true) await widget.timelineController.silentRefresh();
  }

  Future<void> _addTask() async {
    final result = await AddTaskSheet.show(context, userId: widget.userId);
    if (result == true) await widget.timelineController.silentRefresh();
  }

  Future<void> _showSamplePlan() async {
    final id = widget.timelineController.weddingId;
    if (id == null) return;
    await SamplePlanSheet.show(
      context,
      weddingId: id,
      weddingDate: _weddingDate,
    );
    await widget.timelineController.silentRefresh();
  }

  List<TimelineTask> _tasksForDay(DateTime day) {
    return widget.timelineController.tasks
        .where((t) => t.dueDate != null && isSameDay(t.dueDate!, day))
        .toList();
  }

  List<TimelineTask> _visibleTasks(List<TimelineTask> allTasks) {
    var tasks = _selectedDay == null ? allTasks : _tasksForDay(_selectedDay!);
    if (_selectedCategory != null) {
      tasks = tasks.where((t) => t.category == _selectedCategory).toList();
    }
    if (_completionFilter == CompletionFilter.tamamlanan) {
      tasks = tasks.where((t) => t.isCompleted).toList();
    } else if (_completionFilter == CompletionFilter.tamamlanmayan) {
      tasks = tasks.where((t) => !t.isCompleted).toList();
    }
    return tasks;
  }

  List<TimelineTask> _sortedTasks(List<TimelineTask> allTasks) {
    final tasks = List<TimelineTask>.from(_visibleTasks(allTasks));
    tasks.sort((a, b) {
      // due_date'i olmayanlar en üstte, kendi aralarında createdAt DESC
      if (a.dueDate == null && b.dueDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.dueDate == null) return -1;
      if (b.dueDate == null) return 1;
      // İkisinde de due_date var: en yakın tarih en üstte
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.timelineController,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final ctrl = widget.timelineController;
    final allTasks = ctrl.tasks;
    final sorted = _sortedTasks(allTasks);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Planlama Takvimi',
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.textDark),
          actions: [
            if (!ctrl.loading && ctrl.weddingId != null)
              TextButton(
                onPressed: _showSamplePlan,
                child: Text(
                  'Örnek Plan',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: FloatingActionButton(
            heroTag: 'timeline_fab',
            onPressed: _addTask,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            child: AppIcon(AppIcons.add, color: Colors.white),
          ),
        ),
        body: ctrl.loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _CalendarCard(
                      tasks: allTasks,
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      tasksForDay: _tasksForDay,
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _focusedDay = focused;
                          _selectedDay =
                              isSameDay(_selectedDay, selected) ? null : selected;
                        });
                      },
                      onPageChanged: (day) =>
                          setState(() => _focusedDay = day),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            _selectedDay != null
                                ? _formatDate(_selectedDay!)
                                : 'Görevler',
                            style: GoogleFonts.syne(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (_selectedDay != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDay = null),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Tümünü gör',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CompletionFilterBar(
                      active: _completionFilter,
                      onSelect: (f) =>
                          setState(() => _completionFilter = f),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CollapsibleCategoryFilter(
                      expanded: _categoryFilterExpanded,
                      active: _selectedCategory,
                      onToggleExpanded: () => setState(
                          () => _categoryFilterExpanded = !_categoryFilterExpanded),
                      onSelect: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                  if (allTasks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(onAdd: _addTask),
                    )
                  else if (sorted.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _selectedDay != null &&
                              _selectedCategory == null &&
                              _completionFilter == CompletionFilter.tumu
                          ? _DayEmptyState(
                              onClear: () =>
                                  setState(() => _selectedDay = null))
                          : _FilterEmptyState(
                              onClear: () => setState(() {
                                _selectedDay = null;
                                _selectedCategory = null;
                                _completionFilter = CompletionFilter.tumu;
                              }),
                            ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final task = sorted[i];
                            return _TaskCard(
                              task: task,
                              onToggle: () =>
                                  widget.timelineController.toggle(task),
                              onDelete: () =>
                                  widget.timelineController.delete(task),
                              onEdit: () => _editTask(task),
                            );
                          },
                          childCount: sorted.length,
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
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// ── Takvim kartı ──────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.tasks,
    required this.focusedDay,
    required this.selectedDay,
    required this.tasksForDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final List<TimelineTask> tasks;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<TimelineTask> Function(DateTime) tasksForDay;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.28),
            width: 1.2,
          ),
        ),
        child: TableCalendar<TimelineTask>(
          locale: 'tr_TR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          eventLoader: tasksForDay,
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
          startingDayOfWeek: StartingDayOfWeek.monday,
          daysOfWeekHeight: 28,
          rowHeight: 44,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.syne(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
            leftChevronIcon: AppIcon(AppIcons.chevronLeft, color: AppTheme.primary, size: 20),
            rightChevronIcon: AppIcon(AppIcons.chevronRight, color: AppTheme.primary, size: 20),
            headerPadding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
            weekendStyle: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary.withValues(alpha: 0.6),
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.textDark,
            ),
            weekendTextStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.primary.withValues(alpha: 0.8),
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            todayTextStyle: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            markerDecoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markersMaxCount: 1,
            markerMargin: const EdgeInsets.only(top: 2),
            cellMargin: const EdgeInsets.all(4),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              final colors = events
                  .map((e) => e.category.color)
                  .toSet()
                  .take(3)
                  .toList();
              return Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final color in colors)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Collapsible kategori filtresi ─────────────────────────────────────────

class _CollapsibleCategoryFilter extends StatelessWidget {
  final bool expanded;
  final TaskCategory? active;
  final VoidCallback onToggleExpanded;
  final ValueChanged<TaskCategory?> onSelect;

  const _CollapsibleCategoryFilter({
    required this.expanded,
    required this.active,
    required this.onToggleExpanded,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggleExpanded,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Row(
              children: [
                AppIcon(
                  AppIcons.filterFunnel,
                  size: 14,
                  color: active != null
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  active != null
                      ? 'Kategori: ${active!.label}'
                      : 'Kategoriye göre filtrele',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active != null
                        ? AppTheme.primary
                        : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: AppIcon(
                    AppIcons.chevronDown,
                    size: 14,
                    color: active != null
                        ? AppTheme.primary
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: expanded
              ? _TaskCategoryFilter(active: active, onSelect: onSelect)
              : const SizedBox.shrink(),
        ),
        if (expanded) const SizedBox(height: 4),
      ],
    );
  }
}

// ── Görev kartı ───────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final TimelineTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: AppIcon(AppIcons.trash, color: const Color(0xFFB00020), size: 20),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onToggle,
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task.title,
                            style: AppTheme.taskTitleStyle(
                              completed: task.isCompleted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: task.category.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.category.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: task.category.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (task.notes != null && task.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Text(
                          task.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
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
    );
  }
}

// ── Boş durum — seçili gün ────────────────────────────────────────────────

class _DayEmptyState extends StatelessWidget {
  const _DayEmptyState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.calendarTick, size: 40, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              'Bu güne ait görev yok',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Tüm görevleri göster',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Boş durum — genel ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Henüz görev yok',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ butonuyla görev ekleyin\nveya "Örnek Plan"a göz atın.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 180,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: AppIcon(AppIcons.add, size: 18, color: Colors.white),
                label: const Text('GÖREV EKLE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Boş durum — filtre ────────────────────────────────────────────────────

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Eşleşen görev yok',
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu filtre için görev bulunamadı.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClear,
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
    );
  }
}

// ── Tamamlanma filtre çubuğu ──────────────────────────────────────────────

class _CompletionFilterBar extends StatelessWidget {
  final CompletionFilter active;
  final ValueChanged<CompletionFilter> onSelect;

  const _CompletionFilterBar({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (value: CompletionFilter.tumu, label: 'Tümü'),
      (value: CompletionFilter.tamamlanmayan, label: 'Tamamlanmayan'),
      (value: CompletionFilter.tamamlanan, label: 'Tamamlanan'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: filters.map((f) {
          final sel = active == f.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(
                  active == f.value ? CompletionFilter.tumu : f.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: sel
                          ? AppTheme.primary.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  f.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Kategori filtre çubuğu ────────────────────────────────────────────────

class _TaskCategoryFilter extends StatelessWidget {
  final TaskCategory? active;
  final ValueChanged<TaskCategory?> onSelect;

  const _TaskCategoryFilter({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        children: [
          _CategoryChip(
            label: 'Tümü',
            dot: null,
            selected: active == null,
            onTap: () => onSelect(null),
          ),
          ...TaskCategory.values.map(
            (cat) => _CategoryChip(
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? dot;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null && !selected) ...[
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
