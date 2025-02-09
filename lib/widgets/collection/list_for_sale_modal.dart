import 'package:flutter/material.dart';
import 'package:pitdeck/utils/color_utils.dart';
import '../../models/card.dart';
import '../../providers/listing_provider.dart';
import 'package:provider/provider.dart';

class ListForSaleModal extends StatefulWidget {
  final CardDetailModel card;

  const ListForSaleModal({super.key, required this.card});

  @override
  State<ListForSaleModal> createState() => _ListForSaleModalState();
}

class _ListForSaleModalState extends State<ListForSaleModal> {
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
            const Color(0xFF0A0A1A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ).createShader(bounds),
                  child: const Text(
                    'List for Sale',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Card Details',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 14,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCardPreview(widget.card),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Set Price (RC)',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 14,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        autofocus: false,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Orbitron',
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter price',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _listForSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'LIST FOR SALE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(CardDetailModel card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              card.imageUrl,
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
                  card.name,
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
                    color: ColorUtils.getRarityColor(card.rarity)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _listForSale() async {
    if (_priceController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final price = int.parse(_priceController.text);
      await Provider.of<ListingProvider>(context, listen: false)
          .createListing(cardId: widget.card.id, price: price);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}
