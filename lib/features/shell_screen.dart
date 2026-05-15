import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/session')) return 0;
    if (location.startsWith('/characters')) return 1;
    if (location.startsWith('/models')) return 2;
    if (location.startsWith('/settings')) return 3;
    if (location.startsWith('/gallery')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isWide = MediaQuery.sizeOf(context).width > 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) => _navigate(context, i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.mic),
                  selectedIcon: Icon(Icons.mic),
                  label: Text('Session'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Characters'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.download_outlined),
                  selectedIcon: Icon(Icons.download),
                  label: Text('Models'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Settings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.photo_library_outlined),
                  selectedIcon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _navigate(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Session',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Characters',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Models',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/session');
      case 1:
        context.go('/characters');
      case 2:
        context.go('/models');
      case 3:
        context.go('/settings');
      case 4:
        context.go('/gallery');
    }
  }
}
