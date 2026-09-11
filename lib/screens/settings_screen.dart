import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/ai_vision_service.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final displayName = provider.userName ?? 'MCAS Patient';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';
    final conditions = provider.medicalConditions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // Profile Header Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      initial,
                      style: TextStyle(fontSize: 24, color: Colors.teal.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          (conditions != null && conditions.isNotEmpty) ? conditions : 'No conditions added yet',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Profile Section
          _buildSettingsSection(context, "Profile & Medical Conditions", [
            _buildSettingsTile(
              context,
              icon: CupertinoIcons.person,
              title: 'Preferred Name',
              trailing: displayName,
              onTap: () => _showEditDialog(
                context,
                title: 'Preferred Name',
                initialValue: provider.userName ?? '',
                onSave: (newName) {
                  provider.updateUserProfile(name: newName);
                },
              ),
            ),
            const Divider(height: 1, indent: 56),
            _buildSettingsTile(
              context,
              icon: CupertinoIcons.bandage,
              title: 'Medical Conditions / Triggers',
              trailing: (conditions != null && conditions.isNotEmpty) ? conditions : 'Tap to Add',
              onTap: () => _showEditDialog(
                context,
                title: 'Medical Conditions / Triggers',
                initialValue: conditions ?? '',
                onSave: (newConditions) {
                  provider.updateUserProfile(medicalConditions: newConditions);
                },
              ),
            ),
            const Divider(height: 1, indent: 56),
            _buildSettingsTile(
              context,
              icon: CupertinoIcons.sparkles,
              title: 'AI Vision Engine & API Key',
              trailing: provider.useCloudAi ? 'Central Cloud (Beta)' : 'Personal BYOK (${AiVisionService.modelName})',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSettingsScreen()));
              },
            ),
          ]),

          const SizedBox(height: 28),

          // Sign Out Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            onPressed: () async {
              await provider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: title.contains('Conditions') ? 3 : 1,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: title,
              hintText: 'Enter new value...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onSave(controller.text.trim());
                }
                Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade700),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                trailing,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late bool _useCloudAi;
  late TextEditingController _apiKeyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppStateProvider>();
    _useCloudAi = provider.useCloudAi;
    _apiKeyController = TextEditingController(text: provider.customApiKey ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSaveChanges() async {
    setState(() => _isSaving = true);
    final provider = context.read<AppStateProvider>();
    final key = _apiKeyController.text.trim();

    if (!_useCloudAi) {
      if (key.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Key cannot be empty for BYOK mode.'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }
      final isValid = await provider.testCustomApiKey(key);
      if (!isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The provided Gemini API Key is invalid or expired.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    await provider.updateAiPreference(
      useCloudAi: _useCloudAi,
      customApiKey: _useCloudAi ? null : key,
    );

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Settings Saved Successfully!'), backgroundColor: Colors.teal),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Vision Engine')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Primary BYOK Option
          Card(
            elevation: !_useCloudAi ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: !_useCloudAi ? Colors.teal : Colors.grey.shade300, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _useCloudAi,
                    activeColor: Colors.teal,
                    title: const Text('Bring Your Own Key (BYOK)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Recommended for immediate high-speed scanning.'),
                    onChanged: (val) => setState(() => _useCloudAi = val ?? false),
                  ),
                  if (!_useCloudAi) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Your Google Gemini API Key',
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target model: ${AiVisionService.modelName}. Your key is stored securely on your device.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Beta Central Cloud AI Option
          Card(
            elevation: _useCloudAi ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _useCloudAi ? Colors.teal : Colors.grey.shade300, width: 2),
            ),
            child: SwitchListTile(
              title: const Text('Use Central Cloud AI (Beta Feature)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Developer preview. Uses central project backend credentials.'),
              value: _useCloudAi,
              activeColor: Colors.teal,
              onChanged: (val) => setState(() => _useCloudAi = val),
              secondary: const Icon(CupertinoIcons.lab_flask_solid),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSaving ? null : _validateAndSaveChanges,
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
