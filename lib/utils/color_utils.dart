import 'package:flutter/material.dart';
import 'package:pitdeck/models/trade_offer.dart';
import '../models/trade.dart';

class ColorUtils {
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF6B7280);
      case 'rare':
        return const Color(0xFF3B82F6);
      case 'epic':
        return const Color(0xFFE040FB);
      case 'legendary':
        return const Color(0xFFFFD700);
        case 'mythic':
      return const Color(0xFFFF4081); // Vibrant pink
    case 'unique':
      return const Color(0xFFFFD700); // Gold
    case 'magic_moment':
      return const Color(0xFF9C27B0); // Deep purple
    case 'uncommon':
      return const Color(0xFF2196F3); // Blue
      default:
        return Colors.grey;
    }
  }

  static Color getTradeOfferStatusColor(TradeOfferStatus? status) {
    switch (status) {
      case TradeOfferStatus.pending:
        return const Color(0xFFFFA500);
      case TradeOfferStatus.accepted:
        return const Color(0xFF22C55E);
      case TradeOfferStatus.declined:
        return const Color(0xFFEF4444);
      case TradeOfferStatus.cancelled:
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  static Color getTradeStatusColorFromTrade(TradeStatus? status) {
    switch (status) {
      case TradeStatus.PENDING:
        return const Color(0xFFFFA500);
      case TradeStatus.ACCEPTED:
        return const Color(0xFF22C55E);
      case TradeStatus.REJECTED:
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  static Color getTradeStatusColor(
      TradeStatus? status, TradeOfferStatus? offerStatus) {
    if (offerStatus != null) {
      return getTradeOfferStatusColor(offerStatus);
    }
    return getTradeStatusColorFromTrade(status);
  }
}
