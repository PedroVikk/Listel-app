import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/app_icon_service.dart';
import '../../../../core/router/app_routes.dart';

class _ColorOption {
  final Color color;
  final String name;
  _ColorOption({required this.color, required this.name});
}

final _colorPalette = [
  _ColorOption(color: const Color(0xFFE91E8C), name: 'Vermelho Morango'),
  _ColorOption(color: const Color(0xFF6366F1), name: 'Índigo'),
  _ColorOption(color: const Color(0xFF10B981), name: 'Verde Esmeralda'),
  _ColorOption(color: const Color(0xFFF59E0B), name: 'Âmbar'),
  _ColorOption(color: const Color(0xFF06B6D4), name: 'Ciano'),
  _ColorOption(color: const Color(0xFF8B5CF6), name: 'Violeta'),
];

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(themeSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Aparência
            _SectionLabel(label: 'Aparência'),
            const SizedBox(height: 16),
            _ColorPrimaryCard(settings: settings, ref: ref),
            const SizedBox(height: 16),
            _ThemeModeSelector(settings: settings, ref: ref),
            const SizedBox(height: 32),
            // Ícone do app
            _SectionLabel(label: 'Ícone do app'),
            const SizedBox(height: 16),
            const _AppIconPicker(),
            const SizedBox(height: 32),
            // Social
            _SectionLabel(label: 'Social'),
            const SizedBox(height: 16),
            const _FriendsButton(),
            const SizedBox(height: 32),
            // Sobre
            _SectionLabel(label: 'Sobre'),
            const SizedBox(height: 16),
            _AboutCard(),
            const SizedBox(height: 24),
            Text(
              '© 2026 Listel',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ColorPrimaryCard extends ConsumerWidget {
  final dynamic settings;
  final WidgetRef ref;

  const _ColorPrimaryCard({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorName = _colorPalette
        .firstWhere(
          (opt) => opt.color.toARGB32() == settings.primaryColorValue,
          orElse: () =>
              _ColorOption(color: settings.primaryColor, name: 'Personalizada'),
        )
        .name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: settings.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cor Principal',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  colorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _pickColor(context, ref, settings.primaryColor),
            child: const Text('Trocar'),
          ),
        ],
      ),
    );
  }

  void _pickColor(BuildContext context, WidgetRef ref, Color current) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Color picked = current;
          return AlertDialog(
            title: const Text('Cor principal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final opt in _colorPalette)
                        GestureDetector(
                          onTap: () => setState(() => picked = opt.color),
                          child: Tooltip(
                            message: opt.name,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: opt.color,
                                shape: BoxShape.circle,
                                border: picked.toARGB32() == opt.color.toARGB32()
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ColorPicker(
                    pickerColor: picked,
                    onColorChanged: (c) => setState(() => picked = c),
                    labelTypes: const [],
                    pickerAreaHeightPercent: 0.35,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(themeSettingsProvider.notifier).updatePrimaryColor(picked);
                  Navigator.pop(context);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeModeSelector extends ConsumerWidget {
  final dynamic settings;
  final WidgetRef ref;

  const _ThemeModeSelector({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = [
      (mode: ThemeMode.light, icon: Icons.light_mode_outlined, label: 'Light'),
      (mode: ThemeMode.system, icon: Icons.brightness_auto_outlined, label: 'Auto'),
      (mode: ThemeMode.dark, icon: Icons.dark_mode_outlined, label: 'Dark'),
    ];

    return Wrap(
      spacing: 8,
      children: [
        for (final item in modes)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _ThemeModeButton(
              mode: item.mode,
              icon: item.icon,
              label: item.label,
              isSelected: settings.themeMode == item.mode,
              onTap: () => ref
                  .read(themeSettingsProvider.notifier)
                  .updateThemeMode(item.mode),
            ),
          ),
      ],
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeButton({
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
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

class _AppIconPicker extends ConsumerWidget {
  const _AppIconPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconAsync = ref.watch(appIconProvider);
    final activeId = iconAsync.valueOrNull ?? 'default';

    final previewColors = {
      'default': const Color(0xFFFFFFFF),
      'pink': const Color(0xFFFFE4F2),
      'dark': const Color(0xFF1A1A2E),
    };

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppIconVariant.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final variant = AppIconVariant.all[i];
          final isSelected = variant.id == activeId;
          final color = previewColors[variant.id] ?? const Color(0xFFE91E8C);

          return GestureDetector(
            onTap: () => ref.read(appIconProvider.notifier).setIcon(variant.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : Border.all(color: Colors.transparent, width: 3),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  variant.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AboutCard extends StatefulWidget {
  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  String _version = 'carregando...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _AboutItem(
            icon: Icons.info_outlined,
            label: 'Versão',
            value: _version,
          ),
          Divider(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.2),
            height: 12,
          ),
          _AboutItem(
            icon: Icons.description_outlined,
            label: 'Termos',
            value: 'Abrir',
            onTap: () {},
          ),
          Divider(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.2),
            height: 12,
          ),
          _AboutItem(
            icon: Icons.shield_outlined,
            label: 'Privacidade',
            value: 'Abrir',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _AboutItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsButton extends StatelessWidget {
  const _FriendsButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => context.push(AppRoutes.friends),
      icon: const Icon(Icons.people_outline),
      label: const Text('Adicionar Amigos'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

