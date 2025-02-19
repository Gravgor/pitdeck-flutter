

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pitdeck/utils/color_utils.dart';
import 'package:pitdeck/utils/snackbar_utils.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/models/pack.dart';
import 'package:pitdeck/screens/pack/pack_opening_screen.dart';
import 'dart:math' show pi, sin;

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key});

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends State<PacksScreen>
    with SingleTickerProviderStateMixin {
  List<Pack> _packs = [];
  bool _isLoading = true;
  bool _isOpeningLoading = false;
  String _selectedFilter = 'ALL';
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  List<Pack> _filteredPacks = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _fetchPacks();
    _searchController.addListener(_filterPacks);
  }

  void _filterPacks() {
    if (_searchController.text.isEmpty) {
      setState(() => _filteredPacks = _packs);
    } else {
      setState(() {
        _filteredPacks = _packs
            .where((pack) => pack.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchPacks() async {
    try {
      final auth = Provider.of<UserProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse('https://api.pitdeck.app/api/packs/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.user?.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _packs = data
              .map((json) => Pack.fromJson(json))
              .where(
                  (pack) => pack.imageUrl.contains('pitdeck-app.s3.eu-north-1'))
              .toList();
          _filteredPacks = _packs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openPack(Pack pack) async {
    try {
      setState(() => _isOpeningLoading = true);
      final auth = Provider.of<UserProvider>(context, listen: false);

      final response = await http.post(
        Uri.parse('https://api.pitdeck.app/api/packs/${pack.id}/open'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.user?.token}',
        },
      );

      if (response.statusCode == 201) {
        final sessionData = json.decode(response.body);
        final completer = Completer<void>();

        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => PackOpeningScreen(
            sessionData: sessionData,
            pack: pack,
            onComplete: (selectedCardIds) async {
              try {
                final completeResponse = await http.post(
                  Uri.parse(
                      'https://api.pitdeck.app/api/packs/session/${sessionData['sessionId']}/complete'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${auth.user?.token}',
                  },
                  body: json.encode({
                    'selectedCardIds': selectedCardIds,
                  }),
                );

                if (completeResponse.statusCode == 201) {
                  completer.complete();
                    SnackBarUtils.showSuccess(context, title: 'Success', message: 'Pack opened successfully!');
                }
              } catch (e) {
                completer.completeError(e);
                SnackBarUtils.showError(context, title: 'Error', message: 'Failed to complete pack opening');
              }
            },
          ),
        );
        await completer.future;
        if (!mounted) return;
      } else if (response.statusCode == 400) {
        setState(() => _isOpeningLoading = false);
        SnackBarUtils.showError(context, title: 'Error', message: 'You do not have enough coins to open this pack');
      }
    } catch (e) {
      setState(() => _isOpeningLoading = false);
      SnackBarUtils.showError(context, title: 'Error', message: 'Failed to open pack');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatNumber(int number) {
    final String numStr = number.toString();
    final StringBuffer result = StringBuffer();
    int count = 0;

    for (int i = numStr.length - 1; i >= 0; i--) {
      if (count != 0 && count % 3 == 0) {
        result.write('.');
      }
      result.write(numStr[i]);
      count++;
    }

    return result.toString().split('').reversed.join();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 260,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0, end: 4 * pi),
                  curve: Curves.linear,
                  builder: (context, value, child) => Transform.rotate(
                    angle: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.0),
                            const Color(0xFF3B82F6).withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF3B82F6),
                  size: 48,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isOpeningLoading ? 'Opening pack...' : 'Loading packs...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(Pack pack) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            ColorUtils.getRarityColor(pack.guaranteedRarities.first)
                .withOpacity(0.05),
            const Color(0xFF1A1A2E),
          ],
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
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        pack.imageUrl.startsWith('http')
                            ? pack.imageUrl
                            : 'https://pitdeck-app.s3.eu-north-1.amazonaws.com${pack.imageUrl}',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF1A1A2E).withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pack.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatNumber(pack.price),
                                style: const TextStyle(
                                  color: Color(0xFFFFB800),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pack.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pack.guaranteedRarities.map((rarity) {
                        final color = ColorUtils.getRarityColor(rarity);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: color,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rarity,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openPack(pack),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isOpeningLoading ? 'Opening...' : 'Open Pack',
                          style: const TextStyle(
                            fontSize: 16,
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
            ],
          ),
          if (pack.isLimited)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Limited: ${pack.limitedQuantity}',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040412),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildPacksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF040412),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'PACKS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
          const Spacer(),
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                      _formatNumber(userProvider.user?.coins ?? 0),
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
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search packs...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['ALL', 'COMMON', 'RARE', 'EPIC', 'LEGENDARY'];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          final color = _getRarityColor(filter);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(filter),
              labelStyle: TextStyle(
                color: isSelected ? color : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
              backgroundColor: const Color(0xFF1A1A2E),
              selectedColor: color.withOpacity(0.2),
              side: BorderSide(
                color: isSelected ? color : color.withOpacity(0.3),
                width: 1.5,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _filterPacks();
                });
              },
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPacksList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredPacks.length,
      itemBuilder: (context, index) => _buildPackCard(_filteredPacks[index]),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'COMMON':
        return const Color(0xFF9CA3AF);
      case 'RARE':
        return const Color(0xFF3B82F6);
      case 'EPIC':
        return const Color(0xFFA855F7);
      case 'LEGENDARY':
        return const Color(0xFFFFB800);
      default:
        return const Color(0xFF3B82F6); // Default color for 'ALL'
    }
  }
}
