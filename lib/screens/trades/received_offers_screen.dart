import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trade_provider.dart';
import '../../models/trade_offer.dart';
import '../../utils/color_utils.dart';

class ReceivedOffersScreen extends StatefulWidget {
  const ReceivedOffersScreen({super.key});

  @override
  State<ReceivedOffersScreen> createState() => _ReceivedOffersScreenState();
}

class _ReceivedOffersScreenState extends State<ReceivedOffersScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      await Provider.of<TradeProvider>(context, listen: false)
          .fetchAllReceivedOffers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading offers: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptOffer(String offerId) async {
    try {
      await Provider.of<TradeProvider>(context, listen: false)
          .acceptOffer(offerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer accepted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting offer: $e')),
      );
    }
  }

  Future<void> _declineOffer(String offerId) async {
    try {
      await Provider.of<TradeProvider>(context, listen: false)
          .declineOffer(offerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer declined')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining offer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Consumer<TradeProvider>(
            builder: (context, tradeProvider, _) {
              final List<TradeOfferModel> offers = tradeProvider
                  .receivedOffers.values
                  .toList()
                  .expand((list) => list)
                  .toList();

              if (offers.isEmpty) {
                return const Center(
                  child: Text(
                    'No offers received',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  return _buildOfferCard(offers[index]);
                },
              );
            },
          );
  }

  Widget _buildOfferCard(TradeOfferModel offer) {
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
          _buildOfferHeader(offer),
          _buildOfferedCards(offer),
          if (offer.coins > 0) _buildCoinsOffered(offer),
          if (offer.note?.isNotEmpty ?? false) _buildNote(offer),
          _buildActions(offer),
        ],
      ),
    );
  }

  Widget _buildOfferHeader(TradeOfferModel offer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (offer.user.image != null)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  offer.user.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Expires in ${_formatTimeLeft(offer.expiresAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ColorUtils.getTradeOfferStatusColor(offer.status)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              offer.statusText,
              style: TextStyle(
                color: ColorUtils.getTradeOfferStatusColor(offer.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeLeft(DateTime expiresAt) {
    final difference = expiresAt.difference(DateTime.now());
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  Widget _buildOfferedCards(TradeOfferModel offer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Offered Cards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: offer.offeredCards.length,
            itemBuilder: (context, index) {
              final card = offer.offeredCards[index];
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
                    const SizedBox(height: 4),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
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
                        const SizedBox(height: 4),
                        Text(
                          '#${card.serialNumber}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoinsOffered(TradeOfferModel offer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            '${offer.coins} coins offered',
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

  Widget _buildNote(TradeOfferModel offer) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        offer.note!,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActions(TradeOfferModel offer) {
    if (!offer.isPending) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => _declineOffer(offer.id),
            child: const Text(
              'Decline',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _acceptOffer(offer.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
