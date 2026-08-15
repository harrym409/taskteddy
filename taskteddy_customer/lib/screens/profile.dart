import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../state/auth_controller.dart';
import '../state/locale_provider.dart';
import '../theme/theme.dart';
import 'blocked_users.dart';
import 'favorites.dart';
import 'other.dart';

String? _userAvatarUrl(Map<String, dynamic>? user) {
  if (user == null) return null;
  final raw = user['avatar_url'] ?? user['avatarUrl'];
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

/// Localized display label for a saved-address label wire value.
String addressLabelDisplay(AppL10n l, String label) {
  switch (label.toLowerCase()) {
    case 'work':
      return l.addrLabelWork;
    case 'other':
      return l.addrLabelOther;
    case 'home':
      return l.addrLabelHome;
    default:
      return label;
  }
}

const _profileTermsUrl = 'https://taskteddy.com/terms';
const _profilePrivacyUrl = 'https://taskteddy.com/privacy';
const _supportContactEmail = 'support@taskteddy.com';
const _otpGridAccent = Color(0xFFFF6E6E);
const _otpGridBorder = Color(0xFFF0D6D2);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _error;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  /// Pick a new profile photo (gallery/camera), upload it, and refresh.
  Future<void> _editAvatar() async {
    if (_uploadingAvatar) return;
    final l = AppL10n.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: C.primary),
              title: Text(l.commonChooseGallery,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: C.primary),
              title: Text(l.commonTakePhoto,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (picked == null || !mounted) return;
      setState(() => _uploadingAvatar = true);
      final updated = await ApiService.uploadAvatar(picked);
      if (!mounted) return;
      await ref.read(authControllerProvider.notifier).updateCachedUser(updated);
      await _loadProfile(force: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context)!.profilePhotoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: C.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _loadProfile({bool force = false}) async {
    if (mounted) setState(() => _error = null);
    try {
      await ref.read(authControllerProvider.notifier).refreshUser(force: force);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _displayPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return AppL10n.of(context)!.profileAddPhone;
    final local =
        digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    return '+91 $local';
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.profileCouldNotOpen(url))),
      );
    }
  }

  Future<void> _confirmAndOpenExternalUrl({
    required String title,
    required String url,
  }) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppL10n.of(context)!.profileOpenExternalTitle(title),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppL10n.of(context)!.profileOpenExternalBody,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: C.text2,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppL10n.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppL10n.of(context)!.continueLabel),
          ),
        ],
      ),
    );

    if (shouldOpen == true && mounted) {
      await _openExternalUrl(url);
    }
  }

  Future<void> _goToProfileDetails() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileDetailsScreen(user: user)),
    );
    if (mounted && updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppL10n.of(context)!.profileUpdatedSuccess)),
      );
    }
    if (updated is Map<String, dynamic>) {
      await ref.read(authControllerProvider.notifier).updateCachedUser(updated);
    }
    await _loadProfile();
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    final name = (user['name']?.toString().trim().isNotEmpty == true)
        ? user['name'].toString().trim()
        : AppL10n.of(context)!.profileDefaultName;
    final title = user['title']?.toString().trim();
    final phone = _displayPhone(user['phone']?.toString() ?? '');
    final displayName =
        title != null && title.isNotEmpty ? '$title $name' : name;
    final avatarUrl = _userAvatarUrl(user);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [C.primaryDark, C.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: C.primary.withValues(alpha: .24),
            blurRadius: 26,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.paddingOf(context).top + 12,
        18,
        26,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppL10n.of(context)!.navProfile,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _editAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _UserAvatar(
                      name: displayName,
                      title: title,
                      avatarUrl: avatarUrl,
                      size: 84,
                      borderColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                      textColor: Colors.white,
                    ),
                    if (_uploadingAvatar)
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: C.primary, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: C.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.call_outlined,
                            color: Colors.white.withValues(alpha: .8),
                            size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: .8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _goToProfileDetails,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppL10n.of(context)!.profileEditProfile,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppL10n.of(context)!.profileAddressBookReady,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedAddressesScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: .35),
                    ),
                  ),
                  child: Text(
                    AppL10n.of(context)!.profileManage,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppL10n.of(context)!.profileQuickAccess,
            style: GoogleFonts.poppins(
              color: C.text2,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.assignment_outlined,
                  title: AppL10n.of(context)!.bookingsTitle,
                  subtitle: AppL10n.of(context)!.profileTrackManage,
                  accentColor: C.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookingsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.map_outlined,
                  title: AppL10n.of(context)!.profileAddresses,
                  subtitle: AppL10n.of(context)!.profileSaveForCheckout,
                  accentColor: C.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SavedAddressesScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.support_agent_outlined,
                  title: AppL10n.of(context)!.profileHelp,
                  subtitle: AppL10n.of(context)!.profile24x7,
                  accentColor: C.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReferEarnScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7DE), Color(0xFFFFEFBA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF6DD92)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCA9C00).withValues(alpha: .14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Icon(Icons.card_giftcard_outlined,
                      color: Color(0xFFB97A00), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppL10n.of(context)!.profileReferEarn,
                        style: GoogleFonts.poppins(
                          color: C.text1,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppL10n.of(context)!.profileInviteFriends,
                        style: GoogleFonts.poppins(
                          color: C.text2,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    AppL10n.of(context)!.profileUpTo100,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9F6E00),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: C.text2, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    final t = AppL10n.of(context)!;
    final menuItems = [
      (
        icon: Icons.language_rounded,
        title: t.settingsLanguage,
        tint: C.primary,
        destructive: false,
        onTap: _openLanguageChooser,
      ),
      (
        icon: Icons.favorite_border_rounded,
        title: t.profileSavedServicesTaskers,
        tint: C.red,
        destructive: false,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          );
        },
      ),
      (
        icon: Icons.map_outlined,
        title: t.profileSavedAddresses,
        tint: C.blue,
        destructive: false,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
          );
        },
      ),
      (
        icon: Icons.block,
        title: t.blockedUsersTitle,
        tint: C.text2,
        destructive: false,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
          );
        },
      ),
      (
        icon: Icons.info_outline,
        title: t.profileAboutUs,
        tint: C.teal,
        destructive: false,
        onTap: () => _confirmAndOpenExternalUrl(
              title: t.profileAboutUs,
              url: 'https://taskteddy.com/about',
            ),
      ),
      (
        icon: Icons.description_outlined,
        title: t.profileTermsConditions,
        tint: C.text2,
        destructive: false,
        onTap: () => _confirmAndOpenExternalUrl(
              title: t.profileTermsConditions,
              url: _profileTermsUrl,
            ),
      ),
      (
        icon: Icons.privacy_tip_outlined,
        title: t.profilePrivacyPolicy,
        tint: C.text2,
        destructive: false,
        onTap: () => _confirmAndOpenExternalUrl(
              title: t.profilePrivacyPolicy,
              url: _profilePrivacyUrl,
            ),
      ),
      (
        icon: Icons.logout,
        title: t.profileLogout,
        tint: C.red,
        destructive: true,
        onTap: _logout,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.profileAccountSettings,
            style: GoogleFonts.poppins(
              color: C.text2,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: C.border.withValues(alpha: .7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: List.generate(menuItems.length, (index) {
                final row = menuItems[index];
                return Column(
                  children: [
                    _MenuRow(
                      icon: row.icon,
                      title: row.title,
                      iconColor: row.tint,
                      destructive: row.destructive,
                      onTap: row.onTap,
                    ),
                    if (index != menuItems.length - 1)
                      const Divider(height: 1, indent: 62, color: C.divider),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLanguageChooser() async {
    final t = AppL10n.of(context)!;
    final current = ref.read(localeProvider)?.languageCode;

    Widget option({
      required String label,
      required String? code,
    }) {
      final selected = current == code;
      return InkWell(
        onTap: () {
          ref
              .read(localeProvider.notifier)
              .setLocale(code == null ? null : Locale(code));
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? C.primary : C.text1,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, color: C.primary, size: 22),
            ],
          ),
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                t.chooseLanguage,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: C.text1,
                ),
              ),
            ),
            const Divider(height: 1, color: C.divider),
            option(label: t.languageEnglish, code: 'en'),
            const Divider(height: 1, indent: 20, color: C.divider),
            option(label: t.languageHindi, code: 'hi'),
            const Divider(height: 1, indent: 20, color: C.divider),
            option(label: t.languagePunjabi, code: 'pa'),
            const Divider(height: 1, indent: 20, color: C.divider),
            option(label: t.languageSystemDefault, code: null),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final snapshot = authState.valueOrNull;
    final user = snapshot?.user ?? const <String, dynamic>{};
    final hasUser = snapshot?.user != null;
    final providerError = authState.error?.toString().replaceAll(
          'Exception: ',
          '',
        );
    final visibleError = _error ?? providerError;

    return Scaffold(
      backgroundColor: C.bg,
      body: RefreshIndicator(
        color: C.primary,
        onRefresh: () => _loadProfile(force: true),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(user),
            if (snapshot?.isRefreshingUser == true)
              const LinearProgressIndicator(
                minHeight: 2,
                color: C.primary,
                backgroundColor: Color(0xFFFBE6E6),
              ),
            const SizedBox(height: 14),
            if (visibleError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.redLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    visibleError,
                    style: GoogleFonts.poppins(
                      color: C.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            if (authState.isLoading && !hasUser)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child:
                    Center(child: CircularProgressIndicator(color: C.primary)),
              )
            else ...[
              _buildQuickActions(),
              _buildReferCard(),
              _buildMenuList(),
              const SizedBox(height: 24),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                AppL10n.of(context)!.profileAppVersion('1.0.0 (1)'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: C.text3,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor = C.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final accentSurface = Color.lerp(Colors.white, accentColor, .10)!;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentSurface, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accentColor.withValues(alpha: .24)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: .15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: C.text1,
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: C.text3,
                    fontSize: 11,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = C.text2,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: destructive ? C.red : C.text1,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: destructive ? C.red.withValues(alpha: .7) : C.text2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    this.title,
    this.avatarUrl,
    this.size = 84,
    this.borderColor = Colors.white,
    this.backgroundColor = C.primaryLight,
    this.textColor = C.primaryDark,
  });

  final String name;
  final String? title;
  final String? avatarUrl;
  final double size;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  bool get _isMs {
    final value = title?.trim().toLowerCase();
    if (value == 'ms') return true;
    return name.trim().toLowerCase().startsWith('ms ');
  }

  IconData get _genderIcon {
    return _isMs ? Icons.woman_rounded : Icons.man_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final value = avatarUrl?.trim() ?? '';
    final hasAvatar = value.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: !hasAvatar
            ? _buildFallback()
            : Image.network(
                value,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              ),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        _genderIcon,
        size: size * .58,
        color: textColor,
      ),
    );
  }
}

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _EmailVerifyDialogResult {
  const _EmailVerifyDialogResult._({this.code, this.changeEmail = false});

  const _EmailVerifyDialogResult.verify(String value)
      : this._(code: value, changeEmail: false);

  const _EmailVerifyDialogResult.changeEmail() : this._(changeEmail: true);

  final String? code;
  final bool changeEmail;
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late String _initialEmailLower;
  late bool _originalEmailVerified;
  String _selectedTitle = 'Mr';
  bool _emailVerified = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  /// Pick + upload a new profile photo from the edit-profile screen. The upload
  /// endpoint persists immediately, so the change sticks even without Save.
  Future<void> _editAvatar() async {
    if (_uploadingAvatar) return;
    final l = AppL10n.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: C.primary),
              title: Text(l.commonChooseGallery,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: C.primary),
              title: Text(l.commonTakePhoto,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (picked == null || !mounted) return;
      setState(() => _uploadingAvatar = true);
      final updated = await ApiService.uploadAvatar(picked);
      if (!mounted) return;
      final newUrl = updated['avatar_url']?.toString();
      setState(() {
        _avatarUrl = newUrl;
        // Keep the map we hand back to the parent in sync so its cache updates.
        widget.user['avatar_url'] = newUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.profilePhotoUpdated)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: C.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _avatarUrl = _userAvatarUrl(widget.user);
    final fullName = (widget.user['name']?.toString().trim() ?? '');
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final first = parts.isEmpty ? '' : parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final mobileDigits =
        (widget.user['phone']?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
    final mobile10 = mobileDigits.length >= 10
        ? mobileDigits.substring(mobileDigits.length - 10)
        : mobileDigits;

    _firstName = TextEditingController(text: first);
    _lastName = TextEditingController(text: last);
    _mobile = TextEditingController(text: '+91 $mobile10');
    _email =
        TextEditingController(text: widget.user['email']?.toString() ?? '');
    _initialEmailLower = _email.text.trim().toLowerCase();
    _emailVerified = _isEmailVerified(widget.user);
    _originalEmailVerified = _emailVerified;

    final storedTitle = widget.user['title']?.toString().trim();
    if (storedTitle == 'Mr' || storedTitle == 'Ms') {
      _selectedTitle = storedTitle!;
    }

    _firstName.addListener(_onNameChanged);
    _lastName.addListener(_onNameChanged);
    _email.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _firstName.removeListener(_onNameChanged);
    _lastName.removeListener(_onNameChanged);
    _email.removeListener(_onEmailChanged);
    _firstName.dispose();
    _lastName.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  bool _isEmailVerified(Map<String, dynamic> user) {
    if (user['email_verified'] == true) return true;
    final verifiedAt = user['email_verified_at']?.toString();
    return verifiedAt != null && verifiedAt.trim().isNotEmpty;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  void _onEmailChanged() {
    final current = _email.text.trim().toLowerCase();
    final shouldBeVerified =
        current == _initialEmailLower && _originalEmailVerified;
    if (_emailVerified != shouldBeVerified && mounted) {
      setState(() => _emailVerified = shouldBeVerified);
    }
  }

  void _showEmailLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppL10n.of(context)!.profileEmailLocked(_supportContactEmail),
        ),
      ),
    );
  }

  String _capitalizeLeadingLetter(String value) {
    if (value.isEmpty) return value;
    final match = RegExp(r'[A-Za-z]').firstMatch(value);
    if (match == null) return value;
    final index = match.start;
    final letter = value[index];
    final uppercase = letter.toUpperCase();
    if (letter == uppercase) return value;
    return value.replaceRange(index, index + 1, uppercase);
  }

  void _normalizeNameField(TextEditingController controller) {
    final current = controller.text;
    final normalized = _capitalizeLeadingLetter(current);
    if (current == normalized) return;
    final baseOffset = controller.selection.baseOffset;
    final extentOffset = controller.selection.extentOffset;
    controller.value = TextEditingValue(
      text: normalized,
      selection: TextSelection(
        baseOffset: baseOffset.clamp(0, normalized.length),
        extentOffset: extentOffset.clamp(0, normalized.length),
      ),
    );
  }

  void _onNameChanged() {
    _normalizeNameField(_firstName);
    _normalizeNameField(_lastName);
  }

  Future<Map<String, dynamic>> _submitProfileUpdate() async {
    final l = AppL10n.of(context)!;
    final first = _capitalizeLeadingLetter(_firstName.text.trim());
    final last = _capitalizeLeadingLetter(_lastName.text.trim());
    final phone = _mobile.text.trim().replaceAll(RegExp(r'\D'), '');
    final email = _email.text.trim().toLowerCase();

    if (first.isEmpty) {
      throw Exception(l.profileErrFirstName);
    }

    if (phone.length < 10) {
      throw Exception(l.profileErrPhone);
    }

    if (email.isNotEmpty && !_isValidEmail(email)) {
      throw Exception(l.profileErrValidEmail);
    }

    _firstName.text = first;
    _lastName.text = last;
    _email.text = email;

    final updated = await ApiService.updateMe(
      name: '$first $last'.trim(),
      phone: phone,
      location: widget.user['location']?.toString() ?? '',
      bio: widget.user['bio']?.toString() ?? '',
      email: email.isEmpty ? null : email,
      title: _selectedTitle,
    );

    _initialEmailLower =
        (updated['email']?.toString() ?? '').trim().toLowerCase();
    _originalEmailVerified = _isEmailVerified(updated);
    _emailVerified = _originalEmailVerified;
    return updated;
  }

  Future<_EmailVerifyDialogResult?> _askVerificationCode(
    String email,
  ) async {
    return showDialog<_EmailVerifyDialogResult>(
      context: context,
      builder: (context) => _EmailVerifyDialog(
        email: email,
      ),
    );
  }

  Future<String?> _askEmailForVerificationChange(String currentEmail) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppL10n.of(context)!.profileChangeEmail,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppL10n.of(context)!.profileChangeEmailBody,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: C.text2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: C.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                currentEmail,
                style: GoogleFonts.poppins(
                  color: C.text1,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                hintText: AppL10n.of(context)!.profileEnterNewEmail,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppL10n.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppL10n.of(context)!.profileUseThisEmail),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _verifyEmail() async {
    var email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.profileAddEmailFirst)),
      );
      return;
    }
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.profileErrValidEmail)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      while (mounted) {
        _email.text = email;
        await _submitProfileUpdate();
        final result = await ApiService.requestEmailVerification();
        if (!mounted) return;

        final message =
            (result['message']?.toString().trim().isNotEmpty == true)
                ? result['message'].toString().trim()
                : AppL10n.of(context)!.profileVerifCodeSent(email);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(message),
            ),
          );

        final step = await _askVerificationCode(email);
        if (step == null) {
          break;
        }
        if (step.changeEmail) {
          final changed = await _askEmailForVerificationChange(email);
          if (changed == null) {
            break;
          }
          final next = changed.trim().toLowerCase();
          if (next.isEmpty || !_isValidEmail(next)) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(AppL10n.of(context)!.profileErrValidEmailShort)),
            );
            continue;
          }
          email = next;
          if (mounted) {
            setState(() => _emailVerified = false);
          }
          continue;
        }

        final enteredCode = step.code?.trim() ?? '';
        if (enteredCode.length != 6) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppL10n.of(context)!.profileEnterFullOtp)),
          );
          continue;
        }

        final verifiedUser = await ApiService.verifyEmail(code: enteredCode);
        _initialEmailLower =
            (verifiedUser['email']?.toString() ?? email).trim().toLowerCase();
        _originalEmailVerified = _isEmailVerified(verifiedUser);
        _emailVerified = _originalEmailVerified;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context)!.profileEmailVerified)),
        );
        break;
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _previewName() {
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final full = '$first $last'.trim();
    if (full.isEmpty) {
      final original = widget.user['name']?.toString().trim();
      return (original == null || original.isEmpty)
          ? AppL10n.of(context)!.profileDefaultName
          : original;
    }
    return full;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _submitProfileUpdate();
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: C.greenLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: C.green, size: 14),
          const SizedBox(width: 4),
          Text(
            AppL10n.of(context)!.verified,
            style: GoogleFonts.poppins(
              color: C.green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: C.text1,
        title: Text(
          AppL10n.of(context)!.profileEditProfile,
          style: GoogleFonts.poppins(
            color: C.text1,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFDE8E8), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: C.primaryLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: C.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppL10n.of(context)!.profileUpdateDetails,
                                  style: GoogleFonts.poppins(
                                    color: C.text1,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  AppL10n.of(context)!.profileUpdateDetailsBody,
                                  style: GoogleFonts.poppins(
                                    color: C.text3,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCFA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: C.primaryLight, width: 1.4),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _editAvatar,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ListenableBuilder(
                                  listenable: Listenable.merge(
                                      [_firstName, _lastName]),
                                  builder: (context, _) => _UserAvatar(
                                    name: '$_selectedTitle ${_previewName()}',
                                    title: _selectedTitle,
                                    avatarUrl: _avatarUrl,
                                    size: 132,
                                    borderColor: C.primary,
                                    backgroundColor: C.primaryLight,
                                    textColor: Colors.white,
                                  ),
                                ),
                                if (_uploadingAvatar)
                                  const Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.6,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: C.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            decoration: BoxDecoration(
                              color: C.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  AppL10n.of(context)!.profileTitle,
                                  style: GoogleFonts.poppins(
                                    color: C.text2,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ChoicePill(
                                  label: 'Mr',
                                  compact: true,
                                  selected: _selectedTitle == 'Mr',
                                  onTap: () {
                                    setState(() => _selectedTitle = 'Mr');
                                  },
                                ),
                                const SizedBox(width: 6),
                                _ChoicePill(
                                  label: 'Ms',
                                  compact: true,
                                  selected: _selectedTitle == 'Ms',
                                  onTap: () {
                                    setState(() => _selectedTitle = 'Ms');
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppL10n.of(context)!.profileBasicInfo,
                              style: GoogleFonts.poppins(
                                color: C.text2,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _FloatingField(
                            label: AppL10n.of(context)!.profileFirstName,
                            hintText: AppL10n.of(context)!.profileFirstNameHint,
                            controller: _firstName,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            leadingIcon: Icons.badge_outlined,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z .'-]"),
                              ),
                              LengthLimitingTextInputFormatter(40),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _FloatingField(
                            label: AppL10n.of(context)!.profileLastName,
                            hintText: AppL10n.of(context)!.profileLastNameHint,
                            controller: _lastName,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            leadingIcon: Icons.person_outline,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r"[a-zA-Z .'-]"),
                              ),
                              LengthLimitingTextInputFormatter(40),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppL10n.of(context)!.profileContactVerification,
                              style: GoogleFonts.poppins(
                                color: C.text2,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _FloatingField(
                            label: AppL10n.of(context)!.profileMobile,
                            hintText: '+91xxxxxxxxxx',
                            controller: _mobile,
                            enabled: false,
                            keyboardType: TextInputType.phone,
                            textStyle: GoogleFonts.poppins(
                              color: C.text2,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            leadingIcon: Icons.phone_outlined,
                            trailing: _verifiedBadge(),
                          ),
                          const SizedBox(height: 14),
                          _FloatingField(
                            label: AppL10n.of(context)!.profileEmail,
                            hintText: 'name@example.com',
                            controller: _email,
                            readOnly: _emailVerified,
                            onTap:
                                _emailVerified ? _showEmailLockedMessage : null,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.none,
                            leadingIcon: Icons.email_outlined,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              LengthLimitingTextInputFormatter(70),
                            ],
                            textStyle: GoogleFonts.poppins(
                              color: C.text2,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            trailing: _emailVerified
                                ? _verifiedBadge()
                                : TextButton(
                                    onPressed: _saving ? null : _verifyEmail,
                                    style: TextButton.styleFrom(
                                      foregroundColor: C.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    child: Text(
                                      AppL10n.of(context)!.profileVerify,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          AppL10n.of(context)!.profileSaveChanges,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingField extends StatelessWidget {
  const _FloatingField({
    required this.label,
    required this.controller,
    this.textInputAction,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.hintText,
    this.textStyle,
    this.trailing,
    this.leadingIcon,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final String? hintText;
  final TextStyle? textStyle;
  final Widget? trailing;
  final IconData? leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onTap: onTap,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      enabled: enabled,
      readOnly: readOnly,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: textStyle ??
          GoogleFonts.poppins(
            color: C.text1,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: C.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: C.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: C.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: C.border, width: 2),
        ),
        prefixIcon: leadingIcon == null
            ? null
            : Icon(leadingIcon, color: C.text3, size: 19),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: trailing == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 10),
                child: trailing,
              ),
        labelStyle: GoogleFonts.poppins(
          color: C.text2,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          backgroundColor: const Color(0xFFFFFCFA),
        ),
      ),
    );
  }
}

class _EmailVerifyDialog extends StatefulWidget {
  const _EmailVerifyDialog({
    required this.email,
  });

  final String email;

  @override
  State<_EmailVerifyDialog> createState() => _EmailVerifyDialogState();
}

class _EmailVerifyDialogState extends State<_EmailVerifyDialog> {
  late final TextEditingController _otpController;
  late final FocusNode _otpFocusNode;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _submitVerify() {
    Navigator.pop(
      context,
      _EmailVerifyDialogResult.verify(_otpController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppL10n.of(context)!.profileVerifyEmail,
              style: GoogleFonts.poppins(
                color: C.text1,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppL10n.of(context)!.profileVerifyEmailBody(widget.email),
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: C.text2,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _EmailOtpField(
              controller: _otpController,
              focusNode: _otpFocusNode,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: C.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppL10n.of(context)!.cancel,
                      style: GoogleFonts.poppins(
                        color: C.text2,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      const _EmailVerifyDialogResult.changeEmail(),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: C.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppL10n.of(context)!.profileChangeEmail,
                      style: GoogleFonts.poppins(
                        color: C.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  AppL10n.of(context)!.profileVerify,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailOtpField extends StatefulWidget {
  const _EmailOtpField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_EmailOtpField> createState() => _EmailOtpFieldState();
}

class _EmailOtpFieldState extends State<_EmailOtpField> {
  final List<bool> _revealDigit = List<bool>.filled(6, false);
  final List<int> _revealVersion = List<int>.filled(6, 0);
  String _lastOtp = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onOtpChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _EmailOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onOtpChanged);
      widget.controller.addListener(_onOtpChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onOtpChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onOtpChanged() {
    final raw = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final otp = raw.length > 6 ? raw.substring(0, 6) : raw;

    for (var i = 0; i < 6; i++) {
      final previous = i < _lastOtp.length ? _lastOtp[i] : null;
      final next = i < otp.length ? otp[i] : null;

      if (next == null) {
        _revealVersion[i]++;
        _revealDigit[i] = false;
        continue;
      }

      if (previous == null || previous != next) {
        _revealDigit[i] = true;
        _revealVersion[i]++;
        final version = _revealVersion[i];
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted || _revealVersion[i] != version) return;
          setState(() => _revealDigit[i] = false);
        });
      }
    }

    _lastOtp = otp;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final otp = raw.length > 6 ? raw.substring(0, 6) : raw;
    final selectedIndex = otp.length.clamp(0, 5);
    final isFocused = widget.focusNode.hasFocus;

    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              color: Colors.transparent,
              fontSize: 0.01,
              height: 0.01,
            ),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
            ),
          ),
          IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final availableWidth = constraints.maxWidth - (spacing * 5);
                final rawSize = availableWidth / 6;
                final boxSize = rawSize.clamp(42.0, 50.0).toDouble();
                final rowWidth = (boxSize * 6) + (spacing * 5);

                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: rowWidth,
                    child: Row(
                      children: List.generate(6, (index) {
                        final isActive = isFocused && index == selectedIndex;
                        final hasValue = index < otp.length;
                        return Container(
                          width: boxSize,
                          height: boxSize,
                          margin:
                              EdgeInsets.only(right: index == 5 ? 0 : spacing),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? _otpGridAccent : _otpGridBorder,
                              width: isActive ? 1.6 : 1.1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              !hasValue
                                  ? ''
                                  : (_revealDigit[index] ? otp[index] : '•'),
                              style: GoogleFonts.varelaRound(
                                color: C.text1,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: selected ? C.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? C.primary : C.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : C.text2,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class TaskTeddyWalletScreen extends StatefulWidget {
  const TaskTeddyWalletScreen({super.key});

  @override
  State<TaskTeddyWalletScreen> createState() => _TaskTeddyWalletScreenState();
}

class _TaskTeddyWalletScreenState extends State<TaskTeddyWalletScreen> {
  double _balance = 0;
  double _selectedAmount = 250;
  List<Map<String, dynamic>> _transactions = [];
  late final TextEditingController _amountController;
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: _selectedAmount.toInt().toString());
    _amountController.addListener(_onAmountInputChanged);
    _loadWallet();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountInputChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountInputChanged() {
    final value = double.tryParse(_amountController.text.trim());
    if (value == null || value <= 0) return;
    if (value != _selectedAmount) {
      setState(() => _selectedAmount = value);
    }
  }

  Future<void> _loadWallet() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      ApiService.getWalletBalance(),
      ApiService.getWalletTransactions(limit: 10),
    ]);
    final balance = (results[0] as double?) ?? 0;
    final txns = (results[1] as List<Map<String, dynamic>>?) ?? const [];
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _transactions = txns;
      _loading = false;
    });
  }

  String _formatRupee(double value) {
    if (value % 1 == 0) return '₹${value.toInt()}';
    return '₹${value.toStringAsFixed(2)}';
  }

  double get _bonus => _selectedAmount >= 250 ? _selectedAmount * 0.05 : 0;

  Future<void> _topUp() async {
    if (_selectedAmount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.walletMinAmount)),
      );
      return;
    }
    setState(() => _adding = true);
    try {
      final res = await ApiService.topUpWallet(amount: _selectedAmount);
      final balance = (res['balance'] as num?)?.toDouble() ?? _balance;
      final credited =
          (res['credited_amount'] as num?)?.toDouble() ?? _selectedAmount;
      final bonus = (res['bonus'] as num?)?.toDouble() ?? 0;

      if (!mounted) return;
      setState(() => _balance = balance);
      final txns = await ApiService.getWalletTransactions(limit: 10);
      if (!mounted) return;
      setState(() => _transactions = txns);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bonus > 0
                ? AppL10n.of(context)!.walletAddedBonus(
                    _formatRupee(_selectedAmount),
                    _formatRupee(bonus),
                    _formatRupee(credited))
                : AppL10n.of(context)!.walletAdded(_formatRupee(credited)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Widget _amountChoice(double amount, {double? width}) {
    final selected = _selectedAmount == amount;
    final bonus = amount * 0.05;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () {
          _amountController.text = amount.toInt().toString();
          setState(() => _selectedAmount = amount);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: selected ? C.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? C.primary : C.border,
              width: selected ? 2 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? C.primary.withValues(alpha: .14)
                    : Colors.black.withValues(alpha: .02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '₹${amount.toInt()}',
                style: GoogleFonts.poppins(
                  color: C.text1,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: C.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+₹${bonus.toStringAsFixed(bonus % 1 == 0 ? 0 : 1)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTxnTime(dynamic value) {
    try {
      final parsed = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(parsed);
    } catch (_) {
      return AppL10n.of(context)!.timeJustNow;
    }
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Text(
        AppL10n.of(context)!.walletNoTransactions,
        style: GoogleFonts.poppins(
          color: C.text3,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      children: _transactions.take(4).map((txn) {
        final amount = (txn['amount'] as num?)?.toDouble() ?? 0;
        final positive = amount >= 0;
        final title = (txn['description']?.toString().trim().isNotEmpty == true)
            ? txn['description'].toString()
            : AppL10n.of(context)!.walletTransaction;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: C.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border.withValues(alpha: .8)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: positive ? C.greenLight : C.redLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  positive ? Icons.add : Icons.remove,
                  color: positive ? C.green : C.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: C.text1,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTxnTime(txn['created_at']),
                      style: GoogleFonts.poppins(
                        color: C.text3,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${positive ? '+' : '-'}${_formatRupee(amount.abs())}',
                style: GoogleFonts.poppins(
                  color: positive ? C.green : C.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        16, MediaQuery.paddingOf(context).top + 10, 16, 26),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [C.primaryDark, C.primary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _CircularIconButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            _CircularIconButton(
                              icon: Icons.help_outline,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppL10n.of(context)!.walletHelpHint)),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'TaskTeddy',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          AppL10n.of(context)!.walletCardLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 44,
                            height: .9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border:
                              Border.all(color: C.border.withValues(alpha: .7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .05),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppL10n.of(context)!.walletBalance,
                              style: GoogleFonts.poppins(
                                color: C.text2,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatRupee(_balance),
                                style: GoogleFonts.poppins(
                                  color: C.primary,
                                  fontSize: 46,
                                  height: .9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _balance <= 0
                                  ? AppL10n.of(context)!.walletBalanceLow
                                  : AppL10n.of(context)!.walletBalanceUse,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: C.text3,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [C.blue, Color(0xFF1E63C9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppL10n.of(context)!.walletGet5Extra,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    AppL10n.of(context)!.walletOnAdding250,
                                    style: GoogleFonts.poppins(
                                      color:
                                          Colors.white.withValues(alpha: .95),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: C.border.withValues(alpha: .7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppL10n.of(context)!.walletAddMoney,
                            style: GoogleFonts.poppins(
                              color: C.text1,
                              fontSize: 30,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _amountController,
                            onTapOutside: (_) =>
                                FocusScope.of(context).unfocus(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            decoration: InputDecoration(
                              labelText: AppL10n.of(context)!.walletEnterAmount,
                              prefixText: '₹ ',
                              filled: true,
                              fillColor: C.bg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: C.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: C.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: C.border, width: 1.8),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 300;
                                final amountText = Text(
                                  _formatRupee(_selectedAmount),
                                  style: GoogleFonts.poppins(
                                    color: C.text1,
                                    fontSize: compact ? 30 : 38,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                );
                                final badge = Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: C.blueLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    AppL10n.of(context)!
                                        .walletCashback(_formatRupee(_bonus)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: C.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: amountText),
                                      const SizedBox(height: 8),
                                      badge,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: FittedBox(
                                        alignment: Alignment.centerLeft,
                                        fit: BoxFit.scaleDown,
                                        child: amountText,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(child: badge),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppL10n.of(context)!.walletYouWillGet(
                                _formatRupee(_selectedAmount + _bonus)),
                            style: GoogleFonts.poppins(
                              color: C.text2,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final spacing = 10.0;
                              final itemWidth =
                                  (constraints.maxWidth - (spacing * 2)) / 3;
                              if (itemWidth < 94) {
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    _amountChoice(250, width: 110),
                                    _amountChoice(500, width: 110),
                                    _amountChoice(1000, width: 110),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  _amountChoice(250, width: itemWidth),
                                  const SizedBox(width: 10),
                                  _amountChoice(500, width: itemWidth),
                                  const SizedBox(width: 10),
                                  _amountChoice(1000, width: itemWidth),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _adding ? null : _topUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: C.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _adding
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        AppL10n.of(context)!.walletAddToWallet(
                                            _formatRupee(_selectedAmount)),
                                        maxLines: 1,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppL10n.of(context)!.walletRecentTransactions,
                            style: GoogleFonts.poppins(
                              color: C.text1,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _buildTransactionList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _supportDialNumber = '+916239866862';
  static const _supportDisplayNumber = '+91 6239866862';
  static const _supportEmail = 'support@taskteddy.com';

  List<_SupportTopic> _buildTopics(AppL10n l) => [
        _SupportTopic(
          id: 'booking',
          title: l.helpTopicBooking,
          subtitle: l.helpTopicBookingSub,
          faqs: [
            _FaqItem(question: l.faqBookingRecurringQ, answer: l.faqBookingRecurringA),
            _FaqItem(question: l.faqBookingEquipmentQ, answer: l.faqBookingEquipmentA),
            _FaqItem(question: l.faqBookingRescheduleQ, answer: l.faqBookingRescheduleA),
            _FaqItem(question: l.faqBookingIssueQ, answer: l.faqBookingIssueA),
            _FaqItem(question: l.faqBookingPriceQ, answer: l.faqBookingPriceA),
          ],
        ),
        _SupportTopic(
          id: 'account',
          title: l.helpTopicAccount,
          subtitle: l.helpTopicAccountSub,
          faqs: [
            _FaqItem(question: l.faqAccountUpdateAddressQ, answer: l.faqAccountUpdateAddressA),
            _FaqItem(question: l.faqAccountAddAddressQ, answer: l.faqAccountAddAddressA),
            _FaqItem(question: l.faqAccountContactQ, answer: l.faqAccountContactA),
          ],
        ),
        _SupportTopic(
          id: 'payments',
          title: l.helpTopicPayments,
          subtitle: l.helpTopicPaymentsSub,
          faqs: [
            _FaqItem(question: l.faqPaymentsFailedQ, answer: l.faqPaymentsFailedA),
            _FaqItem(question: l.faqPaymentsCouponQ, answer: l.faqPaymentsCouponA),
            _FaqItem(question: l.faqPaymentsRefundQ, answer: l.faqPaymentsRefundA),
          ],
        ),
        _SupportTopic(
          id: 'service_quality',
          title: l.helpTopicServiceQuality,
          subtitle: l.helpTopicServiceQualitySub,
          faqs: [
            _FaqItem(question: l.faqQualityDamageQ, answer: l.faqQualityDamageA),
            _FaqItem(question: l.faqQualityRateQ, answer: l.faqQualityRateA),
          ],
        ),
        _SupportTopic(
          id: 'safety',
          title: l.helpTopicSafety,
          subtitle: l.helpTopicSafetySub,
          faqs: [
            _FaqItem(question: l.faqSafetyTrustQ, answer: l.faqSafetyTrustA),
            _FaqItem(question: l.faqSafetyVerifiedQ, answer: l.faqSafetyVerifiedA),
            _FaqItem(question: l.faqSafetyShareQ, answer: l.faqSafetyShareA),
            _FaqItem(question: l.faqSafetyUnsafeQ, answer: l.faqSafetyUnsafeA),
          ],
        ),
      ];

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _supportDialNumber);
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.helpCouldNotDial)),
      );
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=TaskTeddy Support',
    );
    final opened = await launchUrl(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.helpCouldNotEmail)),
      );
    }
  }

  IconData _topicIcon(String id) {
    switch (id) {
      case 'booking':
        return Icons.calendar_month_outlined;
      case 'account':
        return Icons.person_outline;
      case 'payments':
        return Icons.payments_outlined;
      case 'service_quality':
        return Icons.verified_outlined;
      case 'safety':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _topicTint(String id) {
    switch (id) {
      case 'booking':
        return C.blue;
      case 'account':
        return C.primary;
      case 'payments':
        return C.green;
      case 'service_quality':
        return C.teal;
      case 'safety':
        return C.yellow;
      default:
        return C.text2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: C.text1,
        title: Text(
          AppL10n.of(context)!.helpTitle,
          style: GoogleFonts.poppins(
            color: C.text1,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.border.withValues(alpha: .7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  AppL10n.of(context)!
                      .helpReachOut(_supportDisplayNumber, _supportEmail),
                  style: GoogleFonts.poppins(
                    color: C.text3,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _callSupport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppL10n.of(context)!.helpCallUs,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _emailSupport,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: C.primary),
                        foregroundColor: C.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppL10n.of(context)!.helpEmailUs,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [C.primaryLight, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.primaryLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: C.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppL10n.of(context)!.helpNeedQuickHelp,
                        style: GoogleFonts.poppins(
                          color: C.text1,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppL10n.of(context)!.helpFindAnswers,
                        style: GoogleFonts.poppins(
                          color: C.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .03),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: C.blueLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: C.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppL10n.of(context)!.helpMyRefunds,
                        style: GoogleFonts.poppins(
                          color: C.text1,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        AppL10n.of(context)!.helpNoRefunds,
                        style: GoogleFonts.poppins(
                          color: C.text3,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppL10n.of(context)!.helpBrowseTopics,
            style: GoogleFonts.poppins(
              color: C.text1,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ..._buildTopics(AppL10n.of(context)!).map(
            (topic) {
              final tint = _topicTint(topic.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _SupportTopicScreen(
                          title: topic.title,
                          faqs: topic.faqs,
                          onContactSupport: _callSupport,
                          onEmailSupport: _emailSupport,
                          supportPhoneDisplay: _supportDisplayNumber,
                          supportEmail: _supportEmail,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: C.border),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .025),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_topicIcon(topic.id),
                              color: tint, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.title,
                                style: GoogleFonts.poppins(
                                  color: C.text1,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topic.subtitle,
                                style: GoogleFonts.poppins(
                                  color: C.text3,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: C.text3, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportTopicScreen extends StatefulWidget {
  const _SupportTopicScreen({
    required this.title,
    required this.faqs,
    required this.onContactSupport,
    required this.onEmailSupport,
    required this.supportPhoneDisplay,
    required this.supportEmail,
  });

  final String title;
  final List<_FaqItem> faqs;
  final Future<void> Function() onContactSupport;
  final Future<void> Function() onEmailSupport;
  final String supportPhoneDisplay;
  final String supportEmail;

  @override
  State<_SupportTopicScreen> createState() => _SupportTopicScreenState();
}

class _SupportTopicScreenState extends State<_SupportTopicScreen> {
  final Set<int> _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: C.text1,
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: C.text1,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            AppL10n.of(context)!.helpRelatedTo(widget.title),
            style: GoogleFonts.poppins(
              color: C.text1,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(widget.faqs.length, (index) {
            final faq = widget.faqs[index];
            final open = _expanded.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: C.bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        if (open) {
                          _expanded.remove(index);
                        } else {
                          _expanded.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  faq.question,
                                  style: GoogleFonts.poppins(
                                    color: C.text1,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                open ? Icons.remove : Icons.add,
                                color: C.text2,
                                size: 36,
                              ),
                            ],
                          ),
                          if (open) ...[
                            const SizedBox(height: 10),
                            Text(
                              faq.answer,
                              style: GoogleFonts.poppins(
                                color: C.text2,
                                fontSize: 15,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.greenLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: C.green),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppL10n.of(context)!.helpCantFindAnswer,
                      style: GoogleFonts.poppins(
                        color: C.text1,
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppL10n.of(context)!.helpSupportHere,
                      style: GoogleFonts.poppins(
                        color: C.text3,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: widget.onContactSupport,
                      child: Row(
                        children: [
                          const Icon(Icons.call, color: C.green, size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.supportPhoneDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: C.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: widget.onEmailSupport,
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: C.green, size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.supportEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: C.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final cta = InkWell(
                  onTap: widget.onContactSupport,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: C.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 34),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.support_agent,
                                color: C.green, size: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: cta),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.support_agent,
                          color: C.green, size: 38),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: details),
                    const SizedBox(width: 8),
                    cta,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  String _inviteCodeFromUser(Map<String, dynamic>? user) {
    final id =
        user?['id']?.toString().replaceAll('-', '').toUpperCase() ?? '0000';
    final code = id.length <= 6 ? id : id.substring(id.length - 6);
    return 'TEDDY$code';
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppL10n.of(context)!.referCodeCopied)),
    );
  }

  Future<void> _shareInvite(BuildContext context, String code) async {
    final link = 'https://taskteddy.app/invite/$code';
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppL10n.of(context)!.referLinkCopied)),
    );
  }

  Future<void> _openTerms(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(_profileTermsUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.referCouldNotOpenTerms)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Session.getUser(),
      builder: (context, snapshot) {
        final code = _inviteCodeFromUser(snapshot.data);

        return Scaffold(
          backgroundColor: C.bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: C.text1,
            title: Text(
              AppL10n.of(context)!.profileReferEarn,
              style: GoogleFonts.poppins(
                color: C.text1,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.border.withValues(alpha: .8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareInvite(context, code),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_outlined),
                      label: Text(
                        AppL10n.of(context)!.referShareLink,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => _copyCode(context, code),
                    child: Text(
                      AppL10n.of(context)!.referCopyCode,
                      style: GoogleFonts.poppins(
                        color: C.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [C.primaryDark, C.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: C.primary.withValues(alpha: .2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .34),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.card_giftcard_rounded,
                            size: 48, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppL10n.of(context)!.referTitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppL10n.of(context)!.referGet100,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 44,
                        height: .95,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppL10n.of(context)!.referFriendGets,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: .92),
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => _copyCode(context, code),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .34)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              code,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                height: .9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.copy_rounded,
                                color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: C.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppL10n.of(context)!.howItWorks,
                      style: GoogleFonts.poppins(
                        color: C.text1,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StepRow(
                        number: '1', text: AppL10n.of(context)!.referStep1),
                    _StepRow(
                        number: '2', text: AppL10n.of(context)!.referStep2),
                    _StepRow(
                        number: '3', text: AppL10n.of(context)!.referStep3),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _openTerms(context),
                  child: Text(
                    AppL10n.of(context)!.referReadTerms,
                    style: GoogleFonts.poppins(
                      decoration: TextDecoration.underline,
                      color: C.text3,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: C.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  color: C.primaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: C.text2,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<AddressModel> _addresses = [];
  bool _loading = true;
  bool _error = false;
  // Id of the address a set-default/delete request is currently running for.
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    if (mounted) {
      setState(() {
        _loading = _addresses.isEmpty;
        _error = false;
      });
    }
    try {
      final addresses = await ApiService.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _openAddressEditor({AddressModel? initial}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AddressEditorScreen(initial: initial),
      ),
    );
    if (changed == true) await _loadAddresses();
  }

  Future<void> _setDefault(AddressModel address) async {
    if (address.isDefault) return;
    setState(() => _busyId = address.id);
    try {
      await ApiService.setDefaultAddress(address.id);
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _removeAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppL10n.of(context)!.addrDeleteTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(AppL10n.of(context)!.addrDeleteBody,
            style: GoogleFonts.poppins(fontSize: 13, color: C.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppL10n.of(context)!.cancel,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: C.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppL10n.of(context)!.addrDelete,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: C.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyId = address.id);
    try {
      await ApiService.deleteAddress(address.id);
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  IconData _labelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'work':
        return Icons.work_outline;
      case 'other':
        return Icons.place_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  Color _labelTint(String label) {
    switch (label.toLowerCase()) {
      case 'work':
        return C.blue;
      case 'other':
        return C.teal;
      default:
        return C.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: C.text1,
        title: Text(
          AppL10n.of(context)!.addrMyAddresses,
          style: GoogleFonts.poppins(
            color: C.text1,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.primary))
          : _error
              ? _AddressesErrorView(onRetry: _loadAddresses)
              : RefreshIndicator(
                  color: C.primary,
                  onRefresh: _loadAddresses,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [C.primaryLight, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: C.primaryLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.map_outlined,
                                  color: C.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppL10n.of(context)!.profileSavedAddresses,
                                    style: GoogleFonts.poppins(
                                      color: C.text1,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    AppL10n.of(context)!.addrSubtitle,
                                    style: GoogleFonts.poppins(
                                      color: C.text3,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _openAddressEditor(),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: C.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: C.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: C.primary, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    AppL10n.of(context)!.addrSaveNew,
                                    style: GoogleFonts.poppins(
                                      color: C.text1,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: C.text3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_addresses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: C.border),
                          ),
                          child: Text(
                            AppL10n.of(context)!.addrEmpty,
                            style: GoogleFonts.poppins(
                              color: C.text3,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        ..._addresses.map(_addressCard),
                    ],
                  ),
                ),
    );
  }

  Widget _addressCard(AddressModel address) {
    final tint = _labelTint(address.label);
    final busy = _busyId == address.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: address.isDefault ? C.primary.withValues(alpha: .5) : C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_labelIcon(address.label), color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        addressLabelDisplay(AppL10n.of(context)!, address.label)
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: tint,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: C.greenLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          AppL10n.of(context)!.sdDefault,
                          style: GoogleFonts.poppins(
                            color: C.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address.address,
                  style: GoogleFonts.poppins(
                    color: C.text2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (address.landmark != null &&
                    address.landmark!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    AppL10n.of(context)!.addrLandmark(address.landmark!),
                    style: GoogleFonts.poppins(
                      color: C.text3,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (busy)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: C.primary),
                  )
                else if (!address.isDefault)
                  GestureDetector(
                    onTap: () => _setDefault(address),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline_rounded,
                            color: C.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          AppL10n.of(context)!.addrSetAsDefault,
                          style: GoogleFonts.poppins(
                            color: C.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              _AddressActionButton(
                onTap: busy ? () {} : () => _openAddressEditor(initial: address),
                icon: Icons.edit_outlined,
                color: C.text2,
              ),
              const SizedBox(height: 8),
              _AddressActionButton(
                onTap: busy ? () {} : () => _removeAddress(address),
                icon: Icons.delete_outline,
                color: C.red,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _AddressesErrorView extends StatelessWidget {
  const _AddressesErrorView({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: C.text3),
            const SizedBox(height: 14),
            Text(
              AppL10n.of(context)!.addrLoadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: C.text2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppL10n.of(context)!.retry,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressActionButton extends StatelessWidget {
  const _AddressActionButton({
    required this.onTap,
    required this.icon,
    required this.color,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _AddressEditorScreen extends StatefulWidget {
  const _AddressEditorScreen({this.initial});

  final AddressModel? initial;

  @override
  State<_AddressEditorScreen> createState() => _AddressEditorScreenState();
}

class _AddressEditorScreenState extends State<_AddressEditorScreen> {
  static const LatLng _fallbackPoint = LatLng(30.9010, 75.8573);

  late final TextEditingController _houseCtrl;
  late final TextEditingController _buildingCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _landmarkCtrl;
  late final TextEditingController _pinCtrl;

  String _label = 'Home';
  bool _isDefault = false;
  bool _saving = false;
  LatLng _selectedPoint = _fallbackPoint;
  bool _hasPinnedLocation = false;
  bool _locating = false;
  bool _resolvingLocation = false;
  String? _locationTitle;
  String? _locationSubtitle;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    // Backend addresses store a single combined line, edited in Street/Area.
    // New addresses may fill all the granular fields, which we compose on save.
    _houseCtrl = TextEditingController();
    _buildingCtrl = TextEditingController();
    _streetCtrl = TextEditingController(text: initial?.address ?? '');
    _cityCtrl = TextEditingController();
    _landmarkCtrl = TextEditingController(text: initial?.landmark ?? '');
    _pinCtrl = TextEditingController();

    switch ((initial?.label ?? 'Home').trim().toLowerCase()) {
      case 'work':
        _label = 'Work';
        break;
      case 'other':
        _label = 'Other';
        break;
      default:
        _label = 'Home';
    }
    _isDefault = initial?.isDefault ?? false;

    final lat = initial?.latitude;
    final lng = initial?.longitude;
    if (lat != null && lng != null) {
      _selectedPoint = LatLng(lat, lng);
      _hasPinnedLocation = true;
    }

    _hydrateDefaultLocation();
  }

  @override
  void dispose() {
    _houseCtrl.dispose();
    _buildingCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _landmarkCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrateDefaultLocation() async {
    if (_hasPinnedLocation) return;
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('detected_location_lat');
    final lng = prefs.getDouble('detected_location_lng');
    final label = prefs.getString('detected_location')?.trim() ?? '';
    if (!mounted) return;
    final l = AppL10n.of(context)!;
    if (lat == null || lng == null) {
      if (label.isNotEmpty) _setLocationParts(l, label);
      return;
    }
    setState(() {
      _selectedPoint = LatLng(lat, lng);
      _hasPinnedLocation = true;
      if (label.isNotEmpty) _setLocationParts(l, label);
    });
  }

  void _setLocationParts(AppL10n l, String value) {
    final parts = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      _locationTitle = l.addrSelectedLocation;
      _locationSubtitle = value;
      return;
    }
    _locationTitle = parts.first;
    _locationSubtitle =
        parts.length > 1 ? parts.sublist(1).join(', ') : l.addrAddressDetected;
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }

  Future<LatLng> _getCurrentPoint() async {
    final l = AppL10n.of(context)!;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 4), onTimeout: () => false);
    if (!serviceEnabled) {
      throw Exception(l.addrErrLocationServices);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception(l.addrErrPermissionNeeded);
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(l.addrErrEnablePermission);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 20),
      ),
    ).timeout(const Duration(seconds: 24));

    if (position.isMocked) {
      throw Exception(l.addrErrMockLocation);
    }
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> _applySelectedPoint(
    LatLng point, {
    required bool forceFill,
  }) async {
    final l = AppL10n.of(context)!;
    if (mounted) {
      setState(() {
        _selectedPoint = point;
        _hasPinnedLocation = true;
        _resolvingLocation = true;
      });
    }

    try {
      final places = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      ).timeout(const Duration(seconds: 8));

      if (places.isEmpty) {
        if (!mounted) return;
        setState(() {
          _locationTitle = '${point.latitude.toStringAsFixed(5)}, '
              '${point.longitude.toStringAsFixed(5)}';
          _locationSubtitle = l.addrExactCoords;
        });
        return;
      }

      final place = places.first;
      final area = [
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
      ]
          .whereType<String>()
          .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
      final city = [
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]
          .whereType<String>()
          .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
      final line1 = [
        place.street,
        place.thoroughfare,
        area,
      ]
          .whereType<String>()
          .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
      final subtitleParts = [
        city,
        place.administrativeArea ?? '',
        place.country ?? '',
      ].where((value) => value.trim().isNotEmpty).toSet().toList();
      final subtitle = subtitleParts.join(', ');

      if (!mounted) return;
      setState(() {
        _locationTitle = area.isNotEmpty ? area : l.addrSelectedLocation;
        _locationSubtitle =
            subtitle.isNotEmpty ? subtitle : l.addrLocationDetected;
      });

      if (forceFill || _streetCtrl.text.trim().isEmpty) {
        _streetCtrl.text = line1;
      }
      if (forceFill || _cityCtrl.text.trim().isEmpty) {
        _cityCtrl.text = city;
      }
      final postalDigits =
          (place.postalCode ?? '').replaceAll(RegExp(r'\D'), '');
      if ((forceFill || _pinCtrl.text.trim().isEmpty) &&
          postalDigits.length >= 6) {
        _pinCtrl.text = postalDigits.substring(0, 6);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(e))),
      );
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final point = await _getCurrentPoint();
      await _applySelectedPoint(point, forceFill: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(e))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMapPicker() async {
    LatLng selected = _selectedPoint;
    bool sheetLocating = false;
    String? sheetError;

    final picked = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: C.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppL10n.of(context)!.addrPickExact,
                        style: GoogleFonts.poppins(
                          color: C.text1,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: sheetLocating
                          ? null
                          : () async {
                              setSheetState(() {
                                sheetLocating = true;
                                sheetError = null;
                              });
                              try {
                                selected = await _getCurrentPoint();
                                if (context.mounted) {
                                  setSheetState(() {});
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setSheetState(
                                    () => sheetError = _cleanError(e),
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setSheetState(() => sheetLocating = false);
                                }
                              }
                            },
                      icon: sheetLocating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 16),
                      label: Text(AppL10n.of(context)!.addrUseCurrent),
                    ),
                  ],
                ),
              ),
              if (sheetError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    sheetError!,
                    style: GoogleFonts.poppins(
                      color: C.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      key: ValueKey(
                        '${selected.latitude.toStringAsFixed(5)}:'
                        '${selected.longitude.toStringAsFixed(5)}',
                      ),
                      options: MapOptions(
                        initialCenter: selected,
                        initialZoom: 16,
                        onTap: (_, point) => setSheetState(() {
                          selected = point;
                        }),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.taskteddy.customer',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: selected,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_pin,
                                color: C.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppL10n.of(context)!.addrUseThisLocation,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) {
      await _applySelectedPoint(picked, forceFill: false);
    }
  }

  Future<void> _saveAddress() async {
    final house = _houseCtrl.text.trim();
    final building = _buildingCtrl.text.trim();
    final street = _streetCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final landmark = _landmarkCtrl.text.trim();
    final pincode = _pinCtrl.text.trim();

    // Compose the granular fields into the single address line the backend
    // stores. Empty parts are dropped so the line stays clean.
    final address = [house, building, street, city, pincode]
        .where((value) => value.isNotEmpty)
        .join(', ');
    if (address.isEmpty) {
      setState(() => _formError = AppL10n.of(context)!.addrErrEnterDetails);
      return;
    }
    if (pincode.isNotEmpty &&
        (pincode.length != 6 || int.tryParse(pincode) == null)) {
      setState(() => _formError = AppL10n.of(context)!.addrErrPincode);
      return;
    }

    setState(() {
      _formError = null;
      _saving = true;
    });
    try {
      final lat = _hasPinnedLocation ? _selectedPoint.latitude : null;
      final lng = _hasPinnedLocation ? _selectedPoint.longitude : null;
      if (widget.initial == null) {
        await ApiService.createAddress(
          label: _label,
          address: address,
          landmark: landmark.isEmpty ? null : landmark,
          latitude: lat,
          longitude: lng,
          isDefault: _isDefault,
        );
      } else {
        await ApiService.updateAddress(
          id: widget.initial!.id,
          label: _label,
          address: address,
          landmark: landmark.isEmpty ? null : landmark,
          latitude: lat,
          longitude: lng,
          isDefault: _isDefault,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: C.text1,
        title: Text(
          widget.initial == null
              ? AppL10n.of(context)!.addrEditorAddTitle
              : AppL10n.of(context)!.addrEditorEditTitle,
          style: GoogleFonts.poppins(
            color: C.text1,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: C.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    AppL10n.of(context)!.addrSaveAddress,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                    ),
                  ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 240,
                child: Stack(
                  children: [
                    FlutterMap(
                      key: ValueKey(
                        '${_selectedPoint.latitude.toStringAsFixed(5)}:'
                        '${_selectedPoint.longitude.toStringAsFixed(5)}',
                      ),
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: 16,
                        onTap: (_, point) => _applySelectedPoint(
                          point,
                          forceFill: false,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.taskteddy.customer',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPoint,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_pin,
                                color: C.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_resolvingLocation)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: .46),
                          child: const Center(
                            child: CircularProgressIndicator(color: C.primary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(Icons.location_on_outlined, color: C.text1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationTitle ?? AppL10n.of(context)!.addrLocateOnMap,
                        style: GoogleFonts.poppins(
                          color: C.text1,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _locationSubtitle ??
                            AppL10n.of(context)!.addrLocateSubtitle,
                        style: GoogleFonts.poppins(
                          color: C.text2,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _openMapPicker,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.primary,
                    side: const BorderSide(color: C.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(AppL10n.of(context)!.addrChange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 16),
                label: Text(
                  AppL10n.of(context)!.addrUseCurrentLocation,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: C.primary),
              ),
            ),
            const Divider(height: 24, color: C.border),
            Text(
              AppL10n.of(context)!.addrAddAddress,
              style: GoogleFonts.poppins(
                color: C.text1,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _FloatingField(
              label: AppL10n.of(context)!.addrHouseLabel,
              hintText: AppL10n.of(context)!.addrHouseHint,
              controller: _houseCtrl,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              leadingIcon: Icons.apartment_outlined,
            ),
            const SizedBox(height: 12),
            _FloatingField(
              label: AppL10n.of(context)!.addrBuildingLabel,
              hintText: AppL10n.of(context)!.addrBuildingHint,
              controller: _buildingCtrl,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              leadingIcon: Icons.domain_outlined,
            ),
            const SizedBox(height: 12),
            _FloatingField(
              label: AppL10n.of(context)!.addrStreetLabel,
              hintText: AppL10n.of(context)!.addrStreetHint,
              controller: _streetCtrl,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              leadingIcon: Icons.route_outlined,
            ),
            const SizedBox(height: 12),
            _FloatingField(
              label: AppL10n.of(context)!.addrCityLabel,
              hintText: AppL10n.of(context)!.addrCityHint,
              controller: _cityCtrl,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z .'-]")),
                LengthLimitingTextInputFormatter(45),
              ],
              leadingIcon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 12),
            _FloatingField(
              label: AppL10n.of(context)!.addrLandmarkLabel,
              hintText: AppL10n.of(context)!.addrLandmarkHint,
              controller: _landmarkCtrl,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              leadingIcon: Icons.pin_drop_outlined,
            ),
            const SizedBox(height: 12),
            _FloatingField(
              label: AppL10n.of(context)!.addrPincodeLabel,
              hintText: AppL10n.of(context)!.addrPincodeHint,
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              leadingIcon: Icons.markunread_mailbox_outlined,
            ),
            const SizedBox(height: 24),
            Text(
              AppL10n.of(context)!.addrAddLabel,
              style: GoogleFonts.poppins(
                color: C.text1,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AddressLabelTile(
                    label: AppL10n.of(context)!.addrLabelHome,
                    icon: Icons.home_outlined,
                    selected: _label == 'Home',
                    onTap: () => setState(() => _label = 'Home'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AddressLabelTile(
                    label: AppL10n.of(context)!.addrLabelWork,
                    icon: Icons.work_outline,
                    selected: _label == 'Work',
                    onTap: () => setState(() => _label = 'Work'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AddressLabelTile(
                    label: AppL10n.of(context)!.addrLabelOther,
                    icon: Icons.place_outlined,
                    selected: _label == 'Other',
                    onTap: () => setState(() => _label = 'Other'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.border),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                title: Text(
                  AppL10n.of(context)!.addrSetDefaultTitle,
                  style: GoogleFonts.poppins(
                    color: C.text1,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  AppL10n.of(context)!.addrSetDefaultSub,
                  style: GoogleFonts.poppins(
                    color: C.text3,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 10),
              Text(
                _formError!,
                style: GoogleFonts.poppins(
                  color: C.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddressLabelTile extends StatelessWidget {
  const _AddressLabelTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? C.primary : C.text3;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? C.primary.withValues(alpha: .08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? C.primary : C.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _CircularIconButton extends StatelessWidget {
  const _CircularIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _SupportTopic {
  const _SupportTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.faqs,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<_FaqItem> faqs;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
