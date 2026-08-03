import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import '../../data/models/guest.dart';
import '../controllers/guest_list_controller.dart';
import '../widgets/add_guest_sheet.dart';
import '../widgets/rsvp_link_sheet.dart';

class GuestsPage extends StatefulWidget {
  final String userId;

  const GuestsPage({super.key, required this.userId});

  @override
  State<GuestsPage> createState() => _GuestsPageState();
}

class _GuestsPageState extends State<GuestsPage> {
  late final GuestListController _controller;

  RsvpStatus? _filterStatus;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = GuestListController(userId: widget.userId);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Guest> get _filtered {
    var list = _controller.guests;
    if (_filterStatus != null) {
      list = list.where((g) => g.rsvpStatus == _filterStatus).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((g) => g.fullName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  int get _totalAttendingWithCompanions => _controller.guests
      .where((g) => g.rsvpStatus == RsvpStatus.attending)
      .fold(0, (s, g) => s + 1 + g.companionCount);

  Future<void> _openAddSheet() async {
    final weddingId = _controller.weddingId;
    if (weddingId == null) return;
    final result = await AddGuestSheet.show(context, weddingId: weddingId);
    if (result.guest != null) await _controller.addGuest(result.guest!);
  }

  Future<void> _openEditSheet(Guest guest) async {
    final weddingId = _controller.weddingId;
    if (weddingId == null) return;
    final result =
        await AddGuestSheet.show(context, weddingId: weddingId, guest: guest);
    if (result.guest != null) {
      await _controller.updateGuest(result.guest!);
    } else if (result.deletedId != null) {
      await _controller.removeGuest(result.deletedId!);
    }
  }

  Future<void> _deleteGuest(Guest guest) async {
    await _controller.removeGuest(guest.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Davetliler',
            style: GoogleFonts.syne(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          leading: IconButton(
            icon: AppIcon(AppIcons.arrowLeft, size: 18, color: AppTheme.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_controller.weddingId != null && !_controller.loading)
              IconButton(
                icon: AppIcon(AppIcons.userAdd, size: 20, color: AppTheme.primary),
                tooltip: 'Davetli Ekle',
                onPressed: _openAddSheet,
              ),
          ],
        ),
        floatingActionButton: _controller.weddingId != null && !_controller.loading
            ? Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: FloatingActionButton(
                  heroTag: 'guests_fab',
                  onPressed: () =>
                      RsvpLinkSheet.show(context, weddingId: _controller.weddingId!),
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  child: AppIcon(AppIcons.share, size: 24, color: Colors.white),
                ),
              )
            : null,
        body: _controller.loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2))
            : _controller.error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _controller.load,
                    color: AppTheme.primary,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Column(
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 16),
                                _buildSearchBar(),
                                const SizedBox(height: 12),
                                _buildFilterChips(),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        _filtered.isEmpty
                            ? SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildEmptyState(),
                              )
                            : SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 96),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) {
                                      final guest = _filtered[i];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: _GuestTile(
                                          guest: guest,
                                          onTap: () => _openEditSheet(guest),
                                          onDelete: () => _deleteGuest(guest),
                                        ),
                                      );
                                    },
                                    childCount: _filtered.length,
                                  ),
                                ),
                              ),
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
          AppIcon(AppIcons.danger, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(_controller.error!,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _controller.load,
            child: Text('Tekrar Dene',
                style: GoogleFonts.dmSans(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final total = _controller.guests.length;
    final attending =
        _controller.guests.where((g) => g.rsvpStatus == RsvpStatus.attending).length;
    final pending =
        _controller.guests.where((g) => g.rsvpStatus == RsvpStatus.pending).length;
    final declined =
        _controller.guests.where((g) => g.rsvpStatus == RsvpStatus.declined).length;
    final withCompanions = _totalAttendingWithCompanions;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EEF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(AppIcons.people, size: 22, color: const Color(0xFF7A9671)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Davetli',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$total kişi',
                        style: GoogleFonts.syne(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      if (withCompanions > attending && attending > 0)
                        Text(
                          '+1\'lerle birlikte $withCompanions geliyor',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border, height: 1, thickness: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                      label: 'Onaylı',
                      value: '$attending',
                      color: const Color(0xFF6BAED4)),
                ),
                Expanded(
                  child: _StatItem(
                      label: 'Bekliyor',
                      value: '$pending',
                      color: const Color(0xFFAA8EC0)),
                ),
                Expanded(
                  child: _StatItem(
                      label: 'Gelmiyor',
                      value: '$declined',
                      color: const Color(0xFFB00020)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.60)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          AppIcon(AppIcons.search, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppTheme.textDark),
              decoration: InputDecoration(
                hintText: 'İsme göre ara...',
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 14, color: AppTheme.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
          if (_search.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _search = '');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AppIcon(AppIcons.close, size: 16, color: AppTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      (null, 'Tümü (${_controller.guests.length})'),
      (RsvpStatus.attending, 'Onaylı'),
      (RsvpStatus.pending, 'Bekliyor'),
      (RsvpStatus.maybe, 'Belki'),
      (RsvpStatus.declined, 'Gelmiyor'),
    ];

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final isSelected = _filterStatus == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.60),
                  ),
                ),
                child: Text(
                  f.$2,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.people, size: 52, color: AppTheme.border),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty || _filterStatus != null
                ? 'Eşleşen davetli bulunamadı'
                : 'Henüz davetli eklenmedi',
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          if (_search.isEmpty && _filterStatus == null) ...[
            const SizedBox(height: 6),
            Text(
              'Sağ alttaki + butonuyla davetli ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
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
            style: GoogleFonts.syne(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ── Guest Tile ─────────────────────────────────────────────────────────────

class _GuestTile extends StatelessWidget {
  final Guest guest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GuestTile(
      {required this.guest, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(guest.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Davetliyi Sil',
              style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  fontSize: 18),
            ),
            content: Text(
              '"${guest.fullName}" silinecek. Emin misiniz?',
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppTheme.textMuted),
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
        if (!context.mounted) return false;
        return result == true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sil',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB00020))),
            const SizedBox(width: 5),
            AppIcon(AppIcons.trash, color: const Color(0xFFB00020), size: 18),
          ],
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.50)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    guest.fullName.isNotEmpty
                        ? guest.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            guest.fullName,
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RsvpChip(status: guest.rsvpStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (guest.side != null) ...[
                          Text(
                            _sideLabel(guest.side!),
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                          if (guest.companionCount > 0 ||
                              guest.groupLabel != null)
                            Text(' · ',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, color: AppTheme.border)),
                        ],
                        if (guest.companionCount > 0) ...[
                          Text(
                            '+${guest.companionCount}',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                          if (guest.groupLabel != null)
                            Text(' · ',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, color: AppTheme.border)),
                        ],
                        if (guest.groupLabel != null)
                          Expanded(
                            child: Text(
                              guest.groupLabel!,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(AppIcons.edit, size: 14, color: AppTheme.border),
            ],
          ),
          ),
        ),
      ),
    );
  }

  String _sideLabel(GuestSide side) => switch (side) {
        GuestSide.bride => 'Gelin tarafı',
        GuestSide.groom => 'Damat tarafı',
        GuestSide.both => 'Her iki taraf',
      };
}

// ── RSVP Chip ─────────────────────────────────────────────────────────────

class _RsvpChip extends StatelessWidget {
  final RsvpStatus status;

  const _RsvpChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      RsvpStatus.attending => (
          'Geliyor',
          const Color(0xFF6BAED4),
          const Color(0xFFE3EEF4)
        ),
      RsvpStatus.declined => (
          'Gelmiyor',
          const Color(0xFFB00020),
          const Color(0xFFFFEBEB)
        ),
      RsvpStatus.maybe => (
          'Belki',
          const Color(0xFF7A9EB8),
          const Color(0xFFE8EFF5)
        ),
      RsvpStatus.pending => (
          'Bekliyor',
          const Color(0xFFAA8EC0),
          const Color(0xFFF2EEF8)
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
