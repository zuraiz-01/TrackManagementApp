import 'package:flutter/foundation.dart';

import 'app_settings.dart';
import 'settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._service);

  final SettingsService _service;

  AppSettings _settings = AppSettings.defaults;
  AppSettings get settings => _settings;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> init() async {
    _settings = await _service.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _service.save(settings);
  }
}
