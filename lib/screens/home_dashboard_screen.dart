import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/meal_analysis.dart';
import '../providers/app_state_provider.dart';
import '../services/ble_service.dart';
import 'meal_detail_screen.dart';
import 'meal_history_screen.dart';
import 'settings_screen.dart';
import 'symptom_log_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final latestMeal = provider.latestMeal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCAS Companion', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              child: Text(
                provider.user?.displayName?.substring(0, 1) ?? provider.user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade300,
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDeviceStatus(context, provider),
          const SizedBox(height: 16),
          _buildFeelingCard(context, provider),
          const SizedBox(height: 24),
          if (latestMeal != null) _buildRecentMealCard(context, latestMeal),
          if (latestMeal == null) _buildEmptyState(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final meal = await provider.scanFromCameraOrGallery();
          if (meal != null && context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)));
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(CupertinoIcons.camera, color: Colors.white),
      ),
    );
  }

  Widget _buildDeviceStatus(BuildContext context, AppStateProvider provider) {
    return Row(
      children: [
        Icon(Icons.circle, color: Colors.green.shade600, size: 12),
        const SizedBox(width: 8),
        Text(
          'Device Connected',
          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFeelingCard(BuildContext context, AppStateProvider provider) {
    const labels = {
      1: 'Great',
      2: 'Good',
      3: 'Okay',
      4: 'Bad',
      5: 'Severe',
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How are you feeling now?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Feeling', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(labels[provider.currentFeeling] ?? 'Okay', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
              ],
            ),
            Slider(
              value: provider.currentFeeling.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: Colors.teal,
              inactiveColor: Colors.grey.shade300,
              onChanged: (val) => provider.updateFeeling(val.round()),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Log Symptom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SymptomLogScreen(initialSeverity: provider.currentFeeling)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMealCard(BuildContext context, MealAnalysis meal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Meal Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meal.imageBytes != null)
                  Stack(
                    children: [
                      Image.memory(meal.imageBytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Chip(
                          label: Text(meal.overallRisk.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: meal.overallRisk.color,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(meal.mealName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(CupertinoIcons.sparkles, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text('${meal.confidencePercentage}% Confidence', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.doc_text_search, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No Meals Logged Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Tap the camera button to scan your first meal.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
           TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealHistoryScreen())),
            child: const Text('View Full History'),
          )
        ],
      ),
    );
  }
}
