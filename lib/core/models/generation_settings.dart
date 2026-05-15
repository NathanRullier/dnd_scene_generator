import 'package:flutter/foundation.dart';

@immutable
class GenerationSettings {
  final String baseStylePrompt;
  final String negativePrompt;
  final int width;
  final int height;
  final int steps;
  final double cfgScale;
  final int? seed;
  final String presetName;

  const GenerationSettings({
    this.baseStylePrompt = 'fantasy art, detailed, dramatic lighting',
    this.negativePrompt =
        'blurry, low quality, deformed, ugly, bad anatomy, watermark, text',
    this.width = 512,
    this.height = 512,
    this.steps = 20,
    this.cfgScale = 7.0,
    this.seed,
    this.presetName = 'Fantasy Oil Painting',
  });

  GenerationSettings copyWith({
    String? baseStylePrompt,
    String? negativePrompt,
    int? width,
    int? height,
    int? steps,
    double? cfgScale,
    int? seed,
    String? presetName,
  }) {
    return GenerationSettings(
      baseStylePrompt: baseStylePrompt ?? this.baseStylePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      width: width ?? this.width,
      height: height ?? this.height,
      steps: steps ?? this.steps,
      cfgScale: cfgScale ?? this.cfgScale,
      seed: seed ?? this.seed,
      presetName: presetName ?? this.presetName,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseStylePrompt': baseStylePrompt,
        'negativePrompt': negativePrompt,
        'width': width,
        'height': height,
        'steps': steps,
        'cfgScale': cfgScale,
        'seed': seed,
        'presetName': presetName,
      };

  factory GenerationSettings.fromJson(Map<String, dynamic> json) =>
      GenerationSettings(
        baseStylePrompt:
            json['baseStylePrompt'] as String? ??
            'fantasy art, detailed, dramatic lighting',
        negativePrompt:
            json['negativePrompt'] as String? ??
            'blurry, low quality, deformed, ugly, bad anatomy, watermark, text',
        width: json['width'] as int? ?? 512,
        height: json['height'] as int? ?? 512,
        steps: json['steps'] as int? ?? 20,
        cfgScale: (json['cfgScale'] as num?)?.toDouble() ?? 7.0,
        seed: json['seed'] as int?,
        presetName: json['presetName'] as String? ?? 'Fantasy Oil Painting',
      );

  static const Map<String, GenerationSettings> presets = {
    'Fantasy Oil Painting': GenerationSettings(
      baseStylePrompt:
          'fantasy oil painting, epic scene, dramatic lighting, rich colors, detailed environment',
      presetName: 'Fantasy Oil Painting',
    ),
    'Dark Gothic': GenerationSettings(
      baseStylePrompt:
          'dark gothic art, moody atmosphere, shadows, candlelight, stone architecture, eerie',
      presetName: 'Dark Gothic',
    ),
    'Watercolor': GenerationSettings(
      baseStylePrompt:
          'watercolor painting, soft colors, flowing brushstrokes, gentle lighting, artistic',
      presetName: 'Watercolor',
    ),
    'Anime': GenerationSettings(
      baseStylePrompt:
          'anime style, vibrant colors, detailed background, Studio Ghibli inspired, cel shading',
      presetName: 'Anime',
    ),
    'Realistic': GenerationSettings(
      baseStylePrompt:
          'photorealistic, highly detailed, natural lighting, 8k resolution, cinematic',
      presetName: 'Realistic',
    ),
    'Pixel Art': GenerationSettings(
      baseStylePrompt:
          'pixel art, retro game style, 16-bit, detailed sprites, vibrant palette',
      presetName: 'Pixel Art',
    ),
  };
}
