import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/settings_provider.dart';

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
            ListTile(
              title: const Text('Cor principal'),
              subtitle: const Text('Personaliza o tema do app'),
              trailing: GestureDetector(
                onTap: () => _pickColor(context, ref, settings.primaryColor),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: settings.primaryColor,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('Tema'),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('Sistema')),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Claro')),
                  DropdownMenuItem(
                      value: ThemeMode.dark, child: Text('Escuro')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    ref
                        .read(themeSettingsNotifierProvider.notifier)
                        .updateThemeMode(mode);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickColor(BuildContext context, WidgetRef ref, Color current) {
    Color picked = current;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escolha a cor principal'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => picked = c,
            labelTypes: const [],
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
                  .read(themeSettingsNotifierProvider.notifier)
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
