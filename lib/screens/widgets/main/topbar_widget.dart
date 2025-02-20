import 'package:flutter/material.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:provider/provider.dart';

class TopBarWidget extends StatelessWidget {
  const TopBarWidget({super.key});

  IconData _getLeagueIcon(String league) {
    switch (league) {
      case 'ROOKIE':
        return Icons.directions_car_outlined;
      case 'CLUB_RACER':
        return Icons.sports_motorsports_outlined;
      case 'NATIONAL':
        return Icons.flag_outlined;
      case 'FORMULA_3':
        return Icons.speed_outlined;
      case 'FORMULA_2':
        return Icons.local_fire_department_outlined;
      case 'FORMULA_1':
        return Icons.rocket_launch_outlined;
      case 'GT3':
        return Icons.flash_on_outlined;
      case 'GT2':
        return Icons.bolt_outlined;
      case 'GT1':
        return Icons.stars_outlined;
      case 'ELITE_MOTORSPORT':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.directions_car_outlined;
    }
  }

  Color _getLeagueColor(String league) {
    switch (league) {
      case 'ROOKIE':
        return const Color(0xFF6B7280);
      case 'CLUB_RACER':
        return const Color(0xFF3B82F6);
      case 'NATIONAL':
        return const Color(0xFF10B981);
      case 'FORMULA_3':
        return const Color(0xFFFBBF24);
      case 'FORMULA_2':
        return const Color(0xFFDB2777);
      case 'FORMULA_1':
        return const Color(0xFFEF4444);
      case 'GT3':
        return const Color(0xFF8B5CF6);
      case 'GT2':
        return const Color(0xFFEC4899);
      case 'GT1':
        return const Color(0xFF6366F1);
      case 'ELITE_MOTORSPORT':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF15152A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildUserInfo(),
            const Spacer(),
            _buildLeagueInfo(),
            const SizedBox(width: 6),
            _buildCoinsInfo(),
            const SizedBox(width: 6),
            _buildLevelInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Consumer<UserProvider>(
      builder: (context, auth, _) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            auth.user?.name ?? 'Guest',
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (auth.user?.isPremium ?? false) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFFFD700),
                size: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeagueInfo() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final league = userProvider.user?.league ?? 'ROOKIE';
        final color = _getLeagueColor(league);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getLeagueIcon(league),
                color: color,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                '#${userProvider.user?.leaguePosition ?? '-'}',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinsInfo() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB800).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFFB800).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.monetization_on,
              color: Color(0xFFFFB800),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              _formatNumber(userProvider.user?.coins ?? 0),
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 12,
                color: Color(0xFFFFB800),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelInfo() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.military_tech,
              color: Color(0xFF3B82F6),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              'LVL ${userProvider.user?.level ?? 1}',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 12,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}
