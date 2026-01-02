import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'services/settings_controller.dart';
import 'services/settings_service.dart';

class TrackManagementApp extends StatefulWidget {
  const TrackManagementApp({super.key});

  @override
  State<TrackManagementApp> createState() => _TrackManagementAppState();
}

class _TrackManagementAppState extends State<TrackManagementApp> {
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController(SettingsService());
    _settingsController.init();
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Track Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: AuthGate(settingsController: _settingsController),
    );
  }
}
