import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show
        FilteringTextInputFormatter,
        MaxLengthEnforcement,
        TextInputFormatter,
        TextEditingValue;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/items_provider.dart';
import '../../../../core/services/print_scanner_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Formata entrada numérica como moeda BRL em tempo real (ex: "1234" → "12,34";
/// "12345" → "123,45"). Trabalha em centavos: cada dígito desloca a vírgula.
class _BrlCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final cents = int.parse(digits);
    final reais = cents ~/ 100;
    final frac = (cents % 100).toString().padLeft(2, '0');
    final reaisStr = reais
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final formatted = '$reaisStr,$frac';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CreateItemPage extends ConsumerStatefulWidget {
  final String collectionId;
  const CreateItemPage({super.key, required this.collectionId});

  @override
  ConsumerState<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends ConsumerState<CreateItemPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  final _notesController = TextEditingController();
  String? _localImagePath;
  bool _saving = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onChanged);
    _priceController.addListener(_onChanged);
    _linkController.addListener(_onChanged);
    _notesController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parsePrice() {
    final raw =
        _priceController.text.replaceAll('.', '').replaceAll(',', '.');
    if (raw.trim().isEmpty) return null;
    return double.tryParse(raw);
  }

  bool get _canSave {
    if (_nameController.text.trim().isEmpty) return false;
    if (_priceController.text.trim().isNotEmpty && _parsePrice() == null) {
      return false;
    }
    final link = _linkController.text.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || !uri.hasAuthority) return false;
    }
    return true;
  }

  void _showPhotoOptions() {
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(tokens.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('Escanear print'),
              subtitle: const Text('Detecta nome e preço automaticamente'),
              onTap: () {
                Navigator.pop(ctx);
                _scanPrint();
              },
            ),
            if (_localImagePath != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Remover foto',
                    style:
                        TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _localImagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file != null) setState(() => _localImagePath = file.path);
  }

  Future<void> _scanPrint() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _localImagePath = file.path;
      _scanning = true;
    });

    try {
      final result = await PrintScannerService().scan(file.path);
      if (!mounted) return;

      if (result.name != null && _nameController.text.trim().isEmpty) {
        _nameController.text = result.name!;
      }
      if (result.price != null && _priceController.text.trim().isEmpty) {
        _priceController.text =
            result.price!.toStringAsFixed(2).replaceAll('.', ',');
      }
      if (result.name == null && result.price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível detectar texto no print.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final price = _parsePrice();
      final link = _linkController.text.trim();
      await ref
          .read(itemsNotifierProvider(widget.collectionId).notifier)
          .createManual(
            collectionId: widget.collectionId,
            name: _nameController.text.trim(),
            localImagePath: _localImagePath,
            url: link.isEmpty ? null : link,
            price: price,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppDesignTokens>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar item')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(child: _photoPicker(colorScheme, tokens)),
                    const SizedBox(height: 32),
                    _labeledField(
                      label: 'Nome do item',
                      required: true,
                      controller: _nameController,
                      maxLength: 150,
                      child: TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 150,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Câmera Retro',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _labeledField(
                      label: 'Preço (R\$)',
                      controller: _priceController,
                      maxLength: 12,
                      child: TextField(
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
                      ),
                    ),
                    const SizedBox(height: 20),
                    _labeledField(
                      label: 'Link',
                      controller: _linkController,
                      maxLength: 500,
                      child: TextField(
                        controller: _linkController,
                        keyboardType: TextInputType.url,
                        maxLength: 500,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        decoration: const InputDecoration(
                          hintText: 'https://',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _labeledField(
                      label: 'Observações',
                      controller: _notesController,
                      maxLength: 500,
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        minLines: 4,
                        maxLength: 500,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        decoration: const InputDecoration(
                          hintText: 'Detalhes de cor, tamanho...',
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomActionBar(tokens, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _photoPicker(ColorScheme colorScheme, AppDesignTokens tokens) {
    final hasImage = _localImagePath != null;
    return GestureDetector(
      onTap: _scanning ? null : _showPhotoOptions,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: _scanning
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.file(File(_localImagePath!), fit: BoxFit.cover),
                  Container(
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 8),
                        Text('Detectando...',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              )
            : hasImage
                ? Image.file(File(_localImagePath!), fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 36, color: colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        'Adicionar foto',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    required int maxLength,
    required Widget child,
    bool required = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Row(
            children: [
              Text.rich(
                TextSpan(
                  text: label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                  children: required
                      ? [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ]
                      : null,
                ),
              ),
              const Spacer(),
              Text(
                '${controller.text.characters.length}/$maxLength',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _bottomActionBar(AppDesignTokens tokens, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Opacity(
        opacity: (_canSave && !_saving && !_scanning) ? 1.0 : 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: tokens.primaryGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: tokens.tintedShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: (_canSave && !_saving && !_scanning) ? _save : null,
              child: SizedBox(
                height: 56,
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Salvar item',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
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
