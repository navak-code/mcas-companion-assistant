import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MealRiskLevel {
  low,
  moderate,
  high,
  severe;

  String get label {
    switch (this) {
      case MealRiskLevel.low:
        return 'Low Risk (SIGHI 0)';
      case MealRiskLevel.moderate:
        return 'Moderate Risk (SIGHI 1)';
      case MealRiskLevel.high:
        return 'High Risk (SIGHI 2)';
      case MealRiskLevel.severe:
        return 'Severe Risk (SIGHI 3)';
    }
  }

  Color get color {
    switch (this) {
      case MealRiskLevel.low:
        return const Color(0xFF2E7D32);
      case MealRiskLevel.moderate:
        return const Color(0xFFF57F17);
      case MealRiskLevel.high:
        return const Color(0xFFE65100);
      case MealRiskLevel.severe:
        return const Color(0xFFC62828);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case MealRiskLevel.low:
        return const Color(0xFFE8F5E9);
      case MealRiskLevel.moderate:
        return const Color(0xFFFFFDE7);
      case MealRiskLevel.high:
        return const Color(0xFFFFF3E0);
      case MealRiskLevel.severe:
        return const Color(0xFFFFEBEE);
    }
  }
}

class DetectedIngredient {
  final String name;
  final int sighiScore; // 0 to 3
  final bool isLiberator;
  final bool isBlocker;
  final String notes;

  DetectedIngredient({
    required this.name,
    required this.sighiScore,
    this.isLiberator = false,
    this.isBlocker = false,
    this.notes = '',
  });

  String get reasoning => notes.isNotEmpty ? notes : 'SIGHI compatibility level $sighiScore';

  MealRiskLevel get riskCategory {
    if (sighiScore >= 3 || isBlocker) return MealRiskLevel.severe;
    if (sighiScore == 2) return MealRiskLevel.high;
    if (sighiScore == 1 || isLiberator) return MealRiskLevel.moderate;
    return MealRiskLevel.low;
  }

  factory DetectedIngredient.fromMap(Map<String, dynamic> map) {
    return DetectedIngredient(
      name: map['name'] as String? ?? 'Unknown Ingredient',
      sighiScore: (map['sighiScore'] as num?)?.toInt() ?? 0,
      isLiberator: map['isLiberator'] as bool? ?? false,
      isBlocker: map['isBlocker'] as bool? ?? false,
      notes: map['notes'] as String? ?? map['reasoning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sighiScore': sighiScore,
      'isLiberator': isLiberator,
      'isBlocker': isBlocker,
      'notes': notes,
    };
  }
}

class MealAnalysis {
  final String id;
  final String mealName;
  final int histamineScore;
  final int liberatorScore;
  final double confidenceScore;
  final List<DetectedIngredient> detectedIngredients;
  final List<String> detectedTriggers;
  final String clinicalNotes;
  final DateTime timestamp;
  final bool isConfirmed;
  final Uint8List? imageBytes;

  MealAnalysis({
    required this.id,
    required this.mealName,
    required this.histamineScore,
    required this.liberatorScore,
    required this.confidenceScore,
    required this.detectedIngredients,
    required this.detectedTriggers,
    required this.clinicalNotes,
    required this.timestamp,
    this.isConfirmed = false,
    this.imageBytes,
  });

  List<DetectedIngredient> get ingredientBreakdown => detectedIngredients;
  int get confidencePercentage => (confidenceScore * 100).round();

  MealRiskLevel get overallRisk {
    final maxScore = histamineScore > liberatorScore ? histamineScore : liberatorScore;
    if (maxScore >= 3) return MealRiskLevel.severe;
    if (maxScore == 2) return MealRiskLevel.high;
    if (maxScore == 1) return MealRiskLevel.moderate;
    return MealRiskLevel.low;
  }

  MealAnalysis copyWith({
    String? id,
    String? mealName,
    int? histamineScore,
    int? liberatorScore,
    double? confidenceScore,
    List<DetectedIngredient>? detectedIngredients,
    List<String>? detectedTriggers,
    String? clinicalNotes,
    DateTime? timestamp,
    bool? isConfirmed,
    Uint8List? imageBytes,
  }) {
    return MealAnalysis(
      id: id ?? this.id,
      mealName: mealName ?? this.mealName,
      histamineScore: histamineScore ?? this.histamineScore,
      liberatorScore: liberatorScore ?? this.liberatorScore,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      detectedIngredients: detectedIngredients ?? this.detectedIngredients,
      detectedTriggers: detectedTriggers ?? this.detectedTriggers,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      timestamp: timestamp ?? this.timestamp,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  factory MealAnalysis.fromJson(
    Map<String, dynamic> map, {
    String? docId,
    Uint8List? imageBytes,
  }) {
    final rawIngredients = map['detectedIngredients'] ?? map['ingredientBreakdown'];
    final ingredientsList = (rawIngredients is List)
        ? rawIngredients.map((item) => DetectedIngredient.fromMap(item as Map<String, dynamic>)).toList()
        : <DetectedIngredient>[];

    final triggersList = (map['detectedTriggers'] is List)
        ? List<String>.from(map['detectedTriggers'])
        : <String>[];

    DateTime parsedTimestamp = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTimestamp = DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now();
    }

    Uint8List? parsedImageBytes = imageBytes;
    if (parsedImageBytes == null && map['imageBase64'] is String) {
      try {
        parsedImageBytes = base64Decode(map['imageBase64'] as String);
      } catch (_) {}
    }

    return MealAnalysis(
      id: docId ?? map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      mealName: map['mealName'] as String? ?? 'Unnamed Meal',
      histamineScore: (map['histamineScore'] as num?)?.toInt() ?? 0,
      liberatorScore: (map['liberatorScore'] as num?)?.toInt() ?? 0,
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.95,
      detectedIngredients: ingredientsList,
      detectedTriggers: triggersList,
      clinicalNotes: map['clinicalNotes'] as String? ?? '',
      timestamp: parsedTimestamp,
      isConfirmed: map['isConfirmed'] as bool? ?? false,
      imageBytes: parsedImageBytes,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mealName': mealName,
      'histamineScore': histamineScore,
      'liberatorScore': liberatorScore,
      'confidenceScore': confidenceScore,
      'detectedIngredients': detectedIngredients.map((i) => i.toMap()).toList(),
      'detectedTriggers': detectedTriggers,
      'clinicalNotes': clinicalNotes,
      'timestamp': Timestamp.fromDate(timestamp),
      'isConfirmed': isConfirmed,
      if (imageBytes != null) 'imageBase64': base64Encode(imageBytes!),
    };
  }

  factory MealAnalysis.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MealAnalysis.fromJson(data, docId: doc.id);
  }
}
