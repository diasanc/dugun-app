import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/wedding_service.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/moodboard_item.dart';
import '../../data/services/moodboard_service.dart';

class AddMoodboardItemSheet extends StatefulWidget {
  const AddMoodboardItemSheet({
    super.key,
    required this.userId,
    this.item,
    this.initialSortOrder = 0,
  });

  final String userId;
  final MoodboardItem? item;
  final int initialSortOrder;

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    MoodboardItem? item,
    int initialSortOrder = 0,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMoodboardItemSheet(
        userId: userId,
        item: item,
        initialSortOrder: initialSortOrder,
      ),
    );
  }

  @override
  State<AddMoodboardItemSheet> createState() => _AddMoodboardItemSheetState();
}

class _AddMoodboardItemSheetState extends State<AddMoodboardItemSheet> {
  late MoodboardItemType _type;
  late String _category;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  File? _pickedPhoto;
  bool _loading = false;

  bool get _isEdit => widget.item != null;

  // Arka plan rengi — temadaki pembe gradyanla uyumlu
  static const _sheetBg = Color(0xFFF5E6EB);

  // Sayfaya özel hafif yumuşatılmış mor ton (AppTheme.primary'den biraz pastel)
  static const _accent = Color(0xFF7056C8);

  // TextField dekorasyon yardımcısı — hintText kullanarak label üst-üste binmesi engellendi
  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 13, color: AppTheme.textMuted),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.55),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.black.withValues(alpha: 0.10), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.black.withValues(alpha: 0.10), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _accent, width: 1.5),
        ),
      );

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _type = item.type;
      _category = item.category ?? 'Diğer';
      _titleCtrl.text = item.title ?? '';
      _contentCtrl.text = item.content;
      _notesCtrl.text = item.notes ?? '';
    } else {
      _type = MoodboardItemType.link;
      _category = 'Diğer';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _pickedPhoto = File(picked.path));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Sil',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        content: Text('Bu öğeyi silmek istediğinize emin misiniz?',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Vazgeç', style: GoogleFonts.dmSans()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB00020)),
            child: Text('Sil', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      final service = MoodboardService();
      await service.delete(widget.item!.id);
      if (widget.item!.type == MoodboardItemType.photo) {
        await service.deletePhoto(widget.item!.content);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silinemedi: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    if (_type == MoodboardItemType.photo &&
        _pickedPhoto == null &&
        !_isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir fotoğraf seçin')),
      );
      return;
    }
    if (_type != MoodboardItemType.photo &&
        _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == MoodboardItemType.link
                ? 'Lütfen bir link girin'
                : 'Lütfen not yazın',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final service = MoodboardService();
      final wedding =
          await WeddingService().getOrCreateWedding(widget.userId);
      String content = _contentCtrl.text.trim();

      if (_type == MoodboardItemType.photo && _pickedPhoto != null) {
        content = await service.uploadPhoto(wedding.id, _pickedPhoto!);
      }

      if (_isEdit) {
        await service.update(
          widget.item!.copyWith(
            type: _type,
            title: _titleCtrl.text.trim().isEmpty
                ? null
                : _titleCtrl.text.trim(),
            content: content,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            category: _category,
          ),
        );
      } else {
        await service.create(
          MoodboardItem(
            id: '',
            weddingId: wedding.id,
            type: _type,
            title: _titleCtrl.text.trim().isEmpty
                ? null
                : _titleCtrl.text.trim(),
            content: content,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            category: _category,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            sortOrder: widget.initialSortOrder,
          ),
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: _sheetBg.withValues(alpha: 0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.55), width: 1),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Başlık + silme butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Düzenle' : 'Yeni Ekle',
                    style: GoogleFonts.syne(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (_isEdit)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        onPressed: _loading ? null : _delete,
                        icon: AppIcon(AppIcons.trash, color: const Color(0xFFB00020)),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(
                            minWidth: 36, minHeight: 36),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Tip seçici
              Row(
                children: MoodboardItemType.values.map((t) {
                  final sel = _type == t;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: t != MoodboardItemType.values.last
                            ? 8
                            : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = t;
                          _pickedPhoto = null;
                          _contentCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? _accent
                                : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? _accent
                                  : Colors.black.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              AppIcon(
                                _typeIcon(t),
                                size: 18,
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFF8A8A8A),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _typeLabel(t),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF8A8A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Kategori chip'leri
              Text(
                'Kategori',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: kMoodboardCategories
                      .where((c) => c != 'Tümü')
                      .map((cat) {
                    final sel = _category == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel
                              ? _accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: sel
                                ? _accent
                                : Colors.black.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: sel
                                ? Colors.white
                                : const Color(0xFF7A7A7A),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // Form alanları
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppTheme.textDark),
                decoration: _inputDec(
                  _type == MoodboardItemType.link
                      ? 'Etiket (opsiyonel)'
                      : _type == MoodboardItemType.note
                          ? 'Başlık (opsiyonel)'
                          : 'Açıklama (opsiyonel)',
                ),
              ),
              const SizedBox(height: 10),
              if (_type == MoodboardItemType.link) ...[
                TextField(
                  controller: _contentCtrl,
                  keyboardType: TextInputType.url,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppTheme.textDark),
                  decoration: _inputDec('Link (https://...)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppTheme.textDark),
                  decoration: _inputDec('Not (opsiyonel)'),
                ),
              ] else if (_type == MoodboardItemType.note) ...[
                TextField(
                  controller: _contentCtrl,
                  maxLines: 4,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppTheme.textDark),
                  decoration: _inputDec('Notunuz'),
                ),
              ] else ...[
                const SizedBox(height: 2),
                _PhotoPicker(
                  existingUrl: _isEdit &&
                          widget.item!.type == MoodboardItemType.photo
                      ? widget.item!.content
                      : null,
                  pickedFile: _pickedPhoto,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesCtrl,
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppTheme.textDark),
                  decoration: _inputDec('Not (opsiyonel)'),
                ),
              ],
              const SizedBox(height: 24),

              // Kaydet butonu
              FilledButton(
                onPressed: _loading ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? 'Güncelle' : 'Kaydet',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeIcon(MoodboardItemType t) {
    switch (t) {
      case MoodboardItemType.link:
        return AppIcons.link;
      case MoodboardItemType.note:
        return AppIcons.stickyNote;
      case MoodboardItemType.photo:
        return AppIcons.image;
    }
  }

  String _typeLabel(MoodboardItemType t) {
    switch (t) {
      case MoodboardItemType.link:
        return 'Link';
      case MoodboardItemType.note:
        return 'Not';
      case MoodboardItemType.photo:
        return 'Fotoğraf';
    }
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.onTap,
    this.existingUrl,
    this.pickedFile,
  });

  final String? existingUrl;
  final File? pickedFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedFile != null || existingUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.70), width: 1.5),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: pickedFile != null
                    ? Image.file(pickedFile!, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: existingUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    AppIcons.galleryAdd,
                    size: 32,
                    color: const Color(0xFF7056C8).withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Galeriden fotoğraf seç',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
