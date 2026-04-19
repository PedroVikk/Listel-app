import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../collections/presentation/providers/collections_provider.dart';
import '../../../collections/domain/entities/collection.dart';
import '../../../items/presentation/providers/items_provider.dart';
import '../../../../core/services/metadata_extractor_service.dart';
import '../../../../core/theme/app_theme.dart';

class ShareReceivedPage extends ConsumerWidget {
  final Map<String, dynamic>? sharedData;
  const ShareReceivedPage({super.key, this.sharedData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SaveItemPage(sharedData: sharedData);
  }
}

class _SaveItemPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? sharedData;
  const _SaveItemPage({this.sharedData});

  @override
  ConsumerState<_SaveItemPage> createState() => _SaveItemPageState();
}

class _SaveItemPageState extends ConsumerState<_SaveItemPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  Collection? _selectedCollection;
  bool _saving = false;
  bool _loadingMeta = false;
  String? _extractedImageUrl;

  @override
  void initState() {
    super.initState();
    final raw = widget.sharedData?['rawText'] as String? ?? '';
    final url = widget.sharedData?['url'] as String? ?? '';
    if (raw.isNotEmpty && raw != url) {
      _nameController.text = raw.length > 80 ? raw.substring(0, 80) : raw;
    }
    if (url.isNotEmpty) _fetchMetadata(url);
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() => _loadingMeta = true);
    try {
      final meta = await metadataExtractor.extractFromUrl(url);
      if (!mounted) return;
      setState(() {
        if (meta.title != null && meta.title!.isNotEmpty) {
          _nameController.text = meta.title!;
        }
        if (meta.imageUrl != null) _extractedImageUrl = meta.imageUrl;
        if (meta.price != null && _priceController.text.isEmpty) {
          final cents = (meta.price! * 100).round();
          _priceController.text = _formatBrl(cents);
        }
      });
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  static String _formatBrl(int cents) {
    final reais = cents ~/ 100;
    final frac = (cents % 100).toString().padLeft(2, '0');
    final reaisStr = reais.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$reaisStr,$frac';
  }

  double? _parsePrice() {
    final raw =
        _priceController.text.replaceAll('.', '').replaceAll(',', '.');
    if (raw.trim().isEmpty) return null;
    return double.tryParse(raw);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_nameController.text.trim().isEmpty) return false;
    if (_selectedCollection == null) return false;
    if (_priceController.text.trim().isNotEmpty && _parsePrice() == null) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    try {
      final price = _parsePrice();
      await ref
          .read(itemsNotifierProvider(_selectedCollection!.id).notifier)
          .createFromShare(
            collectionId: _selectedCollection!.id,
            name: _nameController.text.trim(),
            url: widget.sharedData?['url'] as String?,
            imageUrl: _extractedImageUrl,
            price: price,
            store: widget.sharedData?['store'] as String?,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salvo em ${_selectedCollection!.name}'),
        ),
      );
      context.go('/');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = theme.extension<AppDesignTokens>()!;
    final localAsync = ref.watch(collectionsStreamProvider);
    final sharedAsync = ref.watch(sharedCollectionsStreamProvider);
    final collectionsAsync = localAsync.whenData(
      (local) => [
        ...local,
        ...(sharedAsync.valueOrNull ?? []),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Salvar produto'),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: colorScheme.primary),
            onPressed: _canSave && !_saving ? _save : null,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _PreviewImage(
                    loading: _loadingMeta,
                    imageUrl: _extractedImageUrl,
                    store: widget.sharedData?['store'] as String?,
                    tokens: tokens,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 24),
                  _label(context, 'Nome do produto'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Tênis Nike Air Max',
                      counterText: '',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 150,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _label(context, 'Preço (R\$)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    maxLength: 12,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _BrlCurrencyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      hintText: '0,00',
                      prefixText: 'R\$ ',
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  _label(context, 'Observações (opcional)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Tamanho, cor, observação rápida…',
                      counterText: '',
                    ),
                    maxLength: 200,
                    maxLines: 2,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  ),
                  const SizedBox(height: 20),
                  _label(context, 'Salvar em qual pasta?'),
                  const SizedBox(height: 12),
                  collectionsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erro ao carregar pastas: $e'),
                    data: (collections) {
                      if (collections.isEmpty) {
                        return Text(
                          'Nenhuma pasta criada. Crie uma pasta primeiro.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final col in collections)
                            _CollectionChip(
                              collection: col,
                              selected: _selectedCollection?.id == col.id,
                              onTap: () =>
                                  setState(() => _selectedCollection = col),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            _BottomSaveBar(
              enabled: _canSave && !_saving,
              saving: _saving,
              tokens: tokens,
              colorScheme: colorScheme,
              onPressed: _save,
              targetCollection: _selectedCollection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final bool loading;
  final String? imageUrl;
  final String? store;
  final AppDesignTokens tokens;
  final ColorScheme colorScheme;

  const _PreviewImage({
    required this.loading,
    required this.imageUrl,
    required this.store,
    required this.tokens,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Container(
              color: colorScheme.surfaceContainerHighest,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Icon(
                            Icons.image_not_supported_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 48,
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 48,
                          ),
                        ),
            ),
          ),
          if (store != null && store!.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 14, color: colorScheme.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      store!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  final Collection collection;
  final bool selected;
  final VoidCallback onTap;

  const _CollectionChip({
    required this.collection,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(collection.colorValue);
    final bg = selected ? color : theme.colorScheme.surfaceContainerHighest;
    final fg = selected
        ? ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black
        : theme.colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 18, color: fg),
                  const SizedBox(width: 6),
                ] else if (collection.emoji != null &&
                    collection.emoji!.isNotEmpty) ...[
                  Text(collection.emoji!),
                  const SizedBox(width: 6),
                ],
                Text(
                  collection.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
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

class _BottomSaveBar extends StatelessWidget {
  final bool enabled;
  final bool saving;
  final AppDesignTokens tokens;
  final ColorScheme colorScheme;
  final VoidCallback onPressed;
  final Collection? targetCollection;

  const _BottomSaveBar({
    required this.enabled,
    required this.saving,
    required this.tokens,
    required this.colorScheme,
    required this.onPressed,
    required this.targetCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: tokens.primaryGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: enabled ? tokens.tintedShadow : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: 56,
                child: Center(
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          targetCollection != null
                              ? 'Salvar em ${targetCollection!.emoji ?? ''} ${targetCollection!.name}'
                                  .trim()
                              : 'Selecione uma pasta',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrlCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final cents = int.parse(digits);
    final reais = cents ~/ 100;
    final frac = (cents % 100).toString().padLeft(2, '0');
    final reaisStr = reais.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final formatted = '$reaisStr,$frac';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
