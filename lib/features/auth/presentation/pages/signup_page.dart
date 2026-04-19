import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

enum PasswordStrength { empty, weak, fair, good, strong }

class SignupPage extends ConsumerStatefulWidget {
  final String? redirectTo;

  const SignupPage({super.key, this.redirectTo});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  PasswordStrength _strength = PasswordStrength.empty;

  static final RegExp _usernameRegex = RegExp(r'^[a-z][a-z0-9_]{2,19}$');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    // Limpa qualquer SnackBar anterior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final newStrength = _evaluatePasswordStrength(_passwordController.text);
    if (newStrength != _strength) {
      setState(() => _strength = newStrength);
    }
  }

  PasswordStrength _evaluatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    if (password.length < 6) return PasswordStrength.weak;

    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    var score = 0;
    if (hasLetter) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    if (password.length >= 12) score++;

    switch (score) {
      case 0:
      case 1:
        return PasswordStrength.weak;
      case 2:
        return PasswordStrength.fair;
      case 3:
        return PasswordStrength.good;
      default:
        return PasswordStrength.strong;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
        username: _usernameController.text.trim().toLowerCase(),
      );

      if (mounted) context.go(widget.redirectTo ?? '/');
    } on AuthException catch (e) {
      if (!mounted) return;
      final isInfo = e.message.startsWith('Cadastro realizado!');
      _showMessage(e.message, isError: !isInfo);
      if (isInfo) context.go('/auth/login');
    } catch (_) {
      if (mounted) _showMessage('Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
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

  void _goToLogin() {
    final uri = widget.redirectTo != null
        ? '/auth/login?redirectTo=${Uri.encodeQueryComponent(widget.redirectTo!)}'
        : '/auth/login';
    context.go(uri);
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
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FieldLabel(
                                text: 'Nome completo',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 8),
                              _SoftTextField(
                                controller: _displayNameController,
                                hint: 'Seu nome',
                                prefixIcon: Icons.person_outline,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe seu nome';
                                  }
                                  if (v.trim().length > 100) {
                                    return 'Máximo 100 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _FieldLabel(
                                text: '@usuário',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 8),
                              _SoftTextField(
                                controller: _usernameController,
                                hint: 'seu_usuario',
                                prefixIcon: Icons.alternate_email,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  final value =
                                      v?.trim().toLowerCase() ?? '';
                                  if (value.isEmpty) {
                                    return 'Informe seu @usuário';
                                  }
                                  if (!_usernameRegex.hasMatch(value)) {
                                    return '3-20 chars, letras/números/_, começa com letra';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _FieldLabel(
                                text: 'E-mail',
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 8),
                              _SoftTextField(
                                controller: _emailController,
                                hint: 'seu@email.com',
                                prefixIcon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe seu e-mail';
                                  }
                                  final email = v.trim();
                                  final re = RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!re.hasMatch(email)) {
                                    return 'E-mail inválido';
                                  }
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
                                hint: '••••••••',
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
                                    return 'Informe a senha';
                                  }
                                  if (v.length < 6) {
                                    return 'Mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              if (_strength != PasswordStrength.empty) ...[
                                const SizedBox(height: 10),
                                _StrengthMeter(
                                  strength: _strength,
                                  colorScheme: colorScheme,
                                ),
                              ],
                              const SizedBox(height: 24),
                              _PrimaryGradientButton(
                                label: 'Criar conta',
                                loading: _loading,
                                colorScheme: colorScheme,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Já tem uma conta?',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _loading ? null : _goToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                            ),
                            child: Text(
                              'Entrar',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
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
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            height: 1,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Criar conta',
          style: GoogleFonts.plusJakartaSans(
            color: colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Junte-se a nos e comece a suas listas de desejo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.4,
            ),
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
          color: colorScheme.onSurface,
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
  final TextCapitalization textCapitalization;
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
    this.textCapitalization = TextCapitalization.none,
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
      textCapitalization: textCapitalization,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
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

class _StrengthMeter extends StatelessWidget {
  final PasswordStrength strength;
  final ColorScheme colorScheme;

  const _StrengthMeter({required this.strength, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final (label, fraction, color) = switch (strength) {
      PasswordStrength.empty => ('', 0.0, colorScheme.outlineVariant),
      PasswordStrength.weak => (
          'Fraca',
          0.25,
          colorScheme.error,
        ),
      PasswordStrength.fair => (
          'Razoável',
          0.5,
          Colors.orange,
        ),
      PasswordStrength.good => (
          'Boa',
          0.75,
          Colors.lightGreen.shade700,
        ),
      PasswordStrength.strong => (
          'Forte',
          1.0,
          Colors.green.shade700,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
