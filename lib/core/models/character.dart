import 'package:flutter/foundation.dart';

@immutable
class Character {
  final String id;
  final String name;
  final String description;
  final List<String> referenceImagePaths;
  final bool isActive;

  const Character({
    required this.id,
    required this.name,
    required this.description,
    this.referenceImagePaths = const [],
    this.isActive = true,
  });

  Character copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? referenceImagePaths,
    bool? isActive,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      referenceImagePaths: referenceImagePaths ?? this.referenceImagePaths,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'referenceImagePaths': referenceImagePaths,
        'isActive': isActive,
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        referenceImagePaths:
            (json['referenceImagePaths'] as List<dynamic>?)?.cast<String>() ??
                [],
        isActive: json['isActive'] as bool? ?? true,
      );
}
