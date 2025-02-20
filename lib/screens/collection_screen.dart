import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitdeck/models/card.dart';
import 'package:pitdeck/providers/listing_provider.dart';
import 'package:pitdeck/providers/trade_provider.dart';
import 'package:pitdeck/screens/pack/packs_screen.dart';
import 'package:pitdeck/utils/color_utils.dart';
import 'package:pitdeck/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import 'dart:async';
import '../widgets/collection/trade_modal.dart';
import '../widgets/collection/list_for_sale_modal.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  Timer? _refreshTimer;
  bool _isLoading = false;
  List<CardModel> _cards = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedRarities = {};
  Set<String> _selectedTypes = {};
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isCardModalOpen = false;
  late FocusNode _priceFocusNode;
  List<CardModel> _filteredCards = [];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    _filteredCards = List<CardModel>.from(cardProvider.cards);
    _fetchCards();
    _startPeriodicRefresh();
    _priceFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCards() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Provider.of<CardProvider>(context, listen: false)
          .fetchUserCards();
      if (mounted) {
        setState(() {
          _cards = response.cast<CardModel>();
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load cards. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchCards();
    });
  }

  void _refreshCards() {
    _fetchCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040412),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(child: _buildCardGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalCards = _cards.length;
    final legendaryCards =
        _cards.where((card) => card.rarity == 'LEGENDARY').length;
    final uniqueSeries = _cards.map((card) => card.series).toSet().length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF0F0F1E),
            Color(0xFF0A0A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ).createShader(bounds),
                      child: const Text(
                        'My Collection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1A1A2E).withOpacity(0.9),
                                const Color(0xFF0F0F1E).withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _isGridView = !_isGridView);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  _isGridView
                                      ? Icons.view_list_rounded
                                      : Icons.grid_view_rounded,
                                  color: const Color(0xFF3B82F6),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1A1A2E).withOpacity(0.9),
                                const Color(0xFF0F0F1E).withOpacity(0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showFilterModal();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.filter_list_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage and explore your racing cards',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    letterSpacing: 0.5,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatCard('Total', totalCards.toString(),
                    Icons.card_membership_outlined),
                _buildStatCard('Legendary', legendaryCards.toString(),
                    Icons.auto_awesome_outlined),
                _buildStatCard(
                    'Series', uniqueSeries.toString(), Icons.category_outlined),
                _buildStatCard('Recent', '5', Icons.access_time_outlined),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, type, or series...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.3),
                        size: 20,
                      ),
                    ),
                    onChanged: _handleSearch,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.7),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
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

  bool get _hasActiveFilters =>
      _selectedRarities.isNotEmpty || _selectedTypes.isNotEmpty;

  void _handleSearch(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
      final cardProvider = Provider.of<CardProvider>(context, listen: false);

      // First filter by search query
      _filteredCards = cardProvider.cards.where((card) {
        return card.name.toLowerCase().contains(_searchQuery) ||
            card.type.toLowerCase().contains(_searchQuery) ||
            card.series.toLowerCase().contains(_searchQuery);
      }).toList();

      // Then apply other filters
      if (_selectedRarities.isNotEmpty) {
        _filteredCards = _filteredCards
            .where(
                (card) => _selectedRarities.contains(card.rarity.toUpperCase()))
            .toList();
      }

      if (_selectedTypes.isNotEmpty) {
        _filteredCards = _filteredCards
            .where((card) => _selectedTypes.contains(card.type.toUpperCase()))
            .toList();
      }

      // Finally apply selected filter (all/trade/market)
      if (_selectedFilter == 'trade') {
        _filteredCards =
            _filteredCards.where((card) => card.isForTrade).toList();
      } else if (_selectedFilter == 'market') {
        _filteredCards =
            _filteredCards.where((card) => card.isForSale).toList();
      }
    });
  }

  void _applyFilters() {
    setState(() {
      final cardProvider = Provider.of<CardProvider>(context, listen: false);
      _filteredCards = cardProvider.cards;

      // Apply search filter if exists
      if (_searchQuery.isNotEmpty) {
        _filteredCards = _filteredCards.where((card) {
          return card.name.toLowerCase().contains(_searchQuery) ||
              card.type.toLowerCase().contains(_searchQuery) ||
              card.series.toLowerCase().contains(_searchQuery);
        }).toList();
      }

      // Apply rarity filters
      if (_selectedRarities.isNotEmpty) {
        _filteredCards = _filteredCards
            .where((card) => _selectedRarities.contains(card.rarity))
            .toList();
      }

      // Apply type filters
      if (_selectedTypes.isNotEmpty) {
        _filteredCards = _filteredCards
            .where((card) => _selectedTypes.contains(card.type))
            .toList();
      }

      // Apply main filter (all/trade/market)
      if (_selectedFilter == 'trade') {
        _filteredCards =
            _filteredCards.where((card) => card.isForTrade).toList();
      } else if (_selectedFilter == 'market') {
        _filteredCards =
            _filteredCards.where((card) => card.isForSale).toList();
      }
      if (_selectedFilter == 'all') {
        _filteredCards = cardProvider.cards
            .where((card) => !card.isForTrade && !card.isForSale)
            .toList();
      }
    });
  }

  Widget _buildFilterChips() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All',
              value: 'all',
              count: _cards
                  .where((card) => !card.isForTrade && !card.isForSale)
                  .length,
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'In Trade',
              value: 'trade',
              count: _cards.where((card) => card.isForTrade).length,
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              label: 'Listed',
              value: 'market',
              count: _cards.where((card) => card.isForSale).length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
  }) {
    final isSelected = _selectedFilter == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedFilter = value;
              _applyFilters();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFilterIcon(value),
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    fontFamily: 'Orbitron',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF0A0A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFilterIcon(String value) {
    switch (value) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'trade':
        return Icons.swap_horiz_rounded;
      case 'market':
        return Icons.store_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Widget _buildCardGrid() {
    if (_isLoading && _cards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Your collection is empty',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open packs to start collecting cards',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PacksScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OPEN PACKS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCards,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF3B82F6),
      child: _isGridView
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredCards.length,
              itemBuilder: (context, index) {
                final card = _filteredCards[index];
                final isLegendary = card.rarity == 'LEGENDARY';
                final rarityColor = ColorUtils.getRarityColor(card.rarity);

                return GestureDetector(
                  onTap: () => _showCardDetails(context, card.id),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF0F0F1E),
                          if (isLegendary) rarityColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (isLegendary) ...[
                          BoxShadow(
                            color: rarityColor.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: rarityColor.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ] else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              child: AspectRatio(
                                aspectRatio: 1.1,
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3)
                                      ],
                                      stops: const [0.7, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.darken,
                                  child: Image.network(
                                    card.imageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: const Color(0xFF1A1A2E),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: rarityColor,
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (isLegendary)
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                  child: CustomPaint(
                                    painter: GlowingBorderPainter(
                                      color: rarityColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      card.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '#${card.serialNumber}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: rarityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isLegendary
                                      ? Border.all(
                                          color: rarityColor.withOpacity(0.3),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLegendary) ...[
                                      Icon(
                                        Icons.auto_awesome,
                                        color: rarityColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      card.rarity,
                                      style: TextStyle(
                                        color: rarityColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                        letterSpacing: 0.5,
                                      ),
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
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredCards.length,
              itemBuilder: (context, index) {
                final card = _filteredCards[index];
                final rarityColor = ColorUtils.getRarityColor(card.rarity);
                final isLegendary = card.rarity == 'LEGENDARY';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1A2E).withOpacity(0.9),
                        const Color(0xFF0F0F1E).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLegendary
                          ? rarityColor.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showCardDetails(context, card.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'card_${card.id}',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(card.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rarityColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: rarityColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      card.rarity,
                                      style: TextStyle(
                                        color: rarityColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '#${card.serialNumber}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCardDetails(BuildContext context, String cardId) {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final cardFuture = cardProvider.fetchCardDetails(cardId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<CardDetailModel>(
        future: cardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState(context, snapshot.error);
          }

          final card = snapshot.data!;
          final rarityColor = ColorUtils.getRarityColor(card.rarity);
          final isLegendary = card.rarity == 'LEGENDARY';

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF0F0F1E),
                  if (isLegendary) rarityColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
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
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            Hero(
                              tag: 'card_${card.id}',
                              child: Container(
                                height: 360,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(card.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isLegendary)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: rarityColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            Container(
                              height: 360,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                  stops: const [0.7, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          card.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Orbitron',
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          card.series,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 16,
                                            fontFamily: 'Orbitron',
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildRarityBadge(card.rarity, rarityColor),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildDetailsSection(card),
                              if (card.description != null) ...[
                                const SizedBox(height: 32),
                                _buildDescriptionSection(card.description!),
                              ],
                              const SizedBox(height: 32),
                              _buildCardStats(card),
                              const SizedBox(height: 32),
                              _buildActionButtons(context, card),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildRarityBadge(String rarity, Color color) {
    final isLegendary = rarity == 'LEGENDARY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLegendary) ...[
            Icon(Icons.auto_awesome, color: color, size: 16),
            const SizedBox(width: 8),
          ],
          Text(
            rarity,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Center(
        child: Text(
          'Failed to load card details',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
            fontFamily: 'Orbitron',
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(CardDetailModel card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Serial Number', '#${card.serialNumber}'),
        _buildDetailRow('Type', card.type.replaceAll('_', ' ')),
        _buildDetailRow('Year', card.year.toString()),
        _buildDetailRow('Edition', card.edition.toString()),
      ],
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCardStats(CardDetailModel card) {
    if (card.stats == null || card.stats!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 16),
        ...card.stats!.entries.map((stat) {
          // Parse the value to double, with fallback for non-numeric values
          double numericValue;
          if (stat.value is num) {
            numericValue = (stat.value as num).toDouble();
          } else {
            try {
              numericValue = double.parse(stat.value.toString());
            } catch (e) {
              // If value can't be parsed to number, show without progress bar
              return _buildNonNumericStat(stat.key, stat.value.toString());
            }
          }

          final percentage = (numericValue / 100).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat.key.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    Text(
                      stat.value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A1A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6),
                            const Color(0xFF2563EB),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNonNumericStat(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'Orbitron',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Orbitron',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CardDetailModel card) {
    if (card.isForSale) {
      return _buildActionButton(
        label: 'REMOVE FROM SALE',
        icon: Icons.remove_circle_outline,
        onPressed: () {
          Navigator.pop(context);
          _removeFromSale(card);
        },
        gradient: const [Color(0xFFDC2626), Color(0xFFB91C1C)],
      );
    } else if (card.isForTrade && !card.isForSale) {
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'IN ACTIVE TRADE',
              icon: Icons.swap_horiz,
              onPressed: null, // Disabled state
              gradient: const [Color(0xFF6B7280), Color(0xFF4B5563)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              label: 'REMOVE FROM TRADE',
              icon: Icons.remove_circle_outline,
              onPressed: () {
                Navigator.pop(context);
                _removeFromTrade(card);
              },
              gradient: const [Color(0xFFDC2626), Color(0xFFB91C1C)],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'TRADE',
              icon: Icons.swap_horiz,
              onPressed: () {
                Navigator.pop(context);
                _initiateTradeOffer(card);
              },
              gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              label: 'SELL',
              icon: Icons.sell,
              onPressed: () {
                Navigator.pop(context);
                _listForSale(card);
              },
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required List<Color> gradient,
  }) {
    final isDisabled = onPressed == null;
    final colors = isDisabled
        ? gradient.map((c) => c.withOpacity(0.5)).toList()
        : gradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(isDisabled ? 0.5 : 1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isDisabled ? 0.5 : 1),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeFromTrade(CardDetailModel card) {
    Provider.of<TradeProvider>(context, listen: false).cancelTrade(card.id);
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E), Color(0xFF0A0A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ).createShader(bounds),
                      child: const Text(
                        'Filter Collection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF3B82F6),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Rarity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          'LEGENDARY',
                          'EPIC',
                          'RARE',
                          'UNCOMMON',
                          'COMMON'
                        ]
                            .map((rarity) => _buildFilterOption(
                                  label: rarity,
                                  isSelected:
                                      _selectedRarities.contains(rarity),
                                  color: ColorUtils.getRarityColor(rarity),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      if (_selectedRarities.contains(rarity)) {
                                        _selectedRarities.remove(rarity);
                                      } else {
                                        _selectedRarities.add(rarity);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.category,
                              color: Color(0xFF3B82F6),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Type',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            ['F1_DRIVER', 'CIRCUIT', 'HISTORIC_MOMENT', 'TEAM']
                                .map((type) => _buildFilterOption(
                                      label: type.replaceAll('_', ' '),
                                      isSelected: _selectedTypes.contains(type),
                                      color: const Color(0xFF3B82F6),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setModalState(() {
                                          if (_selectedTypes.contains(type)) {
                                            _selectedTypes.remove(type);
                                          } else {
                                            _selectedTypes.add(type);
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0A0A1A).withOpacity(0),
                      const Color(0xFF0A0A1A),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setModalState(() {
                          _selectedRarities.clear();
                          _selectedTypes.clear();
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFF3B82F6).withOpacity(0.5),
                          ),
                        ),
                      ),
                      child: const Text(
                        'CLEAR ALL',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: const Center(
                              child: Text(
                                'APPLY FILTERS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : const Color(0xFF0A0A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromSale(CardDetailModel card) async {
    try {
      await Provider.of<ListingProvider>(context, listen: false)
          .removeFromSale(card.id);

      if (!mounted) return;

      SnackBarUtils.showSuccess(context,
          title: 'Success', message: 'Card removed from sale');
    } catch (e) {
      SnackBarUtils.showError(context,
          title: 'Error', message: e.toString().split(':')[1].trim());
    }
  }

  void _initiateTradeOffer(CardDetailModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TradeModal(card: card),
    );
  }

  void _listForSale(CardDetailModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ListForSaleModal(card: card),
    );
  }
}

class PriceHistoryPainter extends CustomPainter {
  final List<Map<String, dynamic>> priceHistory;
  final double maxPrice;
  final double minPrice;

  PriceHistoryPainter({
    required this.priceHistory,
    required this.maxPrice,
    required this.minPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final priceRange = maxPrice - minPrice;

    for (var i = 0; i < priceHistory.length; i++) {
      final x = (i / (priceHistory.length - 1)) * size.width;
      final normalizedPrice =
          (priceHistory[i]['price'] - minPrice) / priceRange;
      final y = size.height - (normalizedPrice * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw gradient below the line
    final gradientPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.blue.withOpacity(0.2),
        Colors.blue.withOpacity(0),
      ],
    );

    canvas.drawPath(
      gradientPath,
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GlowingBorderPainter extends CustomPainter {
  final Color color;
  final double width;

  GlowingBorderPainter({required this.color, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(GlowingBorderPainter oldDelegate) {
    return color != oldDelegate.color || width != oldDelegate.width;
  }
}
