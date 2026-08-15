import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/category_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'other.dart';
import 'tasks.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<BookingModel> _bookings = [];
  List<TaskModel> _myTasks = [];
  // Task ids the user has already reviewed or dismissed the rate-prompt for.
  Set<String> _reviewHandled = {};
  bool _detectingLocation = false;
  String _locationLabel = 'Set your location';
  double? _locationLat;
  double? _locationLng;
  int _unreadCount = 0;
  int _chatUnreadCount = 0;

  static const _fallbackPoint = LatLng(30.9010, 75.8573);
  // Lightly poll the unread-notifications + chat badges while home is active.
  Timer? _unreadTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _loadData();
    _loadUnreadCount();
    _loadChatUnreadCount();
    _detectAndSetLocation();
    WidgetsBinding.instance.addObserver(this);
    _unreadTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadUnreadCount();
      _loadChatUnreadCount();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the badges when the app returns to the foreground.
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
      _loadChatUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await ApiService.getUnreadNotificationCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _loadChatUnreadCount() async {
    final count = await ApiService.getChatUnreadCount();
    if (!mounted) return;
    setState(() => _chatUnreadCount = count);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadTimer?.cancel();
    super.dispose();
  }

  /// Open the post-a-task flow, optionally with a category preselected, then
  /// refresh home data on return so a freshly posted task shows immediately.
  Future<void> _openPostTask({TaskCategory? category}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => PostTaskScreen(initialCategory: category)),
    );
    if (mounted) _loadData();
  }

  void _openMyTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyTasksScreen()),
    );
  }

  Future<void> _openMessages() async {
    await Navigator.pushNamed(context, '/messages');
    // Opening a conversation marks it read server-side; refresh on return.
    _loadChatUnreadCount();
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    // The notifications screen marks items read; refresh the badge on return.
    _loadUnreadCount();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await Session.getUser();
    final saved = prefs.getString('detected_location');
    final lat = prefs.getDouble('detected_location_lat');
    final lng = prefs.getDouble('detected_location_lng');
    final userLocation = user?['location']?.toString();
    final next = (saved != null && saved.trim().isNotEmpty)
        ? saved
        : (userLocation != null && userLocation.trim().isNotEmpty
            ? userLocation
            : 'Ludhiana, Punjab');
    if (mounted) {
      setState(() {
        _locationLabel = next;
        _locationLat = lat;
        _locationLng = lng;
      });
    }
  }

  Future<void> _detectAndSetLocation() async {
    if (_detectingLocation) return;
    setState(() => _detectingLocation = true);

    try {
      final picked = await _getLiveLocation();
      await _saveLocation(picked);
    } catch (e) {
      if (mounted) {
        _showLocationMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<_PickedLocation> _getLiveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 4), onTimeout: () => false);
    if (!serviceEnabled) {
      throw Exception('Turn on location services to detect your address.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission is needed to detect your address.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Enable location permission from app settings.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        timeLimit: Duration(seconds: 20),
      ),
    ).timeout(const Duration(seconds: 24));

    if (position.isMocked) {
      throw Exception('Mock location detected. Please use real device GPS.');
    }

    final label = await _labelForCoordinates(
      position.latitude,
      position.longitude,
    );
    return _PickedLocation(
      label: label,
      lat: position.latitude,
      lng: position.longitude,
    );
  }

  Future<void> _saveLocation(_PickedLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('detected_location', location.label);
    await prefs.setDouble('detected_location_lat', location.lat);
    await prefs.setDouble('detected_location_lng', location.lng);
    await prefs.setString(
      'detected_location_updated_at',
      DateTime.now().toIso8601String(),
    );
    if (mounted) {
      setState(() {
        _locationLabel = location.label;
        _locationLat = location.lat;
        _locationLng = location.lng;
      });
    }
  }

  Future<String> _labelForCoordinates(double lat, double lng) async {
    final places = await placemarkFromCoordinates(lat, lng)
        .timeout(const Duration(seconds: 6));
    return _locationLabelFromPlacemark(places) ??
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  Future<void> _openLocationPicker() async {
    final picked = await showModalBottomSheet<_PickedLocation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(
        initialLabel: _locationLabel,
        initialPoint: LatLng(
          _locationLat ?? _fallbackPoint.latitude,
          _locationLng ?? _fallbackPoint.longitude,
        ),
        getLiveLocation: _getLiveLocation,
        labelForCoordinates: _labelForCoordinates,
      ),
    );
    if (picked != null) await _saveLocation(picked);
  }

  void _showLocationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _locationLabelFromPlacemark(List<Placemark> places) {
    if (places.isEmpty) return null;
    final place = places.first;
    final city = [
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
    ]
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    final state = place.administrativeArea ?? '';
    final country = place.country ?? '';
    final parts = [city, state.isNotEmpty ? state : country]
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Load the customer's own tasks + bookings (and the review-handled set)
  /// that drive the home screen. Repurposed from the old services loader; it
  /// also backs pull-to-refresh.
  Future<void> _loadData() async {
    final future = Future.wait([
      SharedPreferences.getInstance()
          .then((p) => (p.getStringList('review_handled_tasks') ?? []).toSet()),
      ApiService.getBookings(),
      ApiService.getTasks(),
    ]).then((results) {
      if (!mounted) return;
      setState(() {
        _reviewHandled = results[0] as Set<String>;
        _bookings = results[1] as List<BookingModel>;
        _myTasks = results[2] as List<TaskModel>;
      });
    }).catchError((_) {});

    // Refresh the unread badge alongside a pull-to-refresh.
    _loadUnreadCount();

    await future;
  }

  Future<void> _markReviewHandled(String taskId) async {
    setState(() => _reviewHandled = {..._reviewHandled, taskId});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('review_handled_tasks', _reviewHandled.toList());
  }

  String _greetingText(BuildContext context) {
    final t = AppL10n.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return t.goodMorning;
    if (hour < 17) return t.goodAfternoon;
    return t.goodEvening;
  }

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _header(),
              Expanded(
                child: RefreshIndicator(
                  color: C.primary,
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _heroPostCard()),
                      SliverToBoxAdapter(child: _activeStatusCard()),
                      SliverToBoxAdapter(child: _ratePromptCard()),
                      SliverToBoxAdapter(child: _howItWorks()),
                      SliverToBoxAdapter(child: _needHelpSection()),
                      SliverToBoxAdapter(child: _recentTasksSection()),
                      SliverToBoxAdapter(child: _trustStrip()),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── HEADER with gradient ─────────────────────────────────────
  Widget _header() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [C.primary, C.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 42,
                      width: 154,
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/logo_wordmark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Row(
                      children: [
                        _IconBtn(
                          icon: Icons.notifications_outlined,
                          badge: _unreadCount > 0
                              ? (_unreadCount > 99
                                  ? '99+'
                                  : '$_unreadCount')
                              : null,
                          onTap: _openNotifications,
                        ),
                        const SizedBox(width: 8),
                        _IconBtn(
                          icon: Icons.chat_bubble_outline,
                          badge: _chatUnreadCount > 0
                              ? (_chatUnreadCount > 99
                                  ? '99+'
                                  : '$_chatUnreadCount')
                              : null,
                          onTap: _openMessages,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(_greetingIcon,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      _greetingText(context),
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _openLocationPicker,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        _detectingLocation
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : const Icon(Icons.location_on,
                                color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _detectAndSetLocation,
                          child: const Icon(Icons.my_location,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ── HERO: POST A TASK ────────────────────────────────────────
  Widget _heroPostCard() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: GestureDetector(
          onTap: () => _openPostTask(),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [C.primary, C.brandInk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: C.primary.withValues(alpha: 0.32),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.edit_note_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        AppL10n.of(context)!.heroTitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  AppL10n.of(context)!.heroSubtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPostTask(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: C.brandInk,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 20),
                    label: Text(
                      AppL10n.of(context)!.postATask,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ── ACTIVE TASK / BOOKING STATUS CARD ────────────────────────
  Widget _activeStatusCard() {
    // 1) Lead with the customer's own OPEN posted tasks awaiting offers.
    final open = _myTasks.where((t) => t.status == TaskStatus.open).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (open.isNotEmpty) {
      final t = open.first;
      final n = t.applicantsCount;
      return _statusCardShell(
        category: t.category.name,
        title: t.title.trim().isEmpty ? t.category.label : t.title,
        subtitle: n > 0
            ? '$n ${n == 1 ? 'offer' : 'offers'} received'
            : 'Waiting for offers',
        chipLabel: 'OPEN',
        chipColor: C.accent2Dark,
        chipBg: C.accent2Light,
        onTap: _openMyTasks,
      );
    }

    // 2) Then any assigned / in-progress task.
    final active = _myTasks
        .where((t) =>
            t.status == TaskStatus.assigned || t.status == TaskStatus.inProgress)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (active.isNotEmpty) {
      final t = active.first;
      final tasker = t.assignedTo?.name;
      return _statusCardShell(
        category: t.category.name,
        title: t.title.trim().isEmpty ? t.category.label : t.title,
        subtitle: (tasker != null && tasker.trim().isNotEmpty)
            ? '$tasker is on it'
            : 'Tasker assigned',
        chipLabel:
            t.status == TaskStatus.inProgress ? 'IN PROGRESS' : 'ASSIGNED',
        chipColor: C.blue,
        chipBg: C.blueLight,
        onTap: _openMyTasks,
      );
    }

    // 3) Fall back to the nearest upcoming booking (legacy bookings support).
    final upcoming = _bookings
        .where((b) => b.status == 'pending' || b.status == 'confirmed')
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (upcoming.isNotEmpty) {
      final b = upcoming.first;
      final when = DateFormat('EEE, d MMM • h:mm a').format(b.scheduledAt);
      final confirmed = b.status == 'confirmed';
      return _statusCardShell(
        category: b.service.category,
        title: b.service.name,
        subtitle: when,
        chipLabel: confirmed ? 'CONFIRMED' : 'PENDING',
        chipColor: confirmed ? C.green : C.yellow,
        chipBg: confirmed ? C.greenLight : C.yellowLight,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingsScreen()),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _statusCardShell({
    required String category,
    required String title,
    required String subtitle,
    required String chipLabel,
    required Color chipColor,
    required Color chipBg,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.primary.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: C.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CategoryIconChip(category: category, size: 46, radius: 13),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: C.text1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: C.text3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    chipLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: chipColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: C.text3, size: 22),
              ],
            ),
          ),
        ),
      );

  // ── RATE YOUR SERVICE PROMPT ─────────────────────────────────
  TaskModel? get _pendingReviewTask {
    final candidates = _myTasks
        .where((t) =>
            t.status == TaskStatus.completed &&
            t.assignedTo != null &&
            t.remoteId != null &&
            t.assignedTo!.remoteId != null &&
            !_reviewHandled.contains(t.remoteId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return candidates.isEmpty ? null : candidates.first;
  }

  Widget _ratePromptCard() {
    final t = _pendingReviewTask;
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was "${t.title}"?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: C.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rate ${t.assignedTo!.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: C.text3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _openReviewSheet(t),
                    child: Row(
                      children: List.generate(
                        5,
                        (_) => const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.star_outline_rounded,
                              color: C.star, size: 26),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _markReviewHandled(t.remoteId!),
              icon: const Icon(Icons.close_rounded, color: C.text3, size: 20),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }

  void _openReviewSheet(TaskModel t) {
    double rating = 5;
    final comment = TextEditingController();
    bool submitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate ${t.assignedTo!.name}',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: C.text1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, color: C.text3),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    final filled = i < rating;
                    return GestureDetector(
                      onTap: () => setSheet(() => rating = i + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: C.star,
                          size: 38,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share a few words (optional)',
                  hintStyle:
                      GoogleFonts.poppins(fontSize: 13, color: C.text3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: C.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          setSheet(() => submitting = true);
                          try {
                            await ApiService.createReview(
                              taskId: t.remoteId!,
                              reviewedUserId: t.assignedTo!.remoteId!,
                              rating: rating,
                              comment: comment.text.trim(),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            await _markReviewHandled(t.remoteId!);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Thanks for your review!')),
                            );
                          } catch (e) {
                            final msg =
                                e.toString().replaceAll('Exception: ', '');
                            // Duplicate review — treat as handled.
                            if (msg.toLowerCase().contains('already')) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _markReviewHandled(t.remoteId!);
                              return;
                            }
                            setSheet(() => submitting = false);
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Submit Review',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TRUST STRIP ──────────────────────────────────────────────
  Widget _trustStrip() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: C.primaryLight.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TrustItem(
                    icon: Icons.verified_user_rounded,
                    tint: C.primary,
                    label: AppL10n.of(context)!.trustVerifiedTaskers),
              ),
              Expanded(
                child: _TrustItem(
                    icon: Icons.workspace_premium_rounded,
                    tint: C.star,
                    label: AppL10n.of(context)!.trustTopRated),
              ),
              Expanded(
                child: _TrustItem(
                    icon: Icons.lock_rounded,
                    tint: C.green,
                    label: AppL10n.of(context)!.trustSecurePayments),
              ),
            ],
          ),
        ),
      );

  // ── SECTION HEADER ───────────────────────────────────────────
  Widget _sectionHeader(String title,
          {String? actionLabel, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: C.text1,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      actionLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: C.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: C.primary, size: 18),
                  ],
                ),
              ),
          ],
        ),
      );

  // ── HOW IT WORKS ─────────────────────────────────────────────
  Widget _howItWorks() {
    final t = AppL10n.of(context)!;
    final steps = [
      ('1', t.howStep1Title, t.howStep1Caption),
      ('2', t.howStep2Title, t.howStep2Caption),
      ('3', t.howStep3Title, t.howStep3Caption),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(t.howItWorks),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: C.primaryLight,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            steps[i].$1,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: C.brandInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[i].$2,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: C.text1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                steps[i].$3,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: C.text3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < steps.length - 1)
                    const Divider(height: 1, color: C.divider),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── WHAT DO YOU NEED HELP WITH? (task categories) ────────────
  Widget _needHelpSection() {
    // A tile for each task category, plus a final "Something else" tile that
    // opens the post flow with no preselection.
    final width = MediaQuery.sizeOf(context).width;
    const gap = 12.0;
    final tileWidth = (width - 32 - gap * 2) / 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppL10n.of(context)!.whatDoYouNeedHelp),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final cat in TaskCategory.values)
                _categoryTile(
                  width: tileWidth,
                  icon: categoryIcon(cat.name),
                  tint: categoryColor(cat.name),
                  label: cat.label,
                  onTap: () => _openPostTask(category: cat),
                ),
              _categoryTile(
                width: tileWidth,
                icon: Icons.more_horiz_rounded,
                tint: C.text3,
                label: AppL10n.of(context)!.somethingElse,
                onTap: () => _openPostTask(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryTile({
    required double width,
    required IconData icon,
    required Color tint,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: C.text2,
                ),
              ),
            ],
          ),
        ),
      );

  // ── YOUR RECENT TASKS ────────────────────────────────────────
  Widget _recentTasksSection() {
    if (_myTasks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppL10n.of(context)!.yourTasks),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: C.primaryLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.assignment_outlined,
                        size: 30, color: C.brandInk),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppL10n.of(context)!.noTasksYet,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.text1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppL10n.of(context)!.postFirstTask,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: C.text3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _openPostTask(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline_rounded,
                        size: 18),
                    label: Text(
                      AppL10n.of(context)!.postATask,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final recent = [..._myTasks]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final preview = recent.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppL10n.of(context)!.yourRecentTasks,
            actionLabel: AppL10n.of(context)!.viewAll, onAction: _openMyTasks),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final t in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _recentTaskRow(t),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recentTaskRow(TaskModel t) {
    final colors = _statusColors(t.status);
    final n = t.applicantsCount;
    return GestureDetector(
      onTap: _openMyTasks,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border),
        ),
        child: Row(
          children: [
            CategoryIconChip(category: t.category.name, size: 46, radius: 13),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title.trim().isEmpty ? t.category.label : t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.text1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.$2,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          t.status.label.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: colors.$1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        n > 0
                            ? '$n ${n == 1 ? 'offer' : 'offers'}'
                            : 'No offers yet',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: n > 0 ? C.accent2Dark : C.text3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.text3, size: 22),
          ],
        ),
      ),
    );
  }

  // Status label -> (foreground, background) chip colours.
  (Color, Color) _statusColors(TaskStatus status) {
    switch (status) {
      case TaskStatus.pendingReview:
        return (C.yellow, C.yellowLight);
      case TaskStatus.open:
        return (C.accent2Dark, C.accent2Light);
      case TaskStatus.assigned:
      case TaskStatus.inProgress:
        return (C.blue, C.blueLight);
      case TaskStatus.completed:
        return (C.green, C.greenLight);
      case TaskStatus.cancelled:
      case TaskStatus.rejected:
        return (C.text3, C.divider);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PRESERVED CLASSES: _PickedLocation, _LocationPickerSheet
// ═══════════════════════════════════════════════════════════════

class _PickedLocation {
  const _PickedLocation({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.initialLabel,
    required this.initialPoint,
    required this.getLiveLocation,
    required this.labelForCoordinates,
  });

  final String initialLabel;
  final LatLng initialPoint;
  final Future<_PickedLocation> Function() getLiveLocation;
  final Future<String> Function(double lat, double lng) labelForCoordinates;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final MapController _mapController = MapController();
  late final TextEditingController _search;
  late LatLng _selectedPoint;
  late String _selectedLabel;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
    _selectedLabel = widget.initialLabel;
    _search = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final query = _search.text.trim();
    if (query.length < 3) {
      setState(() => _error = 'Type a complete address or area name.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final matches =
          await locationFromAddress(query).timeout(const Duration(seconds: 8));
      if (matches.isEmpty) {
        throw Exception('No matching location found.');
      }
      final match = matches.first;
      final label = await widget.labelForCoordinates(
        match.latitude,
        match.longitude,
      );
      if (!mounted) return;
      setState(() {
        _selectedPoint = LatLng(match.latitude, match.longitude);
        _selectedLabel = label;
        _search.text = label;
      });
      _mapController.move(_selectedPoint, 15);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = 'Could not find that address. Try area, city, and state.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final picked = await widget.getLiveLocation();
      if (!mounted) return;
      setState(() {
        _selectedPoint = LatLng(picked.lat, picked.lng);
        _selectedLabel = picked.label;
        _search.text = picked.label;
      });
      _mapController.move(_selectedPoint, 15);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickMapPoint(LatLng point) async {
    setState(() {
      _busy = true;
      _error = null;
      _selectedPoint = point;
    });

    try {
      final label =
          await widget.labelForCoordinates(point.latitude, point.longitude);
      if (!mounted) return;
      setState(() {
        _selectedLabel = label;
        _search.text = label;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedLabel =
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
          _search.text = _selectedLabel;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final typed = _search.text.trim();
    if (typed.isNotEmpty &&
        typed.toLowerCase() != _selectedLabel.toLowerCase()) {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        final matches = await locationFromAddress(typed)
            .timeout(const Duration(seconds: 8));
        if (matches.isEmpty) {
          throw Exception('No matching location found.');
        }
        final match = matches.first;
        final label = await widget.labelForCoordinates(
          match.latitude,
          match.longitude,
        );
        if (!mounted) return;
        setState(() {
          _selectedPoint = LatLng(match.latitude, match.longitude);
          _selectedLabel = label;
          _search.text = label;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _error = 'Search this address first, then confirm.';
          _busy = false;
        });
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    final label =
        _search.text.trim().isNotEmpty ? _search.text.trim() : _selectedLabel;
    Navigator.pop(
      context,
      _PickedLocation(
        label: label,
        lat: _selectedPoint.latitude,
        lng: _selectedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * .9;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose Location',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: C.text1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: C.text2),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchAddress(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: C.text1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search area, landmark, city',
                      prefixIcon:
                          const Icon(Icons.search, color: C.text3, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: C.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: C.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: C.primary, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _searchAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _useCurrentLocation,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('Use current location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.primary,
                      side: const BorderSide(color: C.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                _error!,
                style: GoogleFonts.poppins(
                  color: C.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedPoint,
                  initialZoom: 14,
                  onTap: (_, point) => _pickMapPoint(point),
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
                        width: 46,
                        height: 46,
                        child: const Icon(
                          Icons.location_pin,
                          color: C.primary,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: C.primary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: C.text1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Confirm Location',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
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
}

// ═══════════════════════════════════════════════════════════════
// TRUST STRIP ITEM
// ═══════════════════════════════════════════════════════════════

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;

  const _TrustItem(
      {required this.icon, required this.tint, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: C.text2,
            ),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════
// ICON BUTTON
// ═══════════════════════════════════════════════════════════════

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            if (badge != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: C.accent2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      badge!,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
