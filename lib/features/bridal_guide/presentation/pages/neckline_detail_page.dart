import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../bridal_guide_content.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import 'bridal_item_sheet.dart';

class NecklineDetailPage extends StatelessWidget {
  const NecklineDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Yaka Modelleri',
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
        ),
        body: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.73,
          ),
          itemCount: yakaModelleri.length,
          itemBuilder: (context, index) {
            final item = yakaModelleri[index];
            return _NecklineCard(
              item: item,
              onTap: () => showBridalItemSheet(
                context,
                imageWidget: SvgPicture.asset(
                  'assets/icons/bridal/${item['icon']}',
                  width: 120,
                  height: 120,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF191C1D),
                    BlendMode.srcIn,
                  ),
                ),
                isim: item['isim'] as String,
                aciklama: item['aciklama'] as String,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NecklineCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _NecklineCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SvgPicture.asset(
                'assets/icons/bridal/${item['icon']}',
                width: 100,
                height: 100,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF191C1D),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item['isim'] as String,
              style: GoogleFonts.syne(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                item['aciklama'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
