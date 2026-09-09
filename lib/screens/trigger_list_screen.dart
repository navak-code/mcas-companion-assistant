import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/trigger_item.dart';
import '../providers/app_state_provider.dart';

class TriggerListScreen extends StatefulWidget {
  const TriggerListScreen({super.key});

  @override
  State<TriggerListScreen> createState() => _TriggerListScreenState();
}

class _TriggerListScreenState extends State<TriggerListScreen> {
  final Uuid _uuid = const Uuid();
  String _searchQuery = '';
  RiskCategory? _selectedFilter;

  void _showAddTriggerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    RiskCategory selectedCategory = RiskCategory.high;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Trigger'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Food or Trigger Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RiskCategory>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Risk Level',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: RiskCategory.high, child: Text(RiskCategory.high.label)),
                    DropdownMenuItem(value: RiskCategory.medium, child: Text(RiskCategory.medium.label)),
                    DropdownMenuItem(value: RiskCategory.safe, child: Text(RiskCategory.safe.label)),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Personal Notes / Symptoms Caused',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final newTrigger = TriggerItem(
                    id: _uuid.v4(),
                    name: nameController.text.trim(),
                    category: selectedCategory,
                    notes: notesController.text.trim(),
                    isUserCustom: true,
                  );
                  context.read<AppStateProvider>().addTrigger(newTrigger);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Trigger'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final triggers = provider.triggers.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.notes.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == null || item.category == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIGHI & Personal Triggers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        onPressed: () => _showAddTriggerDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Custom'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search foods, chemicals, or SIGHI ratings...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedFilter == null,
                        onSelected: (_) => setState(() => _selectedFilter = null),
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
                        label: const Text('Safe Foods'),
                        selected: _selectedFilter == RiskCategory.safe,
                        selectedColor: const Color(0xFFECFDF5),
                        labelStyle: TextStyle(
                          color: _selectedFilter == RiskCategory.safe ? const Color(0xFF10B981) : Colors.black87,
                        ),
                        onSelected: (_) => setState(() => _selectedFilter = RiskCategory.safe),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: triggers.isEmpty
                ? const Center(child: Text('No matching trigger items found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: triggers.length,
                    itemBuilder: (context, index) {
                      final item = triggers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.category.backgroundColor,
                            child: Icon(Icons.restaurant_menu, color: item.category.color, size: 20),
                          ),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(item.notes.isNotEmpty ? item.notes : item.category.label),
                          trailing: item.isUserCustom
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () => provider.deleteTrigger(item.id),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('SIGHI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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