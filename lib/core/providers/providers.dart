import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';

// --- Storage ---

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// --- Singleton service providers ---

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sttServiceProvider = Provider<SttService>((ref) {
  final service = SttService();
  ref.onDispose(() => service.dispose());
  return service;
});

final nlpServiceProvider = Provider<NlpService>((ref) {
  final service = NlpService();
  ref.onDispose(() => service.dispose());
  return service;
});

final imageGenServiceProvider = Provider<ImageGenService>((ref) {
  final service = ImageGenService();
  ref.onDispose(() => service.dispose());
  return service;
});

final modelManagerProvider = Provider<ModelManager>((ref) {
  final manager = ModelManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final promptBuilderProvider = Provider<PromptBuilder>((ref) {
  return PromptBuilder();
});

// --- Session Controller ---

final sessionControllerProvider = Provider<SessionController>((ref) {
  final controller = SessionController(
    audioService: ref.read(audioServiceProvider),
    sttService: ref.read(sttServiceProvider),
    nlpService: ref.read(nlpServiceProvider),
    imageGenService: ref.read(imageGenServiceProvider),
    promptBuilder: ref.read(promptBuilderProvider),
  );
  ref.onDispose(() => controller.dispose());
  return controller;
});

// --- Generation Settings (persisted) ---

final generationSettingsProvider =
    StateNotifierProvider<GenerationSettingsNotifier, GenerationSettings>((ref) {
  return GenerationSettingsNotifier(ref.read(storageServiceProvider));
});

class GenerationSettingsNotifier extends StateNotifier<GenerationSettings> {
  final StorageService _storage;

  GenerationSettingsNotifier(this._storage) : super(const GenerationSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadSettings();
  }

  void update(GenerationSettings settings) {
    state = settings;
    _storage.saveSettings(settings);
  }

  void applyPreset(String presetName) {
    final preset = GenerationSettings.presets[presetName];
    if (preset != null) {
      state = preset;
      _storage.saveSettings(state);
    }
  }

  void updateBaseStyle(String style) {
    state = state.copyWith(baseStylePrompt: style);
    _storage.saveSettings(state);
  }

  void updateNegativePrompt(String prompt) {
    state = state.copyWith(negativePrompt: prompt);
    _storage.saveSettings(state);
  }

  void updateDimensions(int width, int height) {
    state = state.copyWith(width: width, height: height);
    _storage.saveSettings(state);
  }

  void updateSteps(int steps) {
    state = state.copyWith(steps: steps);
    _storage.saveSettings(state);
  }

  void updateCfgScale(double scale) {
    state = state.copyWith(cfgScale: scale);
    _storage.saveSettings(state);
  }
}

// --- Characters (persisted) ---

final charactersProvider =
    StateNotifierProvider<CharactersNotifier, List<Character>>((ref) {
  return CharactersNotifier(ref.read(storageServiceProvider));
});

class CharactersNotifier extends StateNotifier<List<Character>> {
  final StorageService _storage;

  CharactersNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadCharacters();
  }

  void addCharacter(Character character) {
    state = [...state, character];
    _storage.saveCharacter(character);
  }

  void updateCharacter(Character updated) {
    state = [
      for (final c in state)
        if (c.id == updated.id) updated else c,
    ];
    _storage.saveCharacter(updated);
  }

  void removeCharacter(String id) {
    state = state.where((c) => c.id != id).toList();
    _storage.deleteCharacter(id);
  }

  void toggleActive(String id) {
    final updated = state.map((c) {
      if (c.id == id) return c.copyWith(isActive: !c.isActive);
      return c;
    }).toList();
    state = updated;
    for (final c in updated.where((c) => c.id == id)) {
      _storage.saveCharacter(c);
    }
  }

  List<Character> get activeCharacters =>
      state.where((c) => c.isActive).toList();
}

// --- Model management state ---

final modelsStateProvider =
    StateNotifierProvider<ModelsStateNotifier, List<ModelInfo>>((ref) {
  return ModelsStateNotifier(ref.read(modelManagerProvider));
});

class ModelsStateNotifier extends StateNotifier<List<ModelInfo>> {
  final ModelManager _manager;

  ModelsStateNotifier(this._manager) : super([]) {
    _loadModels();
  }

  Future<void> _loadModels() async {
    state = await _manager.getModelsWithStatus();
  }

  Future<void> refresh() async {
    state = await _manager.getModelsWithStatus();
  }

  void updateModel(ModelInfo updated) {
    state = [
      for (final m in state)
        if (m.id == updated.id) updated else m,
    ];
  }

  List<ModelInfo> byType(ModelType type) =>
      state.where((m) => m.type == type).toList();
}

// --- Active model selection (persisted) ---

final activeWhisperModelProvider =
    StateNotifierProvider<ActiveModelNotifier, String?>((ref) {
  return ActiveModelNotifier(ref.read(storageServiceProvider), 'active_whisper');
});

final activeLlmModelProvider =
    StateNotifierProvider<ActiveModelNotifier, String?>((ref) {
  return ActiveModelNotifier(ref.read(storageServiceProvider), 'active_llm');
});

final activeSdModelProvider =
    StateNotifierProvider<ActiveModelNotifier, String?>((ref) {
  return ActiveModelNotifier(ref.read(storageServiceProvider), 'active_sd');
});

class ActiveModelNotifier extends StateNotifier<String?> {
  final StorageService _storage;
  final String _key;

  ActiveModelNotifier(this._storage, this._key)
      : super(null) {
    state = _storage.loadActiveModel(_key);
  }

  void select(String? modelId) {
    state = modelId;
    _storage.saveActiveModel(_key, modelId);
  }
}

// --- Session state ---

final isListeningProvider = StateProvider<bool>((ref) => false);
final transcriptionBufferProvider = StateProvider<String>((ref) => '');
final currentSceneImageProvider = StateProvider<SceneImage?>((ref) => null);

// --- Gallery (persisted) ---

final galleryProvider =
    StateNotifierProvider<GalleryNotifier, List<SceneImage>>((ref) {
  return GalleryNotifier(ref.read(storageServiceProvider));
});

class GalleryNotifier extends StateNotifier<List<SceneImage>> {
  final StorageService _storage;

  GalleryNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadGallery();
  }

  void addImage(SceneImage image) {
    state = [image, ...state];
    _storage.saveSceneImage(image);
  }

  void removeImage(String id) {
    state = state.where((img) => img.id != id).toList();
    _storage.deleteSceneImage(id);
  }

  void clear() {
    state = [];
    _storage.clearGallery();
  }
}

// --- Generation state ---

final isGeneratingProvider = StateProvider<bool>((ref) => false);
final generationProgressProvider = StateProvider<double>((ref) => 0.0);

/// The most recently detected place description from the NLP analysis.
final detectedPlaceProvider = StateProvider<String>((ref) => '');

/// The full image generation prompt currently in use (cleared when done).
final activeGenerationPromptProvider = StateProvider<String>((ref) => '');
