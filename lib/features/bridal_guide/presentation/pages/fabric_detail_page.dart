import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../bridal_guide_content.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import 'bridal_item_sheet.dart';

class FabricDetailPage extends StatelessWidget {
  const FabricDetailPage({super.key});

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
            'Kumaş Çeşitleri',
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
            childAspectRatio: 0.72,
          ),
          itemCount: kumaslar.length,
          itemBuilder: (context, index) {
            final item = kumaslar[index];
            return _FabricCard(
              item: item,
              onTap: () => showBridalItemSheet(
                context,
                imageWidget: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/bridal/kumas/${item['icon']}',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
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

class _FabricCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _FabricCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              'assets/images/bridal/kumas/${item['icon']}',
              width: double.infinity,
              height: 110,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        fontSize: 10,
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
          ),
        ],
      ),
    );
  }
}
