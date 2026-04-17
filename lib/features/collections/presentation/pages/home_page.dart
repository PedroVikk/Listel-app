import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/collections_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../collections/domain/entities/collection.dart';
import '../../../sharing/presentation/providers/sharing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _showProfileSheet(BuildContext context, WidgetRef ref,
      String displayName, String email) {
    final initials = displayName.trim().split(' ').where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase()).take(2).join();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor:
                  Theme.of(ctx).colorScheme.primaryContainer,
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(displayName,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(email,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(ctx).colorScheme.errorContainer,
                foregroundColor:
                    Theme.of(ctx).colorScheme.onErrorContainer,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref
                    .read(authRepositoryProvider)
                    .signOut();
              },
              child: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localAsync = ref.watch(collectionsStreamProvider);
    final sharedAsync = ref.watch(sharedCollectionsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isLoggedIn = currentUser != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(isLoggedIn
              ? Icons.account_circle
              : Icons.account_circle_outlined),
          onPressed: () {
            if (isLoggedIn) {
              _showProfileSheet(context, ref, currentUser.displayName,
                  currentUser.email);
            } else {
              context.push(AppRoutes.login);
            }
          },
        ),
        title: const Text('Minhas Listas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: localAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (local) {
          final shared = sharedAsync.valueOrNull ?? [];
          final hasAnything = local.isNotEmpty || shared.isNotEmpty;

          if (!hasAnything) {
            return _EmptyState(isLoggedIn: isLoggedIn);
          }

          return CustomScrollView(
            slivers: [
              if (local.isNotEmpty) ...[
                const _SectionHeader(title: 'Minhas listas'),
                _CollectionGrid(collections: local, isShared: false),
              ],
              if (shared.isNotEmpty) ...[
                const _SectionHeader(title: 'Listas compartilhadas'),
                _CollectionGrid(collections: shared, isShared: true),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              context.push(AppRoutes.search);
            case 2:
              context.push(AppRoutes.settings);
            case 3:
              final user = currentUser;
              if (user != null) {
                _showProfileSheet(
                    context, ref, user.displayName, user.email);
              } else {
                context.push(AppRoutes.login);
              }
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Config.',
          ),
          NavigationDestination(
            icon: Icon(isLoggedIn
                ? Icons.account_circle
                : Icons.account_circle_outlined),
            label: isLoggedIn ? 'Perfil' : 'Entrar',
          ),
        ],
      ),
      floatingActionButton: _HomeFab(
        onCreateLocal: () => context.push(AppRoutes.createCollection),
        onCreateShared: () => isLoggedIn
            ? context.push(AppRoutes.createSharedCollection)
            : context.push(
                '${AppRoutes.login}?redirectTo=${AppRoutes.createSharedCollection}'),
        onJoin: () => isLoggedIn
            ? context.push(AppRoutes.sharedJoin)
            : context.push(
                '${AppRoutes.login}?redirectTo=${AppRoutes.sharedJoin}'),
      ),
    );
  }
}

// ─── FAB expandível ──────────────────────────────────────────────────────────

class _HomeFab extends StatefulWidget {
  final VoidCallback onCreateLocal;
  final VoidCallback onCreateShared;
  final VoidCallback onJoin;

  const _HomeFab({
    required this.onCreateLocal,
    required this.onCreateShared,
    required this.onJoin,
  });

  @override
  State<_HomeFab> createState() => _HomeFabState();
}

class _HomeFabState extends State<_HomeFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  void _close() {
    setState(() => _expanded = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          FadeTransition(
            opacity: _fade,
            child: _MiniAction(
              icon: Icons.group_add_outlined,
              label: 'Entrar com código',
              onTap: () {
                _close();
                widget.onJoin();
              },
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fade,
            child: _MiniAction(
              icon: Icons.wifi_tethering_outlined,
              label: 'Nova lista compartilhada',
              onTap: () {
                _close();
                widget.onCreateShared();
              },
            ),
          ),
          const SizedBox(height: 8),
          FadeTransition(
            opacity: _fade,
            child: _MiniAction(
              icon: Icons.add_circle_outline,
              label: 'Nova lista local',
              onTap: () {
                _close();
                widget.onCreateLocal();
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: label,
            onPressed: onTap,
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            child: Icon(icon),
          ),
        ],
      ),
    );
  }
}

// ─── Seção e Grid ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}

class _CollectionGrid extends StatelessWidget {
  final List<Collection> collections;
  final bool isShared;

  const _CollectionGrid({required this.collections, required this.isShared});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final collection = collections[index];
            final navId = isShared
                ? (collection.remoteId ?? collection.id)
                : collection.id;
            return _CollectionCard(
              collection: collection,
              navId: navId,
              isShared: isShared,
            );
          },
          childCount: collections.length,
        ),
      ),
    );
  }
}

class _CollectionCard extends ConsumerWidget {
  final Collection collection;
  final String navId;
  final bool isShared;

  const _CollectionCard({
    required this.collection,
    required this.navId,
    required this.isShared,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isShared ? 'Remover lista' : 'Excluir lista'),
        content: Text(
          isShared
              ? 'Se você for o dono, a lista será excluída para todos os membros. Caso contrário, você apenas sairá dela.'
              : 'Tem certeza? Todos os itens da lista serão excluídos permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isShared ? 'Remover' : 'Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (isShared) {
      final remoteId = collection.remoteId;
      if (remoteId == null) return;
      await ref.read(sharingNotifierProvider.notifier).leaveCollection(remoteId);
    } else {
      await ref.read(collectionsNotifierProvider.notifier).delete(collection.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(collection.colorValue);
    final lum = color.computeLuminance();
    final isVeryDark = lum < 0.05;
    final textColor = collection.coverImagePath != null
        ? Colors.white
        : (lum > 0.5 ? Colors.black87 : Colors.white);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/collection/$navId'),
        onLongPress: () => _confirmDelete(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isVeryDark ? color : null,
            gradient: isVeryDark
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.black, 0.2)!],
                  ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (collection.coverImagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(collection.coverImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.45, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (collection.coverImagePath == null)
                          Text(
                            collection.emoji ??
                                (collection.name.isNotEmpty
                                    ? collection.name[0].toUpperCase()
                                    : '?'),
                            style: TextStyle(
                              fontSize: 28,
                              color:
                                  collection.emoji == null ? textColor : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const Spacer(),
                        if (isShared)
                          Icon(Icons.wifi_tethering,
                              size: 16,
                              color: textColor.withValues(alpha: 0.7)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      collection.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isLoggedIn;
  const _EmptyState({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.collections_bookmark_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Nenhuma lista ainda',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Crie sua primeira lista para organizar seus desejos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
