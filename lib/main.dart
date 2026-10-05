import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'screens/hub/hub_screen.dart';
import 'services/audio_service.dart';
import 'services/content_repository.dart';
import 'services/kids_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await ContentRepository.instance.init();
  // Purchases (offline-cached unlock) and optional login / cloud progress.
  await KidsStore.init();
  runApp(const ArkBustersKidsApp());
  // Newer questions from the school's sheet, if online; used from the next game.
  unawaited(ContentRepository.instance.checkForUpdates());
}

class ArkBustersKidsApp extends StatefulWidget {
  const ArkBustersKidsApp({super.key});

  @override
  State<ArkBustersKidsApp> createState() => _ArkBustersKidsAppState();
}

class _ArkBustersKidsAppState extends State<ArkBustersKidsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pause the music while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      AudioService.instance.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AudioService.instance.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARK BUSTERS KIDS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HubScreen(),
    );
  }
}
