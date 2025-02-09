import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/card_provider.dart';
import '../../providers/trade_provider.dart';
import '../../providers/listing_provider.dart';
import '../../models/card.dart';
import '../../models/trade.dart';
import '../../utils/color_utils.dart';
import 'package:intl/intl.dart';

class MakeOfferScreen extends StatefulWidget {
  final TradeModel originalTrade;

  const MakeOfferScreen({
    super.key,
    required this.originalTrade,
  });

  @override
  State<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends State<MakeOfferScreen> {
  final Set<CardModel> selectedCards = {};
  final Set<String> selectedRarities = {};
  final Set<String> selectedTypes = {};
  final _coinsController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  static const int maxCards = 8;

  @override
  void dispose() {
    _coinsController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<CardModel>> _getAvailableCards() async {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final tradeProvider = Provider.of<TradeProvider>(context, listen: false);
    final listingProvider =
        Provider.of<ListingProvider>(context, listen: false);

    final userCards = cardProvider.getUserCards();
    final cardsInTrades = await tradeProvider.getActiveTradeCardIds();
    final cardsInMarketplace = await listingProvider.getListedCardIds();

    return userCards
        .where((card) =>
            !cardsInTrades.contains(card.id) &&
            !cardsInMarketplace.contains(card.id))
        .toList();
  }

  Future<List<CardModel>> _getFilteredCards() async {
    final cards = await _getAvailableCards();

    return cards.where((card) {
      if (selectedRarities.isNotEmpty &&
          !selectedRarities.contains(card.rarity)) {
        return false;
      }

      // Apply type filter
      if (selectedTypes.isNotEmpty && !selectedTypes.contains(card.type)) {
        return false;
      }

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return card.name.toLowerCase().contains(searchTerm) ||
            card.type.toLowerCase().contains(searchTerm) ||
            card.serialNumber.toString().contains(searchTerm);
      }

      return true;
    }).toList();
  }

  Future<void> _makeOffer() async {
    if (selectedCards.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<TradeProvider>(context, listen: false).makeOffer(
        tradeId: widget.originalTrade.id,
        offeredCardIds: selectedCards.map((card) => card.id).toList(),
        coinsOffered: int.tryParse(_coinsController.text) ?? 0,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer made successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making offer: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ).createShader(bounds),
          child: const Text(
            'Make Offer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildOriginalOffer(),
          _buildSelectedCards(),
          _buildCardSelection(),
          _buildOfferOptions(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildOriginalOffer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Original Trade',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 14,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.originalTrade.offeredCards.length,
              itemBuilder: (context, index) {
                final card = widget.originalTrade.offeredCards[index];
                final rarityColor = ColorUtils.getRarityColor(card.rarity);
                final isLegendary = card.rarity.toUpperCase() == 'LEGENDARY';

                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0A0A1A),
                        if (isLegendary) rarityColor.withOpacity(0.1),
                        const Color(0xFF070711),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLegendary
                          ? rarityColor.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: isLegendary
                        ? [
                            BoxShadow(
                              color: rarityColor.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              card.imageUrl,
                              height: 80,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${card.serialNumber}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 8,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rarityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: rarityColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                card.rarity,
                                style: TextStyle(
                                  color: rarityColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.originalTrade.coinsOffered > 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFB800).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFFB800),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${NumberFormat('#,###').format(widget.originalTrade.coinsOffered)} coins',
                    style: const TextStyle(
                      color: Color(0xFFFFB800),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSelectedCards() {
    if (selectedCards.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
            ),
            child: Text(
              'Your Offer (${selectedCards.length}/$maxCards)',
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 14,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<CardModel>>(
              future: _getFilteredCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No cards found');
                } else {
                  final cards = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final rarityColor =
                          ColorUtils.getRarityColor(card.rarity);
                      final isLegendary =
                          card.rarity.toUpperCase() == 'LEGENDARY';

                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0A0A1A),
                              if (isLegendary) rarityColor.withOpacity(0.1),
                              const Color(0xFF070711),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLegendary
                                ? rarityColor.withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: isLegendary
                              ? [
                                  BoxShadow(
                                    color: rarityColor.withOpacity(0.2),
                                    blurRadius: 16,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        card.imageUrl,
                                        height: 80,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '#${card.serialNumber}',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 8,
                                            fontFamily: 'Orbitron',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Orbitron',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: rarityColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color:
                                                  rarityColor.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          card.rarity,
                                          style: TextStyle(
                                            color: rarityColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Orbitron',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedCards.remove(card);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search cards...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rarity Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['LEGENDARY', 'EPIC', 'RARE', 'UNCOMMON', 'COMMON']
                  .map((rarity) {
                final isSelected = selectedRarities.contains(rarity);
                final rarityColor = ColorUtils.getRarityColor(rarity);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      rarity,
                      style: TextStyle(
                        color: isSelected
                            ? rarityColor
                            : Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    backgroundColor: const Color(0xFF0A0A1A),
                    selectedColor: rarityColor.withOpacity(0.1),
                    side: BorderSide(
                      color: isSelected
                          ? rarityColor
                          : Colors.white.withOpacity(0.1),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedRarities.add(rarity);
                        } else {
                          selectedRarities.remove(rarity);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Type Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['F1_DRIVER', 'CIRCUIT', 'HISTORIC_MOMENT', 'TEAM']
                  .map((type) {
                final isSelected = selectedTypes.contains(type);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      type.replaceAll('_', ' '),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    backgroundColor: const Color(0xFF0A0A1A),
                    selectedColor: const Color(0xFF3B82F6).withOpacity(0.1),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withOpacity(0.1),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedTypes.add(type);
                        } else {
                          selectedTypes.remove(type);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Available Cards Grid
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<CardModel>>(
              future: _getFilteredCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No cards found');
                } else {
                  final cards = snapshot.data!;
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return _buildSelectableCard(card);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableCard(CardModel card) {
    final isSelected = selectedCards.contains(card);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCards.remove(card);
          } else if (selectedCards.length < maxCards) {
            selectedCards.add(card);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    card.imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ColorUtils.getRarityColor(card.rarity)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          card.rarity,
                          style: TextStyle(
                            color: ColorUtils.getRarityColor(card.rarity),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Additional Options',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 14,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _coinsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
              autofocus: false,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add coins to offer',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Orbitron',
                ),
                prefixIcon: Icon(
                  Icons.monetization_on,
                  color: const Color(0xFFFFB800).withOpacity(0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _noteController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Orbitron',
              ),
              autofocus: false,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Add a note (optional)',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Orbitron',
                ),
                prefixIcon: Icon(
                  Icons.note_alt_outlined,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: ElevatedButton(
        onPressed: selectedCards.isEmpty || _isLoading ? null : _makeOffer,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'MAKE OFFER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
      ),
    );
  }
}
