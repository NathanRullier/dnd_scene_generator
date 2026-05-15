import '../models/character.dart';
import '../models/generation_settings.dart';

class PromptBuilder {
  /// Builds the final image generation prompt by combining all elements.
  String buildPrompt({
    required String placeDescription,
    required GenerationSettings settings,
    List<Character> activeCharacters = const [],
  }) {
    final parts = <String>[];

    // Base style
    if (settings.baseStylePrompt.isNotEmpty) {
      parts.add(settings.baseStylePrompt);
    }

    // Place description (the core subject)
    if (placeDescription.isNotEmpty) {
      parts.add(placeDescription);
    }

    // Character descriptions
    for (final character in activeCharacters) {
      if (character.isActive && character.description.isNotEmpty) {
        parts.add(character.description);
      }
    }

    return parts.join(', ');
  }

  /// Builds a PhotoMaker-compatible prompt with trigger words.
  /// PhotoMaker uses "img" as a trigger word for each character.
  String buildPhotoMakerPrompt({
    required String placeDescription,
    required GenerationSettings settings,
    List<Character> activeCharacters = const [],
  }) {
    final parts = <String>[];

    if (settings.baseStylePrompt.isNotEmpty) {
      parts.add(settings.baseStylePrompt);
    }

    if (placeDescription.isNotEmpty) {
      parts.add(placeDescription);
    }

    for (final character in activeCharacters) {
      if (character.isActive && character.referenceImagePaths.isNotEmpty) {
        // PhotoMaker trigger: "a [character description] img"
        parts.add('a ${character.description} img');
      } else if (character.isActive && character.description.isNotEmpty) {
        parts.add(character.description);
      }
    }

    return parts.join(', ');
  }
}
