import 'package:flutter/material.dart';
import 'package:pitdeck/models/card.dart';
import 'package:pitdeck/models/pack.dart';
import 'dart:math' show pi, sin;
import 'package:pitdeck/screens/pack/pack_results_screen.dart';

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
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
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
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF0A0A1A),
                    ],
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
              ),
            ),
            if (_isSelectionComplete)
              Container(
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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

  Widget _buildCard(Map<String, dynamic> card, bool isSelected) {
    final isRevealed = _cardRevealed[card['id']] ?? false;
    final canSelect = !isRevealed || isSelected;
    final remainingSelections =
        widget.pack.cardsPerPack - _selectedCardIds.length;

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
                  ? _buildCardBack(remainingSelections)
                  : _buildCardFront(card, isSelected),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardBack(int remainingSelections) {
    return Container(
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

  Widget _buildCardFront(Map<String, dynamic> card, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : _getRarityColor(card['rarity']).withOpacity(0.5),
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getRarityColor(card['rarity']).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              card['imageUrl'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRarityColor(card['rarity']),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRarityColor(card['rarity']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card['rarity'].toUpperCase(),
                      style: TextStyle(
                        color: _getRarityColor(card['rarity']),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'COMMON':
        return Colors.grey;
      case 'UNCOMMON':
        return Colors.green;
      case 'RARE':
        return Colors.blue;
      case 'EPIC':
        return Colors.purple;
      case 'LEGENDARY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
