import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/meal_analysis.dart';

class AiVisionService {
  static const String modelName = 'gemini-2.5-flash';

  static const String _byokSystemPrompt = '''
You are an expert clinical dietitian and immunologist specializing in Mast Cell Activation Syndrome (MCAS), Histamine Intolerance, and the SIGHI food compatibility scale.

Analyze the meal image provided and return a single, valid, raw JSON object (with NO markdown backticks, NO ```json wrapping) adhering strictly to this schema:
{
  "mealName": "Descriptive meal name",
  "histamineScore": 0,
  "liberatorScore": 0,
  "confidenceScore": 0.95,
  "detectedIngredients": [
    {
      "name": "Ingredient name",
      "sighiScore": 0,
      "isLiberator": false,
      "isBlocker": false,
      "notes": "Histamine risk & clinical explanation"
    }
  ],
  "detectedTriggers": ["Trigger 1", "Trigger 2"],
  "clinicalNotes": "Actionable guidance regarding freshness, DAO support, or preparation."
}
''';

  Future<MealAnalysis> analyzeMeal({
    required Uint8List imageBytes,
    required bool useCloudAi,
    String? customApiKey,
  }) async {
    try {
      if (useCloudAi) {
        return await _analyzeWithCentralCloudFunction(imageBytes);
      } else {
        if (customApiKey == null || customApiKey.trim().isEmpty) {
          throw Exception('BYOK active, but no personal Gemini API key was provided.');
        }
        return await _analyzeWithByok(imageBytes, customApiKey.trim());
      }
    } catch (e, stack) {
      debugPrint('[AiVisionService ERROR] $e');
      debugPrint('[AiVisionService STACK] $stack');
      return _generateFallback(
        imageBytes: imageBytes,
        errorReason: 'AI Analysis Note (${useCloudAi ? "Central Cloud" : "BYOK"}): ${e.toString()}',
      );
    }
  }

  // 1. Central Mode: Zero client API keys; executes through Cloud Function backend
  Future<MealAnalysis> _analyzeWithCentralCloudFunction(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final callable = FirebaseFunctions.instance.httpsCallable('analyzeMealCentral');

    final response = await callable.call<Map<String, dynamic>>({
      'imageBase64': base64Image,
    });

    return MealAnalysis.fromJson(Map<String, dynamic>.from(response.data), imageBytes: imageBytes);
  }

  // 2. BYOK Mode: Client-side Gemini API call with user's personal key
  Future<MealAnalysis> _analyzeWithByok(Uint8List imageBytes, String apiKey) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
      systemInstruction: Content.system(_byokSystemPrompt),
    );

    final prompt = TextPart('Analyze this meal image for MCAS histamine risk. Return strict JSON.');
    final imagePart = DataPart('image/jpeg', imageBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final rawText = response.text;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty response from personal Gemini key.');
    }

    String cleanJson = rawText.trim();
    if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
    if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
    if (cleanJson.endsWith('```')) cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    cleanJson = cleanJson.trim();

    return MealAnalysis.fromJson(jsonDecode(cleanJson) as Map<String, dynamic>, imageBytes: imageBytes);
  }

  Future<bool> validateCustomApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey.trim());
      final response = await model.generateContent([Content.text('Ping. Respond with OK.')]);
      return response.text != null && response.text!.isNotEmpty;
    } catch (_) {
      return false;
    }
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
