import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_card.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  final AuthController controller;

  const RegisterPage({super.key, required this.controller});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleAuthChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleAuthChange);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleAuthChange() {
    if (!mounted) return;
    if (widget.controller.status == AuthStatus.authenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.30),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.50), width: 1),
              ),
              child: AppIcon(AppIcons.arrowLeft,
                  size: 16, color: AppTheme.textDark),
            ),
          ),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final status = widget.controller.status;
              final isLoading = status == AuthStatus.loading;
              final isPending = status == AuthStatus.emailConfirmationPending;
              final errorMessage = status == AuthStatus.error
                  ? widget.controller.errorMessage
                  : null;

              if (isPending) return _buildPendingState();

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Hesap\nOluştur',
                          style: GoogleFonts.playfairDisplay(
                            color: AppTheme.textDark,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Planlamaya hemen başlayın.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),

                        GlassCard(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AuthTextField(
                                  controller: _emailController,
                                  label: 'E-posta',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
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
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Şifre gerekli';
                                    }
                                    if (v.length < 6) {
                                      return 'En az 6 karakter olmalı';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  controller: _confirmController,
                                  label: 'Şifreyi Tekrar Girin',
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  onEditingComplete: isLoading ? null : _submit,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Şifre tekrarı gerekli';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Şifreler eşleşmiyor';
                                    }
                                    return null;
                                  },
                                ),
                                if (errorMessage != null) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    errorMessage,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFB00020),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),
                                GlassButton(
                                  label: 'KAYIT OL',
                                  onPressed: isLoading ? null : _submit,
                                  isLoading: isLoading,
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
                              'Zaten hesabın var mı?  ',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: Text(
                                'Giriş Yap',
                                style: GoogleFonts.inter(
                                  color: AppTheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.40),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.60), width: 1.5),
                ),
                child: AppIcon(
                  AppIcons.messageCheck,
                  size: 34,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'E-postanızı\nDoğrulayın',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.textDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${_emailController.text} adresine doğrulama bağlantısı '
                'gönderdik. Lütfen e-postanızı kontrol edin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              GlassButton(
                label: 'GİRİŞ SAYFASINA DÖN',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
