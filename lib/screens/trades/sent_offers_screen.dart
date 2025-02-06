import 'package:flutter/material.dart';
import 'package:pitdeck/models/trade_offer.dart';
import 'package:provider/provider.dart';
import '../../models/trade.dart';
import '../../providers/trade_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/color_utils.dart';

class SentOffersScreen extends StatelessWidget {
  const SentOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TradeProvider>(
      builder: (context, tradeProvider, child) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.id;

        if (userId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please log in to view your sent offers',
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

        final sentOffers = tradeProvider.trades.where((trade) => trade.senderId == userId).toList();


        if (sentOffers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No sent offers yet',
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sentOffers.length,
          itemBuilder: (context, index) {
            final trade = sentOffers[index];
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    ColorUtils.getTradeStatusColor(trade.status, trade.status as TradeOfferStatus)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: ColorUtils.getTradeStatusColor(
                                          trade.status, trade.status as TradeOfferStatus)
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                trade.status.toString().split('.').last,
                                style: TextStyle(
                                  color: ColorUtils.getTradeStatusColor(
                                      trade.status, trade.status as TradeOfferStatus),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (trade.note != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              trade.note!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
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
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        card.imageUrl,
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      ),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorUtils.getRarityColor(
                                                card.rarity)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        card.rarity,
                                        style: TextStyle(
                                          color: ColorUtils.getRarityColor(
                                              card.rarity),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                  if (trade.status == TradeStatus.PENDING)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.1),
                            const Color(0xFF2563EB).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16)),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          await tradeProvider.cancelTrade(trade.id);
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
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
