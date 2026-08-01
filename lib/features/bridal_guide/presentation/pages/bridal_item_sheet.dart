import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

void showBridalItemSheet(
  BuildContext context, {
  required Widget imageWidget,
  required String isim,
  required String aciklama,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BridalItemSheet(
      imageWidget: imageWidget,
      isim: isim,
      aciklama: aciklama,
    ),
  );
}

class _BridalItemSheet extends StatelessWidget {
  final Widget imageWidget;
  final String isim;
  final String aciklama;

  const _BridalItemSheet({
    required this.imageWidget,
    required this.isim,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D3FD3).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Image (SVG icon veya PNG fotoğraf)
            imageWidget,
            const SizedBox(height: 20),
            // Title
            Text(
              isim,
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: AppTheme.textDark.withValues(alpha: 0.07),
            ),
            const SizedBox(height: 14),
            // Description
            Text(
              aciklama,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

