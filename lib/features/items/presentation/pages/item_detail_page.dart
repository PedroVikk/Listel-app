import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/items_provider.dart';
import '../../domain/entities/saved_item.dart';

final _itemByIdProvider = FutureProvider.family<SavedItem?, String>((ref, id) {
  return ref.watch(itemsRepositoryProvider).getById(id);
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
          itemAsync.valueOrNull != null
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final item = itemAsync.value!;
                    await ref
                        .read(itemsNotifierProvider(item.collectionId).notifier)
                        .delete(item.id);
                    if (context.mounted) context.pop();
                  },
                )
              : const SizedBox.shrink(),
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
              Text(item.name, style: Theme.of(context).textTheme.titleLarge),
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
              if (item.store != null) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.store_outlined, size: 16),
                  label: Text(item.store!),
                ),
              ],
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Observações',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(item.notes!),
              ],
              if (item.url != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {/* TODO: launch url */},
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver produto'),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref
                    .read(itemsNotifierProvider(item.collectionId).notifier)
                    .toggleStatus(item),
                icon: Icon(item.isPurchased
                    ? Icons.remove_shopping_cart
                    : Icons.check),
                label: Text(item.isPurchased
                    ? 'Marcar como pendente'
                    : 'Marcar como comprado'),
              ),
            ],
          );
        },
      ),
    );
  }
}
