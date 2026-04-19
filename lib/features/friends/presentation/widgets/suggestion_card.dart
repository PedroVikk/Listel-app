import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wish_nesita/features/friends/domain/entities/suggestion.dart';
import 'package:wish_nesita/features/friends/presentation/providers/friends_provider.dart';

class SuggestionCard extends ConsumerStatefulWidget {
  final Suggestion suggestion;

  const SuggestionCard({
    super.key,
    required this.suggestion,
  });

  @override
  ConsumerState<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<SuggestionCard> {
  bool _isRequesting = false;
  bool _requestSent = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final friend = widget.suggestion.friend;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: friend.avatarUrl != null
                ? NetworkImage(friend.avatarUrl!)
                : null,
            backgroundColor: colorScheme.surfaceContainerHigh,
            child: friend.avatarUrl == null
                ? Text(
                    friend.initials,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
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
                  widget.suggestion.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

          // Botão Adicionar
          SizedBox(
            height: 36,
            child: _requestSent
                ? Chip(
                    label: const Text('Solicitação enviada'),
                    side: BorderSide(color: colorScheme.primary),
                  )
                : FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _isRequesting ? null : _sendRequest,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Adicionar'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _isRequesting = true);

    try {
      await ref
          .read(friendsNotifierProvider.notifier)
          .sendFriendRequest(widget.suggestion.friend.id);

      setState(() {
        _requestSent = true;
        _isRequesting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada')),
        );
      }
    } catch (e) {
      setState(() => _isRequesting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}
