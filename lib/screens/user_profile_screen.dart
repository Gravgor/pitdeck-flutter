import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../providers/badge_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _isCurrentUser = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _user = await userProvider.fetchAnotherUser(widget.userId);

      if (_user == null) {
        // Mock data for testing
        _user = User(
          id: widget.userId,
          name: 'Test User',
          image: 'https://picsum.photos/200',
          bio:
              'This is a mock user profile for testing purposes. The real user was not found.',
          level: 42,
          coins: 15000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          token: '1234567890',
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      // If there's an error, use mock data
      _user = User(
        id: widget.userId,
        name: 'Error Test User',
        image: 'https://picsum.photos/200',
        bio:
            'This is a mock user profile shown due to an error loading the real profile.',
        level: 7,
        coins: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        token: '1234567890',
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF040412),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF040412),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1494976388531-d1058494cdd8',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF040412).withOpacity(0.85),
            ),
          ),
          Column(
            children: [
              Container(
                color: const Color(0xFF0A0A1A).withOpacity(0.8),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            if (!_isCurrentUser)
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.person_add,
                                    label: 'Add Friend',
                                    onTap: () {
                                      // TODO: Implement friend request
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.mail_outline,
                                    label: 'Message',
                                    onTap: () {
                                      // TODO: Implement messaging
                                    },
                                  ),
                                ],
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
                                  child: Image.network(
                                    _user?.image ??
                                        'https://via.placeholder.com/150',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _user?.name ?? 'Unknown User',
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
                                          _buildInfoChip(
                                            icon: Icons.military_tech,
                                            label: 'LVL ${_user?.level ?? 0}',
                                            color: const Color(0xFF4B9FFF),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildInfoChip(
                                            icon: Icons.monetization_on,
                                            label: '${_user?.coins ?? 0} RC',
                                            color: const Color(0xFFFFD700),
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
                                _buildBadges(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'User not found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildCollection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollection() {
    //if (_user?.recentCards == null || _user!.recentCards!.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No cards to display',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgePreview(String badgeUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        badgeUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),

    );
  }

  Widget _buildBadges() {
    return Consumer<BadgeProvider>(
      builder: (context, provider, child) {
        if (provider.badges.isEmpty) {
          return const SizedBox.shrink();
        }

        final badges = provider.badges.take(5).toList();
        return Row(
          children: badges.map((badge) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildBadgePreview(badge.imageUrl),
            );
          }).toList(),
        );
      },
    );
  }
}
