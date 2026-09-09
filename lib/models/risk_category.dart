import 'package:flutter/material.dart';

enum RiskCategory {
  safe,
  medium,
  high;

  String get label {
    switch (this) {
      case RiskCategory.safe:
        return 'Low / Safe';
      case RiskCategory.medium:
        return 'Moderate Risk';
      case RiskCategory.high:
        return 'High Risk';
    }
  }

  Color get color {
    switch (this) {
      case RiskCategory.safe:
        return const Color(0xFF10B981);
      case RiskCategory.medium:
        return const Color(0xFFF59E0B);
      case RiskCategory.high:
        return const Color(0xFFF43F5E);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RiskCategory.safe:
        return const Color(0xFFE8F5E9);
      case RiskCategory.medium:
        return const Color(0xFFFFF3E0);
      case RiskCategory.high:
        return const Color(0xFFFFEBEE);
    }
  }

  static RiskCategory fromString(String? val) {
    if (val == null) return RiskCategory.safe;
    switch (val.toLowerCase().trim()) {
      case 'high':
      case 'severe':
        return RiskCategory.high;
      case 'medium':
      case 'moderate':
        return RiskCategory.medium;
      case 'safe':
      case 'low':
      default:
        return RiskCategory.safe;
    }
  }
}
