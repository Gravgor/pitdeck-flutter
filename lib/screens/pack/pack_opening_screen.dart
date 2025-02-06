import 'package:flutter/material.dart';
import 'package:pitdeck/models/card.dart';
import 'package:pitdeck/models/pack.dart';
import 'dart:math' show pi, sin;
import 'package:pitdeck/screens/pack/pack_results_screen.dart';
import 'package:pitdeck/utils/color_utils.dart';

class PackOpeningScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Pack pack;
  final Function(List<String>) onComplete;

  const PackOpeningScreen({
    super.key,
    required this.sessionData,
    required this.pack,
    required this.onComplete,
  });

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Map<String, dynamic>> _cardPool = [];
  final Set<String> _selectedCardIds = {};
  bool _isRevealed = false;
  final Map<String, bool> _cardRevealed = {};
  bool _isSelectionComplete = false;
  bool _hasStartedSelection = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _cardPool = List<Map<String, dynamic>>.from(widget.sessionData['cardPool']);
    for (var card in _cardPool) {
      _cardRevealed[card['id']] = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else if (_selectedCardIds.length < widget.pack.cardsPerPack) {
        _selectedCardIds.add(cardId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStartedSelection) {
      return _buildWelcomeScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildCardGrid(),
            ),
            if (_isSelectionComplete) _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Opening Pack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select ${widget.pack.cardsPerPack - _selectedCardIds.length} more cards',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0A0A1A)],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Color(0xFF3B82F6),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Pack Awaits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to begin your selection',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          4 * sin(_controller.value * 2 * pi),
                        ),
                        child: _buildFloatingCards(),
                      );
                    },
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _hasStartedSelection = true;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCards() {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(
        3,
        (index) => Transform.translate(
          offset: Offset(
            (index - 1) * 40.0,
            0,
          ),
          child: Transform.rotate(
            angle: (index - 1) * 0.2,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0A0A1A)],
                ),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.help_outline,
                  color: Colors.white.withOpacity(0.3),
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardGrid() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF0A0A1A)],
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        itemCount: _cardPool.length,
        itemBuilder: (context, index) {
          final card = _cardPool[index];
          final isSelected = _selectedCardIds.contains(card['id']);
          return _buildCard(card, isSelected);
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> card, bool isSelected) {
    final isRevealed = _cardRevealed[card['id']] ?? false;
    final canSelect = !isRevealed || isSelected;
    final isLegendary = card['rarity'] == 'LEGENDARY';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: canSelect ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: () {
          if (!canSelect) return;
          if (!isRevealed) {
            if (_selectedCardIds.length < widget.pack.cardsPerPack) {
              setState(() {
                _cardRevealed[card['id']] = true;
                _selectedCardIds.add(card['id']);
                if (_selectedCardIds.length == widget.pack.cardsPerPack) {
                  _isSelectionComplete = true;
                }
              });
            }
          }
        },
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0, end: isRevealed ? 1 : 0),
          builder: (context, value, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(3.14 * (1 - value)),
              alignment: Alignment.center,
              child: value < 0.5
                  ? _buildCardBack()
                  : _buildCardFront(card, isSelected, isLegendary),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF0A0A1A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.help_outline,
              color: Colors.white.withOpacity(0.3),
              size: 48,
            ),
          ),
          if (!_isRevealed)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                'Tap to Reveal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardFront(
      Map<String, dynamic> card, bool isSelected, bool isLegendary) {
    final rarityColor = ColorUtils.getRarityColor(card['rarity']);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            rarityColor.withOpacity(0.05),
            const Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : rarityColor.withOpacity(0.3),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          if (isLegendary) ...[
            BoxShadow(
              color: rarityColor.withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: rarityColor.withOpacity(0.1),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ] else
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                card['imageUrl'],
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
                  card['name'],
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
                    color: rarityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: isLegendary
                        ? Border.all(
                            color: rarityColor.withOpacity(0.3),
                          )
                        : null,
                  ),
                  child: Text(
                    card['rarity'],
                    style: TextStyle(
                      color: rarityColor,
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

  Widget _buildConfirmButton() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF3B82F6).withOpacity(0.5),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'CONFIRM SELECTION',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                ),
              ),
      ),
    );
  }

  void _onComplete() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<CardModel> selectedCards = [];

      // Fetch details for each selected card
      for (String cardId in _selectedCardIds) {
        final card = _cardPool.firstWhere((card) => card['id'] == cardId);
        selectedCards.add(CardModel.fromJson(card));
      }

      if (!mounted) return;

      // Navigate to results screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PackResultsScreen(cards: selectedCards),
        ),
      );

      // Call the original onComplete callback
      widget.onComplete(_selectedCardIds.toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error processing selected cards'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
