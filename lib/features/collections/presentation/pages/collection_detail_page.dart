import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/collections_provider.dart';
import '../../../items/domain/entities/saved_item.dart';
import '../../../items/presentation/providers/items_provider.dart';

class CollectionDetailPage extends ConsumerWidget {
  final String collectionId;
  const CollectionDetailPage({super.key, required this.collectionId});

  void _shareList(
      BuildContext context, String collectionName, List<SavedItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Lista de desejos: $collectionName');
    buffer.writeln('');

    final pending = items.where((i) => !i.isPurchased).toList();
    final purchased = items.where((i) => i.isPurchased).toList();

    void writeItems(List<SavedItem> list) {
      for (final item in list) {
        buffer.write('• ${item.name}');
        if (item.price != null) {
          buffer.write(' — R\$ ${item.price!.toStringAsFixed(2)}');
        }
        if (item.store != null) {
          buffer.write(' (${item.store})');
        }
        buffer.writeln();
        if (item.url != null) {
          buffer.writeln('  ${item.url}');
        }
      }
    }

    if (pending.isNotEmpty) {
      buffer.writeln('Pendentes (${pending.length}):');
      writeItems(pending);
    }

    if (purchased.isNotEmpty) {
      if (pending.isNotEmpty) buffer.writeln('');
      buffer.writeln('Comprados (${purchased.length}):');
      writeItems(purchased);
    }

    SharePlus.instance.share(ShareParams(text: buffer.toString().trim()));
  }

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
          if (itemsAsync.valueOrNull?.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Compartilhar lista',
              onPressed: () => _shareList(
                context,
                collection?.name ?? '',
                itemsAsync.valueOrNull ?? [],
              ),
            ),
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
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const ColoredBox(
                                  color: Colors.transparent,
                                  child: Center(
                                      child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)))),
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.shopping_bag_outlined),
                            )
                          : item.localImagePath != null
                              ? Image.file(File(item.localImagePath!),
                                  fit: BoxFit.cover)
                              : const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
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
