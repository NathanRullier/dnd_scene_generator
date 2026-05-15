import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('characters');
  await Hive.openBox('settings');
  await Hive.openBox('gallery');
  await Hive.openBox('preferences');

  runApp(
    const ProviderScope(
      child: DndSceneGeneratorApp(),
    ),
  );
}
