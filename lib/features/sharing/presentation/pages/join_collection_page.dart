import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/sharing_provider.dart';

class JoinCollectionPage extends ConsumerStatefulWidget {
  /// Código pré-preenchido quando vindo de deep link.
  final String? code;
  const JoinCollectionPage({super.key, this.code});

  @override
  ConsumerState<JoinCollectionPage> createState() => _JoinCollectionPageState();
}

class _JoinCollectionPageState extends ConsumerState<JoinCollectionPage> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      _controller.text = widget.code!;
      // Auto-submit quando vem por deep link
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final collection = await ref
          .read(sharingNotifierProvider.notifier)
          .joinByInviteCode(_controller.text.trim());

      if (mounted) {
        context.pushReplacement('/collection/${collection.remoteId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loading = ref.watch(sharingNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar em uma lista')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.group_add_outlined, size: 64, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Insira o código de convite',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Peça para o dono da lista te enviar o código de 8 letras.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: 8,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                decoration: InputDecoration(
                  hintText: 'XXXXXXXX',
                  hintStyle: TextStyle(
                    letterSpacing: 8,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 8) {
                    return 'Código deve ter 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Entrar na lista'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
