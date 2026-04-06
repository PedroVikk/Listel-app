import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../collections/presentation/providers/collections_provider.dart';
import '../../../collections/domain/entities/collection.dart';
import '../../../items/presentation/providers/items_provider.dart';
import '../../../../core/services/metadata_extractor_service.dart';

/// Tela intermediária que exibe o bottom sheet de salvamento rápido.
/// Ao fechar, retorna para a home.
class ShareReceivedPage extends ConsumerWidget {
  final Map<String, dynamic>? sharedData;
  const ShareReceivedPage({super.key, this.sharedData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Exibe o bottom sheet logo que a tela monta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _showSaveSheet(context, ref, sharedData);
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  static Future<void> _showSaveSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? data,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SaveItemSheet(sharedData: data),
    );

    if (context.mounted) {
      context.go('/');
    }
  }
}

class _SaveItemSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? sharedData;
  const _SaveItemSheet({this.sharedData});

  @override
  ConsumerState<_SaveItemSheet> createState() => _SaveItemSheetState();
}

class _SaveItemSheetState extends ConsumerState<_SaveItemSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  Collection? _selectedCollection;
  bool _saving = false;

  // Metadata extraction state
  bool _loadingMeta = false;
  String? _extractedImageUrl;

  @override
  void initState() {
    super.initState();
    final raw = widget.sharedData?['rawText'] as String? ?? '';
    final url = widget.sharedData?['url'] as String? ?? '';
    if (raw.isNotEmpty && raw != url) {
      _nameController.text = raw.length > 80 ? raw.substring(0, 80) : raw;
    }

    // Extrai metadados Open Graph se houver URL
    if (url.isNotEmpty) {
      _fetchMetadata(url);
    }
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() => _loadingMeta = true);
    try {
      final meta = await metadataExtractor.extractFromUrl(url);
      if (!mounted) return;
      setState(() {
        if (meta.title != null && meta.title!.isNotEmpty) {
          _nameController.text = meta.title!;
        }
        if (meta.imageUrl != null) {
          _extractedImageUrl = meta.imageUrl;
        }
        if (meta.price != null && _priceController.text.isEmpty) {
          _priceController.text = meta.price!.toStringAsFixed(2);
        }
      });
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma pasta primeiro')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para o produto')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final price = double.tryParse(
          _priceController.text.replaceAll(',', '.'));
      await ref
          .read(itemsNotifierProvider(_selectedCollection!.id).notifier)
          .createFromShare(
            collectionId: _selectedCollection!.id,
            name: _nameController.text.trim(),
            url: widget.sharedData?['url'] as String?,
            imageUrl: _extractedImageUrl,
            price: price,
            store: widget.sharedData?['store'] as String?,
          );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localAsync = ref.watch(collectionsStreamProvider);
    final sharedAsync = ref.watch(sharedCollectionsStreamProvider);

    // Mescla locais + compartilhadas numa única AsyncValue
    final collectionsAsync = localAsync.whenData(
      (local) => [
        ...local,
        ...(sharedAsync.valueOrNull ?? []),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Salvar produto',
                style: Theme.of(context).textTheme.titleLarge),
          ),

          // Imagem extraída via Open Graph
          if (_loadingMeta)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: LinearProgressIndicator(),
            )
          else if (_extractedImageUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _extractedImageUrl!,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator())),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),

          // URL preview
          if (widget.sharedData?['url'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (widget.sharedData?['store'] != null) ...[
                      Chip(
                        label: Text(widget.sharedData!['store'] as String,
                            style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        widget.sharedData!['url'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Nome do produto
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do produto *',
                hintText: 'Ex: Tênis Nike Air Max',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              maxLength: 150,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
            ),
          ),

          // Preço
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preço (R\$)',
                hintText: '0,00',
                prefixText: 'R\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              maxLength: 12,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
            ),
          ),

          // Escolha de pasta
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Salvar em qual pasta?',
                style: Theme.of(context).textTheme.labelLarge),
          ),
          collectionsAsync.when(
            loading: () =>
                const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erro ao carregar pastas: $e'),
            ),
            data: (collections) {
              if (collections.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    'Nenhuma pasta criada. Crie uma pasta primeiro.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              return SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemCount: collections.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    final isSelected = _selectedCollection?.id == col.id;
                    final color = Color(col.colorValue);
                    return ChoiceChip(
                      label: Text('${col.emoji ?? ''} ${col.name}'),
                      selected: isSelected,
                      selectedColor: color.withValues(alpha: 0.25),
                      side: isSelected
                          ? BorderSide(color: color, width: 2)
                          : null,
                      onSelected: (_) =>
                          setState(() => _selectedCollection = col),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Botão salvar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bookmark_add_outlined),
              label: const Text('Salvar produto'),
            ),
          ),
        ],
      ),
    );
  }
}
