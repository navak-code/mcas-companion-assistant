import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _settingsBoxName = 'mcas_settings_box';
  static const String _keyOnboardingComplete = 'is_onboarding_complete';
  static const String _keyUseCloudAi = 'use_cloud_ai';
  static const String _keyCustomApiKey = 'custom_gemini_api_key';
  static const String _keyEnabledPresets = 'enabled_presets';

  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // --- Onboarding Status ---
  bool get isOnboardingCompleted {
    return _settingsBox.get(_keyOnboardingComplete, defaultValue: false) as bool;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _settingsBox.put(_keyOnboardingComplete, value);
  }

  // --- AI Engine Preferences ---
  bool get useCloudAi {
    return _settingsBox.get(_keyUseCloudAi, defaultValue: true) as bool;
  }

  Future<void> setUseCloudAi(bool value) async {
    await _settingsBox.put(_keyUseCloudAi, value);
  }

  String? get customApiKey {
    return _settingsBox.get(_keyCustomApiKey) as String?;
  }

  Future<void> setCustomApiKey(String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _settingsBox.delete(_keyCustomApiKey);
    } else {
      await _settingsBox.put(_keyCustomApiKey, key.trim());
    }
  }

  // --- Preset Preferences ---
  List<String> get enabledPresets {
    final dynamic data = _settingsBox.get(
      _keyEnabledPresets,
      defaultValue: <String>[
        'sighi_level_0',
        'sighi_level_1',
        'sighi_liberators',
        'sighi_blockers',
      ],
    );
    return List<String>.from(data as List);
  }

  Future<void> setEnabledPresets(List<String> presets) async {
    await _settingsBox.put(_keyEnabledPresets, presets);
  }

  Future<void> clearAll() async {
    await _settingsBox.clear();
  }
}
