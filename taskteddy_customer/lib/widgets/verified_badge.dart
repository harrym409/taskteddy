import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../theme/theme.dart';

/// Small coral "Verified" trust marker shown on offers and tasker profiles.
///
/// Two variants:
/// - default: a rounded chip with a shield-check icon and a "Verified" label.
/// - [compact]: an icon-only shield-check (for tight rows next to a name).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({
    super.key,
    this.compact = false,
    this.size = 14,
    this.label,
  });

  /// When true, renders just the coral shield-check icon without the pill.
  final bool compact;

  /// Icon size in logical pixels.
  final double size;

  /// The pill label (ignored when [compact]). Defaults to the localized
  /// "Verified" string when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Icon(Icons.verified_user_rounded, color: C.primary, size: size);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: C.primaryLight,
        borderRadius: BorderRadius.circular(C.rChip),
        border: Border.all(color: C.primary.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, color: C.primary, size: size),
          const SizedBox(width: 4),
          Text(
            label ?? AppL10n.of(context)!.verified,
            style: GoogleFonts.nunito(
              fontSize: size - 3,
              fontWeight: FontWeight.w800,
              color: C.primary,
            ),
          ),
        ],
      ),
    );
  }
}
