import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/items_provider.dart';
import '../../domain/entities/saved_item.dart';

class EditItemPage extends ConsumerStatefulWidget {
  final SavedItem item;
  const EditItemPage({super.key, required this.item});

  @override
  ConsumerState<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends ConsumerState<EditItemPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _linkController;
  late final TextEditingController _notesController;

  /// Novo caminho local escolhido pelo usuário (substitui a imagem atual).
  String? _newLocalImagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item.name);
    _priceController = TextEditingController(
      text: item.price != null
          ? item.price!.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _linkController = TextEditingController(text: item.url ?? '');
    _notesController = TextEditingController(text: item.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) setState(() => _newLocalImagePath = file.path);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final priceText = _priceController.text.replaceAll(',', '.').trim();
      final price = priceText.isEmpty ? null : double.tryParse(priceText);
      final url = _linkController.text.trim();
      final notes = _notesController.text.trim();

      final updated = SavedItem(
        id: widget.item.id,
        collectionId: widget.item.collectionId,
        name: _nameController.text.trim(),
        url: url.isEmpty ? null : url,
        price: price,
        notes: notes.isEmpty ? null : notes,
        imageUrl: _newLocalImagePath != null ? null : widget.item.imageUrl,
        localImagePath: _newLocalImagePath ?? widget.item.localImagePath,
        store: widget.item.store,
        status: widget.item.status,
        source: widget.item.source,
        createdAt: widget.item.createdAt,
        updatedAt: DateTime.now(),
        addedBy: widget.item.addedBy,
        purchasedBy: widget.item.purchasedBy,
      );

      await ref
          .read(itemsNotifierProvider(widget.item.collectionId).notifier)
          .updateItem(updated);

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasNewImage = _newLocalImagePath != null;
    final hasNetworkImage = item.imageUrl != null && !hasNewImage;
    final hasLocalImage = item.localImagePath != null && !hasNewImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar item')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Foto
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: hasNewImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_newLocalImagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : hasNetworkImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                            placeholder: (_, _) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (_, _, _) =>
                                const Center(child: Icon(Icons.broken_image)),
                          ),
                        )
                      : hasLocalImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(item.localImagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
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
          if (hasNetworkImage || hasLocalImage || hasNewImage)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Trocar foto'),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
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
            decoration: const InputDecoration(
                labelText: 'Preço (R\$)', hintText: '0,00'),
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
                : const Text('Salvar alterações'),
          ),
        ],
      ),
    );
  }
}
