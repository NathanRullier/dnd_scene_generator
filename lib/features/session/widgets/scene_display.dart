import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/models/scene_image.dart';

class SceneDisplay extends StatelessWidget {
  final SceneImage? sceneImage;

  const SceneDisplay({super.key, this.sceneImage});

  @override
  Widget build(BuildContext context) {
    if (sceneImage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.landscape_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a session to generate scenes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Describe a place and watch it come to life',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white30,
                  ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(sceneImage!.imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const Center(
            child: Icon(Icons.broken_image, size: 64, color: Colors.white30),
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
            padding: const EdgeInsets.all(16),
            child: Text(
              sceneImage!.placeDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
