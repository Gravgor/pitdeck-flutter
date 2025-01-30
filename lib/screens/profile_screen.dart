import 'package:flutter/material.dart';
import 'package:pitdeck/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';
import 'package:pitdeck/providers/card_provider.dart';
import 'package:pitdeck/providers/favorite_provider.dart';
import 'package:pitdeck/providers/badge_provider.dart';
import 'package:pitdeck/models/badge.dart';
import 'package:pitdeck/providers/scroll_notifier.dart';
import 'package:pitdeck/screens/friends_screen.dart';

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
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: widget.isCurrentUser
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1A1A2E),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 64,
              backgroundColor: const Color(0xFF0A0A1A),
              pinned: true,
              title: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF3B82F6), width: 2),
                        ),
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, _) => Image.network(
                            userProvider.user?.image ??
                                'https://via.placeholder.com/40',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person,
                                    color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) {
                          if (userProvider.user?.isPremium == true) {
                            return Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                color: const Color(0xFFFFD700),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) => Text(
                      userProvider.user?.name ?? 'Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.people_outline,
                      color: Colors.white.withOpacity(0.7)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FriendsScreen()),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined,
                      color: Colors.white.withOpacity(0.7)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: GestureDetector(
                        onTap: () => _showBioEditModal(context),
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Bio',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userProvider.user?.bio ?? 'Tap to add bio',
                                style: TextStyle(
                                  color: userProvider.user?.bio != null
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  fontSize: 14,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          _buildLargeProfileTag(
                            Icons.military_tech,
                            'Level ${context.watch<UserProvider>().user?.level ?? 1}',
                          ),
                          const SizedBox(width: 12),
                          _buildLargeProfileTag(
                            Icons.monetization_on,
                            _formatNumber(
                                context.watch<UserProvider>().user?.coins ?? 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStats(),
                  _buildNavigation(),
                  const SizedBox(height: 16),
                  _buildContent(),
                ],
              ),
            ),
            if (Provider.of<CardProvider>(context, listen: false).isLoading)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _showBioEditModal(BuildContext context) {
    final TextEditingController bioController = TextEditingController(
      text: context.read<UserProvider>().user?.bio ?? '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: bioController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                  maxLength: 150,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    hintText: 'Write something about yourself...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontFamily: 'Orbitron',
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Update bio in UserProvider
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.map_outlined, Icons.map, 'Map', false),
              _buildNavItem(Icons.card_membership_outlined,
                  Icons.card_membership, 'Collection', false),
              _buildNavItem(Icons.store_outlined, Icons.store, 'Market', false),
              _buildNavItem(
                  Icons.person_outline, Icons.person, 'Profile', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label,
      bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          final int index = label == 'Collection'
              ? 1
              : label == 'Market'
                  ? 2
                  : label == 'Profile'
                      ? 3
                      : 0;
          Provider.of<NavigationProvider>(context, listen: false)
              .changePage(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : Colors.white.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontFamily: 'Orbitron',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeProfileTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          _buildStatItem('Collection', '202'),
          _buildStatDivider(),
          _buildStatItem('Favorites', '44'),
          _buildStatDivider(),
          _buildStatItem('Badges', '12'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildNavigation() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          _buildNavItemProfile('Collection', _selectedIndex == 0, 0),
          _buildNavItemProfile('Favorites', _selectedIndex == 1, 1),
          _buildNavItemProfile('Badges', _selectedIndex == 2, 2),
        ],
      ),
    );
  }

  Widget _buildNavItemProfile(String title, bool isSelected, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildCollection(),
          _buildFavorites(),
          _buildBadges(),
        ],
      ),
    );
  }

  Widget _buildCollection() {
    return Consumer<CardProvider>(
      builder: (context, cardProvider, _) {
        if (cardProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final cards = cardProvider.cards;
        if (cards.isEmpty) {
          return _buildEmptyState(
            icon: Icons.style_outlined,
            title: 'No Cards Yet',
            description:
                'Start collecting cards by opening packs or trading with others!',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Recent Collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cards.length > 6 ? 6 : cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.network(
                          card.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black.withOpacity(0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.rarity.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${card.serialNumber}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (cards.length > 6) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextButton(
                  onPressed: () {
                    Provider.of<NavigationProvider>(context, listen: false)
                        .changePage(1);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All ${cards.length} Cards',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF3B82F6),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFavorites() {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, _) {
        if (favoriteProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = favoriteProvider.favorites;
        if (favorites.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_outline,
            title: 'No Favorites',
            description: 'Add your favorite cards to quickly access them here!',
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final favorite = favorites[index];
            return Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  Image.network(
                    favorite.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black.withOpacity(0.7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favorite.type,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          Text(
                            favorite.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadges() {
    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, _) {
        if (badgeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final badges = badgeProvider.badges;
        if (badges.isEmpty) {
          return _buildEmptyState(
            icon: Icons.military_tech_outlined,
            title: 'No Badges',
            description: 'Complete achievements to earn special badges!',
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    badge.icon,
                    color: badge.isUnlocked
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withOpacity(0.3),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    style: TextStyle(
                      color: badge.isUnlocked
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontFamily: 'Orbitron',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'LEGENDARY':
        return const Color(0xFFFFD700);
      case 'EPIC':
        return const Color(0xFFE040FB);
      case 'RARE':
        return const Color(0xFF3B82F6);
      case 'UNCOMMON':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }
}
