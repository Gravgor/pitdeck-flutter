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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF1A1A2E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildRewardContent(),
                _buildStreakInfo(),
                _buildClaimButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              if (_rewardStatus?['canClaim'] == true)
                TweenAnimationBuilder<double>(
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
                ),
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

  Widget _buildRewardContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            '+${_rewardStatus?['nextReward'] ?? 0}',
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

  Widget _buildStreakInfo() {
    final currentStreak = _rewardStatus?['currentStreak'] ?? 0;
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
            '$currentStreak Day${currentStreak == 1 ? '' : 's'} Streak!',
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

  Widget _buildClaimButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: _rewardStatus?['canClaim'] == true ? _collectReward : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isCollecting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _rewardStatus?['canClaim'] == true
                    ? 'CLAIM REWARD'
                    : 'COME BACK TOMORROW',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
