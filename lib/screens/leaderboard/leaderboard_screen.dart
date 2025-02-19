import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late String _currentLeague;
  List<dynamic>? _leaderboardData;
  bool _isLoading = true;
  String baseUrl = 'https://api.pitdeck.app/api';
  int? _currentWeek;

  final Map<String, Color> _leagueColors = {
    'ROOKIE': const Color(0xFF6B7280),
    'CLUB_RACER': const Color(0xFF3B82F6),
    'NATIONAL': const Color(0xFF10B981),
    'FORMULA_3': const Color(0xFFFBBF24),
    'FORMULA_2': const Color(0xFFDB2777),
    'FORMULA_1': const Color(0xFFEF4444),
    'GT3': const Color(0xFF8B5CF6),
    'GT2': const Color(0xFFEC4899),
    'GT1': const Color(0xFF6366F1),
    'ELITE_MOTORSPORT': const Color(0xFFF59E0B),
  };

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentLeague = userProvider.user!.league;
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('$baseUrl/leaderboard/league/$_currentLeague'),
        headers: {'Authorization': 'Bearer ${userProvider.user!.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _leaderboardData = data['leaderboard'];
          _currentWeek = data['currentWeek'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLeagueHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _leagueColors[_currentLeague]!.withOpacity(0.2),
              _leagueColors[_currentLeague]!.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _leagueColors[_currentLeague]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _leagueColors[_currentLeague]!.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: _leagueColors[_currentLeague],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentLeague.replaceAll('_', ' '),
                  style: TextStyle(
                    color: _leagueColors[_currentLeague],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your Current League',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${_leaderboardData?.length ?? '-'} Players',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardEntry(Map<String, dynamic> player, int position) {
    final isUser = player['id'] == Provider.of<UserProvider>(context).user!.id;
    final isTopThree = position <= 3;
    final isPromoting = position <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [
                  _leagueColors[_currentLeague]!.withOpacity(0.15),
                  _leagueColors[_currentLeague]!.withOpacity(0.05),
                ],
              )
            : null,
        color: isUser ? null : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser ? _leagueColors[_currentLeague]! : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isTopThree
                  ? LinearGradient(
                      colors: [
                        _leagueColors[_currentLeague]!,
                        _leagueColors[_currentLeague]!.withOpacity(0.8),
                      ],
                    )
                  : null,
              color: isTopThree ? null : const Color(0xFF0A0A1A),
              shape: BoxShape.circle,
              border: !isTopThree ? Border.all(color: Colors.white12) : null,
              boxShadow: isTopThree
                  ? [
                      BoxShadow(
                        color: _leagueColors[_currentLeague]!.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: TextStyle(
                  color: isTopThree ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isUser ? _leagueColors[_currentLeague]! : Colors.white12,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(player['image'] ?? ''),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Orbitron',
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
                        color: _leagueColors[_currentLeague]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${player['weeklyPoints']} PTS',
                        style: TextStyle(
                          color: _leagueColors[_currentLeague],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                    if (isPromoting) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: Colors.green,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PROMOTING',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF1A1A2E).withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'LEADERBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Week ${_currentWeek ?? '-'}',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildLeagueHeader(),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                ),
              )
            else if (_leaderboardData != null && _leaderboardData!.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _leaderboardData!.length,
                  itemBuilder: (context, index) {
                    final player = _leaderboardData![index];
                    return _buildLeaderboardEntry(
                      player,
                      index + 1, // Position starts from 1
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'No players with points yet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
