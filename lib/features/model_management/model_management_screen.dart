import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/model_info.dart';
import '../../core/providers/providers.dart';

class ModelManagementScreen extends ConsumerStatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  ConsumerState<ModelManagementScreen> createState() =>
      _ModelManagementScreenState();
}

class _ModelManagementScreenState extends ConsumerState<ModelManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(
        () => ref.read(modelsStateProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Speech'),
            Tab(icon: Icon(Icons.psychology), text: 'NLP'),
            Tab(icon: Icon(Icons.image), text: 'Image Gen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ModelList(type: ModelType.whisper),
          _ModelList(type: ModelType.llm),
          _ModelList(type: ModelType.stableDiffusion),
        ],
      ),
    );
  }
}

class _ModelList extends ConsumerWidget {
  final ModelType type;

  const _ModelList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allModels = ref.watch(modelsStateProvider);
    final models = allModels.where((m) => m.type == type).toList();

    final activeModelId = switch (type) {
      ModelType.whisper => ref.watch(activeWhisperModelProvider),
      ModelType.llm => ref.watch(activeLlmModelProvider),
      ModelType.stableDiffusion => ref.watch(activeSdModelProvider),
    };

    if (models.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        return _ModelCard(
          model: model,
          isActive: model.id == activeModelId,
          type: type,
        );
      },
    );
  }
}

class _ModelCard extends ConsumerWidget {
  final ModelInfo model;
  final bool isActive;
  final ModelType type;

  const _ModelCard({
    required this.model,
    required this.isActive,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qualityColor = switch (model.qualityTier) {
      'small' => Colors.green,
      'medium' => Colors.orange,
      'large' => Colors.red.shade300,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: qualityColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              model.qualityTier.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: qualityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  model.sizeLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white38,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    switch (model.status) {
      case DownloadStatus.notDownloaded:
        return FilledButton.icon(
          onPressed: () => _download(ref),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Download'),
        );

      case DownloadStatus.downloading:
        return Column(
          children: [
            LinearProgressIndicator(value: model.downloadProgress),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(model.downloadProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () {
                    ref.read(modelManagerProvider).cancelDownload(model.id);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        );

      case DownloadStatus.downloaded:
        return Row(
          children: [
            if (!isActive)
              FilledButton(
                onPressed: () => _activate(ref),
                child: const Text('Activate'),
              ),
            if (isActive)
              FilledButton.tonal(
                onPressed: null,
                child: const Text('Active'),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _delete(ref),
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              label:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );

      case DownloadStatus.error:
        return Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            const Text('Download failed',
                style: TextStyle(color: Colors.red)),
            const Spacer(),
            FilledButton(
              onPressed: () => _download(ref),
              child: const Text('Retry'),
            ),
          ],
        );
    }
  }

  Future<void> _download(WidgetRef ref) async {
    final manager = ref.read(modelManagerProvider);
    final notifier = ref.read(modelsStateProvider.notifier);

    notifier.updateModel(
        model.copyWith(status: DownloadStatus.downloading));

    try {
      final subscription = manager.downloadProgress.listen((updated) {
        if (updated.id == model.id) {
          notifier.updateModel(updated);
        }
      });

      await manager.downloadModel(model);
      subscription.cancel();
      await notifier.refresh();
    } catch (e) {
      notifier.updateModel(model.copyWith(status: DownloadStatus.error));
    }
  }

  void _activate(WidgetRef ref) {
    switch (type) {
      case ModelType.whisper:
        ref.read(activeWhisperModelProvider.notifier).select(model.id);
      case ModelType.llm:
        ref.read(activeLlmModelProvider.notifier).select(model.id);
      case ModelType.stableDiffusion:
        ref.read(activeSdModelProvider.notifier).select(model.id);
    }
  }

  Future<void> _delete(WidgetRef ref) async {
    final manager = ref.read(modelManagerProvider);
    await manager.deleteModel(model);
    await ref.read(modelsStateProvider.notifier).refresh();

    switch (type) {
      case ModelType.whisper:
        if (ref.read(activeWhisperModelProvider) == model.id) {
          ref.read(activeWhisperModelProvider.notifier).select(null);
        }
      case ModelType.llm:
        if (ref.read(activeLlmModelProvider) == model.id) {
          ref.read(activeLlmModelProvider.notifier).select(null);
        }
      case ModelType.stableDiffusion:
        if (ref.read(activeSdModelProvider) == model.id) {
          ref.read(activeSdModelProvider.notifier).select(null);
        }
    }
  }
}
