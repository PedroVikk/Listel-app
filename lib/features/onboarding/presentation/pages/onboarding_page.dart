import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/router/app_routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _current = 0;

  static const _total = 4;

  void _next() {
    if (_current < _total - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    await OnboardingService.markSeen();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: _current < _total - 1
                  ? TextButton(
                      onPressed: _skip,
                      child: const Text('Pular'),
                    )
                  : const SizedBox(height: 48),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                children: const [
                  _OnboardingStep(
                    illustration: _WelcomeIllustration(),
                    svgPath: 'assets/images/onboarding_1.png.svg',
                    title: 'Bem-vindo ao Listel',
                    description:
                        'Seus desejos em um só lugar. Organize produtos das suas lojas favoritas com facilidade.',
                  ),
                  _OnboardingStep(
                    illustration: _ListsIllustration(),
                    svgPath: 'assets/images/onboarding_2.png.svg',
                    title: 'Crie listas coloridas',
                    description:
                        'Organize por categorias: Roupas, Eletrônicos, Casa e muito mais. Cada lista tem sua cor e emoji.',
                  ),
                  _OnboardingStep(
                    illustration: _AddItemIllustration(),
                    svgPath: 'assets/images/onboarding_3.png.svg',
                    title: 'Adicione produtos',
                    description:
                        'Salve manualmente ou cole uma URL — o Listel busca foto, nome e preço automaticamente.',
                  ),
                  _OnboardingStep(
                    illustration: _ShareIllustration(),
                    svgPath: 'assets/images/onboarding_share.png.svg',
                    title: 'Compartilhe de qualquer loja',
                    description:
                        'Na Shopee, Shein, Mercado Livre ou Amazon: toque em Compartilhar, escolha o Listel e o produto é salvo na hora!',
                  ),
                ],
              ),
            ),

            // Dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _total,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _current ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _current
                          ? colors.primary
                          : colors.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _current == _total - 1 ? 'Começar' : 'Próximo',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step container ─────────────────────────────────────────────────────────

class _OnboardingStep extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;
  final String? svgPath;

  const _OnboardingStep({
    required this.illustration,
    required this.title,
    required this.description,
    this.svgPath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 260,
            child: svgPath != null
                ? SvgPicture.asset(
                    svgPath!,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => illustration,
                  )
                : illustration,
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Illustrations ──────────────────────────────────────────────────────────

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text('🛍️', style: TextStyle(fontSize: 80)),
        ),
      ),
    );
  }
}

class _ListsIllustration extends StatelessWidget {
  const _ListsIllustration();

  static const _folders = [
    ('👗', Color(0xFFE91E8C), 'Roupas'),
    ('📱', Color(0xFF2196F3), 'Eletrônicos'),
    ('🏠', Color(0xFF4CAF50), 'Casa'),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _folders.map((f) {
          final (emoji, color, label) = f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, 0.2)!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AddItemIllustration extends StatelessWidget {
  const _AddItemIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('👟', style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 10, width: 140,
                decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 6),
            Container(height: 10, width: 80,
                decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(5))),
          ],
        ),
      ),
    );
  }
}

class _ShareIllustration extends StatelessWidget {
  const _ShareIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Store app icon
          _AppIcon(emoji: '🛒', color: const Color(0xFFEE4D2D), label: 'Loja'),
          _Arrow(color: colors.outlineVariant),
          // Share icon
          _AppIcon(
              emoji: '↗️', color: colors.surfaceContainerHighest, label: 'Compartilhar'),
          _Arrow(color: colors.outlineVariant),
          // Listel icon
          _AppIcon(emoji: '🛍️', color: colors.primary, label: 'Listel',
              textColor: colors.onPrimary),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final String emoji;
  final Color color;
  final String label;
  final Color? textColor;
  const _AppIcon({
    required this.emoji,
    required this.color,
    required this.label,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final Color color;
  const _Arrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
      child: Icon(Icons.arrow_forward_rounded, color: color, size: 20),
    );
  }
}
