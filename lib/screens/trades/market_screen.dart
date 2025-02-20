import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitdeck/models/listing.dart';
import 'package:pitdeck/models/trade.dart';
import 'package:pitdeck/providers/card_provider.dart';
import 'package:pitdeck/providers/trade_provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/screens/trades/my_listings_screen.dart';
import 'package:pitdeck/screens/trades/trades_screen.dart';
import 'package:pitdeck/utils/snackbar_utils.dart';
import '../../models/card.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/listing_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/trade_card.dart';
import 'sell_card_screen.dart';
import 'create_trade_screen.dart';
import 'package:pitdeck/screens/user_profile_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'my_listings';
  Set<String> _selectedRarities = {};
  Set<String> _selectedTypes = {};
  String _emptyStateMessage = '';
  List<ListingModel> _filteredListings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadListings();
    _loadTrades();
  }

  Future<void> _loadListings() async {
    try {
      setState(() => isLoading = true);
      await Provider.of<ListingProvider>(context, listen: false)
          .fetchListings();
    } catch (e) {
      // TODO: Handle error
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadTrades() async {
    if (!mounted) return;

    try {
      setState(() => isLoading = true);
      final tradeProvider = Provider.of<TradeProvider>(context, listen: false);
      await tradeProvider.fetchTrades();

      if (!mounted) return;

      // Debug log
      print('Active trades: ${tradeProvider.activeTrades.length}');
    } catch (e) {
      print('Error loading trades: $e'); // Debug log
      // TODO: Show error message to user
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMarketplace(),
                _buildTrades(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListingModal(context),
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ).createShader(bounds),
                    child: const Text(
                      'Market Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Buy, sell, and trade racing cards',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showTradeManagement();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                letterSpacing: 0.5,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store_rounded, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('MARKET'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('TRADES'),
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

  Widget _buildMarketplace() {
    return Consumer<ListingProvider>(
      builder: (context, listingProvider, child) {
        if (isLoading) {
          return Column(
            children: [
              _buildFilters(),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: _loadListings,
          color: const Color(0xFF3B82F6),
          child: Column(
            children: [
              _buildFilters(),
              if (_selectedFilter == 'my_listings' && _filteredListings.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.store_rounded,
                            size: 48,
                            color: const Color(0xFF3B82F6).withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Active Listings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start selling your cards in the marketplace',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontFamily: 'Orbitron',
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
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
                                _showAddListingModal(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'CREATE LISTING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredListings.length,
                    itemBuilder: (context, index) {
                      return _buildListingCard(_filteredListings[index]);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    var _myListingsCount = 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF1A1A2E).withOpacity(0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
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
                      hintText: 'Search listings...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontFamily: 'Orbitron',
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    onChanged: _handleSearch,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showFilterModal();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Badge(
                      isLabelVisible: _selectedRarities.isNotEmpty ||
                          _selectedTypes.isNotEmpty,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'My Cards on Sale',
                  value: 'my_listings',
                  count: _myListingsCount,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Price: Low to High',
                  value: 'price_asc',
                  count: _filteredListings.length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Price: High to Low',
                  value: 'price_desc',
                  count: _filteredListings.length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Recently Listed',
                  value: 'recent',
                  count: _filteredListings.length,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    final List<String> rarities = [
      'COMMON',
      'UNCOMMON',
      'RARE',
      'EPIC',
      'LEGENDARY'
    ];
    final List<String> types = ['DRIVER', 'CAR', 'TRACK', 'TEAM', 'MOMENT'];
    RangeValues _priceRange = const RangeValues(0, 100000);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Listings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedRarities.clear();
                          _selectedTypes.clear();
                          _priceRange = const RangeValues(0, 100000);
                        });
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RARITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: rarities.map((rarity) {
                          final isSelected = _selectedRarities.contains(rarity);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(rarity),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontFamily: 'Orbitron',
                            ),
                            backgroundColor: const Color(0xFF0A0A1A),
                            selectedColor: const Color(0xFF3B82F6),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white.withOpacity(0.1),
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedRarities.add(rarity);
                                } else {
                                  _selectedRarities.remove(rarity);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'TYPE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: types.map((type) {
                          final isSelected = _selectedTypes.contains(type);
                          return FilterChip(
                            selected: isSelected,
                            label: Text(type),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontFamily: 'Orbitron',
                            ),
                            backgroundColor: const Color(0xFF0A0A1A),
                            selectedColor: const Color(0xFF3B82F6),
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white.withOpacity(0.1),
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedTypes.add(type);
                                } else {
                                  _selectedTypes.remove(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'PRICE RANGE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 100000,
                        divisions: 100,
                        activeColor: const Color(0xFF3B82F6),
                        inactiveColor: Colors.white.withOpacity(0.1),
                        labels: RangeLabels(
                          '${_priceRange.start.round()} RC',
                          '${_priceRange.end.round()} RC',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.white,
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
                          final listingProvider = Provider.of<ListingProvider>(
                              context,
                              listen: false);

                          listingProvider.applyFilters(
                            rarities: _selectedRarities.toList(),
                            types: _selectedTypes.toList(),
                            minPrice: _priceRange.start,
                            maxPrice: _priceRange.end,
                          );

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

  void _handleSearch(String query) {
    setState(() {
      final listingProvider =
          Provider.of<ListingProvider>(context, listen: false);
      final listings = listingProvider.listings;

      if (query.isEmpty) {
        _loadListings();
        return;
      }

      listingProvider.filteredListings = listings.where((listing) {
        return listing.card.name.toLowerCase().contains(query.toLowerCase()) ||
            listing.card.type.toLowerCase().contains(query.toLowerCase()) ||
            listing.seller.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _buildListingCard(ListingModel listing) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isOwnListing = currentUser?.id == listing.seller.id;
    final formattedPrice = NumberFormat('#,###').format(listing.price);
    final rarityColor = _getRarityColor(listing.card.rarity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E), Color(0xFF0A0A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showCardDetailsMore(context, listing.card);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    listing.card.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${listing.card.serialNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: rarityColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          listing.card.rarity,
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listing.card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontFamily: 'Orbitron',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedPrice RC',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      ),
                      if (isOwnListing)
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.edit_rounded,
                              color: const Color(0xFF3B82F6),
                              onTap: () => _showEditPriceModal(listing),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: Colors.red.shade400,
                              onTap: () => _showDeleteConfirmation(listing),
                            ),
                          ],
                        )
                      else
                        Container(
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
                                _showBuyCardModal(context, listing);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                child: Text(
                                  'BUY NOW',
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _navigateToUserProfile(listing.seller.id),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  NetworkImage(listing.seller.image ?? ''),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.seller.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Level ${listing.seller.level}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _showEditPriceModal(ListingModel listing) {
    final priceController =
        TextEditingController(text: listing.price.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF3B82F6),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Edit Price',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter new price for your card',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Orbitron',
                ),
                decoration: InputDecoration(
                  hintText: 'Enter new price',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(
                    Icons.monetization_on_outlined,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newPrice = int.tryParse(priceController.text);
                  if (newPrice != null) {
                    await Provider.of<ListingProvider>(context, listen: false)
                        .updateListingPrice(listing.id, newPrice);
                    Navigator.pop(context);
                    _loadListings();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'UPDATE PRICE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ListingModel listing) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Remove Listing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to remove this card from sale?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await Provider.of<ListingProvider>(context,
                                listen: false)
                            .removeFromSale(listing.id);
                        Navigator.pop(context);
                        _loadListings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'REMOVE',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
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

  Widget _buildTrades() {
    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        final trades = tradeProvider.activeTrades;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          );
        }

        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 48,
                    color: const Color(0xFF3B82F6).withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Active Trades',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start trading cards with other players',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontFamily: 'Orbitron',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
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
                        _loadTrades();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        child: Text(
                          'REFRESH TRADES',
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
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadTrades,
          color: const Color(0xFF3B82F6),
          backgroundColor: const Color(0xFF1A1A2E),
          child: _buildTradesList(trades),
        );
      },
    );
  }

  Widget _buildTradesList(List<TradeModel> trades) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trades.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return TradeCard(
          trade: trades[index],
          onCardTap: (context, card) {
            HapticFeedback.lightImpact();
            _showCardDetailsMore(context, card);
          },
          onMakeOffer: (context, trade) {
            HapticFeedback.mediumImpact();
            _showMakeOfferModal(context, trade);
          },
        );
      },
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'LEGENDARY':
        return Colors.amber;
      case 'EPIC':
        return Colors.purple;
      case 'RARE':
        return Colors.blue;
      case 'UNCOMMON':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAddListingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ).createShader(bounds),
              child: const Text(
                'Create New Listing',
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
              'Choose how you want to list your cards',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontFamily: 'Orbitron',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionButton(
              icon: Icons.store,
              title: 'Sell Card',
              subtitle: 'List your card for a fixed price',
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellCardScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionButton(
              icon: Icons.swap_horiz,
              title: 'Create Trade',
              subtitle: 'Offer cards for trade with others',
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTradeScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0A1A),
            const Color(0xFF0A0A1A).withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.2),
                        const Color(0xFF60A5FA).withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: const Color(0xFF3B82F6).withOpacity(0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCardDetailsMore(BuildContext context, CardDetailModel card) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  card.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getRarityColor(card.rarity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.rarity,
                  style: TextStyle(
                    color: _getRarityColor(card.rarity),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${card.type}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Serial: #${card.serialNumber}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuyCardModal(BuildContext context, ListingModel listing) {
    bool isProcessing = false;
    final formattedPrice = NumberFormat('#,###').format(listing.price);
    final rarityColor = _getRarityColor(listing.card.rarity);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !isProcessing,
      enableDrag: !isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E), Color(0xFF0A0A1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            listing.card.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${listing.card.serialNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: rarityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: rarityColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              listing.card.rarity,
                              style: TextStyle(
                                color: rarityColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            listing.card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                color: const Color(0xFF3B82F6),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$formattedPrice RC',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
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
                          if (isProcessing)
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
                          onTap: isProcessing
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    isProcessing = true;
                                  });
                                  try {
                                    await Provider.of<ListingProvider>(context,
                                            listen: false)
                                        .buyListing(listing.id);
                                    Navigator.pop(context);
                                    Provider.of<UserProvider>(context,
                                            listen: false)
                                        .refreshUser();
                                    Provider.of<CardProvider>(context,
                                            listen: false)
                                        .fetchUserCards();
                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    SnackBarUtils.showSuccess(
                                      context,
                                      title: 'Success',
                                      message: 'Card purchased successfully',
                                    );
                                  } catch (e) {
                                    setState(() {
                                      isProcessing = false;
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    SnackBarUtils.showError(
                                      context,
                                      title: 'Error',
                                      message: 'Failed to purchase card',
                                    );
                                  }
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              isProcessing ? 'PROCESSING...' : 'BUY NOW',
                              style: const TextStyle(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMakeOfferModal(BuildContext context, TradeModel trade) {
    Set<String> selectedCardIds = {};
    final TextEditingController noteController = TextEditingController();
    final TextEditingController coinsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E), Color(0xFF0A0A1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
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
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make Offer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Select cards to trade',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.close,
                                color: Colors.white.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xFF3B82F6).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.card_giftcard_rounded,
                                size: 16,
                                color: const Color(0xFF3B82F6).withOpacity(0.8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selected Cards (${selectedCardIds.length}/8)',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showCardSelectionModal(selectedCardIds,
                                (selected) {
                              setState(() {
                                selectedCardIds = selected;
                              });
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('Add Cards'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            textStyle: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedCardIds.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.card_giftcard_rounded,
                              size: 32,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No cards selected',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                fontFamily: 'Orbitron',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: selectedCardIds.length,
                          itemBuilder: (context, index) {
                            final card = Provider.of<CardProvider>(context,
                                    listen: false)
                                .cards
                                .firstWhere((card) =>
                                    card.serialNumber ==
                                    selectedCardIds.elementAt(index));
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.1)),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            card.imageUrl,
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              selectedCardIds
                                                  .remove(card.serialNumber);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.7),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.close_rounded,
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    card.name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFFB800).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Coins',
                            style: TextStyle(
                              color: Color(0xFFFFB800),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: coinsController,
                              keyboardType: TextInputType.number,
                              autofocus: false,
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Orbitron',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter amount',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                                suffixIcon: const Icon(
                                  Icons.monetization_on,
                                  color: Color(0xFFFFB800),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: noteController,
                              maxLines: 3,
                              autofocus: false,
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Orbitron',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a note (optional)',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
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
                          gradient: LinearGradient(
                            colors: selectedCardIds.isNotEmpty
                                ? [
                                    const Color(0xFF3B82F6),
                                    const Color(0xFF2563EB)
                                  ]
                                : [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (selectedCardIds.isNotEmpty)
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
                            onTap: selectedCardIds.isNotEmpty
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    // TODO: Implement make offer logic
                                    Navigator.pop(context);
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'SEND OFFER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectedCardIds.isNotEmpty
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTradeManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradesScreen()),
    );
  }

  void _showCardSelectionModal(
      Set<String> selectedCardIds, Function(Set<String>) onConfirm) {
    final TextEditingController searchController = TextEditingController();
    final userCards =
        Provider.of<CardProvider>(context, listen: false).getUserCards();
    List<CardModel> filteredCards = List<CardModel>.from(userCards);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF0A0A1A),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        ).createShader(bounds),
                        child: const Text(
                          'Select Cards',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Select up to ${8 - selectedCardIds.length} more cards',
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close,
                          color: Colors.white.withOpacity(0.7)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                  ),
                  autofocus: false,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search by name, type, or serial...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontFamily: 'Orbitron',
                    ),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      if (value.isEmpty) {
                        filteredCards = List<CardModel>.from(userCards);
                      } else {
                        filteredCards = userCards.where((card) {
                          final searchLower = value.toLowerCase();
                          return card.name
                                  .toLowerCase()
                                  .contains(searchLower) ||
                              card.type.toLowerCase().contains(searchLower) ||
                              card.rarity.toLowerCase().contains(searchLower) ||
                              card.serialNumber
                                  .toLowerCase()
                                  .contains(searchLower);
                        }).toList();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    final isSelected =
                        selectedCardIds.contains(card.serialNumber);

                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          setModalState(() {
                            selectedCardIds.remove(card.serialNumber);
                          });
                        } else if (selectedCardIds.length < 8) {
                          setModalState(() {
                            selectedCardIds.add(card.serialNumber);
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    card.imageUrl,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
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
                                          fontSize: 12,
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
                                          color: _getRarityColor(card.rarity)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          card.rarity,
                                          style: TextStyle(
                                            color: _getRarityColor(card.rarity),
                                            fontSize: 10,
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
                            if (isSelected)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3B82F6)
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
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
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
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
                        onConfirm(selectedCardIds);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Selection',
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
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
  }) {
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            fontFamily: 'Orbitron',
          ),
        ),
      ),
    );
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final listingProvider =
          Provider.of<ListingProvider>(context, listen: false);
      final allListings = listingProvider.listings;
      List<ListingModel> filtered = [...allListings];
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).user;

      switch (filter) {
        case 'my_listings':
          final currentUser =
              Provider.of<UserProvider>(context, listen: false).user;
          if (currentUser != null) {
            filtered = allListings
                .where((l) => l.seller.id == currentUser.id)
                .toList();
            if (filtered.isEmpty) {
              _emptyStateMessage = 'You haven\'t listed any cards yet';
            }
          } else {
            filtered = [];
            _emptyStateMessage = 'Please sign in to view your listings';
          }
          break;
        case 'price_asc':
          filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
          filtered =
              filtered.where((l) => l.seller.id != currentUser?.id).toList();
          break;
        case 'price_desc':
          filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
          filtered =
              filtered.where((l) => l.seller.id != currentUser?.id).toList();
          break;
        case 'recent':
          filtered.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          filtered =
              filtered.where((l) => l.seller.id != currentUser?.id).toList();
          break;
      }

      _filteredListings = filtered;
    });
  }
}
