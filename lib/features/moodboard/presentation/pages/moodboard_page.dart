import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/wedding_service.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import '../../data/models/moodboard_item.dart';
import '../../data/services/moodboard_service.dart';
import '../widgets/add_moodboard_item_sheet.dart';

class MoodboardPage extends StatefulWidget {
  const MoodboardPage({super.key, required this.userId});

  final String userId;

  @override
  State<MoodboardPage> createState() => _MoodboardPageState();
}

class _MoodboardPageState extends State<MoodboardPage> {
  List<MoodboardItem> _items = [];
  bool _loading = true;
  String _activeCategory = 'Tümü';

  final _searchNotifier = ValueNotifier<String>('');

  bool _selectionMode = false;
  bool _reorderMode = false;

  final _selectedIdsNotifier = ValueNotifier<Set<String>>({});

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchNotifier.dispose();
    _selectedIdsNotifier.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final wedding = await WeddingService().getOrCreateWedding(widget.userId);
      final items = await MoodboardService().fetchByWedding(wedding.id);
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addItem() async {
    final result = await AddMoodboardItemSheet.show(
      context,
      userId: widget.userId,
      initialSortOrder: _items.length,
    );
    if (result == true) await _load();
  }

  Future<void> _editItem(MoodboardItem item) async {
    final result = await AddMoodboardItemSheet.show(
      context, userId: widget.userId, item: item,
    );
    if (result == true) await _load();
  }

  Future<void> _deleteItem(MoodboardItem item) async {
    setState(() => _items.removeWhere((i) => i.id == item.id));
    try {
      final service = MoodboardService();
      await service.delete(item.id);
      if (item.type == MoodboardItemType.photo) await service.deletePhoto(item.content);
    } catch (_) { await _load(); }
  }

  Future<void> _deleteSelected() async {
    final selectedIds = _selectedIdsNotifier.value;
    final toDelete = _items.where((i) => selectedIds.contains(i.id)).toList();
    setState(() {
      _items.removeWhere((i) => selectedIds.contains(i.id));
      _selectionMode = false;
    });
    _selectedIdsNotifier.value = const {};
    final service = MoodboardService();
    for (final item in toDelete) {
      await service.delete(item.id);
      if (item.type == MoodboardItemType.photo) await service.deletePhoto(item.content);
    }
  }

  void _enterSelectionMode() {
    _selectedIdsNotifier.value = const {};
    setState(() => _selectionMode = true);
  }

  void _exitSelectionMode() {
    _selectedIdsNotifier.value = const {};
    setState(() => _selectionMode = false);
  }

  void _toggleSelection(String id) {
    final current = Set<String>.from(_selectedIdsNotifier.value);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    _selectedIdsNotifier.value = current;
  }

  void _enterReorderMode() => setState(() => _reorderMode = true);

  Future<void> _exitReorderMode() async {
    setState(() => _reorderMode = false);
    try {
      await MoodboardService().updateOrders(_items);
    } catch (_) {}
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  List<MoodboardItem> _filteredWith(String search) {
    return _items.where((item) {
      final matchCat = _activeCategory == 'Tümü' ||
          (item.category ?? 'Diğer') == _activeCategory;
      final q = search.toLowerCase();
      final matchSearch = q.isEmpty ||
          (item.title?.toLowerCase().contains(q) ?? false) ||
          item.content.toLowerCase().contains(q) ||
          (item.notes?.toLowerCase().contains(q) ?? false);
      return matchCat && matchSearch;
    }).toList();
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
          iconTheme: const IconThemeData(color: AppTheme.textDark),
          leading: _selectionMode
              ? IconButton(
                  icon: AppIcon(AppIcons.close),
                  onPressed: _exitSelectionMode,
                )
              : null,
          title: _selectionMode
              ? ValueListenableBuilder<Set<String>>(
                  valueListenable: _selectedIdsNotifier,
                  builder: (context, ids, _) => Text(
                    ids.isEmpty ? 'Seç' : '${ids.length} seçildi',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                )
              : Text(
                  'İlham Panosu',
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
          actions: _selectionMode
              ? [
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: _selectedIdsNotifier,
                    builder: (context, ids, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (ids.length == 1)
                          IconButton(
                            icon: AppIcon(AppIcons.edit, color: AppTheme.primary),
                            tooltip: 'Düzenle',
                            onPressed: () {
                              final item = _items.firstWhere((i) => i.id == ids.first);
                              _exitSelectionMode();
                              _editItem(item);
                            },
                          ),
                        if (ids.isNotEmpty)
                          IconButton(
                            icon: AppIcon(AppIcons.trash, color: const Color(0xFFB00020)),
                            tooltip: 'Sil',
                            onPressed: _deleteSelected,
                          ),
                      ],
                    ),
                  ),
                ]
              : _reorderMode
                  ? [
                      TextButton(
                        onPressed: _exitReorderMode,
                        child: Text(
                          'Bitti',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ]
                  : [
                      if (_items.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.swap_vert_rounded),
                          tooltip: 'Sırala',
                          onPressed: _enterReorderMode,
                        ),
                      IconButton(
                        icon: AppIcon(AppIcons.checklist),
                        tooltip: 'Seç',
                        onPressed: _enterSelectionMode,
                      ),
                    ],
        ),
        floatingActionButton: (_selectionMode || _reorderMode)
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: FloatingActionButton(
                  heroTag: 'moodboard_fab',
                  onPressed: _addItem,
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: AppIcon(AppIcons.add, size: 26, color: Colors.white),
                ),
              ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : _reorderMode
                ? _ReorderBody(
                    items: _items,
                    onReorder: _onReorder,
                  )
                : Column(
                    children: [
                      if (!_selectionMode) ...[
                        _SearchBar(searchNotifier: _searchNotifier),
                        _CategoryFilter(
                          active: _activeCategory,
                          onSelect: (c) => setState(() => _activeCategory = c),
                        ),
                      ],
                      Expanded(
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_searchNotifier, _selectedIdsNotifier]),
                          builder: (context, _) {
                            final search = _searchNotifier.value;
                            final selectedIds = _selectedIdsNotifier.value;
                            final filtered = _filteredWith(search);

                            if (filtered.isEmpty) {
                              return _EmptyState(onAdd: _addItem);
                            }

                            final left = <MoodboardItem>[];
                            final right = <MoodboardItem>[];
                            for (var i = 0; i < filtered.length; i++) {
                              (i.isEven ? left : right).add(filtered[i]);
                            }

                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: left.map((item) => _ItemCard(
                                        item: item,
                                        selectionMode: _selectionMode,
                                        selected: selectedIds.contains(item.id),
                                        onTap: _selectionMode
                                            ? () => _toggleSelection(item.id)
                                            : () => _editItem(item),
                                        onDelete: () => _deleteItem(item),
                                      )).toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      children: right.map((item) => _ItemCard(
                                        item: item,
                                        selectionMode: _selectionMode,
                                        selected: selectedIds.contains(item.id),
                                        onTap: _selectionMode
                                            ? () => _toggleSelection(item.id)
                                            : () => _editItem(item),
                                        onDelete: () => _deleteItem(item),
                                      )).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ── Sıralama modu gövdesi ──────────────────────────────────────────────────

class _ReorderBody extends StatelessWidget {
  const _ReorderBody({required this.items, required this.onReorder});

  final List<MoodboardItem> items;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                'Basılı tut ve sürükle',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
            itemCount: items.length,
            onReorderItem: onReorder,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) => _ReorderCard(
              key: ValueKey(items[index].id),
              item: items[index],
              index: index,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sıralama kartı ────────────────────────────────────────────────────────

class _ReorderCard extends StatelessWidget {
  const _ReorderCard({required super.key, required this.item, required this.index});

  final MoodboardItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Container(
        height: 68,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SizedBox(
                width: 68,
                height: 68,
                child: _leading(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? _defaultTitle(),
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.category!,
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Icon(Icons.drag_handle_rounded, color: AppTheme.textMuted, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leading() {
    switch (item.type) {
      case MoodboardItemType.photo:
        return CachedNetworkImage(
          imageUrl: item.content,
          fit: BoxFit.cover,
          width: 68,
          height: 68,
          placeholder: (context, url) => Container(color: const Color(0xFFFFF0F3)),
          errorWidget: (context, url, err) => Container(
            color: const Color(0xFFFFF0F3),
            child: const Center(child: Icon(Icons.image_outlined, color: AppTheme.primary, size: 24)),
          ),
        );
      case MoodboardItemType.link:
        return Container(
          color: AppTheme.primaryContainer,
          child: Center(child: AppIcon(AppIcons.link, size: 22, color: AppTheme.primary)),
        );
      case MoodboardItemType.note:
        return Container(
          color: AppTheme.primaryContainer,
          child: Center(child: AppIcon(AppIcons.stickyNote, size: 22, color: AppTheme.primary)),
        );
    }
  }

  String _defaultTitle() {
    switch (item.type) {
      case MoodboardItemType.photo: return 'Fotoğraf';
      case MoodboardItemType.link: return item.content;
      case MoodboardItemType.note: return item.content;
    }
  }
}

// ── Arama çubuğu ──────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueNotifier<String> searchNotifier;

  const _SearchBar({required this.searchNotifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => searchNotifier.value = v,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textDark),
          decoration: InputDecoration(
            hintText: 'Ara...',
            hintStyle: GoogleFonts.dmSans(
                fontSize: 14, color: AppTheme.textMuted),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: AppIcon(AppIcons.search, size: 16, color: AppTheme.textMuted),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// ── Kategori filtresi ─────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final String active;
  final ValueChanged<String> onSelect;

  const _CategoryFilter({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        itemCount: kMoodboardCategories.length,
        separatorBuilder: (_, idx) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = kMoodboardCategories[i];
          final sel = active == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                cat,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Kart ──────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final MoodboardItem item;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  static const _cardHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: _cardHeight,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(color: AppTheme.primary, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(selected ? 12 : 14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AbsorbPointer(absorbing: selectionMode, child: _content()),
              if (selectionMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.85),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? AppIcon(AppIcons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (item.type) {
      case MoodboardItemType.photo:
        return _PhotoContent(item: item);
      case MoodboardItemType.link:
        return _LinkContent(item: item);
      case MoodboardItemType.note:
        return _NoteContent(item: item);
    }
  }
}

// ── Fotoğraf içerik ───────────────────────────────────────────────────────

class _PhotoContent extends StatelessWidget {
  const _PhotoContent({required this.item});
  final MoodboardItem item;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: item.content,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: const Color(0xFFFFF0F3),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary, strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, err) => Container(
        color: const Color(0xFFFFF0F3),
        child: Center(
          child: AppIcon(AppIcons.image, color: const Color(0xFFCEA8DC), size: 30),
        ),
      ),
    );
  }
}

// ── Link içerik ───────────────────────────────────────────────────────────

class _LinkContent extends StatelessWidget {
  const _LinkContent({required this.item});
  final MoodboardItem item;

  Future<void> _open() async {
    final uri = Uri.tryParse(item.content);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEDE8FC).withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0.35),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppIcon(AppIcons.link, size: 15, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title ?? 'Link',
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _open,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AppIcon(AppIcons.exportIcon, size: 14, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.content,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppTheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.notes != null) ...[
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  item.notes!,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (item.category != null) ...[
              const SizedBox(height: 6),
              _CategoryTag(item.category!),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Not içerik (glassmorphism) ────────────────────────────────────────────

class _NoteContent extends StatelessWidget {
  const _NoteContent({required this.item});
  final MoodboardItem item;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.38),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AppIcon(AppIcons.stickyNote, size: 15, color: AppTheme.primary.withValues(alpha: 0.80)),
                ),
                if (item.title != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.title!,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                item.content,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textDark.withValues(alpha: 0.80),
                  height: 1.55,
                ),
                overflow: TextOverflow.fade,
              ),
            ),
            if (item.category != null) ...[
              const SizedBox(height: 8),
              _CategoryTag(item.category!),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Kategori etiketi ──────────────────────────────────────────────────────

class _CategoryTag extends StatelessWidget {
  final String category;

  const _CategoryTag(this.category);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

// ── Boş durum ─────────────────────────────────────────────────────────────

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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: AppIcon(AppIcons.gallery, size: 26, color: AppTheme.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'İlham Panosu Boş',
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fotoğraf, link veya not ekleyerek\ndüğün vizyonunu oluşturmaya başla.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: AppIcon(AppIcons.add, size: 16, color: Colors.white),
              label: Text(
                'İLK ÖĞEYİ EKLE',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
