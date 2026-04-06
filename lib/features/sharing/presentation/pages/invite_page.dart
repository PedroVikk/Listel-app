import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/sharing_provider.dart';

class InvitePage extends ConsumerWidget {
  final String collectionRemoteId;
  final String collectionName;
  final String inviteCode;

  const InvitePage({
    super.key,
    required this.collectionRemoteId,
    required this.collectionName,
    required this.inviteCode,
  });

  String get _deepLink => 'listel://invite?code=$inviteCode';

  String get _shareText =>
      'Oi! Te convidei para a lista "$collectionName" no Listel 🛍️\n\n'
      'Código: $inviteCode\n\n'
      'Ou abre pelo link: $_deepLink';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Convidar para a lista')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Código de convite',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Código em destaque
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                inviteCode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                    ),
              ),
            ),
            const SizedBox(height: 16),

            // Copiar código
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado!')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar código'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Compartilhar via apps
            FilledButton.icon(
              onPressed: () => Share.share(_shareText),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartilhar convite'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),

            // Membros
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _MembersPreview(
                    collectionRemoteId: collectionRemoteId,
                    ref: ref,
                  ),
                ),
              ),
              icon: const Icon(Icons.people_outline),
              label: const Text('Ver membros'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersPreview extends ConsumerWidget {
  final String collectionRemoteId;
  final WidgetRef ref;
  const _MembersPreview(
      {required this.collectionRemoteId, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    final membersAsync = innerRef.watch(membersProvider(collectionRemoteId));
    return Scaffold(
      appBar: AppBar(title: const Text('Membros')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (members) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final m = members[i];
            return ListTile(
              leading: CircleAvatar(
                child: Text(m.displayName[0].toUpperCase()),
              ),
              title: Text(m.displayName),
              trailing: m.role.name == 'owner'
                  ? Chip(
                      label: const Text('Dono'),
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
