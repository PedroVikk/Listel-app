import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/sharing_provider.dart';
import '../../../auth/domain/entities/collection_member.dart';

class MembersPage extends ConsumerWidget {
  final String collectionRemoteId;

  const MembersPage({super.key, required this.collectionRemoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final membersAsync = ref.watch(membersProvider(collectionRemoteId));

    return Scaffold(
      appBar: AppBar(title: const Text('Membros')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('Nenhum membro encontrado'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = members[i];
              return _MemberTile(
                member: m,
                collectionRemoteId: collectionRemoteId,
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => _confirmLeave(context, ref),
            icon: Icon(Icons.exit_to_app, color: colorScheme.error),
            label: Text('Sair da lista',
                style: TextStyle(color: colorScheme.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: colorScheme.error),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da lista'),
        content: const Text(
            'Se você for o dono, a lista e todos os itens serão excluídos para todos os membros. Deseja continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(sharingNotifierProvider.notifier)
          .leaveCollection(collectionRemoteId);
      if (context.mounted) context.go('/');
    }
  }
}

class _MemberTile extends StatelessWidget {
  final CollectionMember member;
  final String collectionRemoteId;

  const _MemberTile(
      {required this.member, required this.collectionRemoteId});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          member.displayName[0].toUpperCase(),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
      ),
      title: Text(member.displayName),
      trailing: member.role == MemberRole.owner
          ? Chip(
              label: const Text('Dono'),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }
}
