import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomLog {
  final String id;
  final String userId;
  final List<String> symptoms;
  final int severity; // 1 to 5
  final String notes;
  final DateTime timestamp;
  final String? linkedMealId; // Added this field

  SymptomLog({
    required this.id,
    required this.userId,
    required this.symptoms,
    required this.severity,
    this.notes = '',
    required this.timestamp,
    this.linkedMealId, // Added to constructor
  });

  factory SymptomLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return SymptomLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      severity: (data['severity'] as num?)?.toInt() ?? 3,
      notes: data['notes'] ?? '',
      timestamp: timestamp,
      linkedMealId: data['linkedMealId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'symptoms': symptoms,
      'severity': severity,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'linkedMealId': linkedMealId,
    };
  }
}
