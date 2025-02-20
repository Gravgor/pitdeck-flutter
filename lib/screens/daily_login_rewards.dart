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
        _buildRewardAmount(nextReward),
        _buildStreakInfo(streak),
        _buildClaimButton(canClaim),
      ],
    );
  }

  Widget _buildHeader(int streak) {
    return Container(
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
          const SizedBox(height: 16),
          const Text(
            'Daily Streak',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
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

  Widget _buildRewardAmount(int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            '+$amount',
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'RACECOINS',
            style: TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakInfo(int streak) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFF3B82F6),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '$streak Day${streak == 1 ? '' : 's'} Streak!',
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

  Widget _buildClaimButton(bool canClaim) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        child: isCollecting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                canClaim ? 'CLAIM REWARD' : 'COME BACK TOMORROW',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
      ),
    );
  }
}
