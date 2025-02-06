import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trade.dart';
import '../../providers/trade_provider.dart';
import '../../providers/user_provider.dart';

class SentOffersScreen extends StatelessWidget {
  const SentOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.id;

        if (userId == null) {
          return const Center(
            child: Text(
              'Please log in to view your sent offers',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final sentOffers = tradeProvider.trades.where((trade) => trade.senderId == userId).toList();

        if (sentOffers.isEmpty) {
          return const Center(
            child: Text(
              'No sent offers',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sentOffers.length,
          itemBuilder: (context, index) {
            final trade = sentOffers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
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
                            const Text(
                              'Offer Sent',
                              style: TextStyle(
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
                                color: _getStatusColor(trade.status.toString())
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                trade.status.toString().split('.').last,
                                style: TextStyle(
                                  color:
                                      _getStatusColor(trade.status.toString()),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trade.note ?? 'No note provided',
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
                            itemCount: trade.offeredCards.length,
                            itemBuilder: (context, index) {
                              final card = trade.offeredCards[index];
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
                    child: TextButton(
                      onPressed: () async {
                        await tradeProvider.cancelTrade(trade.id);
                      },
                      child: const Text(
                        'Cancel Offer',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
}
