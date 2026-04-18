import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  void _editAvatarDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Avatar'),
        content: const Text('Escolha uma foto da sua galeria'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final picker = ImagePicker();
              final pickedFile =
                  await picker.pickImage(source: ImageSource.gallery);

              if (pickedFile != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enviando avatar...')),
                );

                try {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.uploadAvatarAndUpdate(pickedFile.path);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Avatar atualizado com sucesso!')),
                    );
                    ref.invalidate(userProfileProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Selecionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Erro: $err'),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Não autenticado'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 24),
              // Avatar section
              _AvatarSection(
                avatarUrl: profile.user.avatarUrl,
                displayName: profile.user.displayName,
                onEditPressed: () =>
                    _editAvatarDialog(context, ref),
              ),
              const SizedBox(height: 24),
              // User info section
              _UserInfoSection(
                displayName: profile.user.displayName,
                username: profile.user.username,
              ),
              const SizedBox(height: 32),
              // Stats section
              _StatsSection(
                collectionsCount: profile.collectionsCount,
                itemsCount: profile.itemsCount,
                friendsCount: profile.friendsCount,
              ),
              const SizedBox(height: 32),
              // Action cards grid
              _ActionCardsGrid(
                notificationsCount: 0,
                onMyListsTap: () => context.go('/collections'),
                onFriendsTap: () => context.go('/friends'),
                onNotificationsTap: () => context.go('/notifications'),
                onSettingsTap: () => context.go('/settings'),
              ),
              const SizedBox(height: 32),
              // Logout button
              _LogoutButton(
                onLogoutPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      await ref
                          .read(authRepositoryProvider)
                          .signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// COMPONENTS
// ============================================================================

class _AvatarSection extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final VoidCallback onEditPressed;

  const _AvatarSection({
    required this.avatarUrl,
    required this.displayName,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditPressed,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.error,
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfoSection extends StatelessWidget {
  final String displayName;
  final String? username;

  const _UserInfoSection({
    required this.displayName,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          if (username != null) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int collectionsCount;
  final int itemsCount;
  final int friendsCount;

  const _StatsSection({
    required this.collectionsCount,
    required this.itemsCount,
    required this.friendsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(label: 'LISTAS', count: collectionsCount),
        _StatCard(label: 'ITENS', count: itemsCount),
        _StatCard(label: 'AMIGOS', count: friendsCount),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;

  const _StatCard({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCardsGrid extends StatelessWidget {
  final int notificationsCount;
  final VoidCallback onMyListsTap;
  final VoidCallback onFriendsTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;

  const _ActionCardsGrid({
    required this.notificationsCount,
    required this.onMyListsTap,
    required this.onFriendsTap,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _ActionCard(
          icon: Icons.menu_rounded,
          label: 'Minhas Listas',
          subtitle: 'Gerencie suas curadorias',
          backgroundColor: Colors.pink.shade100,
          onTap: onMyListsTap,
        ),
        _ActionCard(
          icon: Icons.people_alt,
          label: 'Amigos',
          backgroundColor: Colors.indigo.shade100,
          onTap: onFriendsTap,
        ),
        _ActionCard(
          icon: Icons.notifications,
          label: 'Notificações',
          badge: notificationsCount > 0 ? notificationsCount : null,
          onTap: onNotificationsTap,
        ),
        _ActionCard(
          icon: Icons.settings,
          label: 'Configurações',
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? backgroundColor;
  final int? badge;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.backgroundColor,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    child: Icon(icon, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  child: Text(
                    badge.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (trailing != null)
              Positioned(
                right: 8,
                top: 50,
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogoutPressed;

  const _LogoutButton({required this.onLogoutPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      onPressed: onLogoutPressed,
      child: const Text('Sair da Conta'),
    );
  }
}
