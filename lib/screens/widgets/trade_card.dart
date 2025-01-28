import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/trade.dart';
import '../../models/card.dart';
import '../../utils/color_utils.dart';
import '../../screens/make_offer_screen.dart';

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
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  trade.sender.image!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Column(
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
              Text(
                'Level ${trade.sender.level}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  ColorUtils.getTradeStatusColor(trade.status, null).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trade.status.toString().split('.').last,
              style: TextStyle(
                color: ColorUtils.getTradeStatusColor(trade.status, null),
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Offering:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
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
    return GestureDetector(
      onTap: () => onCardTap(context, card),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorUtils.getRarityColor(card.rarity).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                  child: Image.network(
                    card.imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      card.rarity.toUpperCase(),
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
      ),
    );
  }

  Widget _buildCoinsOffer(String formattedCoins) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '+ $formattedCoins coins',
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                trade.note ?? 'No note provided',
                style: TextStyle(
                  color: trade.note != null
                      ? Colors.grey
                      : Colors.grey.withOpacity(0.5),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ElevatedButton(
              onPressed: () => _showMakeOfferModal(context, trade),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
