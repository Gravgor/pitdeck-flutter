import 'package:flutter/material.dart';
import '../models/card.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _mockMyListings = [
    {
      'id': '1',
      'offeredCards': [
        CardModel(
          name: 'Monaco',
          serialNumber: 'F1-24-L-000526',
          rarity: 'LEGENDARY',
          imageUrl: 'https://example.com/monaco.jpg',
          type: 'TRACK',
          id: '1',
          series: 'F1-24-L',
          isForSale: true,
        ),
      ],
      'wantedCards': ['Any Legendary Driver'],
      'additionalCoins': 500,
      'note': 'Looking for legendary drivers only',
      'status': 'ACTIVE',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
    },
  ];

  final List<Map<String, dynamic>> _mockReceivedOffers = [
    {
      'id': '1',
      'originalTrade': {
        'offeredCards': [
          CardModel(
            name: 'Monaco',
            serialNumber: 'F1-24-L-000526',
            rarity: 'LEGENDARY',
            imageUrl: 'https://example.com/monaco.jpg',
            type: 'TRACK',
            id: '1',
            series: 'F1-24-L',
            isForSale: true,
          ),
        ],
      },
      'offeredCards': [
        CardModel(
          name: 'Lewis Hamilton',
          serialNumber: 'F1-24-L-000152',
          rarity: 'LEGENDARY',
          imageUrl: 'https://example.com/hamilton.jpg',
          type: 'DRIVER',
          id: '1',
          series: 'F1-24-L',
          isForSale: true,
        ),
      ],
      'additionalCoins': 0,
      'note': 'Interested in your Monaco track',
      'trader': 'User789',
      'status': 'PENDING',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
    },
  ];

  final List<Map<String, dynamic>> _mockSentOffers = [
    {
      'id': '1',
      'originalTrade': {
        'offeredCards': [
          CardModel(
            name: 'Spa-Francorchamps',
            serialNumber: 'F1-24-L-000453',
            rarity: 'LEGENDARY',
            imageUrl: 'https://example.com/spa.jpg',
            type: 'TRACK',
            id: '1',
            series: 'F1-24-L',
            isForSale: true,
          ),
        ],
      },
      'offeredCards': [
        CardModel(
          name: 'Max Verstappen',
          serialNumber: 'F1-24-L-000103',
          rarity: 'LEGENDARY',
          imageUrl: 'https://example.com/verstappen.jpg',
          type: 'DRIVER',
          id: '1',
          series: 'F1-24-L',
          isForSale: true,
        ),
      ],
      'additionalCoins': 200,
      'note': 'Great offer for your track',
      'trader': 'User456',
      'status': 'PENDING',
      'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: 'MY LISTINGS'),
              Tab(text: 'RECEIVED'),
              Tab(text: 'SENT'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyListings(),
                _buildReceivedOffers(),
                _buildSentOffers(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trade Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage your trades and offers',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListings() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockMyListings.length,
      itemBuilder: (context, index) {
        final listing = _mockMyListings[index];
        final offeredCards = listing['offeredCards'] as List<CardModel>;

        return _buildTradeCard(
          cards: offeredCards,
          title: 'Your Trade Listing',
          subtitle: listing['note'],
          status: listing['status'],
          onTap: () => _showTradeDetails(context, listing),
          trailing: TextButton(
            onPressed: () {
              // TODO: Implement cancel listing
            },
            child: const Text(
              'Cancel Listing',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceivedOffers() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockReceivedOffers.length,
      itemBuilder: (context, index) {
        final offer = _mockReceivedOffers[index];
        final offeredCards = offer['offeredCards'] as List<CardModel>;

        return _buildTradeCard(
          cards: offeredCards,
          title: 'Offer from ${offer['trader']}',
          subtitle: offer['note'],
          status: offer['status'],
          onTap: () => _showOfferDetails(context, offer, isReceived: true),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  // TODO: Implement accept offer
                },
                child: const Text(
                  'Accept',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement decline offer
                },
                child: const Text(
                  'Decline',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSentOffers() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockSentOffers.length,
      itemBuilder: (context, index) {
        final offer = _mockSentOffers[index];
        final offeredCards = offer['offeredCards'] as List<CardModel>;

        return _buildTradeCard(
          cards: offeredCards,
          title: 'Your offer to ${offer['trader']}',
          subtitle: offer['note'],
          status: offer['status'],
          onTap: () => _showOfferDetails(context, offer, isReceived: false),
          trailing: TextButton(
            onPressed: () {
              // TODO: Implement cancel offer
            },
            child: const Text(
              'Cancel Offer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTradeCard({
    required List<CardModel> cards,
    required String title,
    required String subtitle,
    required String status,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  card.imageUrl,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white10),
                ),
              ),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTradeDetails(BuildContext context, Map<String, dynamic> trade) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trade Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTradeCardDetails(trade),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement cancel trade
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel Trade'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfferDetails(BuildContext context, Map<String, dynamic> offer,
      {required bool isReceived}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isReceived ? 'Received Offer' : 'Sent Offer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOfferCardDetails(offer, isReceived),
              const SizedBox(height: 24),
              if (isReceived)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement reject offer
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement accept offer
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Implement cancel offer
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel Offer'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeCardDetails(Map<String, dynamic> trade) {
    final offeredCards = trade['offeredCards'] as List<CardModel>;
    final wantedCards = trade['wantedCards'] as List<String>;
    final additionalCoins = trade['additionalCoins'] as int;
    final note = trade['note'] as String;
    final status = trade['status'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Offered Cards:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: offeredCards.length,
            itemBuilder: (context, index) {
              final card = offeredCards[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        card.imageUrl,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Looking For:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: wantedCards
              .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $card',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ))
              .toList(),
        ),
        if (additionalCoins > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Additional Coins: $additionalCoins',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Note:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfferCardDetails(Map<String, dynamic> offer, bool isReceived) {
    final offeredCards = offer['offeredCards'] as List<CardModel>;
    final originalTrade = offer['originalTrade'] as Map<String, dynamic>;
    final originalCards = originalTrade['offeredCards'] as List<CardModel>;
    final additionalCoins = offer['additionalCoins'] as int;
    final note = offer['note'] as String;
    final status = offer['status'] as String;
    final trader = offer['trader'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isReceived ? 'Offered Cards from $trader:' : 'Your Offered Cards:',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildCardsList(offeredCards),
        const SizedBox(height: 16),
        const Text(
          'In Exchange For:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildCardsList(originalCards),
        if (additionalCoins > 0) ...[
          const SizedBox(height: 16),
          Text(
            'Additional Coins: $additionalCoins',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Note:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsList(List<CardModel> cards) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    card.imageUrl,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
