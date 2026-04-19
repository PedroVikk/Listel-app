import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wish_nesita/features/friends/presentation/providers/friends_provider.dart';

class SearchField extends ConsumerWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
      },
      decoration: InputDecoration(
        hintText: 'Buscar por nome ou código...',
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
