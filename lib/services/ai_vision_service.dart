import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../firebase_options.dart';
import '../models/meal_analysis.dart';

class AiVisionService {
  // Model locked to gemini-3.6-flash
  static const String modelName = 'gemini-3.6-flash';

  String _buildSystemPrompt(String? userConditions) {
    final conditionContext = (userConditions != null && userConditions.trim().isNotEmpty)
        ? "The patient has the following medical conditions / sensitivities: $userConditions. Pay special attention to triggers related to these specific conditions."
        : "The patient is tracking dietary triggers, histamine intolerance, and SIGHI food compatibility.";

    return '''
You are an expert clinical dietitian and immunologist.
$conditionContext

Analyze the meal image provided and return a single, valid, raw JSON object (with NO markdown backticks, NO ```json wrapping) adhering strictly to this schema:
{
  "mealName": "Descriptive meal name",
  "histamineScore": 0, // Integer: 0 (safe/low), 1 (moderately compatible), 2 (high risk), 3 (severe/incompatible)
  "liberatorScore": 0, // Integer: 0 (none), 1 (mild liberator), 2 (moderate), 3 (potent liberator)
  "confidenceScore": 0.95, // Float: 0.0 to 1.0
  "detectedIngredients": [
    {
      "name": "Ingredient name",
      "sighiScore": 0, // 0 to 3
      "isLiberator": false,
      "isBlocker": false,
      "notes": "Histamine risk & clinical explanation based on patient's profile"
    }
  ],
  "detectedTriggers": ["Trigger 1", "Trigger 2"],
  "clinicalNotes": "Actionable guidance regarding freshness, DAO support, or preparation."
}
''';
  }

  Future<MealAnalysis> analyzeMeal({
    required Uint8List imageBytes,
    required bool useCloudAi,
    String? customApiKey,
    String? userConditions,
  }) async {
    final effectiveApiKey = (!useCloudAi && customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : DefaultFirebaseOptions.currentPlatform.apiKey;

    final systemPrompt = _buildSystemPrompt(userConditions);

    try {
      debugPrint('[AiVisionService] Analyzing with $modelName. Mode: ${useCloudAi ? "Central (Beta)" : "BYOK"}');

      final model = GenerativeModel(
        model: modelName,
        apiKey: effectiveApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.2,
        ),
        systemInstruction: Content.system(systemPrompt),
      );

      final prompt = TextPart('Analyze this meal image for food triggers and histamine compatibility. Output strict JSON only.');
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final rawText = response.text;
      if (rawText == null || rawText.isEmpty) {
        throw Exception('Empty response received from Gemini.');
      }

      return _parseJsonResponse(rawText, imageBytes);
    } catch (e, stack) {
      debugPrint('[AiVisionService ERROR] $e');
      debugPrint('[AiVisionService STACK] $stack');
      return _generateFallback(
        imageBytes: imageBytes,
        errorReason: 'AI Analysis Note (${useCloudAi ? "Central Beta" : "BYOK"}): ${e.toString()}',
      );
    }
  }

  Future<bool> validateCustomApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey.trim());
      final response = await model.generateContent([Content.text('Ping')]);
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      debugPrint('[AiVisionService validateKey ERROR] $e');
      return false;
    }
  }

  MealAnalysis _parseJsonResponse(String raw, Uint8List imageBytes) {
    String cleanJson = raw.trim();
    if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
    if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
    if (cleanJson.endsWith('```')) cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    cleanJson = cleanJson.trim();

    final Map<String, dynamic> map = jsonDecode(cleanJson) as Map<String, dynamic>;
    return MealAnalysis.fromJson(map, imageBytes: imageBytes);
  }

  MealAnalysis _generateFallback({required Uint8List imageBytes, required String errorReason}) {
    return MealAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealName: 'Scanned Meal (Verification Needed)',
      histamineScore: 1,
      liberatorScore: 1,
      confidenceScore: 0.0,
      detectedIngredients: [
        DetectedIngredient(name: 'Manual Inspection Required', sighiScore: 1, notes: errorReason),
      ],
      detectedTriggers: ['Manual verification recommended'],
      clinicalNotes: errorReason,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    );
  }
}
