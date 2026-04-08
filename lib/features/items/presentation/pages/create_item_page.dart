import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/items_provider.dart';

class CreateItemPage extends ConsumerStatefulWidget {
  final String collectionId;
  const CreateItemPage({super.key, required this.collectionId});

  @override
  ConsumerState<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends ConsumerState<CreateItemPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  final _notesController = TextEditingController();
  String? _localImagePath;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _localImagePath = file.path);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final price = double.tryParse(
          _priceController.text.replaceAll(',', '.'));
      final link = _linkController.text.trim();
      await ref
          .read(itemsNotifierProvider(widget.collectionId).notifier)
          .createManual(
            collectionId: widget.collectionId,
            name: _nameController.text.trim(),
            localImagePath: _localImagePath,
            url: link.isEmpty ? null : link,
            price: price,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar item')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Foto
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _localImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(_localImagePath!), fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Adicionar foto',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                )),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome do item *'),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 150,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration:
                const InputDecoration(labelText: 'Preço (R\$)', hintText: '0,00'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            maxLength: 12,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkController,
            decoration: const InputDecoration(
                labelText: 'Link', hintText: 'https://...'),
            keyboardType: TextInputType.url,
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
                labelText: 'Observações', hintText: 'Opcional...'),
            maxLines: 3,
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar item'),
          ),
        ],
      ),
    );
  }
}
