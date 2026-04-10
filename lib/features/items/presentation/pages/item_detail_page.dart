import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/items_provider.dart';
import '../providers/price_search_provider.dart';
import '../../../../core/services/price_search/price_source.dart';
import '../../domain/entities/saved_item.dart';
import '../../../collections/presentation/providers/collections_provider.dart';

// Provider que observa o item por id via stream — tenta local primeiro, depois remoto
final _itemByIdProvider = StreamProvider.family<SavedItem?, String>((ref, id) {
  final localRepo = ref.watch(itemsRepositoryProvider);
  final remoteRepo = ref.watch(remoteItemsRepositoryProvider);

  return Stream.fromFuture(localRepo.getById(id)).asyncExpand((localItem) {
    if (localItem != null) {
      return localRepo
          .watchByCollection(localItem.collectionId)
          .map((items) => items.where((i) => i.id == id).firstOrNull);
    }
    // Não encontrado localmente — tenta no Supabase
    return Stream.fromFuture(remoteRepo.getById(id)).asyncExpand((remoteItem) {
      if (remoteItem == null) return Stream.value(null);
      return remoteRepo
          .watchByCollection(remoteItem.collectionId)
          .map((items) => items.where((i) => i.id == id).firstOrNull);
    });
  });
});

class ItemDetailPage extends ConsumerWidget {
  final String itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(_itemByIdProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do item'),
        actions: [
          if (itemAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar item',
              onPressed: () {
                context.push('/item/${itemAsync.value!.id}/edit',
                    extra: itemAsync.value);
              },
            ),
          if (itemAsync.valueOrNull != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Excluir item'),
                    content:
                        const Text('Tem certeza que deseja excluir este item?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Excluir')),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final item = itemAsync.value!;
                  await ref
                      .read(itemsNotifierProvider(item.collectionId).notifier)
                      .delete(item.id);
                  if (context.mounted) context.pop();
                }
              },
            ),
        ],
      ),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Item não encontrado'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Imagem
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    height: 240,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SizedBox(
                        height: 240,
                        child: Center(child: CircularProgressIndicator())),
                    errorWidget: (_, _, _) =>
                        const SizedBox(height: 240, child: Placeholder()),
                  ),
                ),
              const SizedBox(height: 16),

              // Status badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isPurchased
                          ? Colors.green.withValues(alpha: 0.15)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isPurchased
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: item.isPurchased
                              ? Colors.green
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isPurchased ? 'Comprado' : 'Pendente',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: item.isPurchased
                                        ? Colors.green
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (item.store != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.store_outlined, size: 14),
                      label: Text(item.store!),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Nome
              Text(item.name,
                  style: Theme.of(context).textTheme.titleLarge),

              // Preço
              if (item.price != null) ...[
                const SizedBox(height: 8),
                Text(
                  'R\$ ${item.price!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],

              // Observações
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Observações',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(item.notes!),
              ],

              const SizedBox(height: 24),

              // Botões de ação
              if (item.url != null)
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(context, item.url!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver produto'),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref
                    .read(itemsNotifierProvider(item.collectionId).notifier)
                    .toggleStatus(item),
                icon: Icon(item.isPurchased
                    ? Icons.remove_shopping_cart_outlined
                    : Icons.check_circle_outline),
                label: Text(item.isPurchased
                    ? 'Marcar como pendente'
                    : 'Marcar como comprado'),
                style: item.isPurchased
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    _showMoveBottomSheet(context, ref, item),
                icon: const Icon(Icons.drive_file_move_outlined),
                label: const Text('Mover para outra lista'),
              ),
              if (item.price != null && item.name.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showPriceSearchBottomSheet(context, item),
                  icon: const Icon(Icons.search_outlined),
                  label: const Text('Buscar mais barato'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showMoveBottomSheet(
      BuildContext context, WidgetRef ref, SavedItem item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final local =
              ref.watch(collectionsStreamProvider).valueOrNull ?? [];
          final shared =
              ref.watch(sharedCollectionsStreamProvider).valueOrNull ?? [];
          final available = [...local, ...shared]
              .where((c) =>
                  c.id != item.collectionId &&
                  c.remoteId != item.collectionId)
              .toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Mover para',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma outra lista disponível.'),
                )
              else
                ...available.map((c) => ListTile(
                      leading: c.emoji != null
                          ? Text(c.emoji!,
                              style: const TextStyle(fontSize: 24))
                          : const Icon(Icons.folder_outlined),
                      title: Text(c.name),
                      trailing: c.isShared
                          ? const Icon(Icons.people_outline, size: 16)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final targetId = c.isShared
                            ? (c.remoteId ?? c.id)
                            : c.id;
                        await ref
                            .read(itemsNotifierProvider(item.collectionId)
                                .notifier)
                            .moveToCollection(item, targetId);
                        if (context.mounted) context.pop();
                      },
                    )),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _showPriceSearchBottomSheet(BuildContext context, SavedItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PriceSearchSheet(item: item),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL inválida')),
        );
      }
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    }
  }
}

class _PriceSearchSheet extends ConsumerStatefulWidget {
  final SavedItem item;
  const _PriceSearchSheet({required this.item});

  @override
  ConsumerState<_PriceSearchSheet> createState() => _PriceSearchSheetState();
}

class _PriceSearchSheetState extends ConsumerState<_PriceSearchSheet> {
  bool _showExternal = false;

  @override
  Widget build(BuildContext context) {
    final args = (name: widget.item.name, price: widget.item.price!);
    final phase1 = ref.watch(directPriceSearchProvider(args));
    final phase2 = _showExternal ? ref.watch(externalPriceSearchProvider(args)) : null;
    final hasExternal =
        ref.watch(priceSearchOrchestratorProvider).hasExternalSearch;

    final bool phase2Loading = _showExternal && (phase2?.isLoading ?? false);

    // Merge fase 1 + fase 2, deduplica por URL, ordena por preço.
    List<PriceAlternative> mergedResults(List<PriceAlternative> p1) {
      if (!_showExternal) return p1;
      final p2 = phase2?.valueOrNull ?? [];
      final seen = <String>{};
      return [...p1, ...p2]
          .where((r) => r.url.isNotEmpty && seen.add(r.url))
          .toList()
        ..sort((a, b) => a.price.compareTo(b.price));
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Alternativas mais baratas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'R\$ ${widget.item.price!.toStringAsFixed(2)} atual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: phase1.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Buscando no Mercado Livre...'),
                  ],
                ),
              ),
              error: (_, _) => const Center(
                child: Text('Erro ao buscar. Verifique sua conexão.'),
              ),
              data: (p1Results) {
                final results = mergedResults(p1Results);
                if (results.isEmpty) {
                  return _EmptyResults(
                    scrollController: scrollController,
                    showExternalButton: !_showExternal && hasExternal,
                    phase2Loading: phase2Loading,
                    externalTriggered: _showExternal,
                    onSearchMore: () => setState(() => _showExternal = true),
                  );
                }
                return _ResultsList(
                  results: results,
                  currentPrice: widget.item.price!,
                  scrollController: scrollController,
                  showExternalButton: !_showExternal && hasExternal,
                  phase2Loading: phase2Loading,
                  showDisclaimer: _showExternal && !phase2Loading,
                  onSearchMore: () => setState(() => _showExternal = true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<PriceAlternative> results;
  final double currentPrice;
  final ScrollController scrollController;
  final bool showExternalButton;
  final bool phase2Loading;
  final bool showDisclaimer;
  final VoidCallback onSearchMore;

  const _ResultsList({
    required this.results,
    required this.currentPrice,
    required this.scrollController,
    required this.showExternalButton,
    required this.phase2Loading,
    required this.showDisclaimer,
    required this.onSearchMore,
  });

  @override
  Widget build(BuildContext context) {
    final stores = results.map((r) => r.source).toSet();
    final storeLabel =
        stores.length == 1 ? stores.first : '${stores.length} lojas';

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${results.length} resultado${results.length == 1 ? '' : 's'} · $storeLabel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ...results.map((r) => _PriceResultTile(
              result: r,
              currentPrice: currentPrice,
            )),
        const Divider(height: 24),
        _SearchMoreButton(
          hasResults: true,
          showButton: showExternalButton,
          isLoading: phase2Loading,
          onPressed: onSearchMore,
        ),
        if (showDisclaimer)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Podem ser produtos similares, não o item exato',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final ScrollController scrollController;
  final bool showExternalButton;
  final bool phase2Loading;
  final bool externalTriggered;
  final VoidCallback onSearchMore;

  const _EmptyResults({
    required this.scrollController,
    required this.showExternalButton,
    required this.phase2Loading,
    required this.externalTriggered,
    required this.onSearchMore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        Icon(Icons.search_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(
          externalTriggered
              ? 'Nenhum resultado encontrado nas lojas pesquisadas.'
              : 'Nenhum resultado no Mercado Livre.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _SearchMoreButton(
          hasResults: false,
          showButton: showExternalButton,
          isLoading: phase2Loading,
          onPressed: onSearchMore,
        ),
      ],
    );
  }
}

class _PriceResultTile extends StatelessWidget {
  final PriceAlternative result;
  final double currentPrice;

  const _PriceResultTile({required this.result, required this.currentPrice});

  @override
  Widget build(BuildContext context) {
    final diff = result.percentDiff(currentPrice);
    final diffText = '${diff.toStringAsFixed(0)}%';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: result.thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                result.thumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              ),
            )
          : const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.shopping_bag_outlined),
            ),
      title: Text(
        result.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'R\$ ${result.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  diffText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          Text(
            result.source,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      trailing: TextButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(result.url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Abrir'),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      ),
    );
  }
}

class _SearchMoreButton extends StatelessWidget {
  final bool hasResults;
  final bool showButton;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SearchMoreButton({
    required this.hasResults,
    required this.showButton,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Buscando em mais lojas...'),
          ],
        ),
      );
    }
    if (!showButton) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.store_outlined),
        label: Text(
          hasResults
              ? 'Buscar em mais lojas →'
              : 'Buscar em Amazon, Americanas e outras →',
        ),
      ),
    );
  }
}
