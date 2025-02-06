import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';
import 'package:pitdeck/screens/profile/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    this.userId,
    this.isCurrentUser = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrentUser) {
      _initializeUserSocket();
    }
    _loadUserData();
  }

  Future<void> _initializeUserSocket() async {
    final auth = Provider.of<UserProvider>(context, listen: false);
    await auth.connectUserSocket();
  }

  Future<void> _loadUserData() async {
    if (!widget.isCurrentUser && widget.userId != null) {
      await Provider.of<UserProvider>(context, listen: false)
          .fetchUserProfile(widget.userId!);
    }
  }

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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        if (widget.isCurrentUser)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },

                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Provider.of<UserProvider>(context)
                                            .user
                                            ?.name ??
                                        'null',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4B9FFF)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.military_tech,
                                              color: Color(0xFF4B9FFF),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'LVL ${Provider.of<UserProvider>(context).user?.level ?? 'null'}',
                                              style: const TextStyle(
                                                color: Color(0xFF4B9FFF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Orbitron',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.monetization_on,
                                              color: Color(0xFFFFD700),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${Provider.of<UserProvider>(context).user?.coins ?? 'null'} RC',
                                              style: const TextStyle(
                                                color: Color(0xFFFFD700),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Orbitron',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildBadgePreview(
                              Icons.speed,
                              Colors.red,
                            ),
                            const SizedBox(width: 8),
                            _buildBadgePreview(
                              Icons.emoji_events,
                              Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 8),
                            _buildBadgePreview(
                              Icons.local_fire_department,
                              Color(0xFF4B9FFF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap:
                              widget.isCurrentUser ? _showEditBioModal : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    Provider.of<UserProvider>(context)
                                            .user
                                            ?.bio ??
                                        'Add bio...',
                                    style: TextStyle(
                                      color: Provider.of<UserProvider>(context)
                                                  .user
                                                  ?.bio !=
                                              null
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.white.withOpacity(0.3),
                                      fontSize: 14,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ),
                                if (widget.isCurrentUser)
                                  Icon(
                                    Icons.edit,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 16,
                                  ),
                              ],
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
          // Rest of the content...
        ],
      ),
    );
  }

  Widget _buildBadgePreview(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }


  void _showEditBioModal() {
    final TextEditingController bioController = TextEditingController(
      text: Provider.of<UserProvider>(context, listen: false).user?.bio,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Bio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      Text(
                        'Enter your bio',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF040412),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: bioController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Orbitron',
                          ),
                          maxLines: 3,
                          maxLength: 150,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Add bio...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                              fontFamily: 'Orbitron',
                            ),
                            counterStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF040412),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Provider.of<UserProvider>(context,
                                        listen: false)
                                    .updateUserBio(bioController.text);
                                Navigator.pop(context);

                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4B9FFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'SAVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
