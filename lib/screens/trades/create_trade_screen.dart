import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/card_provider.dart';
import '../../providers/trade_provider.dart';
import '../../models/card.dart';
import '../../utils/color_utils.dart';

class CreateTradeScreen extends StatefulWidget {
  const CreateTradeScreen({super.key});

  @override
  State<CreateTradeScreen> createState() => _CreateTradeScreenState();
}

class _CreateTradeScreenState extends State<CreateTradeScreen> {
  final Set<CardModel> selectedCards = {};
  final _coinsController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  static const int maxCards = 8;

  @override
  void dispose() {
    _coinsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createTrade() async {
    if (selectedCards.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<TradeProvider>(context, listen: false).createTrade(
        offeredCardIds: selectedCards.map((card) => card.id).toList(),
        coinsOffered: int.tryParse(_coinsController.text) ?? 0,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating trade: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Create Trade',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSelectedCardsSection(),
          _buildCardSelection(),
          _buildTradeOptions(),
        ],
      ),
      bottomNavigationBar: _buildCreateTradeButton(),
    );
  }

  Widget _buildSelectedCardsSection() {
    if (selectedCards.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
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
              Text(
                'Selected Cards (${selectedCards.length}/$maxCards)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              Text(
                '${maxCards - selectedCards.length} remaining',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedCards.length,
              itemBuilder: (context, index) {
                final card = selectedCards.elementAt(index);
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              card.imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            card.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFDC2626).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            setState(() => selectedCards.remove(card));
                          },
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
    );
  }

  Widget _buildCardSelection() {
    return Expanded(
      child: Consumer<CardProvider>(
        builder: (context, cardProvider, _) {
          final cards = cardProvider.cards
              .where((card) => !card.isForSale && !card.isForTrade)
              .toList();

          if (cards.isEmpty) {
            return const Center(
              child: Text(
                'No cards available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final isSelected = selectedCards.contains(card);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedCards.remove(card);
                    } else if (selectedCards.length < maxCards) {
                      selectedCards.add(card);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              card.imageUrl,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                                    color:
                                        ColorUtils.getRarityColor(card.rarity)
                                            .withOpacity(0.2),
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
                                const SizedBox(height: 4),
                                Text(
                                  '#${card.serialNumber}',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
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
          );
        },
      ),
    );
  }

  Widget _buildTradeOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _coinsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
            decoration: InputDecoration(
              hintText: 'Add coins to offer',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontFamily: 'Orbitron',
              ),
              prefixIcon: const Icon(
                Icons.monetization_on,
                color: Color(0xFFFFB800),
              ),
              filled: true,
              fillColor: const Color(0xFF0A0A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note to your trade offer',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontFamily: 'Orbitron',
              ),
              prefixIcon: const Icon(
                Icons.note,
                color: Color(0xFF3B82F6),
              ),
              filled: true,
              fillColor: const Color(0xFF0A0A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTradeButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            selectedCards.isNotEmpty && !_isLoading ? _createTrade : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.withOpacity(0.2),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'CREATE TRADE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
      ),
    );
  }
}
