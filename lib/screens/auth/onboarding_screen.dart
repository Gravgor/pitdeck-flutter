import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to PitDeck',
      'description': 'Your Ultimate Motorsport Card Collection',
      'icon': Icons.sports_motorsports,
      'gradient': [const Color(0xFF1A1A2E), const Color(0xFF0F0F1E)],
    },
    {
      'title': 'Discover & Collect',
      'description': 'Find rare cards from legendary races and iconic drivers',
      'icon': Icons.diamond_outlined,
      'gradient': [const Color(0xFF1A1A2E), const Color(0xFF0F0F1E)],
    },
    {
      'title': 'Trade & Connect',
      'description': 'Build your network and trade with fellow collectors',
      'icon': Icons.swap_horiz,
      'gradient': [const Color(0xFF1A1A2E), const Color(0xFF0F0F1E)],
    },
    {
      'title': 'Choose Your Identity',
      'description': 'Create your unique PitDeck profile',
      'icon': Icons.person_outline,
      'isLast': true,
      'gradient': [const Color(0xFF1A1A2E), const Color(0xFF0F0F1E)],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_usernameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .updateUsername(_usernameController.text);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPage(Map<String, dynamic> page) {
    if (page['isLast'] == true) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page['gradient'],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  page['icon'],
                  size: 80,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 32),
                Text(
                  page['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Orbitron',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'Orbitron',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.alternate_email,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page['gradient'],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                page['icon'],
                size: 80,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 48),
              Text(
                page['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              _currentPage == index ? 1 : 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: _currentPage == _pages.length - 1
                          ? ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _completeOnboarding,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _pages[_currentPage]
                                    ['gradient'][0],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Text(
                                      'GET STARTED',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                            )
                          : ElevatedButton(
                              onPressed: () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _pages[_currentPage]
                                    ['gradient'][0],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'NEXT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
