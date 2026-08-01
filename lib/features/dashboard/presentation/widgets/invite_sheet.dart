import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/services/join_code_service.dart';
import '../../../../../core/theme/app_icon.dart';
import '../../../../../core/theme/app_theme.dart';

class InviteSheet extends StatefulWidget {
  final String userId;

  const InviteSheet({super.key, required this.userId});

  static Future<void> show(BuildContext context, String userId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteSheet(userId: userId),
    );
  }

  @override
  State<InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<InviteSheet> {
  final _service = JoinCodeService();
  String? _code;
  String? _error;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final code = await _service.getOrCreateJoinCode(widget.userId);
      if (mounted) setState(() => _code = code);
    } catch (e) {
      if (mounted) setState(() => _error = 'Kod alınamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _copyCode() async {
    if (_code == null) return;
    await Clipboard.setData(ClipboardData(text: _code!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _shareWhatsApp() async {
    if (_code == null) return;
    final text = Uri.encodeComponent(
      'Düğün planlamama katılmak için bu kodu kullan: $_code\n'
      'Uygulamayı indir ve "Düğün kodunuz var mı?" bölümüne gir.',
    );
    final uri = Uri.parse('whatsapp://send?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(
        Uri.parse('https://wa.me/?text=$text'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5E6EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
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

          Text(
            'Düğününüze Davet Edin',
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kodu paylaşarak eşinizi veya yakınlarınızı\ndüğün planlamasına ekleyin.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          if (_error != null)
            Text(_error!,
                style: GoogleFonts.dmSans(
                    color: const Color(0xFFB00020), fontSize: 13))
          else if (_code == null)
            const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2),
              ),
            )
          else ...[
            // Code box
            GestureDetector(
              onTap: _copyCode,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.20)),
                ),
                child: Column(
                  children: [
                    Text(
                      _code!,
                      style: GoogleFonts.syne(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          _copied ? AppIcons.check : AppIcons.copy,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Kopyalandı!' : 'Kopyalamak için dokun',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _shareWhatsApp,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: AppIcon(AppIcons.send, size: 17),
              label: Text(
                'WhatsApp ile Paylaş',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
