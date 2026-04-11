import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/collection.dart';
import '../providers/collections_provider.dart';
import '../../../items/domain/entities/saved_item.dart';
import '../../../items/presentation/providers/items_provider.dart';
import '../../../items/presentation/providers/list_view_mode_provider.dart';
import '../../../sharing/presentation/pages/invite_page.dart';

class CollectionDetailPage extends ConsumerWidget {
  final String collectionId;
  final Collection? initialCollection;
  const CollectionDetailPage({
    super.key,
    required this.collectionId,
    this.initialCollection,
  });

  // ── helpers ──────────────────────────────────────────────────────────────

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
        if (item.store != null) buffer.write(' (${item.store})');
        buffer.writeln();
        if (item.url != null) buffer.writeln('  ${item.url}');
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

    Share.share(buffer.toString().trim());
  }

  Widget _buildImage(SavedItem item, ColorScheme cs,
      {BoxFit fit = BoxFit.cover}) {
    Widget fallback() => Container(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.shopping_bag_outlined,
                color: cs.onSurfaceVariant, size: 32),
          ),
        );
    if (item.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => fallback(),
        errorWidget: (_, _, _) => fallback(),
      );
    } else if (item.localImagePath != null) {
      return Image.file(
        File(item.localImagePath!),
        fit: fit,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return fallback();
  }

  Widget _priceChip(double price, BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'R\$ ${price.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );

  Widget _statusToggle(
    BuildContext context,
    WidgetRef ref,
    SavedItem item,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ref
            .read(itemsNotifierProvider(collectionId).notifier)
            .toggleStatus(item),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            item.isPurchased
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: Colors.white54,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _purchasedOverlay() => Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: const Center(
          child: Icon(Icons.check_circle_outline,
              color: Colors.white, size: 40),
        ),
      );

  // ── view modes ───────────────────────────────────────────────────────────

  /// Galeria — 2 colunas, imagem + chip de preço + nome + toggle status
  Widget _buildGaleria(
      BuildContext context, WidgetRef ref, List<SavedItem> items, ColorScheme cs) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.70,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => context.push('/item/${item.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(item, cs),
                      if (item.isPurchased) _purchasedOverlay(),
                      if (item.price != null)
                        Positioned(
                            top: 8,
                            left: 8,
                            child: _priceChip(item.price!, context)),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: _statusToggle(context, ref, item),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shopping — 2 colunas, só foto + preço sobreposto (sem nome)
  Widget _buildShopping(
      BuildContext context, WidgetRef ref, List<SavedItem> items, ColorScheme cs) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => context.push('/item/${item.id}'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(item, cs),
                if (item.isPurchased) _purchasedOverlay(),
                // Gradient + preço na parte de baixo
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.72),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: item.price != null
                        ? Text(
                            'R\$ ${item.price!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: _statusToggle(context, ref, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Vitrine — 3 colunas, só fotos (zero texto)
  Widget _buildVitrine(
      BuildContext context, WidgetRef ref, List<SavedItem> items, ColorScheme cs) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.80,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 14,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: cs.surfaceContainerHighest,
              child: InkWell(
                onTap: () => context.push('/item/${item.id}'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(item, cs),
                    // Gradiente suave no topo para o check ficar legível
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (item.isPurchased)
                      Container(
                        color: Colors.black.withValues(alpha: 0.32),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _statusToggle(context, ref, item),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsStreamProvider);
    final itemsAsync = ref.watch(itemsByCollectionProvider(collectionId));
    final viewMode = ref.watch(listViewModeProvider);
    final cs = Theme.of(context).colorScheme;

    // Snackbar ao mudar de modo
    ref.listen<ListViewMode>(listViewModeProvider, (_, mode) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('${mode.emoji} Modo ${mode.label} ativado'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
    });

    final local = collectionsAsync.valueOrNull ?? [];
    final shared =
        ref.watch(sharedCollectionsStreamProvider).valueOrNull ?? [];
    final collection = local.where((c) => c.id == collectionId).firstOrNull ??
        shared
            .where((c) => c.remoteId == collectionId || c.id == collectionId)
            .firstOrNull ??
        initialCollection;

    return Scaffold(
      appBar: AppBar(
        title: Text(collection?.name ?? ''),
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
        actions: [
          if (collection?.isShared == true && collection?.inviteCode != null)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Convidar',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvitePage(
                    collectionRemoteId: collection!.remoteId!,
                    collectionName: collection.name,
                    inviteCode: collection.inviteCode!,
                  ),
                ),
              ),
            ),
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
          // Botão de modo de visualização (câmera) — cicla entre Galeria, Shopping, Vitrine
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Modo: ${viewMode.label}',
            onPressed: () => ref.read(listViewModeProvider.notifier).state =
                viewMode.next,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/collection/$collectionId/edit'),
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
                      size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('Nenhum item ainda',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return switch (viewMode) {
            ListViewMode.galeria => _buildGaleria(context, ref, items, cs),
            ListViewMode.shopping => _buildShopping(context, ref, items, cs),
            ListViewMode.vitrine => _buildVitrine(context, ref, items, cs),
          };
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
