import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../collections/presentation/providers/collections_provider.dart';
import '../../../items/presentation/providers/items_provider.dart';

class ShareReceivedPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? sharedData;
  const ShareReceivedPage({super.key, this.sharedData});

  @override
  ConsumerState<ShareReceivedPage> createState() => _ShareReceivedPageState();
}

class _ShareReceivedPageState extends ConsumerState<ShareReceivedPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCollectionId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final url = widget.sharedData?['url'] as String?;
    if (url != null) _nameController.text = url;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCollectionId == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma lista e informe o nome')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final price = double.tryParse(
          _priceController.text.replaceAll(',', '.'));
      await ref
          .read(itemsNotifierProvider(_selectedCollectionId!).notifier)
          .createFromShare(
            collectionId: _selectedCollectionId!,
            name: _nameController.text.trim(),
            url: widget.sharedData?['url'] as String?,
            price: price,
            store: widget.sharedData?['store'] as String?,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item salvo!')),
        );
        context.go('/');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Salvar produto')),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (collections) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.sharedData?['url'] != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.sharedData!['url'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do produto *'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                  labelText: 'Preço (R\$)', hintText: '0,00'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            if (widget.sharedData?['store'] != null)
              Chip(
                avatar: const Icon(Icons.store_outlined, size: 16),
                label: Text(widget.sharedData!['store'] as String),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCollectionId,
              decoration: const InputDecoration(labelText: 'Salvar em *'),
              items: collections
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.emoji ?? ''} ${c.name}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCollectionId = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                  labelText: 'Observações', hintText: 'Opcional...'),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar produto'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
