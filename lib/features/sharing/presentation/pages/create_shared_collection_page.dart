import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/sharing_provider.dart';

const _kCollectionColors = [
  Color(0xFFE91E8C),
  Color(0xFFE53935),
  Color(0xFFD81B60),
  Color(0xFF8E24AA),
  Color(0xFF5E35B1),
  Color(0xFF1E88E5),
  Color(0xFF039BE5),
  Color(0xFF00ACC1),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF7CB342),
  Color(0xFFC0CA33),
  Color(0xFFFDD835),
  Color(0xFFFFB300),
  Color(0xFFFB8C00),
  Color(0xFFF4511E),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
  Color(0xFF757575),
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFF80AB),
  Color(0xFF80D8FF),
  Color(0xFFCCFF90),
];

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
  final _emojiController = TextEditingController();
  Color _selectedColor = _kCollectionColors.first;

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      if (!(_formKey.currentState?.validate() ?? false)) return;

      final emoji = _emojiController.text.trim();
      final collection = await ref
          .read(sharingNotifierProvider.notifier)
          .createSharedCollection(
            name: _nameController.text.trim(),
            emoji: emoji.isEmpty ? null : emoji,
            colorValue: _selectedColor.toARGB32(),
          );

      if (mounted) {
        context.pushReplacement(
          '/collection/${collection.remoteId}',
          extra: collection,
        );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sharingState = ref.watch(sharingNotifierProvider);
    final loading = sharingState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova lista compartilhada')),
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
                  Icon(Icons.wifi_tethering_outlined, color: colorScheme.primary),
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

            // Preview
            Text('Visualização', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _selectedColor.withValues(alpha: 0.4), width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    _emojiController.text.isEmpty
                        ? 'Use um Emoji'
                        : _emojiController.text,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _nameController.text.isEmpty
                          ? 'Nome da lista'
                          : _nameController.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emoji
            TextField(
              controller: _emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: '🛍️',
              ),
              maxLength: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                hintText: 'Ex: Roupas, Eletrônicos...',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 24),

            // Cor
            Text('Cor da pasta', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _kCollectionColors.length,
              itemBuilder: (context, index) {
                final color = _kCollectionColors[index];
                final isSelected =
                    _selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check,
                            size: 16,
                            color: color.computeLuminance() > 0.7
                                ? Colors.black
                                : Colors.white)
                        : null,
                  ),
                );
              },
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
}
