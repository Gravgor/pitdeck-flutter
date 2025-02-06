import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trade.dart';
import '../../models/card.dart';
import '../../utils/color_utils.dart';
import '../trades/make_offer_screen.dart';

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
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
          if (trade.sender.image != null)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  trade.sender.image!,
                  fit: BoxFit.cover,
                ),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: ColorUtils.getTradeStatusColor(trade.status, null)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
          child: Text(
            'Offering:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
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
    final isLegendary = card.rarity == 'LEGENDARY';

    return GestureDetector(
      onTap: () => onCardTap(context, card),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A0A1A), Color(0xFF070711)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isLegendary) ...[
              BoxShadow(
                color: ColorUtils.getRarityColor(card.rarity).withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: ColorUtils.getRarityColor(card.rarity).withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ],
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
                              color: ColorUtils.getRarityColor(card.rarity)
                                  .withOpacity(0.3),
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
          const Icon(
            Icons.monetization_on,
            color: Color(0xFFFFB800),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '$formattedCoins coins',
            style: const TextStyle(
              color: Color(0xFFFFB800),
              fontSize: 16,
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
                color: trade.note != null
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white.withOpacity(0.3),
                fontSize: 14,
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Make Offer',
              style: TextStyle(
                color: Colors.white,
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
