import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'screens/hub/hub_screen.dart';
import 'services/content_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await ContentRepository.instance.init();
  runApp(const ArkBustersKidsApp());
}

class ArkBustersKidsApp extends StatelessWidget {
  const ArkBustersKidsApp({super.key});

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
