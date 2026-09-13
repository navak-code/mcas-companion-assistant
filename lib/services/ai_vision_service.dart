import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart' as f_ai;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ga;
import '../models/meal_analysis.dart';

class AiVisionService {
  // Locked to the version you requested
  static const String modelName = 'gemini-3.6-flash';

  // Dynamic system prompt generated on the fly based on user setup
  String _buildSystemPrompt(String? userConditions) {
    final conditionsContext = (userConditions != null && userConditions.trim().isNotEmpty)
        ? "The patient has the following medical conditions / dietary sensitivities: $userConditions."
        : "The patient is tracking generic food sensitivities and histamine intolerance.";

    return '''
You are an expert clinical dietitian and immunologist specializing in: $conditionsContext.
You have a deep understanding of food triggers and food compatibility scales like SIGHI.

Analyze the meal image provided and identify any ingredients that could trigger reactions related to the patient's specific conditions.
Return a single, valid, raw JSON object (with NO markdown backticks, NO ```json wrapping) adhering strictly to this schema:
{
  "mealName": "Descriptive meal name",
  "histamineScore": 0, // Integer: 0 (safe/low), 1 (moderately compatible), 2 (high risk), 3 (severe/incompatible)
  "liberatorScore": 0, // Integer: 0 (none), 1 (mild liberator), 2 (moderate), 3 (potent)
  "confidenceScore": 0.95, // Float: 0.0 to 1.0
  "detectedIngredients": [
    {
      "name": "Ingredient name",
      "sighiScore": 0, // 0 to 3
      "isLiberator": false,
      "isBlocker": false,
      "notes": "Trigger warnings and risk analysis tailored specifically to: $conditionsContext"
    }
  ],
  "detectedTriggers": ["Trigger 1", "Trigger 2"],
  "clinicalNotes": "Specific actionable guidance and warning context tailored to: $conditionsContext"
}
''';
  }

  Future<MealAnalysis> analyzeMeal({
    required Uint8List imageBytes,
    required bool useCloudAi,
    String? customApiKey,
    String? userConditions,
  }) async {
    final systemPrompt = _buildSystemPrompt(userConditions);

    try {
      if (useCloudAi) {
        debugPrint('[AiVisionService] Analyzing with Central Firebase AI Logic ($modelName)...');
        return await _analyzeWithFirebaseCentral(imageBytes, systemPrompt);
      } else {
        debugPrint('[AiVisionService] Analyzing with user-provided key (BYOK) ($modelName)...');
        if (customApiKey == null || customApiKey.trim().isEmpty) {
          throw Exception('Bring Your Own Key mode is active, but no API key was provided.');
        }
        return await _analyzeWithByok(imageBytes, customApiKey.trim(), systemPrompt);
      }
    } catch (e, stack) {
      debugPrint('[AiVisionService ERROR] $e');
      debugPrint('[AiVisionService STACK] $stack');
      return _generateFallback(
        imageBytes: imageBytes,
        errorReason: 'AI Analysis Note (${useCloudAi ? "Firebase Cloud" : "BYOK"}): ${e.toString()}',
      );
    }
  }

  // 1. CENTRALIZED SERVICE: Client-side SDK securely proxied by Firebase AI Logic
  Future<MealAnalysis> _analyzeWithFirebaseCentral(Uint8List imageBytes, String systemPrompt) async {
    final model = f_ai.FirebaseAI.instance.generativeModel(
      model: modelName,
      generationConfig: f_ai.GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
      systemInstruction: f_ai.Content.system(systemPrompt),
    );

    final response = await model.generateContent([
      f_ai.Content.multi([
        f_ai.TextPart('Analyze this meal image against my medical profile and triggers. Output strict JSON only.'),
        f_ai.InlineDataPart('image/jpeg', imageBytes),
      ])
    ]);

    final rawText = response.text;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty response returned from Firebase Central AI.');
    }
    return _parseJsonResponse(rawText, imageBytes);
  }

  // 2. BYOK MODE: Local direct Google Generative AI SDK call using user's key
  Future<MealAnalysis> _analyzeWithByok(Uint8List imageBytes, String apiKey, String systemPrompt) async {
    final model = ga.GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: ga.GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
      systemInstruction: ga.Content.system(systemPrompt),
    );

    final response = await model.generateContent([
      ga.Content.multi([
        ga.TextPart('Analyze this meal image against my medical profile and triggers. Output strict JSON only.'),
        ga.DataPart('image/jpeg', imageBytes),
      ])
    ]);

    final rawText = response.text;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Empty response from personal Gemini key.');
    }
    return _parseJsonResponse(rawText, imageBytes);
  }

  Future<bool> validateCustomApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final model = ga.GenerativeModel(model: modelName, apiKey: apiKey.trim());
      final response = await model.generateContent([ga.Content.text('Ping')]);
      return response.text != null && response.text!.isNotEmpty;
    } catch (_) {
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
