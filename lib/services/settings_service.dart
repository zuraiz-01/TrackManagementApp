import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsService {
  static const _kBorderColor = 'settings.borderColor';
  static const _kLabelColor = 'settings.labelColor';
  static const _kBackgroundColor = 'settings.backgroundColor';
  static const _kFontScale = 'settings.fontScale';

  static const _kShowFigureSection = 'settings.showFigureSection';
  static const _kJodiStart = 'settings.jodiStart';
  static const _kJodiEnd = 'settings.jodiEnd';
  static const _kFigureStart = 'settings.figureStart';
  static const _kFigureEnd = 'settings.figureEnd';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      borderColor: Color(
        prefs.getInt(_kBorderColor) ??
            AppSettings.defaults.borderColor.toARGB32(),
      ),
      labelColor: Color(
        prefs.getInt(_kLabelColor) ??
            AppSettings.defaults.labelColor.toARGB32(),
      ),
      backgroundColor: Color(
        prefs.getInt(_kBackgroundColor) ??
            AppSettings.defaults.backgroundColor.toARGB32(),
      ),
      fontScale: prefs.getDouble(_kFontScale) ?? AppSettings.defaults.fontScale,
      showFigureSection:
          prefs.getBool(_kShowFigureSection) ??
          AppSettings.defaults.showFigureSection,
      jodiStart: prefs.getInt(_kJodiStart) ?? AppSettings.defaults.jodiStart,
      jodiEnd: prefs.getInt(_kJodiEnd) ?? AppSettings.defaults.jodiEnd,
      figureStart:
          prefs.getInt(_kFigureStart) ?? AppSettings.defaults.figureStart,
      figureEnd: prefs.getInt(_kFigureEnd) ?? AppSettings.defaults.figureEnd,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBorderColor, settings.borderColor.toARGB32());
    await prefs.setInt(_kLabelColor, settings.labelColor.toARGB32());
    await prefs.setInt(_kBackgroundColor, settings.backgroundColor.toARGB32());
    await prefs.setDouble(_kFontScale, settings.fontScale);

    await prefs.setBool(_kShowFigureSection, settings.showFigureSection);
    await prefs.setInt(_kJodiStart, settings.jodiStart);
    await prefs.setInt(_kJodiEnd, settings.jodiEnd);
    await prefs.setInt(_kFigureStart, settings.figureStart);
    await prefs.setInt(_kFigureEnd, settings.figureEnd);
  }
}
