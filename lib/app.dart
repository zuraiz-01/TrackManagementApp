import 'package:flutter/material.dart';

import 'auth/auth_gate.dart';
import 'services/app_settings.dart';
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
    return AnimatedBuilder(
      animation: _settingsController,
      builder: (context, _) {
        final settings = _settingsController.settings;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Track Management',
          theme: _buildTheme(settings),
          home: AuthGate(settingsController: _settingsController),
        );
      },
    );
  }
}

ThemeData _buildTheme(AppSettings settings) {
  final colorScheme = ColorScheme.dark(
    primary: settings.borderColor,
    secondary: settings.labelColor,
    surface: const Color(0xFF0C0D12),
    error: const Color(0xFFFF5252),
  );

  final textTheme = Typography.whiteMountainView.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: settings.backgroundColor,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0C0D12),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0C0D12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: settings.borderColor, width: 1),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF0C0D12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: settings.borderColor, width: 1),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: textTheme.bodyMedium,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0D0E14),
      labelStyle: TextStyle(color: settings.labelColor),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: settings.borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: settings.borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: settings.labelColor, width: 1.2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: settings.borderColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: settings.borderColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: settings.borderColor, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: settings.labelColor),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0C0D12),
      indicatorColor: settings.borderColor.withValues(alpha: 0.25),
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: settings.borderColor);
        }
        return IconThemeData(color: Colors.white.withValues(alpha: 0.7));
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return settings.borderColor;
        return Colors.white.withValues(alpha: 0.6);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return settings.borderColor.withValues(alpha: 0.35);
        }
        return Colors.white.withValues(alpha: 0.15);
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: settings.borderColor,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
      thumbColor: settings.borderColor,
      overlayColor: settings.borderColor.withValues(alpha: 0.12),
      valueIndicatorColor: const Color(0xFF0C0D12),
      valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
