import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/join_code_service.dart';
import '../../../../core/theme/app_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import 'register_page.dart';

class JoinCodePage extends StatefulWidget {
  final AuthController controller;

  const JoinCodePage({super.key, required this.controller});

  @override
  State<JoinCodePage> createState() => _JoinCodePageState();
}

class _JoinCodePageState extends State<JoinCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _service = JoinCodeService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Kodu doğrula
      final code = _codeController.text.toUpperCase().trim();
      final weddingId = await _service.validateCode(code);
      if (weddingId == null) {
        setState(() {
          _error = 'Geçersiz katılım kodu. Lütfen kontrol edin.';
          _loading = false;
        });
        return;
      }

      // 2. Giriş yap
      await widget.controller.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (widget.controller.status != AuthStatus.authenticated) {
        setState(() => _loading = false);
        return; // Hata controller.errorMessage'da gösterilir
      }

      // 3. Düğüne ekle
      final userId = widget.controller.user!.id;
      await _service.joinByCode(code, userId);

      // 4. _AppShell zaten dashboard'a geçti; stack'i temizle
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bir hata oluştu. Lütfen tekrar deneyin.';
          _loading = false;
        });
      }
    }
  }

  void _goToRegister() {
    // Kodu pending olarak sakla: kayıt sonrası main.dart işler
    final code = _codeController.text.toUpperCase().trim();
    if (code.isNotEmpty) JoinCodeService.setPendingCode(code);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: AppIcon(AppIcons.arrowLeft,
              size: 18, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final isLoading = _loading ||
                widget.controller.status == AuthStatus.loading;
            final controllerError =
                widget.controller.status == AuthStatus.error
                    ? widget.controller.errorMessage
                    : null;
            final displayError = _error ?? controllerError;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // İkon
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryContainer,
                              border: Border.all(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.2)),
                            ),
                            child: AppIcon(AppIcons.userAdd,
                                color: AppTheme.primary, size: 26),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Katılım Koduyla Gir',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Düğün sahibinden aldığınız 6 haneli\nkodu ve giriş bilgilerinizi girin.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),
                        const Divider(
                            color: AppTheme.border, height: 1, thickness: 1),
                        const SizedBox(height: 32),

                        // Kod alanı
                        TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(6),
                            _UpperCaseFormatter(),
                          ],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: '------',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.border,
                              letterSpacing: 8,
                            ),
                            labelText: 'Katılım Kodu',
                            labelStyle: GoogleFonts.inter(
                                color: AppTheme.textMuted, fontSize: 13),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 6) {
                              return '6 haneli kod giriniz';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // E-posta
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
                        const SizedBox(height: 24),

                        // Şifre
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Şifre',
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: isLoading ? null : _submit,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Şifre gerekli';
                            }
                            return null;
                          },
                        ),

                        if (displayError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            displayError,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFB00020),
                              fontSize: 13,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('KATIL'),
                        ),

                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hesabın yok mu?  ',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textMuted, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: isLoading ? null : _goToRegister,
                              child: Text(
                                'Kayıt Ol',
                                style: GoogleFonts.inter(
                                  color: AppTheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
