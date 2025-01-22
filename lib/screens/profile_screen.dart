import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';
import 'package:pitdeck/providers/card_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 90,
              backgroundColor: const Color(0xFF0A0A1A),
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF0A0A1A),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF3B82F6),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Consumer<UserProvider>(
                                    builder: (context, userProvider, _) =>
                                        Image.network(
                                      userProvider.user?.image ??
                                          'https://via.placeholder.com/60',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
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
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700),
                                              Color(0xFFFFA500)
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700)
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'PREMIUM',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Orbitron',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<UserProvider>(
                                  builder: (context, userProvider, _) => Text(
                                    userProvider.user?.name ?? 'Guest',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.military_tech,
                                            color: Color(0xFF3B82F6),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Consumer<UserProvider>(
                                            builder:
                                                (context, userProvider, _) =>
                                                    Text(
                                              'Level ${userProvider.user?.level ?? 1}',
                                              style: const TextStyle(
                                                color: Color(0xFF3B82F6),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Consumer<UserProvider>(
                                      builder: (context, userProvider, _) =>
                                          Row(
                                        children: [
                                          Icon(
                                            Icons.monetization_on,
                                            color: const Color(0xFFFFD700),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_formatNumber(userProvider.user?.coins ?? 0)}',
                                            style: const TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'RaceCoins',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatItem(
                                        Icons.grid_view, '142', 'Cards'),
                                    const SizedBox(width: 16),
                                    _buildStatItem(
                                        Icons.swap_horiz, '23', 'Trades'),
                                    const SizedBox(width: 16),
                                    _buildStatItem(Icons.sell, '15', 'Sales'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Bio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) => Text(
                      userProvider.user?.bio ??
                          'Racing enthusiast and collector. Always looking for rare cards and epic moments in motorsport history!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Badges',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildBadge(
                            'Early Bird', 'assets/badges/early_bird.png', true),
                        _buildBadge(
                            'Collector', 'assets/badges/collector.png', true),
                        _buildBadge(
                            'Trading Pro', 'assets/badges/trading.png', false),
                        _buildBadge(
                            'Legend', 'assets/badges/legend.png', false),
                        _buildBadge(
                            'Pioneer', 'assets/badges/pioneer.png', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Favorites',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFavoriteItem('Driver', 'https://picsum.photos/100',
                          'Max Verstappen'),
                      _buildFavoriteItem('Team', 'https://picsum.photos/101',
                          'Red Bull Racing'),
                      _buildFavoriteItem(
                          'Series', 'https://picsum.photos/102', '2024 Season'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Collection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final navProvider = Provider.of<NavigationProvider>(
                              context,
                              listen: false);
                          navProvider.changePage(1); // Switch to Collection tab
                        },
                        child: Row(
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white.withOpacity(0.7),
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: Consumer<CardProvider>(
                      builder: (context, cardProvider, _) {
                        final cards = cardProvider.cards.take(5).toList();
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getRarityColor(card.rarity)
                                            .withOpacity(0.3),
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(card.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    card.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Text(
                                        '#${card.serialNumber}',
                                        style: TextStyle(
                                          color: _getRarityColor(card.rarity),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.map, 'Map', false),
              _buildNavItem(Icons.card_membership, 'Collection', false),
              _buildNavItem(Icons.store, 'Market', false),
              _buildNavItem(Icons.person, 'Profile', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          if (!isSelected) {
            final int index = label == 'Collection'
                ? 1
                : label == 'Market'
                    ? 2
                    : label == 'Profile'
                        ? 3
                        : 0;
            final navProvider =
                Provider.of<NavigationProvider>(context, listen: false);
            navProvider.changePage(index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String name, String imagePath, bool isUnlocked) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A2E),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFF3B82F6)
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.emoji_events,
                color: isUnlocked
                    ? const Color(0xFF3B82F6)
                    : Colors.grey.withOpacity(0.3),
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.grey.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(String type, String imageUrl, String name) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              width: 2,
            ),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          type,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
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
}
