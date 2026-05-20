import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Wraps whisper.cpp for local speech-to-text.
///
/// In production, this uses FFI bindings to whisper.cpp compiled as a shared
/// library for each platform. During development / until the native libs are
/// built, it provides a stub that returns empty transcriptions.
class SttService {
  String? _modelPath;
  bool _isLoaded = false;

  bool get isModelLoaded => _isLoaded;

  Future<void> loadModel(String modelPath) async {
    if (!await File(modelPath).exists()) {
      // Native lib is a stub — allow loading without the file so the
      // full session pipeline can be exercised in development.
      debugPrint('[SttService] Model file not found, running in stub mode: $modelPath');
      _isLoaded = true;
      return;
    }
    _modelPath = modelPath;
    _isLoaded = true;
    debugPrint('[SttService] Model loaded: $modelPath');
  }

  /// Transcribes a WAV audio file to text.
  /// Returns the transcribed string.
  Future<String> transcribe(String audioFilePath) async {
    if (!_isLoaded) {
      throw Exception('Whisper model not loaded. Call loadModel() first.');
    }

    if (!await File(audioFilePath).exists()) {
      return '';
    }

    if (_modelPath == null) return '';

    // Run transcription in an isolate to avoid blocking the UI thread.
    // This delegates to the native whisper.cpp FFI call.
    final result = await Isolate.run(() {
      return _transcribeNative(audioFilePath, _modelPath!);
    });

    return result;
  }

  void unloadModel() {
    _isLoaded = false;
    _modelPath = null;
    debugPrint('[SttService] Model unloaded');
  }

  void dispose() {
    unloadModel();
  }
}

/// Native whisper.cpp transcription via FFI.
///
/// This is a placeholder that will be replaced with actual FFI bindings once
/// the whisper.cpp shared libraries are compiled for each platform.
String _transcribeNative(String audioPath, String modelPath) {
  // TODO: Replace with actual whisper.cpp FFI call:
  //
  //   final dylib = DynamicLibrary.open(_getLibraryPath());
  //   final whisperInit = dylib.lookupFunction<...>('whisper_init_from_file');
  //   final whisperFull = dylib.lookupFunction<...>('whisper_full');
  //   ...
  //
  // For now, return empty string as a stub.
  return '';
}
