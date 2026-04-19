import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wish_nesita/features/friends/presentation/providers/friends_provider.dart';
import 'package:wish_nesita/features/friends/presentation/widgets/search_field.dart';
import 'package:wish_nesita/features/friends/presentation/widgets/pending_invites_section.dart';
import 'package:wish_nesita/features/friends/presentation/widgets/suggestions_section.dart';

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Amigos'),
        centerTitle: true,
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildError(context, error),
        data: (data) => _buildContent(context, ref, data),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar amigos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // Refresh
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, data) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const SearchField(),
            const SizedBox(height: 32),
            PendingInvitesSection(requests: data.pendingRequests),
            const SizedBox(height: 32),
            SuggestionsSection(suggestions: data.suggestions),
          ],
        ),
      ),
    );
  }
}
