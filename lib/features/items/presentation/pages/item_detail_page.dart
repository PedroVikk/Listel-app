import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/items_provider.dart';
import '../../domain/entities/saved_item.dart';
import '../../../collections/presentation/providers/collections_provider.dart';
import '../../../collections/domain/entities/collection.dart';

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
