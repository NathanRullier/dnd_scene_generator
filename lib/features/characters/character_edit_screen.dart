import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/character.dart';
import '../../core/providers/providers.dart';

class CharacterEditScreen extends ConsumerStatefulWidget {
  final String? characterId;

  const CharacterEditScreen({super.key, required this.characterId});

  @override
  ConsumerState<CharacterEditScreen> createState() =>
      _CharacterEditScreenState();
}

class _CharacterEditScreenState extends ConsumerState<CharacterEditScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  List<String> _referenceImages = [];
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    if (widget.characterId != null) {
      final characters = ref.read(charactersProvider);
      final existing = characters
          .where((c) => c.id == widget.characterId)
          .firstOrNull;
      if (existing != null) {
        _isNew = false;
        _nameController.text = existing.name;
        _descriptionController.text = existing.description;
        _referenceImages = List.from(existing.referenceImagePaths);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _referenceImages.addAll(images.map((x) => x.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _referenceImages.removeAt(index);
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final character = Character(
      id: widget.characterId ?? const Uuid().v4(),
      name: name,
      description: description,
      referenceImagePaths: _referenceImages,
    );

    if (_isNew) {
      ref.read(charactersProvider.notifier).addCharacter(character);
    } else {
      ref.read(charactersProvider.notifier).updateCharacter(character);
    }

    context.go('/characters');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Character' : 'Edit Character'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/characters'),
        ),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Character Name',
                hintText: 'e.g., Gandalf the Grey',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Visual Description',
                hintText:
                    'e.g., an old wizard in grey robes with a long white beard and a tall pointed hat',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Reference Images',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                Text(
                  '(optional, for PhotoMaker with SDXL)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Provide 1-4 reference images of this character for consistent appearance across scenes.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._referenceImages.asMap().entries.map((entry) {
                  return _ImageTile(
                    imagePath: entry.value,
                    onRemove: () => _removeImage(entry.key),
                  );
                }),
                if (_referenceImages.length < 4)
                  _AddImageTile(onTap: _pickImage),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _ImageTile({required this.imagePath, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imagePath),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => Container(
              width: 100,
              height: 100,
              color: Colors.grey.shade800,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
