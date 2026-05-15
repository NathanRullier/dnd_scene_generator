import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/generation_settings.dart';
import '../../core/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _styleController;
  late TextEditingController _negativeController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(generationSettingsProvider);
    _styleController = TextEditingController(text: settings.baseStylePrompt);
    _negativeController = TextEditingController(text: settings.negativePrompt);
  }

  @override
  void dispose() {
    _styleController.dispose();
    _negativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(generationSettingsProvider);
    final notifier = ref.read(generationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Generation Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Style Presets
            Text('Style Presets',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GenerationSettings.presets.keys.map((presetName) {
                final isSelected = settings.presetName == presetName;
                return ChoiceChip(
                  label: Text(presetName),
                  selected: isSelected,
                  onSelected: (_) {
                    notifier.applyPreset(presetName);
                    _styleController.text =
                        GenerationSettings.presets[presetName]!
                            .baseStylePrompt;
                    _negativeController.text =
                        GenerationSettings.presets[presetName]!
                            .negativePrompt;
                  },
                  selectedColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Base Style Prompt
            Text('Base Style Prompt',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _styleController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the visual style for all generated images',
              ),
              onChanged: (value) => notifier.updateBaseStyle(value),
            ),

            const SizedBox(height: 16),

            // Negative Prompt
            Text('Negative Prompt',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _negativeController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Things to exclude from generated images',
              ),
              onChanged: (value) => notifier.updateNegativePrompt(value),
            ),

            const SizedBox(height: 24),

            // Image Dimensions
            Text('Image Dimensions',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _DimensionSelector(
              width: settings.width,
              height: settings.height,
              onChanged: (w, h) => notifier.updateDimensions(w, h),
            ),

            const SizedBox(height: 24),

            // Inference Steps
            Text(
              'Inference Steps: ${settings.steps}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Slider(
              value: settings.steps.toDouble(),
              min: 5,
              max: 50,
              divisions: 45,
              label: settings.steps.toString(),
              onChanged: (value) => notifier.updateSteps(value.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fast (5)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white38,
                        )),
                Text('Quality (50)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white38,
                        )),
              ],
            ),

            const SizedBox(height: 24),

            // CFG Scale
            Text(
              'CFG Scale: ${settings.cfgScale.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Slider(
              value: settings.cfgScale,
              min: 1.0,
              max: 20.0,
              divisions: 38,
              label: settings.cfgScale.toStringAsFixed(1),
              onChanged: (value) => notifier.updateCfgScale(value),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Creative (1)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white38,
                        )),
                Text('Faithful (20)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white38,
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionSelector extends StatelessWidget {
  final int width;
  final int height;
  final void Function(int width, int height) onChanged;

  const _DimensionSelector({
    required this.width,
    required this.height,
    required this.onChanged,
  });

  static const _presets = [
    (256, 256, '256x256'),
    (512, 512, '512x512'),
    (768, 768, '768x768'),
    (1024, 1024, '1024x1024'),
    (512, 768, '512x768'),
    (768, 512, '768x512'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets.map((preset) {
        final (w, h, label) = preset;
        final isSelected = width == w && height == h;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(w, h),
          selectedColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }
}
