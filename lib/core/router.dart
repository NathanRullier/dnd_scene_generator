import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/session/session_screen.dart';
import '../features/characters/characters_screen.dart';
import '../features/characters/character_edit_screen.dart';
import '../features/model_management/model_management_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/speech_test/speech_test_screen.dart';
import '../features/shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/session',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/session',
            builder: (context, state) => const SessionScreen(),
          ),
          GoRoute(
            path: '/characters',
            builder: (context, state) => const CharactersScreen(),
            routes: [
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CharacterEditScreen(characterId: id);
                },
              ),
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const CharacterEditScreen(characterId: null),
              ),
            ],
          ),
          GoRoute(
            path: '/models',
            builder: (context, state) => const ModelManagementScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const GalleryScreen(),
          ),
          GoRoute(
            path: '/speech-test',
            builder: (context, state) => const SpeechTestScreen(),
          ),
        ],
      ),
    ],
  );
});
