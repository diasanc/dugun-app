import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import 'join_code_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final AuthController controller;
  final VoidCallback? onBackToOnboarding;

  const LoginPage({
    super.key,
    required this.controller,
    this.onBackToOnboarding,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage(controller: widget.controller),
      ),
    );
  }

  void _goToJoinCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinCodePage(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final isLoading =
                  widget.controller.status == AuthStatus.loading;
              final errorMessage =
                  widget.controller.status == AuthStatus.error
                      ? widget.controller.errorMessage
                      : null;

              return Stack(
                children: [
                  // Geri butonu — sadece callback verilmişse göster
                  if (widget.onBackToOnboarding != null)
                    Positioned(
                      top: 12,
                      left: 16,
                      child: GestureDetector(
                        onTap: widget.onBackToOnboarding,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.30),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.50),
                                  width: 1,
                                ),
                              ),
                              child: AppIcon(
                                AppIcons.arrowLeft,
                                size: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // İçerik
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 48),

                            // Marka adı
                            Center(
                              child: Text(
                                'LIERA',
                                style: GoogleFonts.syne(
                                  color: AppTheme.primary,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                'Tekrar hoş geldiniz',
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.textMuted,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Form kartı
                            GlassCard(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 28, 24, 28),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AuthTextField(
                                      controller: _emailController,
                                      label: 'E-posta',
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction:
                                          TextInputAction.next,
                                      validator: (v) {
                                        if (v == null ||
                                            v.trim().isEmpty) {
                                          return 'E-posta gerekli';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Geçerli bir e-posta girin';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    AuthTextField(
                                      controller: _passwordController,
                                      label: 'Şifre',
                                      isPassword: true,
                                      textInputAction:
                                          TextInputAction.done,
                                      onEditingComplete:
                                          isLoading ? null : _submit,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Şifre gerekli';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (errorMessage != null) ...[
                                      const SizedBox(height: 14),
                                      Text(
                                        errorMessage,
                                        style: GoogleFonts.dmSans(
                                          color:
                                              const Color(0xFFB00020),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 28),
                                    FilledButton(
                                      onPressed:
                                          isLoading ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.primary,
                                        minimumSize: const Size(
                                            double.infinity, 52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'GİRİŞ YAP',
                                              style: GoogleFonts.dmSans(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w700,
                                                letterSpacing: 1.1,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hesabın yok mu?  ',
                                  style: GoogleFonts.dmSans(
                                    color: AppTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap:
                                      isLoading ? null : _goToRegister,
                                  child: Text(
                                    'Kayıt Ol',
                                    style: GoogleFonts.dmSans(
                                      color: AppTheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: isLoading ? null : _goToJoinCode,
                              child: Text(
                                'Düğün kodunuz var mı?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.textMuted,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
