import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/meal_analysis.dart';
import '../models/symptom_log.dart';
import '../providers/app_state_provider.dart';
import 'symptom_logged_confirmation_screen.dart';

class SymptomLogScreen extends StatefulWidget {
  final int initialSeverity;
  const SymptomLogScreen({super.key, this.initialSeverity = 3});

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1 Data
  final Set<String> _selectedSymptoms = {};
  final TextEditingController _customSymptomController = TextEditingController();
  final List<String> _commonSymptoms = [
    'Flushing', 'Fatigue', 'Brain Fog', 'Headache', 'Hives', 'GI Distress', 'Tachycardia'
  ];

  // Step 2 Data
  late int _severity;

  // Step 3 Data
  DateTime _timeStarted = DateTime.now();
  MealAnalysis? _linkedMeal;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _severity = widget.initialSeverity;
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _customSymptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeLog() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one symptom.'), backgroundColor: Colors.red));
      _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      return;
    }

    final provider = context.read<AppStateProvider>();
    final newLog = SymptomLog(
      id: const Uuid().v4(),
      userId: provider.user?.uid ?? 'anonymous',
      symptoms: _selectedSymptoms.toList(),
      severity: _severity,
      notes: _notesController.text,
      timestamp: _timeStarted,
      linkedMealId: _linkedMeal?.id,
    );
    
    await provider.logSymptom(newLog);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SymptomLoggedConfirmationScreen(log: newLog)),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / 3;

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage == 0
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _previousPage),
        title: Text('Step ${_currentPage + 1} of 3'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildSymptomSelectionStep(),
          _buildIntensityStep(),
          _buildFinalDetailsStep(),
        ],
      ),
    );
  }

  Widget _buildSymptomSelectionStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('What are you feeling?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Select all symptoms that apply to you right now.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        const SizedBox(height: 24),
        TextField(
          controller: _customSymptomController,
          decoration: InputDecoration(
            hintText: 'Search or add custom...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() => _selectedSymptoms.add(value.trim()));
              _customSymptomController.clear();
            }
          },
        ),
        const SizedBox(height: 16),
        const Text('Common MCAS Symptoms', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _commonSymptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return ChoiceChip(
              label: Text(symptom),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
              selectedColor: Colors.teal,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              backgroundColor: Colors.grey.shade200,
              shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.teal : Colors.grey.shade300)),
            );
          }).toList(),
        ),
         if (_selectedSymptoms.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Selected Symptoms', style: TextStyle(fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           Wrap(
             spacing: 8.0,
            runSpacing: 4.0,
            children: _selectedSymptoms.map((symptom) => Chip(
              label: Text(symptom),
              onDeleted: () => setState(() => _selectedSymptoms.remove(symptom)),
              backgroundColor: Colors.teal.shade50,
              deleteIconColor: Colors.teal.shade700,
            )).toList(),
           )
         ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildIntensityStep() {
     const labels = {
      1: 'Mild', 2: 'Minor', 3: 'Moderate', 4: 'Severe', 5: 'Very Severe'
    };
    final colors = {
      1: Colors.green, 2: Colors.lightGreen, 3: Colors.amber, 4: Colors.orange, 5: Colors.red
    };

    return Padding(
       padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text('How intense is it?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Rate the severity of your symptoms on a scale of 1 to 5.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: colors[_severity]!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Text('$_severity - ${labels[_severity]}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors[_severity])),
              ),
            ),
            const SizedBox(height: 24),
            Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: labels[_severity],
              activeColor: colors[_severity],
              onChanged: (val) => setState(() => _severity = val.round()),
            ),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Mild', style: TextStyle(color: Colors.grey.shade600)),
                 Text('Severe', style: TextStyle(color: Colors.grey.shade600)),
               ],
             ),
            const Spacer(),
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 50)),
              child: const Text('Continue'),
            ),
        ],
      ),
    );
  }

   Widget _buildFinalDetailsStep() {
     final provider = context.read<AppStateProvider>();
     final recentMeals = provider.meals.where((m) => DateTime.now().difference(m.timestamp).inHours <= 4).toList();

    return ListView(
       padding: const EdgeInsets.all(24),
      children: [
          const Text('Final Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Add context to help identify patterns.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 24),

        // --- Time Started ---
        const Text('Time Started', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_timeStarted));
            if(time != null) {
              setState(() {
                final now = DateTime.now();
                _timeStarted = DateTime(now.year, now.month, now.day, time.hour, time.minute);
              });
            }
          },
          child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
               color: Colors.grey.shade100,
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.grey.shade300)
             ),
            child: Row(children: [
              const Icon(CupertinoIcons.clock, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(child: Text(DateFormat.yMMMd().add_jm().format(_timeStarted))),
               const Text('Change', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            ],),
          ),
        ),

        const SizedBox(height: 24),

        // --- Link to Recent Meal ---
         const Text('Link to Recent Meal', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<MealAnalysis>(
          initialValue: _linkedMeal,
          hint: const Text('Choose a meal from the last 4 hours'),
           decoration: InputDecoration(
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
           ),
          items: recentMeals.map((meal) {
            return DropdownMenuItem<MealAnalysis>(
              value: meal,
              child: Text('${meal.mealName} (${DateFormat.jm().format(meal.timestamp)})'),
            );
          }).toList(),
          onChanged: (MealAnalysis? newValue) {
            setState(() => _linkedMeal = newValue);
          },
        ),

         const SizedBox(height: 24),
        
         // --- Notes ---
         const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Any additional details...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
             filled: true,
              fillColor: Colors.grey.shade100,
          ),
        ),
         const SizedBox(height: 24),

         // --- Complete Button ---
          ElevatedButton.icon(
          onPressed: _completeLog,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 50)),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Complete Log'),
        ),
      ],
    );
  }
}
