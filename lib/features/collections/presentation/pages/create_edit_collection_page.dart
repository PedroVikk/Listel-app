import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../providers/collections_provider.dart';

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
  Color _selectedColor = const Color(0xFFE91E8C);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final collections =
        await ref.read(collectionsRepositoryProvider).getAll();
    final existing =
        collections.where((c) => c.id == widget.collectionId).firstOrNull;
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
        final repo = ref.read(collectionsRepositoryProvider);
        final existing = await repo.getById(widget.collectionId!);
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

  void _pickColor() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escolha uma cor'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (c) => setState(() => _selectedColor = c),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar lista' : 'Nova lista'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _emojiController,
            decoration: const InputDecoration(
              labelText: 'Emoji',
              hintText: '🛍️',
            ),
            maxLength: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da lista',
              hintText: 'Ex: Roupas, Eletrônicos...',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Cor:'),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _pickColor,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                ),
              ),
            ],
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
