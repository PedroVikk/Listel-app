import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/collections_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../collections/domain/entities/collection.dart';
import '../../../sharing/presentation/providers/sharing_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localAsync = ref.watch(collectionsStreamProvider);
    final sharedAsync = ref.watch(sharedCollectionsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isLoggedIn = currentUser != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: _GlassAppBar(
        isLoggedIn: isLoggedIn,
        onProfileTap: () {
          if (isLoggedIn) {
            context.push(AppRoutes.profile);
          } else {
            context.push(AppRoutes.login);
          }
        },
        onSearch: () => context.push(AppRoutes.search),
        onSettings: () => context.push(AppRoutes.settings),
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
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
              if (local.isNotEmpty) ...[
                const _SectionHeader(
                    title: 'Minhas listas', subtitle: 'Coleções pessoais'),
                _CollectionGrid(collections: local, isShared: false),
              ],
              if (shared.isNotEmpty) ...[
                const _SectionHeader(
                    title: 'Compartilhadas',
                    subtitle: 'Listas em que você participa'),
                _CollectionGrid(collections: shared, isShared: true),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          );
        },
      ),
      bottomNavigationBar: _GlassNavBar(
        isLoggedIn: isLoggedIn,
        onSearch: () => context.push(AppRoutes.search),
        onSettings: () => context.push(AppRoutes.settings),
        onProfile: () {
          if (isLoggedIn) {
            context.push(AppRoutes.profile);
          } else {
            context.push(AppRoutes.login);
          }
        },
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

// ─── AppBar Glassmorphism ─────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoggedIn;
  final VoidCallback onProfileTap;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  const _GlassAppBar({
    required this.isLoggedIn,
    required this.onProfileTap,
    required this.onSearch,
    required this.onSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: tokens.glassBlur, sigmaY: tokens.glassBlur),
        child: AppBar(
          backgroundColor: colorScheme.surface
              .withValues(alpha: tokens.glassOpacity),
          leading: IconButton(
            icon: Icon(isLoggedIn
                ? Icons.account_circle
                : Icons.account_circle_outlined),
            onPressed: onProfileTap,
          ),
          title: Text(
            'Listel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: onSearch,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NavigationBar Glassmorphism ──────────────────────────────────────────────

class _GlassNavBar extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  const _GlassNavBar({
    required this.isLoggedIn,
    required this.onSearch,
    required this.onSettings,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: tokens.glassBlur, sigmaY: tokens.glassBlur),
        child: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            switch (index) {
              case 1:
                onSearch();
              case 2:
                onSettings();
              case 3:
                onProfile();
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
      ),
    );
  }
}

// ─── FAB expandível com gradiente primary ─────────────────────────────────────

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

// ─── Section header editorial ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: colorScheme.onSurface,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Grid e Cards (tonal layering) ────────────────────────────────────────────

class _CollectionGrid extends StatelessWidget {
  final List<Collection> collections;
  final bool isShared;

  const _CollectionGrid(
      {required this.collections, required this.isShared});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
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
      await ref
          .read(sharingNotifierProvider.notifier)
          .leaveCollection(remoteId);
    } else {
      await ref
          .read(collectionsNotifierProvider.notifier)
          .delete(collection.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;
    final color = Color(collection.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        boxShadow: tokens.tintedShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: InkWell(
          onTap: () => context.push('/collection/$navId'),
          onLongPress: () => _confirmDelete(context, ref),
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CardThumbnail(
                    collection: collection,
                    color: color,
                    radius: tokens.radiusMd,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (isShared) ...[
                            Icon(Icons.wifi_tethering,
                                size: 12,
                                color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Compartilhada',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ] else
                            Text(
                              'Pessoal',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
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

class _CardThumbnail extends StatelessWidget {
  final Collection collection;
  final Color color;
  final double radius;

  const _CardThumbnail({
    required this.collection,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final lum = color.computeLuminance();
    final textColor = lum > 0.5 ? Colors.black87 : Colors.white;
    final hasImage = collection.coverImagePath != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.file(
              File(collection.coverImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _colorBlock(),
            )
          else
            _colorBlock(),
          if (!hasImage)
            Center(
              child: Text(
                collection.emoji ??
                    (collection.name.isNotEmpty
                        ? collection.name[0].toUpperCase()
                        : '?'),
                style: TextStyle(
                  fontSize: 44,
                  color: collection.emoji == null ? textColor : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _colorBlock() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.85),
              Color.lerp(color, Colors.black, 0.15)!,
            ],
          ),
        ),
      );
}

// ─── Empty state editorial ────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isLoggedIn;
  const _EmptyState({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(tokens.radiusXl),
              ),
              child: Icon(
                Icons.collections_bookmark_outlined,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Sua galeria\nestá esperando',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: colorScheme.onSurface,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crie sua primeira lista para começar seus desejos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
