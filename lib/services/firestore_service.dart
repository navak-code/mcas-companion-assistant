import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_analysis.dart';
import '../models/symptom_log.dart';
import '../models/trigger_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Settings ---
  Future<void> saveUserSettings(String uid, Map<String, dynamic> settings) async {
    await _db.collection('users').doc(uid).set(settings, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserSettings(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // --- Meals Collection ---
  Stream<List<MealAnalysis>> streamMeals(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MealAnalysis.fromFirestore(doc)).toList());
  }

  Future<void> addMeal(String uid, MealAnalysis meal) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toFirestore());
  }

  Future<void> updateMeal(String uid, MealAnalysis meal) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(meal.id)
        .update(meal.toFirestore());
  }

  // --- Symptoms Collection ---
  Stream<List<SymptomLog>> streamSymptoms(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('symptoms')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SymptomLog.fromFirestore(doc)).toList());
  }

  Future<void> addSymptom(String uid, SymptomLog symptom) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('symptoms')
        .doc(symptom.id)
        .set(symptom.toFirestore());
  }

  // --- Triggers Collection ---
  Stream<List<TriggerItem>> streamTriggers(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('triggers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TriggerItem.fromFirestore(doc)).toList());
  }

  Future<void> addTrigger(String uid, TriggerItem trigger) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('triggers')
        .doc(trigger.id)
        .set(trigger.toFirestore());
  }

  Future<void> deleteTrigger(String uid, String triggerId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('triggers')
        .doc(triggerId)
        .delete();
  }
}
