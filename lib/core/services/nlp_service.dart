import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

@immutable
class PlaceAnalysis {
  final bool isPlaceDescription;
  final bool isNewPlace;
  final String extractedDescription;
  final String suggestedPrompt;
  final double confidence;

  const PlaceAnalysis({
    required this.isPlaceDescription,
    required this.isNewPlace,
    required this.extractedDescription,
    required this.suggestedPrompt,
    required this.confidence,
  });

  static const empty = PlaceAnalysis(
    isPlaceDescription: false,
    isNewPlace: false,
    extractedDescription: '',
    suggestedPrompt: '',
    confidence: 0.0,
  );
}

/// Wraps llama.cpp for local NLP - place detection and prompt crafting.
///
/// Uses a small language model (Phi-3-mini, Qwen2-0.5B, etc.) to analyze
/// transcribed text and detect place/scene descriptions.
class NlpService {
  String? _modelPath;
  bool _isLoaded = false;
  String _lastPlaceDescription = '';
  final List<String> _placeHistory = [];

  bool get isModelLoaded => _isLoaded;

  /// System prompt instructing the LLM to analyze narration for places.
  /// Structured output format for reliable parsing.
  static const String _systemPrompt = '''You are a scene analyzer for a tabletop RPG (like D&D). Your job is to analyze narration and determine if the narrator is describing a PLACE or SCENE.

RESPOND IN THIS EXACT FORMAT (one field per line):
IS_PLACE: true or false
IS_NEW: true or false
DESCRIPTION: short plain-language description of the place, or empty
PROMPT: a vivid Stable Diffusion image prompt for the scene (under 75 words), or empty
CONFIDENCE: a number from 0.0 to 1.0

RULES:
1. A place description mentions physical surroundings: rooms, landscapes, buildings, terrain, weather, lighting, furniture, decorations.
2. IS_NEW is true only if this describes a DIFFERENT location from the previous place. Movement words ("you enter", "walking into", "you arrive at") strongly indicate a new place.
3. IS_PLACE is false for dialogue, combat mechanics, character actions without location context, or rules discussion.
4. PROMPT should focus on visual elements: architecture, lighting, colors, atmosphere, textures, scale. Write it as a Stable Diffusion prompt (comma-separated descriptors).
5. CONFIDENCE: 0.8+ for clear scene descriptions, 0.5-0.8 for partial, below 0.5 for unclear.
6. If the text is too short or vague to determine a place, set IS_PLACE: false.''';

  Future<void> loadModel(String modelPath) async {
    if (!await File(modelPath).exists()) {
      debugPrint('[NlpService] Model file not found, running in stub mode: $modelPath');
      _isLoaded = true;
      return;
    }
    _modelPath = modelPath;
    _isLoaded = true;
    debugPrint('[NlpService] Model loaded: $modelPath');
  }

  Future<PlaceAnalysis> analyzeText(String text) async {
    if (!_isLoaded || text.trim().isEmpty) {
      return PlaceAnalysis.empty;
    }

    if (text.trim().split(' ').length < 5) {
      return PlaceAnalysis.empty;
    }

    final contextPart = _lastPlaceDescription.isNotEmpty
        ? '\n\nPrevious place: "$_lastPlaceDescription"'
        : '\n\nNo previous place has been described yet.';

    final userPrompt =
        'Analyze this tabletop RPG narration for place/scene descriptions:$contextPart\n\nNew narration text:\n"$text"';

    if (_modelPath == null) return PlaceAnalysis.empty;

    final response = await Isolate.run(() {
      return _inferNative(_modelPath!, _systemPrompt, userPrompt);
    });

    final analysis = _parseResponse(response);

    if (analysis.isPlaceDescription && analysis.isNewPlace) {
      _lastPlaceDescription = analysis.extractedDescription;
      _placeHistory.add(analysis.extractedDescription);
    }

    return analysis;
  }

  PlaceAnalysis _parseResponse(String response) {
    if (response.isEmpty) return PlaceAnalysis.empty;

    try {
      final lines = response.split('\n');
      bool isPlace = false;
      bool isNew = false;
      String description = '';
      String prompt = '';
      double confidence = 0.0;

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('IS_PLACE:')) {
          isPlace = trimmed.substring(9).trim().toLowerCase() == 'true';
        } else if (trimmed.startsWith('IS_NEW:')) {
          isNew = trimmed.substring(7).trim().toLowerCase() == 'true';
        } else if (trimmed.startsWith('DESCRIPTION:')) {
          description = trimmed.substring(12).trim();
        } else if (trimmed.startsWith('PROMPT:')) {
          prompt = trimmed.substring(7).trim();
        } else if (trimmed.startsWith('CONFIDENCE:')) {
          confidence =
              double.tryParse(trimmed.substring(11).trim()) ?? 0.0;
        }
      }

      return PlaceAnalysis(
        isPlaceDescription: isPlace,
        isNewPlace: isNew,
        extractedDescription: description,
        suggestedPrompt: prompt,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('[NlpService] Failed to parse LLM response: $e');
      return PlaceAnalysis.empty;
    }
  }

  void resetContext() {
    _lastPlaceDescription = '';
    _placeHistory.clear();
  }

  List<String> get placeHistory => List.unmodifiable(_placeHistory);

  void unloadModel() {
    _isLoaded = false;
    _modelPath = null;
  }

  void dispose() {
    unloadModel();
  }
}

/// Native llama.cpp inference via FFI.
///
/// Placeholder - will be replaced with actual llamadart / llama.cpp FFI calls
/// when the native libraries are compiled and integrated.
///
/// Integration path:
///   1. Add llamadart package to pubspec.yaml
///   2. Initialize model: LlamaModel.load(modelPath, contextSize: 2048)
///   3. Generate: model.generate(systemPrompt: ..., prompt: ..., maxTokens: 256)
///   4. Parse structured output
String _inferNative(
    String modelPath, String systemPrompt, String userPrompt) {
  // TODO: Wire up llamadart FFI
  return '';
}
