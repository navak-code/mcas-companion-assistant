import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/symptom_log.dart';
import 'meal_history_screen.dart';

class SymptomLoggedConfirmationScreen extends StatelessWidget {
  final SymptomLog log;
  const SymptomLoggedConfirmationScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.teal, size: 80),
              const SizedBox(height: 24),
              const Text('Symptom Logged', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Your data has been securely saved to your history. This helps MCAS Companion identify your personal triggers.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.question_circle, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(log.symptoms.join(', '), style: const TextStyle(fontWeight: FontWeight.w500))),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(CupertinoIcons.chart_bar_alt_fill, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text('Severity: ${log.severity}/5', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    if (log.notes.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(CupertinoIcons.pencil_ellipsis_rectangle, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Expanded(child: Text(log.notes, style: const TextStyle(fontStyle: FontStyle.italic))),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Dashboard'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MealHistoryScreen()));
                },
                icon: const Icon(CupertinoIcons.list_bullet),
                label: const Text('View Log History'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
