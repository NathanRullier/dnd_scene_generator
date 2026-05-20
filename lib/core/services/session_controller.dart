import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'audio_service.dart';
import 'stt_service.dart';
import 'nlp_service.dart';
import 'image_gen_service.dart';
import 'prompt_builder.dart';

enum SessionState { idle, listening, analyzing, generating }

class SessionEvent {
  final SessionEventType type;
  final String? message;
  final SceneImage? sceneImage;
  final double? progress;
  final String? prompt;

  const SessionEvent({
    required this.type,
    this.message,
    this.sceneImage,
    this.progress,
    this.prompt,
  });
}

enum SessionEventType {
  stateChanged,
  transcriptionUpdated,
  placeDetected,
  generationStarted,
  generationProgress,
  generationComplete,
  error,
}

/// Orchestrates the full pipeline: audio -> STT -> NLP -> image generation.
///
/// This is the central controller that connects all services and manages
/// the continuous listening + place-detection + generation loop.
class SessionController {
  final AudioService _audioService;
  final SttService _sttService;
  final NlpService _nlpService;
  final ImageGenService _imageGenService;
  final PromptBuilder _promptBuilder;

  SessionState _state = SessionState.idle;
  final StringBuffer _textBuffer = StringBuffer();
  String _currentTranscription = '';
  Timer? _analysisTimer;
  StreamSubscription<String>? _audioSubscription;

  GenerationSettings _settings = const GenerationSettings();
  List<Character> _activeCharacters = [];

  final StreamController<SessionEvent> _eventController =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get events => _eventController.stream;
  SessionState get state => _state;
  String get currentTranscription => _currentTranscription;

  SessionController({
    required AudioService audioService,
    required SttService sttService,
    required NlpService nlpService,
    required ImageGenService imageGenService,
    required PromptBuilder promptBuilder,
  })  : _audioService = audioService,
        _sttService = sttService,
        _nlpService = nlpService,
        _imageGenService = imageGenService,
        _promptBuilder = promptBuilder;

  void updateSettings(GenerationSettings settings) {
    _settings = settings;
  }

  void updateCharacters(List<Character> characters) {
    _activeCharacters = characters.where((c) => c.isActive).toList();
  }

  Future<void> startSession() async {
    if (_state != SessionState.idle) return;

    if (!_sttService.isModelLoaded) {
      _emitError('Speech-to-text model not loaded');
      return;
    }
    if (!_nlpService.isModelLoaded) {
      _emitError('NLP model not loaded');
      return;
    }
    if (!_imageGenService.isModelLoaded) {
      _emitError('Image generation model not loaded');
      return;
    }

    _setState(SessionState.listening);
    _textBuffer.clear();
    _currentTranscription = '';
    _nlpService.resetContext();

    try {
      await _audioService.startListening(
        chunkDuration: const Duration(seconds: 5),
      );

      _audioSubscription = _audioService.audioChunks.listen(_onAudioChunk);

      // Analyze buffer periodically for place descriptions
      _analysisTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _analyzeAccumulatedText(),
      );
    } catch (e) {
      _setState(SessionState.idle);
      _emitError('Failed to start session: $e');
    }
  }

  Future<void> stopSession() async {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _audioSubscription?.cancel();
    _audioSubscription = null;
    await _audioService.stopListening();
    _setState(SessionState.idle);
  }

  Future<void> _onAudioChunk(String chunkPath) async {
    try {
      final transcription = await _sttService.transcribe(chunkPath);

      // Clean up temp file
      try {
        await File(chunkPath).delete();
      } catch (_) {}

      if (transcription.trim().isEmpty) return;

      _textBuffer.write(' ');
      _textBuffer.write(transcription.trim());
      _currentTranscription = _textBuffer.toString().trim();

      _eventController.add(SessionEvent(
        type: SessionEventType.transcriptionUpdated,
        message: _currentTranscription,
      ));
    } catch (e) {
      debugPrint('[SessionController] Transcription error: $e');
    }
  }

  Future<void> _analyzeAccumulatedText() async {
    if (_state != SessionState.listening) return;

    final text = _textBuffer.toString().trim();
    if (text.isEmpty) return;

    _setState(SessionState.analyzing);

    try {
      final analysis = await _nlpService.analyzeText(text);

      if (analysis.isPlaceDescription &&
          analysis.isNewPlace &&
          analysis.confidence > 0.6) {
        _eventController.add(SessionEvent(
          type: SessionEventType.placeDetected,
          message: analysis.extractedDescription,
        ));

        // Clear buffer since we've consumed this description
        _textBuffer.clear();
        _currentTranscription = '';

        await _generateScene(analysis);
      }
    } catch (e) {
      debugPrint('[SessionController] Analysis error: $e');
    }

    if (_state == SessionState.analyzing) {
      _setState(SessionState.listening);
    }
  }

  Future<void> _generateScene(PlaceAnalysis analysis) async {
    _setState(SessionState.generating);

    final hasPhotoMaker =
        _activeCharacters.any((c) => c.referenceImagePaths.isNotEmpty);

    final prompt = hasPhotoMaker
        ? _promptBuilder.buildPhotoMakerPrompt(
            placeDescription: analysis.suggestedPrompt,
            settings: _settings,
            activeCharacters: _activeCharacters,
          )
        : _promptBuilder.buildPrompt(
            placeDescription: analysis.suggestedPrompt,
            settings: _settings,
            activeCharacters: _activeCharacters,
          );

    _eventController.add(SessionEvent(
      type: SessionEventType.generationStarted,
      prompt: prompt,
    ));

    final charImages = _activeCharacters
        .expand((c) => c.referenceImagePaths)
        .toList();

    // Listen for generation progress
    final progressSub = _imageGenService.progress.listen((p) {
      _eventController.add(SessionEvent(
        type: SessionEventType.generationProgress,
        progress: p,
      ));
    });

    final result = await _imageGenService.generateImage(
      prompt: prompt,
      settings: _settings,
      characterImagePaths: charImages.isNotEmpty ? charImages : null,
    );

    await progressSub.cancel();

    if (result.success && result.imagePath != null) {
      final sceneImage = SceneImage(
        id: const Uuid().v4(),
        imagePath: result.imagePath!,
        prompt: prompt,
        placeDescription: analysis.extractedDescription,
        baseStyle: _settings.baseStylePrompt,
        characterNames: _activeCharacters.map((c) => c.name).toList(),
        createdAt: DateTime.now(),
        generationParams: {
          ..._settings.toJson(),
          'elapsed_ms': result.elapsed.inMilliseconds,
        },
      );

      _eventController.add(SessionEvent(
        type: SessionEventType.generationComplete,
        sceneImage: sceneImage,
      ));
    } else {
      _emitError(result.error ?? 'Image generation failed');
    }

    // Resume listening
    _setState(SessionState.listening);
  }

  void _setState(SessionState newState) {
    _state = newState;
    _eventController.add(SessionEvent(
      type: SessionEventType.stateChanged,
      message: newState.name,
    ));
  }

  void _emitError(String message) {
    _eventController.add(SessionEvent(
      type: SessionEventType.error,
      message: message,
    ));
  }

  Future<void> dispose() async {
    await stopSession();
    await _eventController.close();
  }
}
