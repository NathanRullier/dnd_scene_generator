import 'package:flutter/material.dart';

/// Displays the three live pipeline stages in a compact panel:
///   1. Hearing  — scrolling transcription of what the mic picks up
///   2. Detected — the place description the NLP extracted
///   3. Generating — the image prompt being sent to Stable Diffusion + progress
class PipelineStatusPanel extends StatelessWidget {
  final String transcription;
  final String detectedPlace;
  final String generationPrompt;
  final bool isGenerating;
  final double generationProgress;

  const PipelineStatusPanel({
    super.key,
    required this.transcription,
    required this.detectedPlace,
    required this.generationPrompt,
    required this.isGenerating,
    required this.generationProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasTranscription = transcription.isNotEmpty;
    final bool hasDetected = detectedPlace.isNotEmpty;
    final bool hasGeneration = isGenerating && generationPrompt.isNotEmpty;

    if (!hasTranscription && !hasDetected && !hasGeneration) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTranscription) _HearingRow(text: transcription),
          if (hasDetected) _DetectedRow(description: detectedPlace),
          if (hasGeneration)
            _GeneratingRow(
              prompt: generationPrompt,
              progress: generationProgress,
            ),
        ],
      ),
    );
  }
}

class _HearingRow extends StatelessWidget {
  final String text;
  const _HearingRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.hearing,
            size: 15,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedRow extends StatelessWidget {
  final String description;
  const _DetectedRow({required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 15,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scene detected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratingRow extends StatelessWidget {
  final String prompt;
  final double progress;
  const _GeneratingRow({required this.prompt, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progress > 0
                    ? 'Generating image… ${(progress * 100).round()}%'
                    : 'Generating image…',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            prompt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress > 0) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              color: theme.colorScheme.tertiary,
              backgroundColor:
                  theme.colorScheme.tertiary.withValues(alpha: 0.2),
            ),
          ],
        ],
      ),
    );
  }
}
