import 'package:flutter/material.dart';
import 'package:pitdeck/models/listing.dart';
import 'package:pitdeck/models/trade.dart';
import 'package:pitdeck/providers/card_provider.dart';
import 'package:pitdeck/providers/trade_provider.dart';
import 'package:pitdeck/screens/trades/my_listings_screen.dart';
import 'package:pitdeck/screens/trades/trades_screen.dart';
import '../../models/card.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/listing_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/trade_card.dart';
import 'sell_card_screen.dart';
import 'create_trade_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Market Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buy, sell, and trade racing cards',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showTradeManagement(),
                icon: Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('MARKET'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_horiz, size: 16),
                      SizedBox(width: 8),
                      Text('TRADES'),
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
        final listings = listingProvider.listings;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (listings.isEmpty) {
          return const Center(
            child: Text(
              'No listings available',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadListings,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              return _buildListingCard(listings[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    final formattedPrice = NumberFormat('#,###').format(listing.price);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCardDetailsMore(context, listing.card),
        borderRadius: BorderRadius.circular(16),
        child: Column(
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.card.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRarityColor(listing.card.rarity)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getRarityColor(listing.card.rarity)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          listing.card.rarity,
                          style: TextStyle(
                            color: _getRarityColor(listing.card.rarity),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${listing.card.serialNumber}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedPrice RC',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _showBuyCardModal(context, listing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'BUY NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
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
    );
  }

  Widget _buildTrades() {
    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        final trades = tradeProvider.activeTrades;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No trades available',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadTrades,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadTrades,
          child: _buildTradesList(trades),
        );
      },
    );
  }

  Widget _buildTradesList(List<TradeModel> trades) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        return TradeCard(
          trade: trades[index],
          onCardTap: _showCardDetailsMore,
          onMakeOffer: _showMakeOfferModal,
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
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Listing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to list your cards',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionButton(
              icon: Icons.store,
              title: 'Sell Card',
              subtitle: 'List your card for a fixed price',
              onTap: () {
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !isProcessing,
      enableDrag: !isProcessing,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        listing.card.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Price: $formattedPrice coins',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '#${listing.card.serialNumber}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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
                    child: ElevatedButton(
                      onPressed:
                          isProcessing ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
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
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setState(() {
                                isProcessing = true;
                              });
                              try {
                                await Provider.of<ListingProvider>(context,
                                        listen: false)
                                    .buyListing(listing.id);
                                Navigator.pop(context);
                                // TODO: Show success message
                              } catch (e) {
                                setState(() {
                                  isProcessing = false;
                                });
                                // TODO: Show error message
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isProcessing ? 'Processing...' : 'Buy Now',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          color: Colors.white,
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
            color: Color(0xFF0A0A1A),
            border: Border(
              top: BorderSide(color: Colors.white10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Make Offer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select cards to trade',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
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
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                        Text(
                          'Selected Cards',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (selectedCardIds.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Center(
                          child: Text(
                            'No cards selected',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedCardIds.length,
                          itemBuilder: (context, index) {
                            final card = Provider.of<CardProvider>(context,
                                    listen: false)
                                .cards
                                .firstWhere((card) =>
                                    card.serialNumber ==
                                    selectedCardIds.elementAt(index));
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.white10),
                                        ),
                                        child: Image.network(
                                          card.imageUrl,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedCardIds
                                                  .remove(card.serialNumber);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              border: Border.all(
                                                  color: Colors.white24),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Coins',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TextField(
                        controller: coinsController,
                        keyboardType: TextInputType.number,
                        autofocus: false,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.monetization_on,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Note',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TextField(
                        controller: noteController,
                        maxLines: 3,
                        autofocus: false,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: const TextStyle(
                          color: Colors.white,
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
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.2)),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedCardIds.isNotEmpty
                            ? () {
                                // TODO: Implement make offer logic
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(),
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.05),
                        ),
                        child: Text(
                          'Send Offer',
                          style: TextStyle(
                            color: selectedCardIds.isNotEmpty
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            fontSize: 16,
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
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                          ),
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
                        backgroundColor: Colors.white.withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
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
}
