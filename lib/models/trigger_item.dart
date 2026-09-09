import 'package:cloud_firestore/cloud_firestore.dart';
import 'risk_category.dart';

export 'risk_category.dart';

class TriggerItem {
  final String id;
  final String name;
  final RiskCategory category;
  final int histamineScore; // 0 (tolerated) to 3 (severe trigger)
  final String notes;
  final bool isUserCustom;

  TriggerItem({
    required this.id,
    required this.name,
    this.category = RiskCategory.high,
    this.histamineScore = 2,
    this.notes = '',
    this.isUserCustom = false,
  });

  String get severity => category.label;

  TriggerItem copyWith({
    String? id,
    String? name,
    RiskCategory? category,
    int? histamineScore,
    String? notes,
    bool? isUserCustom,
  }) {
    return TriggerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      histamineScore: histamineScore ?? this.histamineScore,
      notes: notes ?? this.notes,
      isUserCustom: isUserCustom ?? this.isUserCustom,
    );
  }

  factory TriggerItem.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return TriggerItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: RiskCategory.fromString(data['category'] as String?),
      histamineScore: (data['histamineScore'] as num?)?.toInt() ?? 2,
      notes: data['notes'] as String? ?? '',
      isUserCustom: data['isUserCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category.name,
      'histamineScore': histamineScore,
      'notes': notes,
      'isUserCustom': isUserCustom,
    };
  }
}
