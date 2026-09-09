import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal_analysis.dart';
import '../models/symptom_log.dart';
import '../models/trigger_item.dart';
import '../services/ai_vision_service.dart';
import '../services/ble_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class AppStateProvider extends ChangeNotifier {
  final StorageService storageService;
  final FirestoreService _firestoreService = FirestoreService();
  final AiVisionService _aiVisionService = AiVisionService();
  final BleService _bleService = BleService();
  final ImagePicker _imagePicker = ImagePicker();

  User? _currentUser;
  String? _userName;
  String? _medicalConditions;

  bool _isLoading = true;
  bool _isAnalyzing = false;
  int _currentFeeling = 3;
  bool _isMockMode = true;

  bool _isOnboardingCompleted = false;
  bool _useCloudAi = true;
  String? _customApiKey;
  List<String> _enabledPresets = [];

  List<MealAnalysis> _meals = [];
  List<SymptomLog> _symptoms = [];
  List<TriggerItem> _triggers = [];

  AppStateProvider({required this.storageService}) {
    _initialize();
  }

  // --- Getters ---
  User? get user => _currentUser;
  String? get userName => _userName ?? _currentUser?.displayName ?? 'MCAS Patient';
  String? get medicalConditions => _medicalConditions;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  int get currentFeeling => _currentFeeling;
  bool get isMockMode => _isMockMode;

  BleConnectionState get bleState => _bleService.connectionState;
  int get batteryLevel => _bleService.batteryLevel;

  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get useCloudAi => _useCloudAi;
  String? get customApiKey => _customApiKey;
  List<String> get enabledPresets => _enabledPresets;

  List<MealAnalysis> get meals => _meals;
  MealAnalysis? get latestMeal => _meals.isNotEmpty ? _meals.first : null;
  List<SymptomLog> get symptoms => _symptoms;
  List<TriggerItem> get triggers => _triggers;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    await storageService.init();
    _isOnboardingCompleted = storageService.isOnboardingCompleted;
    _useCloudAi = storageService.useCloudAi;
    _customApiKey = storageService.customApiKey;
    _enabledPresets = storageService.enabledPresets;

    _bleService.stateStream.listen((_) => notifyListeners());

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _clearLocalData();
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    final settings = await _firestoreService.getUserSettings(uid);
    _userName = settings?['displayName'] as String? ?? _currentUser?.displayName;
    _medicalConditions = settings?['medicalConditions'] as String?;

    if (settings != null) {
      if (settings.containsKey('useCloudAi')) {
        _useCloudAi = settings['useCloudAi'] as bool;
        await storageService.setUseCloudAi(_useCloudAi);
      }
    }

    _syncUserData(uid);
    notifyListeners();
  }

  void _clearLocalData() {
    _meals = [];
    _symptoms = [];
    _triggers = [];
    _userName = null;
    _medicalConditions = null;
  }

  Future<void> _syncUserData(String uid) async {
    _firestoreService.streamMeals(uid).listen((meals) {
      _meals = meals;
      notifyListeners();
    });
    _firestoreService.streamSymptoms(uid).listen((symptoms) {
      _symptoms = symptoms;
      notifyListeners();
    });
    _firestoreService.streamTriggers(uid).listen((triggers) {
      _triggers = triggers;
      notifyListeners();
    });
  }

  // --- Profile & Custom Key Management ---
  Future<void> updateUserProfile({String? name, String? medicalConditions}) async {
    final Map<String, dynamic> dataToUpdate = {};
    if (name != null) {
      _userName = name;
      dataToUpdate['displayName'] = name;
      if (_currentUser?.displayName != name) {
        await _currentUser?.updateDisplayName(name);
        _currentUser = FirebaseAuth.instance.currentUser;
      }
    }
    if (medicalConditions != null) {
      _medicalConditions = medicalConditions;
      dataToUpdate['medicalConditions'] = medicalConditions;
    }

    if (_currentUser != null && dataToUpdate.isNotEmpty) {
      await _firestoreService.saveUserSettings(_currentUser!.uid, dataToUpdate);
    }
    notifyListeners();
  }

  Future<void> updateAiPreference({
    required bool useCloudAi,
    String? customApiKey,
  }) async {
    _useCloudAi = useCloudAi;
    _customApiKey = customApiKey;

    await storageService.setUseCloudAi(useCloudAi);
    await storageService.setCustomApiKey(customApiKey);

    if (_currentUser != null) {
      await _firestoreService.saveUserSettings(_currentUser!.uid, {
        'useCloudAi': useCloudAi,
        'hasCustomApiKey': customApiKey != null && customApiKey.isNotEmpty,
        'aiModel': AiVisionService.modelName,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    notifyListeners();
  }

  Future<bool> testCustomApiKey(String apiKey) async {
    return await _aiVisionService.validateCustomApiKey(apiKey);
  }

  Future<void> completeOnboarding({
    required String name,
    required String medicalConditions,
    required List<String> selectedPresets,
    required bool useCloudAi,
    String? customApiKey,
  }) async {
    await updateUserProfile(name: name, medicalConditions: medicalConditions);

    _enabledPresets = selectedPresets;
    _useCloudAi = useCloudAi;
    _customApiKey = customApiKey;
    _isOnboardingCompleted = true;

    await storageService.setEnabledPresets(selectedPresets);
    await storageService.setUseCloudAi(useCloudAi);
    await storageService.setCustomApiKey(customApiKey);
    await storageService.setOnboardingCompleted(true);

    if (_currentUser != null) {
      await _firestoreService.saveUserSettings(_currentUser!.uid, {
        'onboardingCompleted': true,
        'presets': selectedPresets,
        'useCloudAi': useCloudAi,
        'hasCustomApiKey': customApiKey != null && customApiKey.isNotEmpty,
        'aiModel': AiVisionService.modelName,
        'completedAt': DateTime.now().toIso8601String(),
      });
    }
    notifyListeners();
  }

  void updateFeeling(int feeling) {
    _currentFeeling = feeling;
    notifyListeners();
  }

  void toggleMockMode() {
    _isMockMode = !_isMockMode;
    _bleService.setMockMode(_isMockMode);
    notifyListeners();
  }

  Future<void> retryBleScan() async {
    await _bleService.startScan();
    notifyListeners();
  }

  Future<MealAnalysis?> scanFromCameraOrGallery({bool fromGallery = false}) async {
    final XFile? file = await _imagePicker.pickImage(
      source: fromGallery ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return await analyzeAndSaveMeal(bytes);
  }

  Future<MealAnalysis?> scanFromBlePocketUnit() async {
    final bytes = await _bleService.captureFrameFromDevice();
    if (bytes == null) return null;
    return await analyzeAndSaveMeal(bytes);
  }

  Future<MealAnalysis> analyzeAndSaveMeal(Uint8List imageBytes) async {
    _isAnalyzing = true;
    notifyListeners();
    try {
      final analysis = await _aiVisionService.analyzeMeal(
        imageBytes: imageBytes,
        useCloudAi: _useCloudAi,
        customApiKey: _customApiKey,
      );
      if (_currentUser != null) {
        await _firestoreService.addMeal(_currentUser!.uid, analysis);
      }
      return analysis;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> confirmMeal(MealAnalysis meal) async {
    final updated = meal.copyWith(isConfirmed: true);
    if (_currentUser != null) {
      await _firestoreService.updateMeal(_currentUser!.uid, updated);
    }
  }

  Future<void> logSymptom(SymptomLog symptom) async {
    if (_currentUser != null) {
      await _firestoreService.addSymptom(_currentUser!.uid, symptom);
    }
  }

  Future<void> addTrigger(TriggerItem trigger) async {
    if (_currentUser != null) {
      await _firestoreService.addTrigger(_currentUser!.uid, trigger);
    }
  }

  Future<void> deleteTrigger(String triggerId) async {
    if (_currentUser != null) {
      await _firestoreService.deleteTrigger(_currentUser!.uid, triggerId);
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await storageService.clearAll();
    _isOnboardingCompleted = false;
    _useCloudAi = true;
    _customApiKey = null;
    _clearLocalData();
    notifyListeners();
  }
}
