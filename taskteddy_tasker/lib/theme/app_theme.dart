import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Centralised design helpers for the tasker "operational work console" look.
///
/// This complements the raw colour tokens in [T] with the structural pieces
/// that give the tasker app its distinct, data-forward, partner-ops identity:
/// crisp bordered cards, structured header panels, strong section headers and
/// consistent status colour coding (online is green, pending is amber,
/// offline/inactive is neutral grey).
class AppTheme {
  AppTheme._();

  /// Soft, premium card radius (matches the polished blue consumer look).
  static const double cardRadius = 18;
  static const double chipRadius = 12;

  /// A clean card surface: white, hairline border + a soft low shadow.
  static BoxDecoration card({Color? color, Color? borderColor}) =>
      BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderColor ?? T.border),
        boxShadow: [
          BoxShadow(
            color: T.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );

  /// Brand-blue header gradient (bright, premium — replaces the old dark navy
  /// "console" panel so the app reads as the polished blue theme).
  static const LinearGradient panelGradient = LinearGradient(
    colors: [T.primary, T.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// A premium bright-blue gradient [AppBar] with rounded bottom corners.
  /// Drop-in replacement for `AppBar(title: Text(x))` on secondary screens so
  /// every header reads as the same polished blue treatment.
  static AppBar gradientBar(
    String title, {
    List<Widget>? actions,
    Widget? leading,
    double titleSize = 19,
  }) =>
      AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: actions,
        leading: leading,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: panelGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
      );

  /// Strong, tight section header used above list groups.
  static TextStyle sectionHeader({double size = 18, Color? color}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? T.text1,
        letterSpacing: -0.3,
      );

  /// Uppercase eyebrow label used above panels.
  static TextStyle eyebrow({Color? color}) => GoogleFonts.nunito(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: color ?? T.text3,
        letterSpacing: 1.1,
      );

  /// Big tabular-feeling metric number for dashboards / wallet.
  static TextStyle metric({double size = 22, Color? color}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? T.text1,
        letterSpacing: -0.6,
        height: 1.0,
      );

  /// Maps a status/state string to its accent colour.
  static Color statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'online':
      case 'available':
      case 'active':
      case 'accepted':
      case 'confirmed':
      case 'completed':
      case 'paid':
      case 'success':
        return T.online;
      case 'pending':
      case 'under review':
      case 'in_progress':
      case 'inprogress':
      case 'processing':
      case 'in progress':
        return T.pending;
      case 'cancelled':
      case 'rejected':
      case 'failed':
        return T.red;
      default:
        return T.offline;
    }
  }
}

/// A premium bright-blue gradient header with a back button, title, optional
/// subtitle and trailing actions. Rounded bottom corners give the polished
/// blue look shared across the app. Use in place of a plain [AppBar] on
/// secondary screens for a cohesive header treatment.
class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? leadingIcon;
  final EdgeInsets padding;

  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
    this.actions = const [],
    this.leadingIcon,
    this.padding = const EdgeInsets.fromLTRB(6, 6, 12, 18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A4F6FC5),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  onPressed: onBack ?? () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                )
              else
                const SizedBox(width: 6),
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// A friendly, iconified empty / error state used across list screens.
class FriendlyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final Color? iconColor;

  const FriendlyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? T.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 36, color: c),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: T.text1,
              ),
            ),
            if (body != null && body!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: T.text3,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A small status indicator dot with an optional soft glow.
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool glow;
  const StatusDot({super.key, required this.color, this.size = 8, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
