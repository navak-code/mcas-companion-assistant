import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'home_dashboard_screen.dart';

class OnboardingPresetsScreen extends StatefulWidget {
  const OnboardingPresetsScreen({super.key});

  @override
  State<OnboardingPresetsScreen> createState() => _OnboardingPresetsScreenState();
}

class _OnboardingPresetsScreenState extends State<OnboardingPresetsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Profile
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();

  // Step 2: Presets
  final Map<String, String> _availablePresets = {
    'sighi_level_0': 'SIGHI Level 0 (Well Tolerated / Safe Baseline)',
    'sighi_level_1': 'SIGHI Level 1 (Moderately Compatible Foods)',
    'sighi_liberators': 'Flag Histamine Liberators (Citrus, Shellfish, Strawberries)',
    'sighi_blockers': 'Flag DAO Enzyme Blockers (Alcohol, Black/Green Tea)',
    'preservatives': 'Artificial Preservatives, Sulfites, Nitrites & Benzoates',
    'leftovers': 'High Histamine Aging Alert (Leftovers & Aged Cheeses)',
  };
  late Set<String> _selectedPresets;

  // Step 3: AI Selection
  bool _useCloudAi = true;
  final TextEditingController _apiKeyController = TextEditingController();
  String? _keyValidationError;

  @override
  void initState() {
    super.initState();
    _selectedPresets = {'sighi_level_0', 'sighi_level_1', 'sighi_liberators', 'sighi_blockers'};
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _conditionsController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your preferred name.'), backgroundColor: Colors.red),
      );
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _finishOnboarding() async {
    if (!_useCloudAi && _apiKeyController.text.trim().isEmpty) {
      setState(() => _keyValidationError = 'API Key is required when opting out of Cloud AI.');
      return;
    }

    final provider = context.read<AppStateProvider>();
    await provider.completeOnboarding(
      name: _nameController.text.trim(),
      medicalConditions: _conditionsController.text.trim(),
      selectedPresets: _selectedPresets.toList(),
      useCloudAi: _useCloudAi,
      customApiKey: _useCloudAi ? null : _apiKeyController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Step ${_currentPage + 1} of 4'),
        centerTitle: true,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildProfileStep(),
          _buildMedicalStep(),
          _buildPresetStep(),
          _buildAiChoiceStep(),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    return _buildStepLayout(
      title: "Welcome to MCAS Companion",
      subtitle: "Let's personalize your care by setting up your profile.",
      content: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Your Preferred Name',
          hintText: 'e.g., Alex',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(CupertinoIcons.person),
        ),
        textCapitalization: TextCapitalization.words,
      ),
      onContinue: _nextPage,
    );
  }

  Widget _buildMedicalStep() {
    return _buildStepLayout(
      title: "Medical Profile",
      subtitle: "List any relevant diagnoses (e.g., MCAS, POTS, EDS, Histamine Intolerance). This helps calibrate trigger alerts.",
      content: TextField(
        controller: _conditionsController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Diagnoses / Sensitivities (Optional)',
          hintText: 'e.g., MCAS, POTS, DAO deficiency',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(CupertinoIcons.bandage),
        ),
      ),
      onContinue: _nextPage,
      onBack: _previousPage,
    );
  }

  Widget _buildPresetStep() {
    return _buildStepLayout(
      title: "Clinical Triggers",
      subtitle: "Select your baseline sensitivity presets to guide the AI when scanning meals.",
      content: ListView(
        shrinkWrap: true,
        children: _availablePresets.entries.map((entry) {
          final isSelected = _selectedPresets.contains(entry.key);
          return CheckboxListTile(
            value: isSelected,
            title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            activeColor: Colors.teal,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedPresets.add(entry.key);
                } else {
                  _selectedPresets.remove(entry.key);
                }
              });
            },
          );
        }).toList(),
      ),
      onContinue: _nextPage,
      onBack: _previousPage,
    );
  }

  Widget _buildAiChoiceStep() {
    return _buildStepLayout(
      title: "AI Engine Setup",
      subtitle: "Choose how your meal images are scanned and scored for histamine risks.",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: _useCloudAi ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _useCloudAi ? Colors.teal : Colors.grey.shade300,
                width: _useCloudAi ? 2 : 1,
              ),
            ),
            child: RadioListTile<bool>(
              value: true,
              groupValue: _useCloudAi,
              activeColor: Colors.teal,
              title: const Text('Use MCAS Cloud AI (Recommended)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Zero setup required. Powered automatically via secure Cloud Gemini Flash pipeline.'),
              onChanged: (val) => setState(() {
                _useCloudAi = val ?? true;
                _keyValidationError = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: !_useCloudAi ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: !_useCloudAi ? Colors.teal : Colors.grey.shade300,
                width: !_useCloudAi ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _useCloudAi,
                    activeColor: Colors.teal,
                    title: const Text('Bring Your Own Key (BYOK)', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Use your personal Google Gemini API key.'),
                    onChanged: (val) => setState(() => _useCloudAi = val ?? false),
                  ),
                  if (!_useCloudAi)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Google Gemini API Key',
                          hintText: 'AIzaSy...',
                          errorText: _keyValidationError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      onContinue: _finishOnboarding,
      onBack: _previousPage,
      continueText: 'Finish Setup & Start',
    );
  }

  Widget _buildStepLayout({
    required String title,
    required String subtitle,
    required Widget content,
    required VoidCallback onContinue,
    VoidCallback? onBack,
    String continueText = 'Continue',
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          const SizedBox(height: 20),
          Expanded(child: SingleChildScrollView(child: content)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onBack != null)
                OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back'),
                ),
              if (onBack != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(continueText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
