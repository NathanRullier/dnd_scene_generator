import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/generation_settings.dart';

@immutable
class GenerationResult {
  final bool success;
  final String? imagePath;
  final String? error;
  final Duration elapsed;

  const GenerationResult({
    required this.success,
    this.imagePath,
    this.error,
    required this.elapsed,
  });
}

/// Wraps stable-diffusion.cpp for local image generation.
///
/// The service operates in two modes:
///   1. **Native FFI** (production): Uses compiled sd_native library via FFI
///      bindings in `core/native/sd_ffi.dart`.
///   2. **Stub** (development): Returns failure results. Used when the native
///      library hasn't been compiled yet.
///
/// Integration steps to activate native mode:
///   1. Clone stable-diffusion.cpp into native/stable-diffusion.cpp
///   2. Uncomment the link target in native/CMakeLists.txt
///   3. Build the native library for each platform
///   4. Place the .dll/.so/.dylib in the appropriate platform directory
class ImageGenService {
  String? _modelPath;
  bool _isLoaded = false;
  bool _isGenerating = false;

  bool get isModelLoaded => _isLoaded;
  bool get isGenerating => _isGenerating;

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  Stream<double> get progress => _progressController.stream;

  Future<void> loadModel(String modelPath) async {
    if (!await File(modelPath).exists()) {
      throw Exception('SD model not found at $modelPath');
    }
    _modelPath = modelPath;
    _isLoaded = true;
    debugPrint('[ImageGenService] Model loaded: $modelPath');
  }

  Future<GenerationResult> generateImage({
    required String prompt,
    required GenerationSettings settings,
    List<String>? characterImagePaths,
    String? photoMakerModelPath,
  }) async {
    if (!_isLoaded) {
      return const GenerationResult(
        success: false,
        error: 'Model not loaded',
        elapsed: Duration.zero,
      );
    }

    if (_isGenerating) {
      return const GenerationResult(
        success: false,
        error: 'Generation already in progress',
        elapsed: Duration.zero,
      );
    }

    _isGenerating = true;
    _progressController.add(0.0);

    final stopwatch = Stopwatch()..start();

    try {
      final outputDir = await getApplicationDocumentsDirectory();
      final galleryDir = p.join(outputDir.path, 'dnd_scenes');
      await Directory(galleryDir).create(recursive: true);

      final outputPath = p.join(galleryDir, '${const Uuid().v4()}.png');

      final fullPrompt = '${settings.baseStylePrompt}, $prompt';

      // Attempt native generation in a separate isolate
      final success = await Isolate.run(() {
        return _generateNative(
          modelPath: _modelPath!,
          prompt: fullPrompt,
          negativePrompt: settings.negativePrompt,
          width: settings.width,
          height: settings.height,
          steps: settings.steps,
          cfgScale: settings.cfgScale,
          seed: settings.seed ?? -1,
          outputPath: outputPath,
          characterImagePaths: characterImagePaths,
          photoMakerModelPath: photoMakerModelPath,
        );
      });

      stopwatch.stop();
      _progressController.add(1.0);

      if (success && await File(outputPath).exists()) {
        return GenerationResult(
          success: true,
          imagePath: outputPath,
          elapsed: stopwatch.elapsed,
        );
      } else {
        return GenerationResult(
          success: false,
          error:
              'Native library not yet linked. Build the sd_native library first.',
          elapsed: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return GenerationResult(
        success: false,
        error: e.toString(),
        elapsed: stopwatch.elapsed,
      );
    } finally {
      _isGenerating = false;
    }
  }

  void unloadModel() {
    _isLoaded = false;
    _modelPath = null;
  }

  void dispose() {
    unloadModel();
    _progressController.close();
  }
}

/// Native generation call.
///
/// When stable-diffusion.cpp is compiled and linked, this function will use
/// the SdFfi bindings from core/native/sd_ffi.dart to invoke the C library.
///
/// Current stub returns false until the native library is available.
bool _generateNative({
  required String modelPath,
  required String prompt,
  required String negativePrompt,
  required int width,
  required int height,
  required int steps,
  required double cfgScale,
  required int seed,
  required String outputPath,
  List<String>? characterImagePaths,
  String? photoMakerModelPath,
}) {
  // Native library integration point.
  //
  // Production implementation:
  //   final ffi = SdFfi();
  //   final ctx = ffi.sdInit(modelPath.toNativeUtf8(), nullptr, -1);
  //   if (ctx == nullptr) return false;
  //
  //   if (photoMakerModelPath != null) {
  //     ffi.sdSetPhotomaker(ctx, photoMakerModelPath.toNativeUtf8());
  //   }
  //
  //   final params = calloc<SdGenerationParams>();
  //   params.ref.width = width;
  //   params.ref.height = height;
  //   params.ref.steps = steps;
  //   params.ref.cfgScale = cfgScale;
  //   params.ref.seed = seed;
  //   params.ref.sampleMethod = 0;  // euler_a
  //   params.ref.batchCount = 1;
  //   params.ref.clipSkip = -1;
  //
  //   final image = ffi.sdTxt2img(ctx, prompt, negativePrompt, params.ref, ...);
  //   if (image != nullptr) {
  //     ffi.sdSaveImage(image, outputPath.toNativeUtf8());
  //     ffi.sdFreeImage(image);
  //   }
  //
  //   calloc.free(params);
  //   ffi.sdFree(ctx);
  //   return image != nullptr;
  //
  return false;
}
