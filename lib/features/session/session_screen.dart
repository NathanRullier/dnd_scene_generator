import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/services/session_controller.dart';
import 'widgets/listening_indicator.dart';
import 'widgets/scene_display.dart';
import 'widgets/transcription_ticker.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  StreamSubscription<SessionEvent>? _eventSubscription;

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleSession() async {
    final controller = ref.read(sessionControllerProvider);
    final isListening = ref.read(isListeningProvider);

    if (isListening) {
      await controller.stopSession();
      ref.read(isListeningProvider.notifier).state = false;
      _eventSubscription?.cancel();
      _eventSubscription = null;
    } else {
      // Sync current settings and characters with the controller
      controller.updateSettings(ref.read(generationSettingsProvider));
      controller.updateCharacters(ref.read(charactersProvider));

      // Check microphone permission
      final audioService = ref.read(audioServiceProvider);
      final hasMicPermission = await audioService.hasPermission();
      if (!hasMicPermission) {
        _showError('Microphone permission is required. Please grant it in settings.');
        return;
      }

      // Load models if needed
      final loadError = await _ensureModelsLoaded();
      if (loadError != null) {
        _showError(loadError);
        return;
      }

      // Subscribe to session events
      _eventSubscription = controller.events.listen(_onSessionEvent);

      await controller.startSession();
      ref.read(isListeningProvider.notifier).state = true;
    }
  }

  Future<String?> _ensureModelsLoaded() async {
    final sttService = ref.read(sttServiceProvider);
    final nlpService = ref.read(nlpServiceProvider);
    final imageGenService = ref.read(imageGenServiceProvider);
    final modelManager = ref.read(modelManagerProvider);

    // Load Whisper model
    if (!sttService.isModelLoaded) {
      final whisperModelId = ref.read(activeWhisperModelProvider);
      if (whisperModelId == null) {
        return 'No speech model selected. Go to Models tab to download and activate one.';
      }
      final path = await modelManager.getModelPath(whisperModelId);
      if (path == null) {
        return 'Speech model not downloaded. Go to Models tab to download it.';
      }
      await sttService.loadModel(path);
    }

    // Load LLM model
    if (!nlpService.isModelLoaded) {
      final llmModelId = ref.read(activeLlmModelProvider);
      if (llmModelId == null) {
        return 'No NLP model selected. Go to Models tab to download and activate one.';
      }
      final path = await modelManager.getModelPath(llmModelId);
      if (path == null) {
        return 'NLP model not downloaded. Go to Models tab to download it.';
      }
      await nlpService.loadModel(path);
    }

    // Load SD model
    if (!imageGenService.isModelLoaded) {
      final sdModelId = ref.read(activeSdModelProvider);
      if (sdModelId == null) {
        return 'No image model selected. Go to Models tab to download and activate one.';
      }
      final path = await modelManager.getModelPath(sdModelId);
      if (path == null) {
        return 'Image model not downloaded. Go to Models tab to download it.';
      }
      await imageGenService.loadModel(path);
    }

    return null;
  }

  void _onSessionEvent(SessionEvent event) {
    if (!mounted) return;

    switch (event.type) {
      case SessionEventType.transcriptionUpdated:
        ref.read(transcriptionBufferProvider.notifier).state =
            event.message ?? '';

      case SessionEventType.placeDetected:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New scene detected: ${event.message}'),
            backgroundColor:
                Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );

      case SessionEventType.generationStarted:
        ref.read(isGeneratingProvider.notifier).state = true;
        ref.read(generationProgressProvider.notifier).state = 0.0;

      case SessionEventType.generationProgress:
        ref.read(generationProgressProvider.notifier).state =
            event.progress ?? 0.0;

      case SessionEventType.generationComplete:
        ref.read(isGeneratingProvider.notifier).state = false;
        if (event.sceneImage != null) {
          ref.read(currentSceneImageProvider.notifier).state =
              event.sceneImage;
          ref.read(galleryProvider.notifier).addImage(event.sceneImage!);
        }

      case SessionEventType.error:
        _showError(event.message ?? 'Unknown error');

      case SessionEventType.stateChanged:
        break;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final isGenerating = ref.watch(isGeneratingProvider);
    final genProgress = ref.watch(generationProgressProvider);
    final currentScene = ref.watch(currentSceneImageProvider);
    final transcription = ref.watch(transcriptionBufferProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('D&D Scene Generator'),
        actions: [
          if (isGenerating)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SceneDisplay(sceneImage: currentScene),
          ),
          if (isGenerating)
            LinearProgressIndicator(
              value: genProgress > 0 ? genProgress : null,
            ),
          TranscriptionTicker(text: transcription),
          _buildControls(context, isListening, isGenerating),
        ],
      ),
    );
  }

  Widget _buildControls(
      BuildContext context, bool isListening, bool isGenerating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListeningIndicator(isListening: isListening),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: isGenerating ? null : _toggleSession,
              icon: Icon(isListening ? Icons.stop : Icons.mic),
              label: Text(isListening ? 'Stop Session' : 'Start Session'),
              style: FilledButton.styleFrom(
                backgroundColor: isListening
                    ? Colors.red.shade700
                    : Theme.of(context).colorScheme.primary,
                disabledBackgroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            if (isGenerating) ...[
              const SizedBox(width: 16),
              Text(
                'Generating...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
