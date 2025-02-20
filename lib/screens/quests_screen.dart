import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitdeck/models/quest.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/services/quest_service.dart';
import 'package:pitdeck/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<QuestCategory> _categories = QuestCategory.values;
  Map<QuestCategory, List<Quest>> _questsCache = {};
  List<Quest>? _allQuests;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _categories.length + 1, vsync: this); // +1 for "All" tab
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final questService = Provider.of<QuestService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.user?.token ?? '';

      // Load all available quests
      _allQuests = await questService.getAvailableQuests(token);

      // Load quests by category
      for (final category in _categories) {
        final categoryQuests = await questService.getAvailableQuestsByCategory(
          token,
          category.toString().split('.').last,
        );

        if (mounted) {
          setState(() {
            _questsCache[category] = categoryQuests;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040412),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF040412).withOpacity(0.95),
                    const Color(0xFF040412).withOpacity(0.9),
                    const Color(0xFF040412).withOpacity(0.85),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildQuestStats(),
                _buildSearchBar(),
                _buildCategoryTabs(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF3B82F6).withOpacity(0.7),
                            ),
                            strokeWidth: 3,
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _QuestList(
                              key: const ValueKey('all'),
                              quests: _allQuests ?? [],
                              onQuestClaimed: _loadInitialData,
                            ),
                            ..._categories.map((category) {
                              return _QuestList(
                                key: ValueKey(category),
                                quests: _questsCache[category] ?? [],
                                onQuestClaimed: _loadInitialData,
                              );
                            }),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                ).createShader(bounds),
                child: const Text(
                  'Quests Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Complete quests to earn rewards',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Orbitron',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.star_rounded,
            label: 'Total',
            value: _allQuests?.length.toString() ?? '0',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: _questsCache.values
                .fold(0, (sum, quests) => sum + quests.length)
                .toString(),
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.trending_up_rounded,
            label: 'Active',
            value: _questsCache.values
                .fold(0, (sum, quests) => sum + quests.length)
                .toString(),
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
              decoration: InputDecoration(
                hintText: 'Search quests...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Orbitron',
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: const Color(0xFF3B82F6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildCategoryChip(
            'All',
            _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
          ),
          ..._categories.asMap().entries.map((entry) {
            final index = entry.key + 1; // +1 because 'All' is at index 0
            final category = entry.value;
            return _buildCategoryChip(
              category.toString().split('.').last.replaceAll('_', ' '),
              _tabController.index == index,
              onTap: () => _tabController.animateTo(index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected,
      {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Orbitron',
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestList extends StatelessWidget {
  final List<Quest> quests;
  final VoidCallback onQuestClaimed;

  const _QuestList({
    required Key key,
    required this.quests,
    required this.onQuestClaimed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No quests available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return _QuestCard(
          key: ValueKey(quests[index].id),
          quest: quests[index],
          onClaimed: onQuestClaimed,
        );
      },
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onClaimed;

  const _QuestCard({
    required Key key,
    required this.quest,
    required this.onClaimed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: quest.status == QuestStatus.COMPLETED
              ? () => _claimReward(context)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildQuestTypeIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quest.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildProgressBar(),
                const SizedBox(height: 16),
                _buildRewards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestTypeIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getQuestColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getQuestIcon(),
        color: _getQuestColor(),
        size: 24,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: quest.getProgress(),
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_getQuestColor()),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              quest.getProgressText(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'Orbitron',
              ),
            ),
            if (quest.status == QuestStatus.COMPLETED)
              const Text(
                'TAP TO CLAIM',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRewards() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (quest.rewards.coins != null)
          _buildRewardChip(
            icon: Icons.monetization_on,
            text: _formatNumber(quest.rewards.coins!),
            color: const Color(0xFFFFB800),
          ),
        if (quest.rewards.badge != null)
          _buildRewardChip(
            icon: Icons.military_tech,
            text: 'Badge',
            color: const Color(0xFF3B82F6),
          ),
        if (quest.rewards.visualEffect != null)
          _buildRewardChip(
            icon: Icons.auto_awesome,
            text: 'Effect',
            color: const Color(0xFFEC4899),
          ),
        if (quest.rewards.cards != null)
          _buildRewardChip(
            icon: Icons.style,
            text:
                '${quest.rewards.cards!.length} Card${quest.rewards.cards!.length > 1 ? 's' : ''}',
            color: const Color(0xFF10B981),
          ),
        if (quest.rewards.pack != null)
          _buildRewardChip(
            icon: Icons.inventory_2,
            text: 'Pack',
            color: const Color(0xFF8B5CF6),
          ),
      ],
    );
  }

  Widget _buildRewardChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Color _getQuestColor() {
    switch (quest.category) {
      case QuestCategory.BASIC:
        return const Color(0xFF10B981);
      case QuestCategory.PIT_CREW:
        return const Color(0xFF3B82F6);
      case QuestCategory.GRAND_PRIX:
        return const Color(0xFFFFB800);
      case QuestCategory.CHAMPIONS_LEAGUE:
        return const Color(0xFFEC4899);
    }
  }

  IconData _getQuestIcon() {
    switch (quest.type) {
      case 'COLLECT_FIRST':
        return Icons.style;
      case 'DISCOVER_LOCATIONS':
        return Icons.explore;
      case 'TRADE':
        return Icons.swap_horiz;
      case 'COLLECT_CATEGORIES':
        return Icons.category;
      case 'MARKET_SALE':
        return Icons.sell;
      case 'COLLECT_TEAMS':
        return Icons.group;
      case 'DISCOVER_DROPS':
        return Icons.place;
      case 'COLLECT_CIRCUITS':
        return Icons.track_changes;
      case 'COLLECT_EPIC':
        return Icons.stars;
      case 'MARKET_TRADE_MASTER':
        return Icons.trending_up;
      case 'COLLECT_TEAM_SET':
        return Icons.collections;
      case 'COLLECT_ALL_CIRCUITS':
        return Icons.public;
      default:
        return Icons.assignment;
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

  Future<void> _claimReward(BuildContext context) async {
    final questService = Provider.of<QuestService>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final result = await questService.claimQuestReward(
        userProvider.user?.token ?? '',
        quest.id,
      );

      if (result['coins'] != null) {
        userProvider.updateCoins(result['coins']);
        onClaimed();
      }

      SnackBarUtils.showSuccess(context,
          title: 'Success', message: 'Quest rewards claimed!');
    } catch (e) {
      SnackBarUtils.showError(context,
          title: 'Error', message: 'Error claiming quest rewards: $e');
    }
  }
}
