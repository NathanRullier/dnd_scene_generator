import 'package:flutter/foundation.dart';

@immutable
class SceneImage {
  final String id;
  final String imagePath;
  final String prompt;
  final String placeDescription;
  final String baseStyle;
  final List<String> characterNames;
  final DateTime createdAt;
  final Map<String, dynamic> generationParams;

  const SceneImage({
    required this.id,
    required this.imagePath,
    required this.prompt,
    required this.placeDescription,
    required this.baseStyle,
    this.characterNames = const [],
    required this.createdAt,
    this.generationParams = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'prompt': prompt,
        'placeDescription': placeDescription,
        'baseStyle': baseStyle,
        'characterNames': characterNames,
        'createdAt': createdAt.toIso8601String(),
        'generationParams': generationParams,
      };

  factory SceneImage.fromJson(Map<String, dynamic> json) => SceneImage(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        prompt: json['prompt'] as String,
        placeDescription: json['placeDescription'] as String,
        baseStyle: json['baseStyle'] as String,
        characterNames:
            (json['characterNames'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        generationParams:
            (json['generationParams'] as Map<String, dynamic>?) ?? {},
      );
}
