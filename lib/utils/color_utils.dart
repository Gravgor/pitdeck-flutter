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
      default:
        return Colors.grey;
    }
  }

  static Color getTradeOfferStatusColor(TradeOfferStatus? status) {
    switch (status) {
      case TradeOfferStatus.PENDING:
        return const Color(0xFFFFA500);
      case TradeOfferStatus.ACCEPTED:
        return const Color(0xFF22C55E);
      case TradeOfferStatus.DECLINED:
        return const Color(0xFFEF4444);
      case TradeOfferStatus.CANCELLED:
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

  static Color getTradeStatusColor(TradeStatus? status, TradeOfferStatus? offerStatus) {
    if (offerStatus != null) {
      return getTradeOfferStatusColor(offerStatus);
    }
    return getTradeStatusColorFromTrade(status);
  }
}
