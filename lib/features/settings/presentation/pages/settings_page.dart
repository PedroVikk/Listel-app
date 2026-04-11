import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/app_icon_service.dart';

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
          padding: const EdgeInsets.all(16),
          children: [
            Text('Aparência',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 8),
            // Preview da cor atual
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: settings.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: settings.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: settings.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cor principal',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '#${settings.primaryColorValue.toRadixString(16).toUpperCase().substring(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () =>
                        _pickColor(context, ref, settings.primaryColor),
                    child: const Text('Trocar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modo de exibição',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Claro')),
                      ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('Auto')),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Escuro')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (sel) {
                      ref
                          .read(themeSettingsProvider.notifier)
                          .updateThemeMode(sel.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Ícone do app',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 12),
            _appIconPicker(),
            const SizedBox(height: 32),
            // Dedicatória
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text('', style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'O Seu app de listas de desejos',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Criado por Ines Gomides, Desenvolvido por Pedro Victor',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                        ),
                      ],
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

  Widget _appIconPicker() => Consumer(
        builder: (context, ref, _) {
          final iconAsync = ref.watch(appIconProvider);
          final activeId = iconAsync.valueOrNull ?? 'default';

          // Cores de fundo do preview — espelham o bg real de cada mipmap
          final previewColors = {
            'default': const Color(0xFFFFFFFF),
            'pink':    const Color(0xFFFFE4F2),
            'dark':    const Color(0xFF1A1A2E),
          };

          return SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppIconVariant.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final variant = AppIconVariant.all[i];
                final isSelected = variant.id == activeId;
                final color = previewColors[variant.id] ?? const Color(0xFFE91E8C);

                return GestureDetector(
                  onTap: () => ref.read(appIconProvider.notifier).setIcon(variant.id),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
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
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
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
        },
      );

  void _pickColor(BuildContext context, WidgetRef ref, Color current) {
    Color picked = current;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cor principal do app'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => picked = c,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(themeSettingsProvider.notifier)
                  .updatePrimaryColor(picked);
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
