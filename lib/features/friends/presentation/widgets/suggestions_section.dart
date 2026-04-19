import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wish_nesita/features/friends/domain/entities/suggestion.dart';
import 'package:wish_nesita/features/friends/presentation/providers/friends_provider.dart';
import 'package:wish_nesita/features/friends/presentation/widgets/suggestion_card.dart';

class SuggestionsSection extends ConsumerWidget {
  final List<Suggestion> suggestions;

  const SuggestionsSection({
    super.key,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredSuggestions = ref.watch(filteredSuggestionsProvider);
    final friendsState = ref.watch(friendsNotifierProvider).valueOrNull;
    final isLoadingMore = friendsState?.isLoadingMore ?? false;

    if (filteredSuggestions.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma sugestão encontrada',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sugestões de amigos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredSuggestions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return SuggestionCard(suggestion: filteredSuggestions[index]);
          },
        ),
        const SizedBox(height: 16),
        if (!isLoadingMore)
          OutlinedButton.icon(
            onPressed: () {
              ref.read(friendsNotifierProvider.notifier).loadMoreSuggestions();
            },
            icon: const Icon(Icons.expand_more),
            label: const Text('Ver mais sugestões'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          Center(
            child: SizedBox(
              height: 40,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }
}
