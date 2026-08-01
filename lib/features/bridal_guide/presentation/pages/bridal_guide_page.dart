import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../bridal_guide_content.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import 'fabric_detail_page.dart';
import 'neckline_detail_page.dart';
import 'skirt_detail_page.dart';
import 'sleeve_detail_page.dart';

class BridalGuidePage extends StatelessWidget {
  final String userId;

  const BridalGuidePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final smallCardW = (w - 32 - 16) / 3;
    final iconSize = (smallCardW * 0.80).clamp(50.0, 120.0);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Gelinlik Rehberi',
            style: GoogleFonts.syne(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Blok 1 (flex 3): Başlık + 3'lü Row ─────────────────
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori seç',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark.withValues(alpha: 0.45),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _SmallCategoryCard(
                                label: 'Yaka',
                                tint: const Color(0xFFE8416F),
                                count: yakaModelleri.length,
                                descUnit: 'yaka modeli',
                                iconWidget: SvgPicture.asset(
                                  'assets/icons/bridal/yaka_sweetheart.svg',
                                  width: iconSize,
                                  height: iconSize,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFE8416F),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NecklineDetailPage()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SmallCategoryCard(
                                label: 'Etek',
                                tint: AppTheme.primary,
                                count: etekKesimleri.length,
                                descUnit: 'etek kesimi',
                                iconWidget: SvgPicture.asset(
                                  'assets/icons/bridal/etek_a.svg',
                                  width: iconSize,
                                  height: iconSize,
                                  colorFilter: const ColorFilter.mode(
                                    AppTheme.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SkirtDetailPage()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SmallCategoryCard(
                                label: 'Kol',
                                tint: const Color(0xFFC23066),
                                count: kolModelleri.length,
                                descUnit: 'kol modeli',
                                iconWidget: SvgPicture.asset(
                                  'assets/icons/bridal/kol_offshoulder_balon_uzun.svg',
                                  width: iconSize,
                                  height: iconSize,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFC23066),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const SleeveDetailPage()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Blok 2 (flex 2): Kumaş kartı ────────────────────────
                Expanded(
                  flex: 2,
                  child: GlassCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FabricDetailPage()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/bridal/kumas/kumas_saten.png',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kumaş',
                                  style: GoogleFonts.syne(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Doku & his rehberi',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppIcon(
                            AppIcons.chevronRight,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Blok 3 (flex 3): İki "Yakında" kartı ────────────────
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        child: _ComingSoonCard(
                          icon: AppIcons.heartShine,
                          title: 'Hayalindeki Gelinliği Oluştur',
                          subtitle: 'Tercihlerine göre kişisel stil önerisi',
                        ),
                      ),
                      const SizedBox(height: 9),
                      Expanded(
                        child: _ComingSoonCard(
                          icon: AppIcons.store,
                          title: 'Firmalar & Instagram\'lar',
                          subtitle: 'Taslağın hangi firmada var, bulalım',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Küçük Kategori Kartı (3'lü Row) ──────────────────────────────────────────

class _SmallCategoryCard extends StatelessWidget {
  final String label;
  final Color tint;
  final Widget iconWidget;
  final int count;
  final String descUnit;
  final VoidCallback onTap;

  const _SmallCategoryCard({
    required this.label,
    required this.tint,
    required this.iconWidget,
    required this.count,
    required this.descUnit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: tint,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İkon — üstte, ortalanmış
            Center(child: iconWidget),
            // Başlık — tutarlı font
            Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tint,
                height: 1.1,
              ),
            ),
            // Açıklama + "İncele!" — altta
            RichText(
              text: TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tint.withValues(alpha: 0.80),
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: '$count farklı $descUnit burada. '),
                  const TextSpan(
                    text: 'İncele!',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "Yakında" Placeholder Kartı ───────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.42,
      child: CustomPaint(
        painter: DashedRectPainter(
          color: AppTheme.primary,
          strokeWidth: 1.5,
          gap: 6.0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppIcon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Çok Yakında!',
                    style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary.withValues(alpha: 0.80),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
