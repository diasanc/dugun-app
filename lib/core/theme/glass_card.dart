import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_icon.dart';

// ── Holographic Glass Card ────────────────────────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? tint;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 14.0,
    this.padding,
    this.radius = 16.0,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final t = tint;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.mirror),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: t != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      t.withValues(alpha: 0.18),
                      t.withValues(alpha: 0.08),
                      t.withValues(alpha: 0.18),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      const Color(0xFFE1E1F5).withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.35),
                    ],
                  ),
            border: Border.all(
              color: t != null
                  ? t.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

// ── Liquid Background ─────────────────────────────────────────────────────

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF0F3),
                  Color(0xFFFFCDD8),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ── Floating Glass Navigation Bar ────────────────────────────────────────

const _kNavItemCount = 5;
const _kHighlightSize = 48.0;

class FloatingGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  /// Pass the page's primary ScrollController to enable collapse-on-scroll.
  final ScrollController? scrollController;

  const FloatingGlassNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.scrollController,
  });

  @override
  State<FloatingGlassNavBar> createState() => _FloatingGlassNavBarState();
}

class _FloatingGlassNavBarState extends State<FloatingGlassNavBar> {
  bool _collapsed = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(FloatingGlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      old.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController!.offset;
    final goingDown = offset > _lastOffset;
    _lastOffset = offset;

    if (goingDown && offset > 60 && !_collapsed) {
      setState(() => _collapsed = true);
    } else if (!goingDown && _collapsed) {
      setState(() => _collapsed = false);
    }
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 320);
    const curve = Curves.easeOutCubic;
    final idx = widget.currentIndex.clamp(0, 4);

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      // Shrink width by growing horizontal margin when collapsed
      margin: EdgeInsets.symmetric(horizontal: _collapsed ? 20 : 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: AnimatedContainer(
            duration: duration,
            curve: curve,
            // Shrink height by reducing vertical padding when collapsed
            padding: EdgeInsets.symmetric(vertical: _collapsed ? 3 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.50),
                width: 1.0,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Each of the 5 slots occupies exactly 1/5 of the available width.
                // Highlight left = slot_left + (slot_width - circle) / 2
                final slotW = constraints.maxWidth / _kNavItemCount;
                final highlightLeft =
                    idx * slotW + (slotW - _kHighlightSize) / 2;

                return Stack(
                  children: [
                    // Sliding highlight — AnimatedPositioned is a positioned
                    // child so it never contributes to Stack sizing.
                    AnimatedPositioned(
                      duration: duration,
                      curve: curve,
                      left: highlightLeft,
                      top: 0,
                      bottom: 0,
                      width: _kHighlightSize,
                      child: Center(
                        child: Container(
                          width: _kHighlightSize,
                          height: _kHighlightSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D3FD3)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    // Nav items — Expanded keeps each slot exactly 1/5 wide,
                    // matching the highlight slot calculation above.
                    Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: AppIcons.home,
                            isActive: widget.currentIndex == 0,
                            onTap: () => _handleTap(0),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: AppIcons.calendar,
                            isActive: widget.currentIndex == 1,
                            onTap: () => _handleTap(1),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: AppIcons.wallet,
                            isActive: widget.currentIndex == 2,
                            onTap: () => _handleTap(2),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: AppIcons.imageSparkle,
                            isActive: widget.currentIndex == 3,
                            onTap: () => _handleTap(3),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: AppIcons.hanger,
                            isActive: widget.currentIndex == 4,
                            onTap: () => _handleTap(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Height fixed at 48; width is driven by Expanded in the parent Row.
      // Center ensures the SVG is always pixel-perfect regardless of its viewBox.
      child: SizedBox(
        height: _kHighlightSize,
        child: Center(
          child: AppIcon(
            icon,
            size: 24,
            color: isActive
                ? const Color(0xFF5D3FD3)
                : const Color(0xFF191C1D).withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

// ── Glass Button ──────────────────────────────────────────────────────────

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFC), Color(0xFF5D3FD3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D3FD3).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            splashColor: Colors.white.withValues(alpha: 0.15),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashed Border Painter ─────────────────────────────────────────────────

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  const DashedRectPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    double distance = 0;
    for (final metric in path.computeMetrics()) {
      final total = metric.length;
      while (distance < total) {
        final end = (distance + gap).clamp(0.0, total);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRectPainter old) =>
      old.color != color || old.gap != gap;
}

// ── Floral Decor (onboarding için) ───────────────────────────────────────

class FloralDecor extends StatelessWidget {
  final double size;
  final Color color;

  const FloralDecor({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FloralPainter(color: color)),
    );
  }
}

class _FloralPainter extends CustomPainter {
  final Color color;
  _FloralPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawCircle(
        Offset(cx + r * 0.45 * cos(angle), cy + r * 0.45 * sin(angle)),
        r * 0.42,
        paint,
      );
    }
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.30,
      paint..color = color.withValues(alpha: 0.32),
    );
  }

  @override
  bool shouldRepaint(_FloralPainter old) => old.color != color;
}
