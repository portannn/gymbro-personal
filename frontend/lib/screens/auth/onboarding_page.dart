import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../utils/palette.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Form data
  String _selectedGender = '';
  final List<String> _selectedGoals = [];
  double _currentWeight = 70.0;
  final double _targetWeight = 65.0;
  final TextEditingController _weightController = TextEditingController();

  final List<String> _genders = ['male', 'female'];
  final List<String> _goals = [
    'Weight Loss',
    'Muscle Gain', 
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _weightController.text = _currentWeight.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    if (_currentPage == 0) return _selectedGender.isNotEmpty;
    if (_currentPage == 1) return _selectedGoals.isNotEmpty;
    if (_currentPage == 2) return _currentWeight > 0;
    return true;
  }

  void _nextPage() {
    if (_canProceed() && _currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    debugPrint('OnboardingPage - Starting completion...');
    
    final authProvider = context.read<AuthProvider>();
    
    final onboardingData = {
      'gender': _selectedGender,
      'goals': _selectedGoals,
      'currentWeight': _currentWeight,
      'targetWeight': _targetWeight,
      'onboardingCompleted': true,
    };

    debugPrint('OnboardingPage - Data: $onboardingData');
    
    final success = await authProvider.completeOnboarding(onboardingData);
    
    debugPrint('OnboardingPage - Success: $success');
    
    if (success && mounted) {
      debugPrint('OnboardingPage - Navigating to home...');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      debugPrint('OnboardingPage - Failed to complete onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? _previousPage : null,
                    icon: const Icon(Icons.arrow_back, color: kTextPrimary),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 4,
                      backgroundColor: kCard,
                      valueColor: const AlwaysStoppedAnimation<Color>(kAccent),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGenderPage(),
                  _buildGoalsPage(),
                  _buildWeightPage(),
                  _buildSummaryPage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(color: kAccent),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentPage == 3 ? _completeOnboarding : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: kBg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: kCard,
                        disabledForegroundColor: kTextMuted,
                      ),
                      child: Text(_currentPage == 3 ? 'Complete Setup' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your gender?',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us personalize your workout recommendations.',
            style: TextStyle(color: kTextMuted, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ..._genders.map((gender) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GenderOption(
              gender: gender,
              isSelected: _selectedGender == gender,
              onTap: () => setState(() => _selectedGender = gender),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are your fitness goals?',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that apply to you.',
            style: TextStyle(color: kTextMuted, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _goals.map((goal) => _GoalOption(
              goal: goal,
              isSelected: _selectedGoals.contains(goal),
              onTap: () {
                setState(() {
                  if (_selectedGoals.contains(goal)) {
                    _selectedGoals.remove(goal);
                  } else {
                    _selectedGoals.add(goal);
                  }
                });
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your current weight?',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us track your progress and calculate calories.',
            style: TextStyle(color: kTextMuted, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: kTextPrimary, fontSize: 24),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter weight',
                            hintStyle: TextStyle(color: kTextMuted),
                          ),
                          onChanged: (value) {
                            final weight = double.tryParse(value);
                            if (weight != null && weight >= 30 && weight <= 200) {
                              setState(() => _currentWeight = weight);
                            }
                          },
                          onEditingComplete: () {
                            final weight = double.tryParse(_weightController.text);
                            if (weight == null || weight < 30) {
                              setState(() {
                                _currentWeight = 30.0;
                                _weightController.text = '30.0';
                              });
                            } else if (weight > 200) {
                              setState(() {
                                _currentWeight = 200.0;
                                _weightController.text = '200.0';
                              });
                            }
                          },
                        ),
                      ),
                      const Text(
                        'kg',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _currentWeight,
                  min: 30,
                  max: 200,
                  divisions: 170,
                  activeColor: kAccent,
                  inactiveColor: kCard,
                  onChanged: (value) {
                    setState(() {
                      _currentWeight = value;
                      _weightController.text = value.toStringAsFixed(1);
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '30 kg',
                      style: TextStyle(color: kTextMuted, fontSize: 12),
                    ),
                    Text(
                      '200 kg',
                      style: TextStyle(color: kTextMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You\'re all set!',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Here\'s your profile summary:',
            style: TextStyle(color: kTextMuted, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _SummaryItem(label: 'Gender', value: _selectedGender),
                const Divider(color: Colors.white10),
                _SummaryItem(label: 'Goals', value: _selectedGoals.join(', ')),
                const Divider(color: Colors.white10),
                _SummaryItem(label: 'Current Weight', value: '${_currentWeight.toStringAsFixed(1)} kg'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'We\'ll use this information to personalize your workout recommendations and track your progress.',
            style: TextStyle(color: kTextMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  final String gender;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? kAccent.withAlpha(31) : kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kAccent : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person,
              color: isSelected ? kAccent : kTextMuted,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                gender[0].toUpperCase() + gender.substring(1),
                style: TextStyle(
                  color: isSelected ? kAccent : kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kAccent),
          ],
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  final String goal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kAccent.withAlpha(31) : kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kAccent : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          goal,
          style: TextStyle(
            color: isSelected ? kAccent : kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
