import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_analysis.dart';
import '../models/trigger_item.dart';
import '../providers/app_state_provider.dart';
import 'meal_detail_screen.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  String _searchQuery = '';
  RiskCategory? _selectedFilter;

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final allMeals = provider.meals;

    final filteredMeals = allMeals.where((meal) {
      final matchesFilter = _selectedFilter == null || meal.overallRisk == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          meal.detectedIngredients.any((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Meal Log History'),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search ingredients in meal history...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Meals'),
                        selected: _selectedFilter == null,
                        onSelected: (_) => setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Safe'),
                        selected: _selectedFilter == RiskCategory.safe,
                        selectedColor: const Color(0xFFECFDF5),
                        labelStyle: TextStyle(
                          color: _selectedFilter == RiskCategory.safe ? const Color(0xFF10B981) : Colors.black87,
                        ),
                        onSelected: (_) => setState(() => _selectedFilter = RiskCategory.safe),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Medium Risk'),
                        selected: _selectedFilter == RiskCategory.medium,
                        selectedColor: const Color(0xFFFFFBEB),
                        labelStyle: TextStyle(
                          color: _selectedFilter == RiskCategory.medium ? const Color(0xFFF59E0B) : Colors.black87,
                        ),
                        onSelected: (_) => setState(() => _selectedFilter = RiskCategory.medium),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('High Triggers'),
                        selected: _selectedFilter == RiskCategory.high,
                        selectedColor: const Color(0xFFFFF1F2),
                        labelStyle: TextStyle(
                          color: _selectedFilter == RiskCategory.high ? const Color(0xFFF43F5E) : Colors.black87,
                        ),
                        onSelected: (_) => setState(() => _selectedFilter = RiskCategory.high),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Meal List
          Expanded(
            child: filteredMeals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          allMeals.isEmpty ? 'No meals analyzed yet.' : 'No meals match your filter.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredMeals.length,
                    itemBuilder: (context, index) {
                      final meal = filteredMeals[index];
                      final firstThreeIngredients = meal.detectedIngredients.take(3).map((e) => e.name).join(', ');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    color: Colors.grey.shade200,
                                    child: meal.imageBytes != null
                                        ? Image.memory(meal.imageBytes!, fit: BoxFit.cover)
                                        : const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: meal.overallRisk.backgroundColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              meal.overallRisk.label,
                                              style: TextStyle(
                                                color: meal.overallRisk.color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDate(meal.timestamp),
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        firstThreeIngredients.isNotEmpty ? firstThreeIngredients : 'Analyzed meal',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${meal.detectedIngredients.length} ingredients • ${meal.confidencePercentage}% confidence',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}