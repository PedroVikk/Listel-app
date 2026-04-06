import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/sharing_provider.dart';

class CreateSharedCollectionPage extends ConsumerStatefulWidget {
  const CreateSharedCollectionPage({super.key});

  @override
  ConsumerState<CreateSharedCollectionPage> createState() =>
      _CreateSharedCollectionPageState();
}

class _CreateSharedCollectionPageState
    extends ConsumerState<CreateSharedCollectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _emoji;
  Color _color = const Color(0xFF6750A4);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      if (!(_formKey.currentState?.validate() ?? false)) return;

      final collection = await ref
          .read(sharingNotifierProvider.notifier)
          .createSharedCollection(
            name: _nameController.text.trim(),
            emoji: _emoji,
            colorValue: _color.toARGB32(),
          );

      if (mounted) {
        context.go('/collection/${collection.remoteId}');
      }
    } catch (e, st) {
      debugPrint('ERRO ao criar lista compartilhada: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cor da lista'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _color,
            onColorChanged: (c) => setState(() => _color = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sharingState = ref.watch(sharingNotifierProvider);
    final loading = sharingState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova lista compartilhada'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_tethering_outlined,
                      color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta lista será sincronizada em tempo real com quem você convidar.',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emoji
            Center(
              child: GestureDetector(
                onTap: _pickEmoji,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _emoji ?? '🛍️',
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Toque para mudar o emoji',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, fontSize: 12)),
            ),
            const SizedBox(height: 24),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome da lista',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 16),

            // Cor
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cor'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(backgroundColor: _color, radius: 16),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _pickColor,
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Criar lista compartilhada'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickEmoji() {
    const emojis = [
      '🛍️','🎁','👗','💄','👟','📱','💻','🏠','🛋️','🎮',
      '📚','🍕','✈️','💍','🎵','🌸','⚽','🧸','🎨','🏋️',
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => GridView.count(
        crossAxisCount: 6,
        padding: const EdgeInsets.all(16),
        children: emojis
            .map((e) => GestureDetector(
                  onTap: () {
                    setState(() => _emoji = e);
                    Navigator.pop(context);
                  },
                  child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 28))),
                ))
            .toList(),
      ),
    );
  }
}
