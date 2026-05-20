import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
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

  /// True when [message] is a live partial result, not yet committed.
  final bool isPartial;

  const SessionEvent({
    required this.type,
    this.message,
    this.sceneImage,
    this.progress,
    this.prompt,
    this.isPartial = false,
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
class SessionController {
  static const _analysisInterval = Duration(seconds: 8);
  static const _audioChunkDuration = Duration(seconds: 5);
  static const _platformSttListenFor = Duration(seconds: 30);
  static const _platformSttPauseFor = Duration(seconds: 4);
  static const _platformSttRestartDelay = Duration(milliseconds: 300);
  static const _placeConfidenceThreshold = 0.6;

  final AudioService _audioService;
  final SttService _sttService;
  final NlpService _nlpService;
  final ImageGenService _imageGenService;
  final PromptBuilder _promptBuilder;

  SessionState _state = SessionState.idle;
  final StringBuffer _textBuffer = StringBuffer();
  Timer? _analysisTimer;
  StreamSubscription<String>? _audioSubscription;
  final SpeechToText _platformStt = SpeechToText();

  GenerationSettings _settings = const GenerationSettings();
  List<Character> _activeCharacters = [];

  final StreamController<SessionEvent> _eventController =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get events => _eventController.stream;
  SessionState get state => _state;
  String get currentTranscription => _textBuffer.toString().trim();
  bool get _usingPlatformStt => _sttService.isStubMode;

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

  void updateSettings(GenerationSettings settings) => _settings = settings;

  void updateCharacters(List<Character> characters) {
    _activeCharacters = characters.where((c) => c.isActive).toList();
  }

  Future<void> startSession() async {
    if (_state != SessionState.idle) return;

    final missing = _firstUnloadedService();
    if (missing != null) {
      _emitError('$missing model not loaded');
      return;
    }

    _setState(SessionState.listening);
    _textBuffer.clear();
    _nlpService.resetContext();

    try {
      if (_usingPlatformStt) {
        await _startPlatformStt();
      } else {
        await _startNativeStt();
      }
      _analysisTimer =
          Timer.periodic(_analysisInterval, (_) => _analyzeAccumulatedText());
    } catch (e) {
      _setState(SessionState.idle);
      _emitError('Failed to start session: $e');
    }
  }

  String? _firstUnloadedService() {
    if (!_sttService.isModelLoaded) return 'Speech-to-text';
    if (!_nlpService.isModelLoaded) return 'NLP';
    if (!_imageGenService.isModelLoaded) return 'Image generation';
    return null;
  }

  Future<void> _startNativeStt() async {
    await _audioService.startListening(chunkDuration: _audioChunkDuration);
    _audioSubscription = _audioService.audioChunks.listen(_onAudioChunk);
  }

  Future<void> _startPlatformStt() async {
    final available = await _platformStt.initialize(
      onStatus: _onPlatformSttStatus,
      onError: (e) {
        debugPrint('[SessionController] Platform STT error: ${e.errorMsg}');
        _emitPartialTranscription('Speech recognition error: ${e.errorMsg}');
      },
    );
    if (!available) {
      throw StateError(
        'Speech recognition is not available on this platform. '
        'Install a Whisper model from the Models tab to enable transcription.',
      );
    }
    _emitPartialTranscription('Listening — speak into the microphone…');
    await _listenOncePlatformStt();
  }

  void _onPlatformSttStatus(String status) {
    debugPrint('[SessionController] Platform STT status: $status');
    if (status == SpeechToText.doneStatus && _state != SessionState.idle) {
      Future.delayed(_platformSttRestartDelay, _listenOncePlatformStt);
    }
  }

  Future<void> _listenOncePlatformStt() async {
    if (_state == SessionState.idle) return;
    await _platformStt.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        if (result.finalResult) {
          _textBuffer.write(' ');
          _textBuffer.write(words);
          _emitTranscription(currentTranscription, isPartial: false);
        } else {
          _emitPartialTranscription(words);
        }
      },
      listenFor: _platformSttListenFor,
      pauseFor: _platformSttPauseFor,
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
  }

  Future<void> stopSession() async {
    _analysisTimer?.cancel();
    _analysisTimer = null;

    if (_usingPlatformStt) {
      _platformStt.statusListener = null;
      await _platformStt.stop();
    } else {
      _audioSubscription?.cancel();
      _audioSubscription = null;
      await _audioService.stopListening();
    }

    _setState(SessionState.idle);
  }

  Future<void> _onAudioChunk(String chunkPath) async {
    try {
      final transcription = (await _sttService.transcribe(chunkPath)).trim();
      try { await File(chunkPath).delete(); } catch (_) {}
      if (transcription.isEmpty) return;

      _textBuffer.write(' ');
      _textBuffer.write(transcription);
      _emitTranscription(currentTranscription, isPartial: false);
    } catch (e) {
      debugPrint('[SessionController] Transcription error: $e');
    }
  }

  Future<void> _analyzeAccumulatedText() async {
    if (_state != SessionState.listening) return;

    final text = currentTranscription;
    if (text.isEmpty) return;

    _setState(SessionState.analyzing);

    try {
      final analysis = await _nlpService.analyzeText(text);
      if (analysis.isPlaceDescription &&
          analysis.isNewPlace &&
          analysis.confidence > _placeConfidenceThreshold) {
        _eventController.add(SessionEvent(
          type: SessionEventType.placeDetected,
          message: analysis.extractedDescription,
        ));
        _textBuffer.clear();
        await _generateScene(analysis);
      }
    } catch (e) {
      debugPrint('[SessionController] Analysis error: $e');
    }

    if (_state == SessionState.analyzing) {
      _setState(SessionState.listening);
    }
  }

  void _emitTranscription(String text, {required bool isPartial}) {
    _eventController.add(SessionEvent(
      type: SessionEventType.transcriptionUpdated,
      message: text,
      isPartial: isPartial,
    ));
  }

  void _emitPartialTranscription(String text) =>
      _emitTranscription(text, isPartial: true);

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
