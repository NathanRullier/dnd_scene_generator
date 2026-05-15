import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/character.dart';
import '../../core/providers/providers.dart';

class CharactersScreen extends ConsumerWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characters = ref.watch(charactersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Characters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.go('/characters/new'),
            tooltip: 'Add Character',
          ),
        ],
      ),
      body: characters.isEmpty
          ? _buildEmptyState(context)
          : _buildCharacterList(context, ref, characters),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No characters yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add characters to include them in generated scenes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white30,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/characters/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Character'),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList(
      BuildContext context, WidgetRef ref, List<Character> characters) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        return _CharacterCard(character: character);
      },
    );
  }
}

class _CharacterCard extends ConsumerWidget {
  final Character character;

  const _CharacterCard({required this.character});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/characters/edit/${character.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (character.referenceImagePaths.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${character.referenceImagePaths.length} reference image(s)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: character.isActive,
                onChanged: (_) {
                  ref
                      .read(charactersProvider.notifier)
                      .toggleActive(character.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  ref
                      .read(charactersProvider.notifier)
                      .removeCharacter(character.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (character.referenceImagePaths.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(character.referenceImagePaths.first),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _buildPlaceholderAvatar(context),
        ),
      );
    }
    return _buildPlaceholderAvatar(context);
  }

  Widget _buildPlaceholderAvatar(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      ),
      child: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
