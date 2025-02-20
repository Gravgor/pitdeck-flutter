import 'package:flutter/material.dart';
import 'package:pitdeck/main.dart';
import 'dart:ui';
import 'package:pitdeck/services/daily_reward_service.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:provider/provider.dart';

class DailyLoginRewardsPopup extends StatefulWidget {
  final String token;

  const DailyLoginRewardsPopup({
    super.key,
    required this.token,
  });

  @override
  State<DailyLoginRewardsPopup> createState() => _DailyLoginRewardsPopupState();
}

class _DailyLoginRewardsPopupState extends State<DailyLoginRewardsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final DailyRewardService _rewardService = DailyRewardService();

  bool _isLoading = true;
  bool _isCollecting = false;
  bool _error = false;
  String _errorMessage = '';

  Map<String, dynamic>? _rewardStatus;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    _loadRewardStatus();
  }

  Future<void> _loadRewardStatus() async {
    try {
      final status = await _rewardService.getDailyRewardStatus(widget.token);
      setState(() {
        _rewardStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _collectReward() async {
    if (_isCollecting) return;

    setState(() => _isCollecting = true);

    try {
      final result = await _rewardService.claimDailyReward(widget.token);
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      await userProvider.fetchUserProfile();
      await _loadRewardStatus();
      Navigator.of(context).pop(result);
    } catch (e) {
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isCollecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: _isLoading
                ? const _LoadingView()
                : _error
                    ? _ErrorView(message: _errorMessage)
                    : _RewardView(
                        rewardStatus: _rewardStatus!,
                        isCollecting: _isCollecting,
                        onCollect: _collectReward,
                      ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0, end: 4 * 3.14159),
            curve: Curves.linear,
            builder: (context, value, child) => Transform.rotate(
              angle: value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Rewards...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Rewards',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CLOSE',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardView extends StatelessWidget {
  final Map<String, dynamic> rewardStatus;
  final bool isCollecting;
  final VoidCallback onCollect;

  const _RewardView({
    required this.rewardStatus,
    required this.isCollecting,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final bool canClaim = rewardStatus['canClaim'] ?? false;
    final int streak = rewardStatus['currentStreak'] ?? 0;
    final int nextReward = rewardStatus['nextReward'] ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(streak),
        _buildStreakCounter(streak),
        _buildRewardAmount(nextReward),
        _buildClaimButton(canClaim),
      ],
    );
  }

  Widget _buildHeader(int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.3),
                      const Color(0xFF3B82F6).withOpacity(0.0),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFF3B82F6),
                  size: 40,
                ),
              ),
              if (rewardStatus['canClaim'] == true) _buildRotatingRing(),
            ],
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
            ).createShader(bounds),
            child: const Text(
              'Daily Streak',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep logging in daily to earn more rewards!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'Orbitron',
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingRing() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakCounter(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(5, (index) {
              final dayNumber = streak - 2 + index;
              final isCurrentDay = index == 2;
              final isPastDay = index < 2;

              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(
                  begin: 0.8,
                  end: isCurrentDay ? 1.2 : (isPastDay ? 0.9 : 0.7),
                ),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: Color.lerp(
                              const Color(0xFF3B82F6),
                              const Color(0xFFEF4444),
                              isCurrentDay ? 1.0 : (isPastDay ? 0.7 : 0.3),
                            ),
                            size: isCurrentDay ? 36 : 24,
                          ),
                          const SizedBox(height: 8),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Color.lerp(
                                  const Color(0xFF3B82F6),
                                  const Color(0xFFEF4444),
                                  isCurrentDay ? 1.0 : (isPastDay ? 0.7 : 0.3),
                                )!,
                                Color.lerp(
                                  const Color(0xFF60A5FA),
                                  const Color(0xFFFCA5A5),
                                  isCurrentDay ? 1.0 : (isPastDay ? 0.7 : 0.3),
                                )!,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              dayNumber > 0 ? '$dayNumber' : '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    isCurrentDay ? 48 : (isPastDay ? 36 : 28),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (isCurrentDay) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFFEF4444).withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'TODAY',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardAmount(int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ).createShader(bounds),
                  child: Text(
                    '+$amount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const Text(
                  'RACECOINS',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton(bool canClaim) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canClaim ? onCollect : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            canClaim ? 'CLAIM REWARD' : 'COME BACK TOMORROW',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
