import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/theme.dart';

/// Brand color for a reputation tier.
/// new=grey, bronze=#CD7F32, silver=#9CA3AF, gold=#F5A623, pro=coral.
Color levelColor(String level) {
  switch (level) {
    case 'bronze':
      return const Color(0xFFCD7F32);
    case 'silver':
      return const Color(0xFF9CA3AF);
    case 'gold':
      return const Color(0xFFF5A623);
    case 'pro':
      return C.primary;
    default:
      return const Color(0xFF9E9E9E); // new
  }
}

/// Small colored chip showing a tasker's reputation tier (e.g. "Gold"),
/// tinted by tier. The label text comes straight from the backend
/// (`level_label`), falling back to the raw level key.
class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.reputation, this.compact = false});

  final Reputation reputation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = levelColor(reputation.level);
    final label = reputation.levelLabel.trim().isNotEmpty
        ? reputation.levelLabel
        : reputation.level;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
