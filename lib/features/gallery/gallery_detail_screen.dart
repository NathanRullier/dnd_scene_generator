import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/models/scene_image.dart';

class GalleryDetailScreen extends StatelessWidget {
  final SceneImage scene;

  const GalleryDetailScreen({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          DateFormat('MMM d, yyyy • h:mm a').format(scene.createdAt),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy prompt',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: scene.prompt));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prompt copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  File(scene.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, e, s) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          size: 64, color: Colors.white30),
                      const SizedBox(height: 8),
                      Text(
                        'Image not found',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _DetailPanel(scene: scene),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final SceneImage scene;

  const _DetailPanel({required this.scene});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Scene', value: scene.placeDescription),
            const SizedBox(height: 8),
            _InfoRow(label: 'Full Prompt', value: scene.prompt),
            if (scene.characterNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Characters',
                value: scene.characterNames.join(', '),
              ),
            ],
            const SizedBox(height: 8),
            _InfoRow(label: 'Style', value: scene.baseStyle),
            if (scene.generationParams.containsKey('elapsed_ms')) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Generation Time',
                value:
                    '${(scene.generationParams['elapsed_ms'] / 1000).toStringAsFixed(1)}s',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
      ],
    );
  }
}
