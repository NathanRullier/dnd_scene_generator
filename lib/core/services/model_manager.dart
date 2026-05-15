import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/model_info.dart';

class ModelManager {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _activeDownloads = {};
  String? _modelsDir;

  final StreamController<ModelInfo> _downloadProgressController =
      StreamController<ModelInfo>.broadcast();

  Stream<ModelInfo> get downloadProgress => _downloadProgressController.stream;

  Future<String> get modelsDirectory async {
    if (_modelsDir != null) return _modelsDir!;
    final dir = await getApplicationDocumentsDirectory();
    _modelsDir = p.join(dir.path, 'dnd_models');
    await Directory(_modelsDir!).create(recursive: true);
    return _modelsDir!;
  }

  /// All available models that can be downloaded.
  List<ModelInfo> get availableModels => [
        // Whisper STT models
        const ModelInfo(
          id: 'whisper-tiny',
          name: 'Whisper Tiny',
          description: 'Fastest, lower accuracy. Good for quick testing.',
          type: ModelType.whisper,
          downloadUrl:
              'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
          fileName: 'ggml-tiny.bin',
          sizeBytes: 75 * 1024 * 1024,
          qualityTier: 'small',
        ),
        const ModelInfo(
          id: 'whisper-base',
          name: 'Whisper Base',
          description: 'Balanced speed and accuracy.',
          type: ModelType.whisper,
          downloadUrl:
              'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
          fileName: 'ggml-base.bin',
          sizeBytes: 148 * 1024 * 1024,
          qualityTier: 'medium',
        ),
        const ModelInfo(
          id: 'whisper-small',
          name: 'Whisper Small',
          description: 'Best accuracy for the Whisper family. Slower.',
          type: ModelType.whisper,
          downloadUrl:
              'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
          fileName: 'ggml-small.bin',
          sizeBytes: 488 * 1024 * 1024,
          qualityTier: 'large',
        ),

        // LLM models for NLP
        const ModelInfo(
          id: 'qwen2-0.5b',
          name: 'Qwen2 0.5B',
          description: 'Tiny but capable. Fast on mobile devices.',
          type: ModelType.llm,
          downloadUrl:
              'https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf',
          fileName: 'qwen2-0_5b-instruct-q4_k_m.gguf',
          sizeBytes: 400 * 1024 * 1024,
          qualityTier: 'small',
        ),
        const ModelInfo(
          id: 'phi3-mini',
          name: 'Phi-3 Mini',
          description: 'Excellent reasoning for its size. Good balance.',
          type: ModelType.llm,
          downloadUrl:
              'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf',
          fileName: 'Phi-3-mini-4k-instruct-q4.gguf',
          sizeBytes: 2300 * 1024 * 1024,
          qualityTier: 'medium',
        ),
        const ModelInfo(
          id: 'llama-3.2-3b',
          name: 'Llama 3.2 3B',
          description: 'High quality NLP. Needs more RAM.',
          type: ModelType.llm,
          downloadUrl:
              'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
          fileName: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
          sizeBytes: 2000 * 1024 * 1024,
          qualityTier: 'large',
        ),

        // Stable Diffusion models
        const ModelInfo(
          id: 'sd-1.5-q4',
          name: 'SD 1.5 (Q4)',
          description:
              'Fast and lightweight. Works on most devices. No PhotoMaker.',
          type: ModelType.stableDiffusion,
          downloadUrl:
              'https://huggingface.co/justinpinkney/miniSD/resolve/main/miniSD.ckpt',
          fileName: 'sd-v1-5-q4.gguf',
          sizeBytes: 1024 * 1024 * 1024,
          qualityTier: 'small',
        ),
        const ModelInfo(
          id: 'sdxl-q4',
          name: 'SDXL (Q4)',
          description:
              'High quality. Supports PhotoMaker for character images. Needs 8GB+ RAM.',
          type: ModelType.stableDiffusion,
          downloadUrl:
              'https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors',
          fileName: 'sdxl-base-q4.gguf',
          sizeBytes: 3584 * 1024 * 1024,
          qualityTier: 'medium',
        ),
        const ModelInfo(
          id: 'sdxl-q8',
          name: 'SDXL (Q8)',
          description:
              'Best quality. Supports PhotoMaker. Desktop recommended.',
          type: ModelType.stableDiffusion,
          downloadUrl:
              'https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors',
          fileName: 'sdxl-base-q8.gguf',
          sizeBytes: 6656 * 1024 * 1024,
          qualityTier: 'large',
        ),
      ];

  /// Gets the current download status for all models by checking local files.
  Future<List<ModelInfo>> getModelsWithStatus() async {
    final dir = await modelsDirectory;
    final models = <ModelInfo>[];

    for (final model in availableModels) {
      final filePath = p.join(dir, model.fileName);
      if (await File(filePath).exists()) {
        models.add(model.copyWith(
          status: DownloadStatus.downloaded,
          downloadProgress: 1.0,
          localPath: filePath,
        ));
      } else if (_activeDownloads.containsKey(model.id)) {
        models.add(model);
      } else {
        models.add(model);
      }
    }

    return models;
  }

  /// Downloads a model from Hugging Face.
  Future<ModelInfo> downloadModel(ModelInfo model) async {
    if (_activeDownloads.containsKey(model.id)) {
      throw Exception('Model ${model.name} is already being downloaded');
    }

    final dir = await modelsDirectory;
    final filePath = p.join(dir, model.fileName);
    final cancelToken = CancelToken();
    _activeDownloads[model.id] = cancelToken;

    var updatedModel = model.copyWith(
      status: DownloadStatus.downloading,
      downloadProgress: 0.0,
    );
    _downloadProgressController.add(updatedModel);

    try {
      await _dio.download(
        model.downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            updatedModel = model.copyWith(
              status: DownloadStatus.downloading,
              downloadProgress: progress,
            );
            _downloadProgressController.add(updatedModel);
          }
        },
      );

      updatedModel = model.copyWith(
        status: DownloadStatus.downloaded,
        downloadProgress: 1.0,
        localPath: filePath,
      );
      _downloadProgressController.add(updatedModel);

      _activeDownloads.remove(model.id);
      return updatedModel;
    } catch (e) {
      _activeDownloads.remove(model.id);

      if (e is DioException && e.type == DioExceptionType.cancel) {
        updatedModel = model.copyWith(
          status: DownloadStatus.notDownloaded,
          downloadProgress: 0.0,
        );
      } else {
        updatedModel = model.copyWith(status: DownloadStatus.error);
      }

      _downloadProgressController.add(updatedModel);

      // Clean up partial download
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      rethrow;
    }
  }

  void cancelDownload(String modelId) {
    _activeDownloads[modelId]?.cancel();
    _activeDownloads.remove(modelId);
  }

  Future<void> deleteModel(ModelInfo model) async {
    final dir = await modelsDirectory;
    final filePath = p.join(dir, model.fileName);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Returns the local path for a downloaded model, or null.
  Future<String?> getModelPath(String modelId) async {
    final dir = await modelsDirectory;
    final model = availableModels.firstWhere((m) => m.id == modelId);
    final filePath = p.join(dir, model.fileName);
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }

  void dispose() {
    for (final token in _activeDownloads.values) {
      token.cancel();
    }
    _activeDownloads.clear();
    _downloadProgressController.close();
    _dio.close();
  }
}
