import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/collections_provider.dart';
import '../../../items/presentation/providers/items_provider.dart';

class CollectionDetailPage extends ConsumerWidget {
  final String collectionId;
  const CollectionDetailPage({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsStreamProvider);
    final itemsAsync = ref.watch(itemsByCollectionProvider(collectionId));

    final collection = collectionsAsync.valueOrNull
        ?.where((c) => c.id == collectionId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(collection?.name ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/collection/$collectionId/edit'),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Nenhum item ainda',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  onTap: () => context.push('/item/${item.id}'),
                  leading: item.imageUrl != null || item.localImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const SizedBox(width: 48, height: 48,
                              child: Placeholder()),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  title: Text(item.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: item.price != null
                      ? Text('R\$ ${item.price!.toStringAsFixed(2)}')
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      item.isPurchased
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: item.isPurchased
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () => ref
                        .read(itemsNotifierProvider(collectionId).notifier)
                        .toggleStatus(item),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.push('/collection/$collectionId/item/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
