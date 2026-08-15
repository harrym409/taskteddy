import 'package:flutter/material.dart';
import 'theme.dart';

/// Safe avatar initial for a (possibly empty/null) display name.
///
/// Indexing an empty string (`name[0]`) throws a RangeError and crashes the
/// widget — a common cause of blank-name accounts crashing avatar chips. This
/// always returns a single printable character.
String initialFor(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return '?';
  return trimmed[0].toUpperCase();
}

/// Maps a task/service category name to a Material icon.
///
/// Categories arrive as lowercase strings (`TaskCategory.name`, or the
/// `category` field on admin-assigned service bookings). Everything unknown
/// falls back to a generic handyman icon.
IconData categoryIcon(String category) {
  switch (category.toLowerCase().trim()) {
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
    default:
      return Icons.handyman_rounded;
  }
}

/// A tint colour for a category, used behind [categoryIcon] in chips.
Color categoryColor(String category) {
  switch (category.toLowerCase().trim()) {
    case 'cleaning':
      return T.teal;
    case 'repair':
    case 'home':
      return T.primary;
    case 'delivery':
    case 'moving':
      return T.blue;
    case 'errands':
      return const Color(0xFFF97316); // orange
    case 'cooking':
    case 'kitchen':
      return const Color(0xFFEF4444); // red
    case 'tutoring':
      return const Color(0xFF8B5CF6); // violet
    case 'tech':
      return const Color(0xFF0EA5E9); // sky
    case 'photography':
      return const Color(0xFFEC4899); // pink
    case 'painting':
      return const Color(0xFFF59E0B); // amber
    case 'gardening':
    case 'wellness':
      return T.green;
    case 'laundry':
      return const Color(0xFF06B6D4); // cyan
    case 'beauty':
      return const Color(0xFFEC4899); // pink
    case 'automotive':
      return const Color(0xFF64748B); // slate
    default:
      return T.primary;
  }
}

/// Renders a category as an icon inside a small rounded tinted chip.
class CategoryIconChip extends StatelessWidget {
  final String category;
  final double size;
  final double iconSize;
  final double radius;

  const CategoryIconChip({
    super.key,
    required this.category,
    this.size = 46,
    this.iconSize = 22,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(categoryIcon(category), color: color, size: iconSize),
    );
  }
}
