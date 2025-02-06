import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040412),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A1A2E),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSection(
                    'Account',
                    [
                      _buildSettingItem(
                        'Profile Picture',
                        Icons.person,
                        onTap: () {
                          // Handle profile picture change
                        },
                      ),
                      _buildSettingItem(
                        'Background Image',
                        Icons.image,
                        isPremium: true,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A1A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(8),
                                        ),
                                        image: const DecorationImage(
                                          image: NetworkImage(
                                            'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text(
                                              'REMOVE',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Orbitron',
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // Handle image selection
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              'CHANGE',
                                              style: TextStyle(
                                                color: Color(0xFF4B9FFF),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Orbitron',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        'Change Username',
                        Icons.edit,
                        onTap: () {
                          // Handle username change
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    'Preferences',
                    [
                      _buildSettingItem(
                        'Notifications',
                        Icons.notifications,
                        onTap: () {
                          // Handle notifications settings
                        },
                      ),
                      _buildSettingItem(
                        'Language',
                        Icons.language,
                        value: 'English',
                        onTap: () {
                          // Handle language change
                        },
                      ),
                      _buildSettingItem(
                        'Sound Effects',
                        Icons.volume_up,
                        isToggle: true,
                        onTap: () {
                          // Handle sound toggle
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    'Support',
                    [
                      _buildSettingItem(
                        'Help Center',
                        Icons.help,
                        onTap: () {
                          // Navigate to help center
                        },
                      ),
                      _buildSettingItem(
                        'Privacy Policy',
                        Icons.privacy_tip,
                        onTap: () {
                          // Show privacy policy
                        },
                      ),
                      _buildSettingItem(
                        'Terms of Service',
                        Icons.description,
                        onTap: () {
                          // Show terms of service
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        // Handle logout
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'LOGOUT',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon, {
    String? value,
    bool isPremium = false,
    bool isToggle = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4B9FFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4B9FFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  if (isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                ),
              ),
            if (isToggle)
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF4B9FFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            if (!isToggle && value == null)
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.5),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
