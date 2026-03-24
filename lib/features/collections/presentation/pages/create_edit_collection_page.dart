import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/collections_provider.dart';

// Paleta de 24 cores para pastas
const _kCollectionColors = [
  Color(0xFFE91E8C), // Rosa
  Color(0xFFE53935), // Vermelho
  Color(0xFFD81B60), // Rosa escuro
  Color(0xFF8E24AA), // Roxo
  Color(0xFF5E35B1), // Roxo escuro
  Color(0xFF1E88E5), // Azul
  Color(0xFF039BE5), // Azul claro
  Color(0xFF00ACC1), // Ciano
  Color(0xFF00897B), // Teal
  Color(0xFF43A047), // Verde
  Color(0xFF7CB342), // Verde claro
  Color(0xFFC0CA33), // Lima
  Color(0xFFFDD835), // Amarelo
  Color(0xFFFFB300), // Âmbar
  Color(0xFFFB8C00), // Laranja
  Color(0xFFF4511E), // Laranja escuro
  Color(0xFF6D4C41), // Marrom
  Color(0xFF546E7A), // Azul acinzentado
  Color(0xFF757575), // Cinza
  Color(0xFF000000), // Preto
  Color(0xFFFFFFFF), // Branco
  Color(0xFFFF80AB), // Rosa pastel
  Color(0xFF80D8FF), // Azul pastel
  Color(0xFFCCFF90), // Verde pastel
];

class CreateEditCollectionPage extends ConsumerStatefulWidget {
  final String? collectionId;
  const CreateEditCollectionPage({super.key, this.collectionId});

  bool get isEditing => collectionId != null;

  @override
  ConsumerState<CreateEditCollectionPage> createState() =>
      _CreateEditCollectionPageState();
}

class _CreateEditCollectionPageState
    extends ConsumerState<CreateEditCollectionPage> {
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🛍️');
  Color _selectedColor = _kCollectionColors.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing =
        await ref.read(collectionsRepositoryProvider).getById(widget.collectionId!);
    if (existing != null && mounted) {
      setState(() {
        _nameController.text = existing.name;
        _emojiController.text = existing.emoji ?? '🛍️';
        _selectedColor = Color(existing.colorValue);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        final existing =
            await ref.read(collectionsRepositoryProvider).getById(widget.collectionId!);
        if (existing != null) {
          await ref
              .read(collectionsNotifierProvider.notifier)
              .updateCollection(existing.copyWith(
                name: _nameController.text.trim(),
                emoji: _emojiController.text.trim(),
                colorValue: _selectedColor.toARGB32(),
              ));
        }
      } else {
        await ref.read(collectionsNotifierProvider.notifier).create(
              name: _nameController.text.trim(),
              emoji: _emojiController.text.trim(),
              colorValue: _selectedColor.toARGB32(),
            );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar lista' : 'Nova lista'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Preview do card
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
                      ? '🛍️'
                      : _emojiController.text,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _nameController.text.isEmpty
                        ? 'Nome da lista'
                        : _nameController.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _selectedColor.computeLuminance() > 0.7
                              ? Colors.black87
                              : null,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da lista',
              hintText: 'Ex: Roupas, Eletrônicos...',
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('Cor da pasta',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          // Grade de cores
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
              final isSelected = _selectedColor.toARGB32() == color.toARGB32();
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
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.isEditing ? 'Salvar' : 'Criar lista'),
          ),
        ],
      ),
    );
  }
}
