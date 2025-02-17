import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trade.dart';
import '../../models/card.dart';
import '../../utils/color_utils.dart';
import '../trades/make_offer_screen.dart';
import '../../widgets/user_avatar.dart';

class TradeCard extends StatelessWidget {
  final TradeModel trade;
  final Function(BuildContext, CardDetailModel) onCardTap;
  final Function(BuildContext, TradeModel) onMakeOffer;

  const TradeCard({
    super.key,
    required this.trade,
    required this.onCardTap,
    required this.onMakeOffer,
  });

  @override
  Widget build(BuildContext context) {
    final formattedCoins = NumberFormat('#,###').format(trade.coinsOffered);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
            const Color(0xFF0A0A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildTradeHeader(),
          _buildOfferedCards(),
          if (trade.coinsOffered > 0) _buildCoinsOffer(formattedCoins),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildTradeHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            userId: trade.sender.id,
            imageUrl: trade.sender.image,
            size: 40,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  trade.sender.name ?? 'Unknown Trader',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Level ${trade.sender.level}',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColorUtils.getTradeStatusColor(trade.status, null)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorUtils.getTradeStatusColor(trade.status, null)
                    .withOpacity(0.3),
              ),
            ),
            child: Text(
              trade.status.toString().split('.').last,
              style: TextStyle(
                color: ColorUtils.getTradeStatusColor(trade.status, null),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferedCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
            ),
            child: const Text(
              'Offering',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 14,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: trade.offeredCards.length,
            itemBuilder: (context, index) =>
                _buildCardItem(context, trade.offeredCards[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(BuildContext context, CardDetailModel card) {
    final isLegendary = card.rarity.toUpperCase() == 'LEGENDARY';
    final rarityColor = ColorUtils.getRarityColor(card.rarity);

    return GestureDetector(
      onTap: () => onCardTap(context, card),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white.withOpacity(0.1),
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white54),
                  ),
                ),
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
                      fontFamily: 'Orbitron',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: rarityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: rarityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      card.rarity,
                      style: TextStyle(
                        color: rarityColor,
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
      ),
    );
  }

  Widget _buildCoinsOffer(String formattedCoins) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB800).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFFB800), size: 20),
          const SizedBox(width: 8),
          Text(
            '$formattedCoins coins',
            style: const TextStyle(
              color: Color(0xFFFFB800),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              trade.note ?? 'No note provided',
              style: TextStyle(
                color: Colors.white.withOpacity(trade.note != null ? 0.7 : 0.3),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontFamily: 'Orbitron',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _showMakeOfferModal(context, trade),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Make Offer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMakeOfferModal(BuildContext context, TradeModel trade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MakeOfferScreen(originalTrade: trade),
      ),
    );
  }
}
