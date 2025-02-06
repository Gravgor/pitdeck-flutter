import 'package:flutter/material.dart';
import 'package:pitdeck/models/card.dart';
import 'package:pitdeck/screens/pack/packs_screen.dart';
import 'package:pitdeck/utils/color_utils.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/card_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage and explore your racing cards',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              letterSpacing: 0.5,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search by name, type, or series...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Orbitron',
                      ),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: _handleSearch,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showFilterModal,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _hasActiveFilters
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _hasActiveFilters ? null : const Color(0xFF0A0A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: _hasActiveFilters ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filters',
                        style: TextStyle(
                          color: _hasActiveFilters ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      if (_hasActiveFilters)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (_selectedRarities.length + _selectedTypes.length)
                                .toString(),
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'Orbitron',
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

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    setState(() {
      if (_selectedRarities.isEmpty && _selectedTypes.isEmpty) {
        _filteredCards = List<CardModel>.from(cardProvider.cards);
      } else {
        _filteredCards = cardProvider.cards.where((card) {
          final matchesRarity = _selectedRarities.isEmpty ||
              _selectedRarities.contains(card.rarity.toUpperCase());
          final matchesType = _selectedTypes.isEmpty ||
              _selectedTypes.contains(card.type.toUpperCase());
          return matchesRarity && matchesType;
        }).toList();
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF0A0A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
      child: GridView.builder(
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

          return GestureDetector(
            onTap: () => _showCardDetails(context, card.id),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isLegendary) ...[
                    BoxShadow(
                      color: ColorUtils.getRarityColor(card.rarity)
                          .withOpacity(0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: ColorUtils.getRarityColor(card.rarity)
                          .withOpacity(0.1),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ] else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.2, // Makes image slightly smaller
                      child: Image.network(
                        card.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ColorUtils.getRarityColor(card.rarity)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: isLegendary
                                ? Border.all(
                                    color:
                                        ColorUtils.getRarityColor(card.rarity)
                                            .withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Text(
                            card.rarity,
                            style: TextStyle(
                              color: ColorUtils.getRarityColor(card.rarity),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${card.serialNumber}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontFamily: 'Orbitron',
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
      ),
    );
  }

  void _showCardDetails(BuildContext context, String cardId) {
    final card = Provider.of<CardProvider>(context, listen: false)
        .fetchCardDetails(cardId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<CardDetailModel>(
        future: card,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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

          if (snapshot.hasError || !snapshot.hasData) {
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

          final card = snapshot.data!;
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(card.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
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
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Orbitron',
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
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          ColorUtils.getRarityColor(card.rarity)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: ColorUtils.getRarityColor(
                                                card.rarity)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      card.rarity,
                                      style: TextStyle(
                                        color: ColorUtils.getRarityColor(
                                            card.rarity),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildDetailRow(
                                  'Serial Number', '#${card.serialNumber}'),
                              _buildDetailRow(
                                  'Type', card.type.replaceAll('_', ' ')),
                              _buildDetailRow('Year', card.year.toString()),
                              _buildDetailRow(
                                  'Edition', card.edition.toString()),
                              if (card.description != null) ...[
                                const SizedBox(height: 24),
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
                                  card.description,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              _buildCardStats(card),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButton(
                                      label: 'TRADE',
                                      icon: Icons.swap_horiz,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _initiateTradeOffer(card);
                                      },
                                      gradient: const [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB)
                                      ],
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
                                      gradient: const [
                                        Color(0xFF10B981),
                                        Color(0xFF059669)
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
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
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
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
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
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
                    const Text(
                      'Filter Collection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rarity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
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
                                isSelected: _selectedRarities.contains(rarity),
                                color: ColorUtils.getRarityColor(rarity),
                                onTap: () {
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
                    const Text(
                      'Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
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
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
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
                          ),
                        ),
                        child: const Text(
                          'CLEAR ALL',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'APPLY FILTERS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildCardStats(CardDetailModel card) {
    if (card.stats == null || card.stats!.isEmpty)
      return const SizedBox.shrink();

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
          final percentage = (stat.value / 100).clamp(0.0, 1.0);
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
