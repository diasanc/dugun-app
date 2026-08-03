import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/guest.dart';

const _kAccent = Color(0xFF7056C8);

class AddGuestSheet extends StatefulWidget {
  final String weddingId;

  /// Düzenleme modunda mevcut davetli; null ise ekleme modu.
  final Guest? guest;

  const AddGuestSheet({super.key, required this.weddingId, this.guest});

  /// Returns the form data on save, or a deletedId on delete, or nulls on cancel.
  static Future<({Guest? guest, String? deletedId})> show(
    BuildContext context, {
    required String weddingId,
    Guest? guest,
  }) async {
    final result = await showModalBottomSheet<({Guest? guest, String? deletedId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGuestSheet(weddingId: weddingId, guest: guest),
    );
    return result ?? (guest: null, deletedId: null);
  }

  @override
  State<AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends State<AddGuestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _groupController = TextEditingController();

  late RsvpStatus _rsvpStatus;
  GuestSide? _side;
  int _companionCount = 0;

  bool get _isEditing => widget.guest != null;

  @override
  void initState() {
    super.initState();
    final g = widget.guest;
    if (g != null) {
      _nameController.text = g.fullName;
      _phoneController.text = g.phone ?? '';
      _groupController.text = g.groupLabel ?? '';
      _rsvpStatus = g.rsvpStatus;
      _side = g.side;
      _companionCount = g.companionCount;
    } else {
      _rsvpStatus = RsvpStatus.pending;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final phone = _phoneController.text.trim();
    final group = _groupController.text.trim();

    final Guest result;
    if (_isEditing) {
      result = Guest(
        id: widget.guest!.id,
        weddingId: widget.guest!.weddingId,
        fullName: _nameController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        side: _side,
        rsvpStatus: _rsvpStatus,
        companionCount: _companionCount,
        groupLabel: group.isEmpty ? null : group,
        notes: widget.guest!.notes,
        createdAt: widget.guest!.createdAt,
        updatedAt: now,
      );
    } else {
      result = Guest(
        id: '',
        weddingId: widget.weddingId,
        fullName: _nameController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        side: _side,
        rsvpStatus: _rsvpStatus,
        companionCount: _companionCount,
        groupLabel: group.isEmpty ? null : group,
        createdAt: now,
        updatedAt: now,
      );
    }
    if (mounted) {
      Navigator.pop(context, (guest: result, deletedId: null as String?));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Davetliyi Sil',
          style: GoogleFonts.syne(
              fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
        content: Text(
          '"${widget.guest!.fullName}" silinecek. Emin misiniz?',
          style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFB00020)),
            child: Text('Sil',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    Navigator.pop(context, (guest: null as Guest?, deletedId: widget.guest!.id));
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
                      _isEditing ? 'Davetliyi Düzenle' : 'Davetli Ekle',
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
                        onPressed: _delete,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Ad Soyad ──────────────────────────────────────────────────
              _Label('Ad Soyad'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style:
                    GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textDark),
                decoration: _dec('Örn: Ayşe Kaya'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ad soyad gerekli' : null,
              ),
              const SizedBox(height: 22),

              // ── Telefon ───────────────────────────────────────────────────
              _Label('Telefon (opsiyonel)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style:
                    GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textDark),
                decoration: _dec('05XX XXX XX XX'),
              ),
              const SizedBox(height: 22),

              // ── Taraf ─────────────────────────────────────────────────────
              _Label('Taraf (opsiyonel)'),
              const SizedBox(height: 10),
              _SidePicker(
                selected: _side,
                onChanged: (s) => setState(() => _side = s),
              ),
              const SizedBox(height: 22),

              // ── RSVP Durumu ───────────────────────────────────────────────
              _Label('Katılım Durumu'),
              const SizedBox(height: 10),
              _RsvpPicker(
                selected: _rsvpStatus,
                onChanged: (s) => setState(() => _rsvpStatus = s),
              ),
              const SizedBox(height: 22),

              // ── +1 Sayısı ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('+1 Sayısı'),
                        const SizedBox(height: 4),
                        Text(
                          'Yanında getireceklerinin sayısı',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _CompanionStepper(
                    value: _companionCount,
                    onChanged: (v) => setState(() => _companionCount = v),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Grup Etiketi ──────────────────────────────────────────────
              _Label('Grup Etiketi (opsiyonel)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _groupController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onEditingComplete: _save,
                style:
                    GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textDark),
                decoration: _dec('Örn: Aile, Üniversite'),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
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
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
        ),
      );
}

// ── Yardımcı Widget'lar ────────────────────────────────────────────────────

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

class _SidePicker extends StatelessWidget {
  final GuestSide? selected;
  final ValueChanged<GuestSide?> onChanged;

  const _SidePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (null as GuestSide?, 'Belirtilmemiş'),
      (GuestSide.bride, 'Gelin'),
      (GuestSide.groom, 'Damat'),
      (GuestSide.both, 'Her İkisi'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected == o.$1;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _kAccent
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? _kAccent
                    : Colors.black.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              o.$2,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF8A8A8A),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RsvpPicker extends StatelessWidget {
  final RsvpStatus selected;
  final ValueChanged<RsvpStatus> onChanged;

  const _RsvpPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      (RsvpStatus.pending, 'Bekliyor'),
      (RsvpStatus.attending, 'Geliyor'),
      (RsvpStatus.maybe, 'Belki'),
      (RsvpStatus.declined, 'Gelmiyor'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected == o.$1;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _kAccent
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? _kAccent
                    : Colors.black.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              o.$2,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF8A8A8A),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CompanionStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CompanionStepper(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: AppIcons.minus,
          onTap: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark),
          ),
        ),
        _StepButton(
          icon: AppIcons.add,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primaryContainer
              : AppTheme.border.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AppIcon(
            icon,
            size: 16,
            color: onTap != null ? AppTheme.primary : AppTheme.border,
          ),
        ),
      ),
    );
  }
}
