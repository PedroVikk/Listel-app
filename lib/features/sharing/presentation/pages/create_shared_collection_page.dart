import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/sharing_provider.dart';

const _kCollectionColors = [
  Color(0xFFE91E8C),
  Color(0xFFE53935),
  Color(0xFFD81B60),
  Color(0xFF8E24AA),
  Color(0xFF5E35B1),
  Color(0xFF1E88E5),
  Color(0xFF039BE5),
  Color(0xFF00ACC1),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF7CB342),
  Color(0xFFC0CA33),
  Color(0xFFFDD835),
  Color(0xFFFFB300),
  Color(0xFFFB8C00),
  Color(0xFFF4511E),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
  Color(0xFF757575),
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFF80AB),
  Color(0xFF80D8FF),
  Color(0xFFCCFF90),
];

class CreateSharedCollectionPage extends ConsumerStatefulWidget {
  const CreateSharedCollectionPage({super.key});

  @override
  ConsumerState<CreateSharedCollectionPage> createState() =>
      _CreateSharedCollectionPageState();
}

class _CreateSharedCollectionPageState
    extends ConsumerState<CreateSharedCollectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = _kCollectionColors.first;
  String? _coverImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null || !mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto de capa',
          toolbarColor: colorScheme.surface,
          toolbarWidgetColor: colorScheme.onSurface,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: colorScheme.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${docsDir.path}/collection_covers');
    await coversDir.create(recursive: true);

    final srcPath = cropped.path;
    final dotIndex = srcPath.lastIndexOf('.');
    final ext = dotIndex != -1 ? srcPath.substring(dotIndex) : '.jpg';
    final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = '${coversDir.path}/$fileName';
    await File(srcPath).copy(destPath);

    if (_coverImagePath != null && _coverImagePath != destPath) {
      final old = File(_coverImagePath!);
      if (await old.exists()) await old.delete();
    }

    setState(() => _coverImagePath = destPath);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (_coverImagePath != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('Remover foto',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _coverImagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    try {
      if (!(_formKey.currentState?.validate() ?? false)) return;

      final collection = await ref
          .read(sharingNotifierProvider.notifier)
          .createSharedCollection(
            name: _nameController.text.trim(),
            colorValue: _selectedColor.toARGB32(),
            coverImagePath: _coverImagePath,
          );

      if (mounted) {
        final path = '/collection/${collection.remoteId}';
        context.pop();
        context.push(path, extra: collection);
      }
    } catch (e, st) {
      debugPrint('ERRO ao criar lista compartilhada: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sharingState = ref.watch(sharingNotifierProvider);
    final loading = sharingState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova lista compartilhada')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_tethering_outlined, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta lista será sincronizada em tempo real com quem você convidar.',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Foto de capa
            Text('Foto de capa', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _CoverPhotoPicker(
              coverImagePath: _coverImagePath,
              collectionName: _nameController.text,
              color: _selectedColor,
              onTap: _showImageSourceSheet,
            ),
            const SizedBox(height: 24),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da lista',
                hintText: 'Ex: Roupas, Eletrônicos...',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 24),

            // Cor
            Text('Cor de fundo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _kCollectionColors.length,
              itemBuilder: (context, index) {
                final color = _kCollectionColors[index];
                final isSelected =
                    _selectedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 3)
                          : Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check,
                            size: 16,
                            color: color.computeLuminance() > 0.7
                                ? Colors.black
                                : Colors.white)
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

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
                  : const Text('Criar lista compartilhada'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPhotoPicker extends StatelessWidget {
  final String? coverImagePath;
  final String collectionName;
  final Color color;
  final VoidCallback onTap;

  const _CoverPhotoPicker({
    required this.coverImagePath,
    required this.collectionName,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCover = coverImagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: hasCover
                  ? Image.file(
                      File(coverImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _Placeholder(color: color, name: collectionName),
                    )
                  : _Placeholder(color: color, name: collectionName),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: hasCover ? 0.3 : 0.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasCover
                          ? Icons.edit_outlined
                          : Icons.add_a_photo_outlined,
                      size: 24,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Color color;
  final String name;

  const _Placeholder({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    final lum = color.computeLuminance();
    final textColor = lum > 0.5 ? Colors.black54 : Colors.white54;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.2)!],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
