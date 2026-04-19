import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/items_provider.dart';
import '../providers/price_search_provider.dart';
import '../../../../core/services/price_search/price_source.dart';
import '../../../../core/theme/app_theme.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do item'),
        actions: [
          if (itemAsync.valueOrNull != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar item',
              onPressed: () {
                context.push('/item/${itemAsync.value!.id}/edit',
                    extra: itemAsync.value);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: Material(
                color: colorScheme.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _confirmDelete(context, ref, itemAsync.value!),
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(Icons.delete_outline,
                        color: colorScheme.onError, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: itemAsync.when(
        loading: () => _buildSkeleton(context),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Item não encontrado'));
          }
          return _DetailBody(item: item);
        },
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        const SizedBox(height: 24),
        Container(
            height: 28,
            width: 240,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 12),
        Container(
            height: 16,
            width: 120,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
      ],
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, SavedItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir item'),
        content: const Text('Tem certeza que deseja excluir este item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(itemsNotifierProvider(item.collectionId).notifier)
          .delete(item.id);
      if (context.mounted) context.pop();
    }
  }

}

class _DetailBody extends ConsumerWidget {
  final SavedItem item;
  const _DetailBody({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _ImageCard(item: item, tokens: tokens, colorScheme: colorScheme),
        const SizedBox(height: 24),

        Text(
          item.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
        ),

        if (item.price != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'R\$ ${item.price!.toStringAsFixed(2).replaceAll('.', ',')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],

        if (item.notes != null && item.notes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _NotesCard(notes: item.notes!, colorScheme: colorScheme, tokens: tokens),
        ],

        if (item.addedBy != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Adicionado por ${item.addedBy}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 28),

        _PrimaryToggleButton(item: item, tokens: tokens, colorScheme: colorScheme),
        const SizedBox(height: 12),
        Row(
          children: [
            if (item.url != null) ...[
              Expanded(
                child: _PillOutlined(
                  icon: Icons.open_in_new,
                  label: 'Ver produto',
                  onTap: () => _launchProductUrl(context, item.url!),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _PillOutlined(
                icon: Icons.swap_horiz,
                label: 'Mover lista',
                onTap: () => _showMoveBottomSheet(context, ref, item),
              ),
            ),
          ],
        ),
        if (item.price != null && item.name.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PillOutlined(
            icon: Icons.search_outlined,
            label: 'Buscar mais barato',
            onTap: () => _showPriceSearchBottomSheet(context, item),
          ),
        ],
      ],
    );
  }

  Future<void> _launchProductUrl(BuildContext context, String url) async {
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

  void _showMoveBottomSheet(
      BuildContext context, WidgetRef ref, SavedItem item) {
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(tokens.radiusLg)),
      ),
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

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Mover para',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
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
                          final targetId =
                              c.isShared ? (c.remoteId ?? c.id) : c.id;
                          await ref
                              .read(itemsNotifierProvider(item.collectionId)
                                  .notifier)
                              .moveToCollection(item, targetId);
                          if (context.mounted) context.pop();
                        },
                      )),
                const SizedBox(height: 16),
              ],
            ),
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
}

class _ImageCard extends StatelessWidget {
  final SavedItem item;
  final AppDesignTokens tokens;
  final ColorScheme colorScheme;
  const _ImageCard(
      {required this.item, required this.tokens, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        item.imageUrl != null || (item.localImagePath?.isNotEmpty ?? false);
    return Hero(
      tag: 'item-image-${item.id}',
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          child: Container(
            height: 260,
            color: colorScheme.surfaceContainerHighest,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, _, _) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 56,
                        color: colorScheme.onSurfaceVariant),
                  )
                else if (item.localImagePath?.isNotEmpty ?? false)
                  Image.file(File(item.localImagePath!), fit: BoxFit.cover)
                else
                  Center(
                    child: Icon(Icons.image_outlined,
                        size: 64, color: colorScheme.onSurfaceVariant),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _StatusBadge(isPurchased: item.isPurchased),
                ),
                if (item.store != null)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _StoreBadge(store: item.store!),
                  ),
                if (!hasImage)
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPurchased;
  const _StatusBadge({required this.isPurchased});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isPurchased ? Colors.green.shade600 : colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        isPurchased ? 'COMPRADO' : 'PENDENTE',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  final String store;
  const _StoreBadge({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.store_outlined, size: 14, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            store,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  final ColorScheme colorScheme;
  final AppDesignTokens tokens;
  const _NotesCard(
      {required this.notes,
      required this.colorScheme,
      required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Observações',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryToggleButton extends ConsumerWidget {
  final SavedItem item;
  final AppDesignTokens tokens;
  final ColorScheme colorScheme;
  const _PrimaryToggleButton(
      {required this.item, required this.tokens, required this.colorScheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchased = item.isPurchased;
    final label =
        purchased ? 'Marcar como pendente' : 'Marcar como comprado';
    final icon = purchased
        ? Icons.remove_shopping_cart_outlined
        : Icons.check_circle_outline;

    final decoration = purchased
        ? BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          )
        : BoxDecoration(
            gradient: tokens.primaryGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: tokens.tintedShadow,
          );
    final fg = purchased ? colorScheme.onSurface : Colors.white;

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => ref
              .read(itemsNotifierProvider(item.collectionId).notifier)
              .toggleStatus(item),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillOutlined extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillOutlined(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
