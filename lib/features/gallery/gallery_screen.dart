import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/scene_image.dart';
import '../../core/providers/providers.dart';
import 'gallery_detail_screen.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Gallery'),
        actions: [
          if (gallery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _confirmClear(context, ref),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: gallery.isEmpty
          ? _buildEmptyState(context)
          : _buildGalleryGrid(context, ref, gallery),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No scenes generated yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generated scenes will appear here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white30,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(
      BuildContext context, WidgetRef ref, List<SceneImage> gallery) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 4 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: gallery.length,
      itemBuilder: (context, index) {
        final scene = gallery[index];
        return _GalleryTile(
          scene: scene,
          onTap: () => _showFullScreen(context, scene),
          onDelete: () =>
              ref.read(galleryProvider.notifier).removeImage(scene.id),
        );
      },
    );
  }

  void _showFullScreen(BuildContext context, SceneImage scene) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryDetailScreen(scene: scene),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Gallery'),
        content: const Text(
            'This will remove all generated scenes. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(galleryProvider.notifier).clear();
              Navigator.pop(context);
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final SceneImage scene;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GalleryTile({
    required this.scene,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('View Details'),
                  onTap: () {
                    Navigator.pop(context);
                    onTap();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(scene.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                color: Colors.grey.shade900,
                child: const Icon(Icons.broken_image,
                    size: 40, color: Colors.white30),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  scene.placeDescription,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

