import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/collections_provider.dart';
import '../../../sharing/presentation/providers/sharing_provider.dart';

// Paleta de 24 cores para pastas
const _kCollectionColors = [
  Color(0xFFE91E8C), // Rosa
  Color(0xFFE53935), // Vermelho
  Color(0xFFD81B60), // Rosa escuro
  Color(0xFF8E24AA), // Roxo
  Color(0xFF5E35B1), // Roxo escuro
  Color(0xFF1E88E5), // Azul
  Color(0xFF039BE5), // Azul claro
  Color(0xFF00ACC1), // Ciano
  Color(0xFF00897B), // Teal
  Color(0xFF43A047), // Verde
  Color(0xFF7CB342), // Verde claro
  Color(0xFFC0CA33), // Lima
  Color(0xFFFDD835), // Amarelo
  Color(0xFFFFB300), // Âmbar
  Color(0xFFFB8C00), // Laranja
  Color(0xFFF4511E), // Laranja escuro
  Color(0xFF6D4C41), // Marrom
  Color(0xFF546E7A), // Azul acinzentado
  Color(0xFF757575), // Cinza
  Color(0xFF000000), // Preto
  Color(0xFFFFFFFF), // Branco
  Color(0xFFFF80AB), // Rosa pastel
  Color(0xFF80D8FF), // Azul pastel
  Color(0xFFCCFF90), // Verde pastel
];

class CreateEditCollectionPage extends ConsumerStatefulWidget {
  final String? collectionId;
  const CreateEditCollectionPage({super.key, this.collectionId});

  bool get isEditing => collectionId != null;

  @override
  ConsumerState<CreateEditCollectionPage> createState() =>
      _CreateEditCollectionPageState();
}

class _CreateEditCollectionPageState
    extends ConsumerState<CreateEditCollectionPage> {
  final _nameController = TextEditingController();
  Color _selectedColor = _kCollectionColors.first;
  String? _coverImagePath;
  bool _saving = false;
  bool _isShared = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final localRepo = ref.read(collectionsRepositoryProvider);
    final local = await localRepo.getById(widget.collectionId!);

    if (local != null && !local.isShared) {
      // Lista local
      if (mounted) {
        setState(() {
          _nameController.text = local.name;
          _selectedColor = Color(local.colorValue);
          _coverImagePath = local.coverImagePath;
        });
      }
      return;
    }

    // Lista compartilhada — dados canônicos vêm do Supabase
    try {
      final remote = await ref
          .read(remoteCollectionsRepositoryProvider)
          .getById(widget.collectionId!);
      if (remote != null && mounted) {
        setState(() {
          _nameController.text = remote.name;
          _selectedColor = Color(remote.colorValue);
          _coverImagePath = local?.coverImagePath; // foto fica só no Isar
          _isShared = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null || !mounted) return;

    // Abre o editor de recorte — o usuário escolhe qual parte da foto usar
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

    // Copia para o diretório permanente do app (arquivo recortado é temporário)
    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory('${docsDir.path}/collection_covers');
    await coversDir.create(recursive: true);

    final srcPath = cropped.path;
    final dotIndex = srcPath.lastIndexOf('.');
    final ext = dotIndex != -1 ? srcPath.substring(dotIndex) : '.jpg';
    final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = '${coversDir.path}/$fileName';
    await File(srcPath).copy(destPath);

    // Remove foto anterior se havia uma diferente
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

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        if (_isShared) {
          // Lista compartilhada — atualiza Supabase + coverImagePath local
          final remote = await ref
              .read(remoteCollectionsRepositoryProvider)
              .getById(widget.collectionId!);
          if (remote != null) {
            await ref
                .read(sharingNotifierProvider.notifier)
                .updateSharedCollection(
                  collection: remote.copyWith(
                    name: _nameController.text.trim(),
                    colorValue: _selectedColor.toARGB32(),
                  ),
                  coverImagePath: _coverImagePath,
                );
          }
        } else {
          // Lista local — salva no Isar
          final existing = await ref
              .read(collectionsRepositoryProvider)
              .getById(widget.collectionId!);
          if (existing != null) {
            await ref
                .read(collectionsNotifierProvider.notifier)
                .updateCollection(existing.copyWith(
                  name: _nameController.text.trim(),
                  colorValue: _selectedColor.toARGB32(),
                  coverImagePath: _coverImagePath,
                ));
          }
        }
      } else {
        await ref.read(collectionsNotifierProvider.notifier).create(
              name: _nameController.text.trim(),
              colorValue: _selectedColor.toARGB32(),
              coverImagePath: _coverImagePath,
            );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar lista' : 'Nova lista'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Foto de capa', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          _CoverPhotoPicker(
            coverImagePath: _coverImagePath,
            collectionName: _nameController.text,
            color: _selectedColor,
            onTap: _showImageSourceSheet,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome da lista',
              hintText: 'Ex: Roupas, Eletrônicos...',
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('Cor de fundo',
              style: Theme.of(context).textTheme.labelLarge),
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
              final isSelected = _selectedColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: colorScheme.primary,
                            width: 3)
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
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.isEditing ? 'Salvar' : 'Criar lista'),
          ),
        ],
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
                      errorBuilder: (_, _, _) => _Placeholder(
                          color: color, name: collectionName),
                    )
                  : _Placeholder(color: color, name: collectionName),
            ),
            // Overlay escuro + ícone de câmera
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
