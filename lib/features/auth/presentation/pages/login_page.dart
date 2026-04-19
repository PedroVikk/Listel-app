import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  /// Rota para redirecionar após login bem-sucedido.
  final String? redirectTo;

  const LoginPage({super.key, this.redirectTo});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Limpa qualquer SnackBar anterior (ex: de logout ou erro prévio)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go(widget.redirectTo ?? '/');
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage('Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForgotPasswordDialog() async {
    final controller =
        TextEditingController(text: _emailController.text.trim());
    final colorScheme = Theme.of(context).colorScheme;

    final email = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Recuperar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Informe o e-mail cadastrado. Enviaremos um link para você criar uma nova senha.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty && value.contains('@')) {
                Navigator.of(dialogCtx).pop(value);
              }
            },
            child: const Text('Enviar link'),
          ),
        ],
      ),
    );

    if (email == null || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).resetPasswordForEmail(email);
      if (mounted) {
        _showMessage(
          'Link enviado! Verifique seu e-mail.',
          isError: false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage('Não foi possível enviar o link agora.');
    }
  }

  void _showMessage(String text, {bool isError = true}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor:
            isError ? colorScheme.error : colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          _AmbientBackground(colorScheme: colorScheme),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(colorScheme: colorScheme),
                      const SizedBox(height: 48),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(
                              text: 'E-mail',
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 8),
                            _SoftTextField(
                              controller: _emailController,
                              hint: 'Seu e-mail',
                              prefixIcon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe seu e-mail';
                                }
                                if (!v.contains('@')) return 'E-mail inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _FieldLabel(
                              text: 'Senha',
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 8),
                            _SoftTextField(
                              controller: _passwordController,
                              hint: 'Sua senha secreta',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Informe sua senha';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : _openForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                child: const Text(
                                  'Esqueci minha senha',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _PrimaryGradientButton(
                              label: 'Entrar',
                              loading: _loading,
                              colorScheme: colorScheme,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        'Ainda não tem uma conta?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  final uri = widget.redirectTo != null
                                      ? '/auth/signup?redirectTo=${Uri.encodeQueryComponent(widget.redirectTo!)}'
                                      : '/auth/signup';
                                  context.push(uri);
                                },
                          style: TextButton.styleFrom(
                            backgroundColor:
                                colorScheme.surfaceContainerHigh,
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Criar conta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ColorScheme colorScheme;

  const _Header({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Listel',
          style: GoogleFonts.plusJakartaSans(
            color: colorScheme.primary,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            height: 1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Boas-vindas',
          style: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre para organizar suas listas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _FieldLabel({required this.text, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SoftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const _SoftTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.outlineVariant),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(prefixIcon,
              color: colorScheme.onSurfaceVariant, size: 22),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:
              BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  const _PrimaryGradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary),
                    ),
                  )
                : Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: colorScheme.onPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  final ColorScheme colorScheme;

  const _AmbientBackground({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -120,
              child: _Glow(
                size: 320,
                color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              ),
            ),
            Positioned(
              bottom: -140,
              right: -140,
              child: _Glow(
                size: 360,
                color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}
