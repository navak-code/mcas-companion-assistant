\import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../firebase_options.dart';
import '../models/meal_analysis.dart';

class AiVisionService {
  static const String modelName = 'gemini-1.5-flash';

  static const String _systemPrompt = '''
You are an expert clinical dietitian specializing in MCAS. Analyze the provided meal image and return a valid, raw JSON object adhering to this schema:
{
  "mealName": "Descriptive Name", "histamineScore": 0, "liberatorScore": 0, "confidenceScore": 0.95,
  "detectedIngredients": [{"name": "Ingredient", "sighiScore": 0, "isLiberator": false, "isBlocker": false, "notes": "Clinical explanation"}],
  "detectedTriggers": ["Trigger1"], "clinicalNotes": "Actionable guidance."
}
''';

  Future<MealAnalysis> analyzeMeal({
    required Uint8List imageBytes,
    required bool useCloudAi,
    String? customApiKey,
  }) async {
    final effectiveApiKey = (useCloudAi || customApiKey == null || customApiKey.isEmpty)
        ? DefaultFirebaseOptions.currentPlatform.apiKey
        : customApiKey.trim();

    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: effectiveApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.2,
        ),
        systemInstruction: Content.system(_systemPrompt),
      );

      final response = await model.generateContent([
        Content.multi([
          TextPart('Analyze this meal image for MCAS histamine risk.'),
          DataPart('image/jpeg', imageBytes)
        ])
      ]);

      if (response.text == null) {
        throw Exception('Empty response from Gemini.');
      }
      return _parseJsonResponse(response.text!, imageBytes);
    } catch (e) {
      debugPrint('[AiVisionService ERROR] $e');
      return _generateFallback(imageBytes: imageBytes, errorReason: e.toString());
    }
  }

  MealAnalysis _parseJsonResponse(String raw, Uint8List imageBytes) {
    final cleanJson = raw.trim().replaceAll('```json', '').replaceAll('```', '').trim();
    final map = jsonDecode(cleanJson) as Map<String, dynamic>;
    return MealAnalysis.fromJson(map, imageBytes: imageBytes);
  }

  MealAnalysis _generateFallback({required Uint8List imageBytes, required String errorReason}) {
    return MealAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mealName: 'Unverified Meal (Fallback)',
      histamineScore: 1, liberatorScore: 1, confidenceScore: 0.0,
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
