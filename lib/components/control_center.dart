import 'package:flutter/material.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'dart:ui';
import 'package:pitdeck/screens/packs_screen.dart';
import 'package:provider/provider.dart';

class ControlTile {
  final IconData icon;
  final String label;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  const ControlTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });
}

class DailyReward {
  final int day;
  final int coins;
  final bool isCollected;
  final bool isToday;

  const DailyReward({
    required this.day,
    required this.coins,
    required this.isCollected,
    required this.isToday,
  });
}

class ControlCenter extends StatelessWidget {
  const ControlCenter({super.key});

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  List<DailyReward> _getDailyRewards() {
    return [
      DailyReward(day: 1, coins: 100, isCollected: true, isToday: false),
      DailyReward(day: 2, coins: 200, isCollected: true, isToday: false),
      DailyReward(day: 3, coins: 300, isCollected: true, isToday: false),
      DailyReward(day: 4, coins: 500, isCollected: false, isToday: true),
      DailyReward(day: 5, coins: 750, isCollected: false, isToday: false),
      DailyReward(day: 6, coins: 1000, isCollected: false, isToday: false),
      DailyReward(day: 7, coins: 2000, isCollected: false, isToday: false),
    ];
  }

  void _showCollectionAnimation(BuildContext context, DailyReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutExpo,
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF0A0A1A),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Text(
                    'Daily Rewards',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${reward.day} Day Streak!',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 2),
                        tween: Tween(begin: 0, end: 4 * 3.14159),
                        curve: Curves.linear,
                        builder: (context, value, child) => Transform.rotate(
                          angle: value,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xFFFFD700).withOpacity(0.0),
                                  const Color(0xFFFFD700).withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFFD700),
                        size: 64,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Text(
                          '+${_formatNumber(reward.coins)}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _getDailyRewards().map((dailyReward) {
                          return Container(
                            width: 64,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dailyReward.isCollected
                                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                                  : dailyReward.isToday
                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                      : const Color(0xFF1F1F3F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dailyReward.isCollected
                                    ? const Color(0xFF3B82F6).withOpacity(0.3)
                                    : dailyReward.isToday
                                        ? const Color(0xFF10B981)
                                            .withOpacity(0.3)
                                        : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${dailyReward.day}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  Icons.monetization_on,
                                  color: dailyReward.isCollected
                                      ? const Color(0xFFFFD700).withOpacity(0.3)
                                      : const Color(0xFFFFD700),
                                  size: 24,
                                ),
                                if (dailyReward.isCollected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF3B82F6),
                                    size: 16,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Collected ${_formatNumber(reward.coins)} coins!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'COLLECT REWARD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<ControlTile> _getControlTiles(BuildContext context) {
    return [
      ControlTile(
        icon: Icons.card_giftcard,
        label: 'Packs',
        description: 'Open new card packs',
        accentColor: const Color(0xFFEF4444),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PacksScreen()),
          );
        },
      ),
      ControlTile(
        icon: Icons.star_rounded,
        label: 'Quests',
        description: 'Daily challenges',
        accentColor: const Color(0xFFFFB800),
        onTap: () {},
      ),
      ControlTile(
        icon: Icons.flag_rounded,
        label: 'Races',
        description: 'Join competitions',
        accentColor: const Color(0xFF10B981),
        onTap: () {},
      ),
      ControlTile(
        icon: Icons.leaderboard_rounded,
        label: 'Leaderboard',
        description: 'View rankings',
        accentColor: const Color(0xFF8B5CF6),
        onTap: () {},
      ),
    ];
  }

  Widget _buildRaceCoins(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'CONTROL CENTER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatNumber(userProvider.user?.coins ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile(ControlTile tile) {
    return GestureDetector(
      onTap: tile.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tile.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tile.accentColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tile.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tile.accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      tile.icon,
                      color: tile.accentColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tile.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tile.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildRaceCoins(context),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                physics: const BouncingScrollPhysics(),
                children: _getControlTiles(context)
                    .map((tile) => _buildControlTile(tile))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatTimeRemaining() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final remaining = tomorrow.difference(now);
    return '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
