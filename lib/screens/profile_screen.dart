import 'package:flutter/material.dart';
import 'package:pitdeck/providers/trade_provider.dart';
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
import 'package:pitdeck/screens/collection_screen.dart';

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
      body: Stack(
        children: [
          Image.asset(
            'assets/images/racing_bg.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.1),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStats(),
                _buildNavigation(),
                Expanded(child: _buildContent()),
                _buildBottomNavigationBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF4B9FFF), width: 2),
                    ),
                    child: Image.network(
                      '${Provider.of<UserProvider>(context).user?.image}',
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (widget.isCurrentUser)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4B9FFF),
                          border: Border.all(
                              color: const Color(0xFF1A1A2E), width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${Provider.of<UserProvider>(context).user?.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B9FFF).withOpacity(0.2),
                            border: Border.all(color: const Color(0xFF4B9FFF)),
                          ),
                          child: Text(
                            'LVL ${Provider.of<UserProvider>(context).user?.level}',
                            style: const TextStyle(
                              color: Color(0xFF4B9FFF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            border: Border.all(color: const Color(0xFFFFD700)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                size: 12,
                                color: Color(0xFFFFD700),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${Provider.of<UserProvider>(context).user?.coins} RC',
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
          const SizedBox(height: 12),
          Text(
            '${Provider.of<UserProvider>(context).user?.bio}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Badges'),
          const SizedBox(height: 16),
          _buildBadgesGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('Favorite Cards'),
          const SizedBox(height: 16),
          _buildFavoriteCards(),
         /* const SizedBox(height: 24),
          _buildSectionTitle('Recent Achievements'),
          const SizedBox(height: 16),
          _buildAchievementItem(
            title: 'Speed Demon',
            description: 'Win 5 races in a row',
            progress: 0.8,
            reward: '500 XP',
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            title: 'Collector',
            description: 'Collect 100 unique cards',
            progress: 0.6,
            reward: '1000 XP',
          ),*/
        ],
      ),
    );
  }

  IconData _getBadgeIcon(int index) {
    final icons = [
      Icons.speed,
      Icons.emoji_events,
      Icons.star,
      Icons.local_fire_department,
      Icons.trending_up,
      Icons.military_tech,
      Icons.workspace_premium,
      Icons.diamond,
    ];
    return icons[index % icons.length];
  }

  Widget _buildFavoriteCards() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border:
                  Border.all(color: const Color(0xFF4B9FFF).withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.directions_car,
                    color: const Color(0xFF4B9FFF).withOpacity(0.5),
                    size: 48,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                    ),
                    child: Text(
                      'Car ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            border: Border.all(color: const Color(0xFF4B9FFF).withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getBadgeIcon(index),
                  color: const Color(0xFF4B9FFF),
                  size: 32,
                ),
              ),
              if (index > 5)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white.withOpacity(0.5),
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level Progress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  Text(
                    '2,345 / 5,000 XP',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.47, // 2345/5000
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4B9FFF), Color(0xFF3B82F6)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats Grid
          Row(
            children: [
              _buildStatItem(
                label: 'Cards',
                value: '${Provider.of<CardProvider>(context).cards.length}',
                icon: Icons.style,
              ),
              _buildStatDivider(),

              _buildStatItem(
                label: 'Trades',
                value: '${Provider.of<TradeProvider>(context).trades.length}',
                icon: Icons.swap_horiz,
              ),

              _buildStatDivider(),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4B9FFF).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFF4B9FFF).withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4B9FFF),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
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
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildStatsContent(),
          _buildInventoryContent(),
          _buildSettingsContent(),
        ],
      ),
    );
  }

  Widget _buildInventoryContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Collection'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B9FFF).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFF4B9FFF)),
                ),
                child: Text(
                  '${Provider.of<CardProvider>(context).cards.length} Cards',
                  style: const TextStyle(
                    color: Color(0xFF4B9FFF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',

                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: Provider.of<CardProvider>(context).cards.length,
            itemBuilder: (context, index) {
              final card = Provider.of<CardProvider>(context).cards[index];
              return Container(
                decoration: BoxDecoration(

                  color: const Color(0xFF1A1A2E),
                  border: Border.all(
                      color: const Color(0xFF4B9FFF).withOpacity(0.3)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4B9FFF).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Image.network(
                        card.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),

                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              border:
                                  Border.all(color: const Color(0xFFFFD700)),
                            ),
                            child: Text(
                              card.rarity,
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',

                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const CollectionScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF4B9FFF)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4B9FFF).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'VIEW FULL COLLECTION',
                  style: TextStyle(
                    color: Color(0xFF4B9FFF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          /* const SizedBox(height: 24),
          _buildSectionTitle('Card Packs'),
          const SizedBox(height: 16),

          _buildPackItem(
            name: 'Premium Pack',
            quantity: 2,
            rarity: 'RARE',
          ),
          const SizedBox(height: 12),
          _buildPackItem(
            name: 'Standard Pack',
            quantity: 5,
            rarity: 'COMMON',
          ),*/
        ],
      ),
    );

  }

  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingItem(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () {},
        ),
        _buildSettingItem(
          icon: Icons.link,
          title: 'Connect Social Accounts',
          onTap: () {},
        ),
        _buildSettingItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {},
        ),
        _buildSettingItem(
          icon: Icons.logout,
          title: 'Logout',
          isDestructive: true,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Orbitron',
      ),
    );
  }

  Widget _buildAchievementItem({
    required String title,
    required String description,
    required double progress,
    required String reward,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: const Color(0xFF4B9FFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B9FFF).withOpacity(0.2),
                  border: Border.all(color: const Color(0xFF4B9FFF)),
                ),
                child: Text(
                  reward,
                  style: const TextStyle(
                    color: Color(0xFF4B9FFF),
                    fontSize: 12,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
            ),
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4B9FFF), Color(0xFF3B82F6)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackItem({
    required String name,
    required int quantity,
    required String rarity,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border.all(color: const Color(0xFF4B9FFF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4B9FFF).withOpacity(0.1),
              border: Border.all(color: const Color(0xFF4B9FFF)),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Color(0xFF4B9FFF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                Text(
                  rarity,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4B9FFF).withOpacity(0.2),
              border: Border.all(color: const Color(0xFF4B9FFF)),
            ),
            child: Text(
              'x$quantity',
              style: const TextStyle(
                color: Color(0xFF4B9FFF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFF4B9FFF),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
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

  Widget _buildNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildNavItemSmall(
                  title: 'Stats',
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  isSelected: _selectedIndex == 0,
                  index: 0,
                ),
                _buildNavItemSmall(
                  title: 'Collection',
                  icon: Icons.inventory_2_outlined,
                  selectedIcon: Icons.inventory_2,
                  isSelected: _selectedIndex == 1,
                  index: 1,
                ),
                _buildNavItemSmall(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  isSelected: _selectedIndex == 2,
                  index: 2,
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * _selectedIndex / 3,
              right:
                  MediaQuery.of(context).size.width * (2 - _selectedIndex) / 3,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4B9FFF), Color(0xFF3B82F6)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItemSmall({
    required String title,
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required int index,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4B9FFF).withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? const Color(0xFF4B9FFF)
                    : Colors.white.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4B9FFF)
                      : Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
