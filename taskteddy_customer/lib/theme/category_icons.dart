import 'package:flutter/material.dart';
import 'theme.dart';

/// Single source of truth for turning a service/task category string into a
/// tasteful Material icon + tint. The backend also sends an `emoji` field for
/// each service — we intentionally ignore it and render icons instead so the
/// customer app has a cohesive, professional look.
IconData categoryIcon(String? category) {
  switch ((category ?? '').trim().toLowerCase()) {
    case 'cleaning':
      return Icons.cleaning_services_rounded;
    case 'repair':
      return Icons.build_rounded;
    case 'delivery':
      return Icons.local_shipping_rounded;
    case 'errands':
      return Icons.shopping_bag_rounded;
    case 'moving':
      return Icons.local_shipping_rounded;
    case 'cooking':
      return Icons.restaurant_rounded;
    case 'tutoring':
      return Icons.menu_book_rounded;
    case 'tech':
      return Icons.devices_rounded;
    case 'photography':
      return Icons.photo_camera_rounded;
    case 'painting':
      return Icons.format_paint_rounded;
    case 'gardening':
      return Icons.local_florist_rounded;
    case 'laundry':
      return Icons.local_laundry_service_rounded;
    case 'kitchen':
      return Icons.countertops_rounded;
    case 'beauty':
      return Icons.spa_rounded;
    case 'wellness':
      return Icons.self_improvement_rounded;
    case 'automotive':
      return Icons.directions_car_rounded;
    case 'home':
      return Icons.home_repair_service_rounded;
    case 'other':
    default:
      return Icons.handyman_rounded;
  }
}

/// A tasteful, category-specific tint used behind the category icon chip. The
/// returned colour is used at full strength for the glyph and at low opacity
/// for the chip background.
Color categoryColor(String? category) {
  switch ((category ?? '').trim().toLowerCase()) {
    case 'cleaning':
      return const Color(0xFF2BB3C0); // teal
    case 'repair':
      return const Color(0xFFEF7A45); // orange
    case 'delivery':
      return const Color(0xFFFF6E6E); // brand coral
    case 'errands':
      return const Color(0xFF8B5CF6); // violet
    case 'moving':
      return const Color(0xFF3B82F6); // blue
    case 'cooking':
      return const Color(0xFFEF6B6B); // warm red
    case 'tutoring':
      return const Color(0xFF6366F1); // indigo
    case 'tech':
      return const Color(0xFF0EA5E9); // sky
    case 'photography':
      return const Color(0xFFEC4899); // pink
    case 'painting':
      return const Color(0xFFF59E0B); // amber
    case 'gardening':
      return const Color(0xFF22B573); // green
    case 'laundry':
      return const Color(0xFF38BDF8); // light blue
    case 'kitchen':
      return const Color(0xFFF97316); // deep orange
    case 'beauty':
      return const Color(0xFFDB6FA6); // rose
    case 'wellness':
      return const Color(0xFF10B981); // emerald
    case 'automotive':
      return const Color(0xFF475569); // slate
    case 'home':
      return const Color(0xFF0D9488); // deep teal
    case 'other':
    default:
      return C.primary;
  }
}

/// A rounded, tinted square holding the category icon — the standard way to
/// represent a service/task category throughout the customer app.
class CategoryIconChip extends StatelessWidget {
  const CategoryIconChip({
    super.key,
    required this.category,
    this.size = 46,
    this.radius = 14,
    this.iconScale = 0.52,
  });

  /// The category string (e.g. 'cleaning'). Falls back to a generic icon.
  final String? category;
  final double size;
  final double radius;

  /// Icon size as a fraction of [size].
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    final tint = categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(categoryIcon(category), color: tint, size: size * iconScale),
    );
  }
}

// ── Notification type -> icon + tint ──

/// Map a notification `type` to a Material icon (the backend `emoji` field is
/// intentionally ignored so notifications match the rest of the icon system).
IconData notifTypeIcon(String? type) {
  switch ((type ?? '').trim().toLowerCase()) {
    case 'booking':
      return Icons.event_available_rounded;
    case 'task':
      return Icons.assignment_rounded;
    case 'message':
    case 'chat':
      return Icons.chat_bubble_rounded;
    case 'payment':
      return Icons.account_balance_wallet_rounded;
    case 'earning':
      return Icons.payments_rounded;
    case 'system':
      return Icons.info_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color notifTypeColor(String? type) {
  switch ((type ?? '').trim().toLowerCase()) {
    case 'booking':
      return const Color(0xFF3B82F6); // blue
    case 'task':
      return C.primary;
    case 'message':
    case 'chat':
      return const Color(0xFF14B8A6); // teal
    case 'payment':
      return const Color(0xFF8B5CF6); // violet
    case 'earning':
      return const Color(0xFF22B573); // green
    case 'system':
      return const Color(0xFF6B7280); // grey
    default:
      return C.accent2;
  }
}
