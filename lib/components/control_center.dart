import 'package:flutter/material.dart';
  import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/services/daily_reward_service.dart';
import 'dart:ui';
import 'package:pitdeck/screens/pack/packs_screen.dart';
import 'package:pitdeck/screens/quests_screen.dart';
import 'package:pitdeck/screens/leaderboard/leaderboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/utils/snackbar_utils.dart';

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
      const DailyReward(day: 1, coins: 100, isCollected: true, isToday: false),
      const DailyReward(day: 2, coins: 200, isCollected: true, isToday: false),
      const DailyReward(day: 3, coins: 300, isCollected: true, isToday: false),
      const DailyReward(day: 4, coins: 500, isCollected: false, isToday: true),
      const DailyReward(day: 5, coins: 750, isCollected: false, isToday: false),
      const DailyReward(
          day: 6, coins: 1000, isCollected: false, isToday: false),
      const DailyReward(
          day: 7, coins: 2000, isCollected: false, isToday: false),
    ];
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
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuestsScreen()),
          );
        },
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
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF040412),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'CONTROL CENTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDailyRewards(context),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                      children: _getControlTiles(context)
                          .map((tile) => _buildControlTile(tile))
                          .toList(),
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

  Future<Map<String, dynamic>> getDailyRewardStatus(
      BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.user?.token;
    final rewardService =
        Provider.of<DailyRewardService>(context, listen: false);
    final status = await rewardService.getDailyRewardStatus(token ?? '');
    print(status);
    return status;
  }

   Widget _buildDailyRewards(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getDailyRewardStatus(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDailyRewardsContainer(
            child: Column(
              children: [
                _buildDailyRewardsHeader(),
                const SizedBox(height: 20),
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildDailyRewardsContainer(
            borderColor: const Color(0xFFEF4444).withOpacity(0.3),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Error Loading Rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          );
        }

        final status = snapshot.data!;
        final canClaim = status['canClaim'] as bool;
        final currentStreak = status['currentStreak'] as int;
        final nextReward = status['nextReward'] as int;

        return _buildDailyRewardsContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDailyRewardsHeader(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$currentStreak',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: canClaim ? () => _handleClaim(context) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: canClaim 
                        ? const Color(0xFF0A2F25)
                        : const Color(0xFF1F1F3F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canClaim
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: canClaim
                            ? const Color(0xFFFFD700)
                            : const Color(0xFFFFD700).withOpacity(0.3),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatNumber(nextReward),
                        style: TextStyle(
                          color: canClaim
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            canClaim ? 'Claim Daily Reward' : 'Come back tomorrow',
                            style: TextStyle(
                              color: canClaim
                                  ? const Color(0xFF10B981)
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          if (canClaim) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: const Color(0xFF10B981),
                              size: 16,
                            ),
                          ],
                        ],
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
  }

  Future<void> _handleClaim(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final rewardService = Provider.of<DailyRewardService>(context, listen: false);
    
    try {
      final result = await rewardService.claimDailyReward(userProvider.user?.token ?? '');
      
      if (result != null) {
        // Update user's coins
        if (result['coins'] != null) {
          userProvider.updateCoins(result['coins']);
        }
        
        // Show success message
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, title: 'Success', message: 'Reward claimed');
        }
        
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Failed to claim reward',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Widget _buildDailyRewardsContainer({
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDailyRewardsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.calendar_today,
            color: Color(0xFF10B981),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Daily Rewards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }

  Widget _buildControlTile(ControlTile tile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tile.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tile.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
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
