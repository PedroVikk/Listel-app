import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wish_nesita/features/friends/domain/entities/friend_request.dart';
import 'package:wish_nesita/features/friends/presentation/providers/friends_provider.dart';

class FriendRequestCard extends ConsumerWidget {
  final FriendRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const FriendRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final friend = request.friend;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: friend.avatarUrl != null
                ? NetworkImage(friend.avatarUrl!)
                : null,
            backgroundColor: colorScheme.primaryContainer,
            child: friend.avatarUrl == null
                ? Text(
                    friend.initials,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Nome e descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quer adicionar você',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // Botões de ação
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão rejeitar
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    foregroundColor: colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    ref
                        .read(friendsNotifierProvider.notifier)
                        .rejectRequest(request.id)
                        .then((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Convite rejeitado')),
                        );
                      }
                    }).catchError((e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    });
                    onReject?.call();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Botão aceitar
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  onPressed: () {
                    ref
                        .read(friendsNotifierProvider.notifier)
                        .acceptRequest(request.id)
                        .then((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Amigo adicionado')),
                        );
                      }
                    }).catchError((e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    });
                    onAccept?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
