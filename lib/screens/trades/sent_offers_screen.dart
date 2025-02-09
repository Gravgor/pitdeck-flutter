import 'package:flutter/material.dart';
import 'package:pitdeck/models/trade_offer.dart';
import 'package:provider/provider.dart';
import '../../models/trade.dart';
import '../../providers/trade_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/color_utils.dart';
import '../../widgets/trade/trade_card.dart';

class SentOffersScreen extends StatelessWidget {
  const SentOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.id;

        if (userId == null) {
          return _buildEmptyState(
            icon: Icons.account_circle_outlined,
            message: 'Please log in to view your sent offers',
          );
        }

        final sentOffers = tradeProvider.trades
            .where((trade) => trade.senderId == userId)
            .toList();

        if (sentOffers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.local_offer_outlined,
            message: 'No sent offers yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sentOffers.length,
          itemBuilder: (context, index) => _buildOfferCard(
            context,
            sentOffers[index],
            tradeProvider,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(
    BuildContext context,
    TradeModel trade,
    TradeProvider tradeProvider,
  ) {
    return TradeCard(
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    _buildStatusChip(trade.status),
                  ],
                ),
                if (trade.note != null) ...[
                  const SizedBox(height: 12),
                  _buildNote(trade.note!),
                ],
                const SizedBox(height: 16),
                _buildOfferedCards(trade),
                if (trade.coinsOffered > 0)
                  _buildCoinsOffered(trade.coinsOffered),
              ],
            ),
          ),
          if (trade.status == TradeStatus.PENDING)
            _buildCancelButton(context, trade.id, tradeProvider),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TradeStatus status) {
    final color = ColorUtils.getTradeStatusColor(status, null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toString().split('.').last,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Orbitron',
        ),
      ),
    );
  }

  Widget _buildNote(String note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        note,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildOfferedCards(TradeModel trade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Offered Cards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trade.offeredCards.length,
            itemBuilder: (context, index) {
              final card = trade.offeredCards[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            card.imageUrl,
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${card.serialNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    _buildRarityChip(card.rarity),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRarityChip(String rarity) {
    final color = ColorUtils.getRarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCoinsOffered(int coins) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(
            Icons.monetization_on,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$coins coins offered',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(
    BuildContext context,
    String tradeId,
    TradeProvider tradeProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF2563EB).withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: TextButton(
        onPressed: () async {
          await tradeProvider.cancelTrade(tradeId);
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'CANCEL OFFER',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
