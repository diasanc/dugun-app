import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage1 extends StatelessWidget {
  final VoidCallback? onNext;

  const OnboardingPage1({super.key, this.onNext});

  static const _onSurface = Color(0xFF1B1C1A);
  static const _onSurfaceVariant = Color(0xFF504444);
  static const _outline = Color(0xFF827474);
  static const _tertiaryFixed = Color(0xFFE7E2D9);
  static const _secondaryContainer = Color(0xFFFED65B);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.1,
            child: _BlurredCircle(
              diameter: size.width * 0.5,
              color: AppTheme.primary.withValues(alpha: 0.05),
              blurSigma: 60,
            ),
          ),
          Positioned(
            bottom: -size.height * 0.05,
            left: -size.width * 0.05,
            child: _BlurredCircle(
              diameter: size.width * 0.4,
              color: _secondaryContainer.withValues(alpha: 0.10),
              blurSigma: 50,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildProgress(),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildImagePlaceholder(),
                              const SizedBox(height: 32),
                              _buildTexts(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _buildButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AppIcon(AppIcons.arrowLeft,
                  color: AppTheme.primary, size: 20),
            ),
          ),
          Opacity(
            opacity: 0,
            child: Text(
              'LIERA',
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Text(
          'ADIM 1 / 5',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _outline,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: const LinearProgressIndicator(
            value: 0.2,
            backgroundColor: _tertiaryFixed,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 192,
      height: 256,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _tertiaryFixed,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AppIcon(AppIcons.image, size: 64, color: _outline),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppTheme.surface.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTexts() {
    return Column(
      children: [
        Text(
          'Sizin İçin\nTasarlandı',
          textAlign: TextAlign.center,
          style: GoogleFonts.syne(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: _onSurface,
            height: 44 / 36,
            letterSpacing: -0.36,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 280,
          child: Text(
            'Hayatınızın en özel gününü planlamak artık çok daha kolay — ve tamamen size özel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _onSurfaceVariant,
              height: 24 / 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const StadiumBorder(),
          elevation: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BAŞLAYALIM',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(width: 8),
            AppIcon(AppIcons.arrowRight, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  const _BlurredCircle({
    required this.diameter,
    required this.color,
    required this.blurSigma,
  });

  final double diameter;
  final Color color;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
