import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Persistent local storage backed by Hive.
///
/// Stores characters, generation settings, gallery metadata, and active
/// model selections.
class StorageService {
  static const _charactersBox = 'characters';
  static const _settingsBox = 'settings';
  static const _galleryBox = 'gallery';
  static const _prefsBox = 'preferences';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_charactersBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_galleryBox);
    await Hive.openBox(_prefsBox);
  }

  // --- Characters ---

  Future<List<Character>> loadCharacters() async {
    final box = Hive.box(_charactersBox);
    final chars = <Character>[];
    for (final key in box.keys) {
      final jsonStr = box.get(key) as String?;
      if (jsonStr != null) {
        chars.add(Character.fromJson(
            json.decode(jsonStr) as Map<String, dynamic>));
      }
    }
    return chars;
  }

  Future<void> saveCharacter(Character character) async {
    final box = Hive.box(_charactersBox);
    await box.put(character.id, json.encode(character.toJson()));
  }

  Future<void> deleteCharacter(String id) async {
    final box = Hive.box(_charactersBox);
    await box.delete(id);
  }

  Future<void> saveAllCharacters(List<Character> characters) async {
    final box = Hive.box(_charactersBox);
    await box.clear();
    for (final c in characters) {
      await box.put(c.id, json.encode(c.toJson()));
    }
  }

  // --- Generation Settings ---

  Future<GenerationSettings> loadSettings() async {
    final box = Hive.box(_settingsBox);
    final jsonStr = box.get('generation_settings') as String?;
    if (jsonStr != null) {
      return GenerationSettings.fromJson(
          json.decode(jsonStr) as Map<String, dynamic>);
    }
    return const GenerationSettings();
  }

  Future<void> saveSettings(GenerationSettings settings) async {
    final box = Hive.box(_settingsBox);
    await box.put('generation_settings', json.encode(settings.toJson()));
  }

  // --- Gallery ---

  Future<List<SceneImage>> loadGallery() async {
    final box = Hive.box(_galleryBox);
    final images = <SceneImage>[];
    for (final key in box.keys) {
      final jsonStr = box.get(key) as String?;
      if (jsonStr != null) {
        images.add(SceneImage.fromJson(
            json.decode(jsonStr) as Map<String, dynamic>));
      }
    }
    images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return images;
  }

  Future<void> saveSceneImage(SceneImage image) async {
    final box = Hive.box(_galleryBox);
    await box.put(image.id, json.encode(image.toJson()));
  }

  Future<void> deleteSceneImage(String id) async {
    final box = Hive.box(_galleryBox);
    await box.delete(id);
  }

  Future<void> clearGallery() async {
    final box = Hive.box(_galleryBox);
    await box.clear();
  }

  // --- Active model preferences ---

  Future<void> saveActiveModel(String key, String? modelId) async {
    final box = Hive.box(_prefsBox);
    if (modelId != null) {
      await box.put(key, modelId);
    } else {
      await box.delete(key);
    }
  }

  String? loadActiveModel(String key) {
    final box = Hive.box(_prefsBox);
    return box.get(key) as String?;
  }
}
