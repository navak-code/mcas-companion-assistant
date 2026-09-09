import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/meal_analysis.dart';
import '../providers/app_state_provider.dart';

class MealDetailScreen extends StatelessWidget {
  final MealAnalysis meal;
  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.mealName),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (meal.imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                meal.imageBytes!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(meal.mealName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: meal.overallRisk.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          meal.overallRisk.label,
                          style: TextStyle(color: meal.overallRisk.color, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // CORRECTED ICON
                      const Icon(CupertinoIcons.sparkles, size: 16, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        '${meal.confidencePercentage}% AI Confidence • ${DateFormat.yMMMd().add_jm().format(meal.timestamp)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
           if (meal.clinicalNotes.isNotEmpty) ...[
            Text('Clinical Notes & Guidance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill, color: Colors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        meal.clinicalNotes,
                        style: TextStyle(color: Colors.teal.shade900, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
           Text('Detected Ingredients Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...meal.detectedIngredients.map((ingredient) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ingredient.riskCategory.backgroundColor,
                    child: Text(
                      '${ingredient.sighiScore}',
                      style: TextStyle(color: ingredient.riskCategory.color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(ingredient.reasoning),
                ),
              )),
             const SizedBox(height: 24),
              if (!meal.isConfirmed)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm & Log Meal', style: TextStyle(fontSize: 16)),
                    onPressed: () async {
                       await context.read<AppStateProvider>().confirmMeal(meal);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Meal confirmed successfully!'), backgroundColor: Colors.teal),
                          );
                          Navigator.pop(context);
                        }
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
