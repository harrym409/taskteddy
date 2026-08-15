import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/tasker_state.dart';
import '../services/api_service.dart';

import 'browse.dart';
import 'wallet.dart';
import 'notifications.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends State<DashboardScreen> {
  final TaskerState _state = TaskerState();
  int _unreadCount = 0;
  int _chatUnread = 0;
  Timer? _notifTimer;

  List<TaskModel> _activeTasks = [];
  List<TaskModel> _availableTasks = [];
  List<Map<String, dynamic>> _bookings = [];
  double _todayEarnings = 0;
  double _weekEarnings = 0;
  double _monthEarnings = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
    _state.loadUser();
    // Defer the first load: _loadData() calls setState() before its first await,
    // and initState runs while the shell's IndexedStack is still building every
    // tab — a synchronous setState there throws "setState called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
    _loadUnreadCount();
    _loadChatUnread();
    _startNotifPolling();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {
      // Leave the badge unchanged if the fetch fails/offline.
    }
  }

  Future<void> _loadChatUnread() async {
    // getChatUnreadCount never throws (returns 0 on error/offline).
    final count = await ApiService.getChatUnreadCount();
    if (!mounted) return;
    setState(() => _chatUnread = count);
  }

  void _startNotifPolling() {
    _notifTimer?.cancel();
    // Light polling for the unread badges while the dashboard is active.
    _notifTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _loadUnreadCount();
      _loadChatUnread();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fire all four requests together instead of one-after-another so the
      // dashboard fills in ~1x network latency instead of 4x.
      final results = await Future.wait([
        ApiService.getTasks(status: 'open'),
        ApiService.getMyApplications(),
        ApiService.getEarnings(),
        ApiService.getTaskerBookings(),
      ]);
      final tasks = results[0] as List<TaskModel>;
      final apps = results[1] as List<ApplicationModel>;
      final earnings = results[2] as Map<String, dynamic>;
      final bookings = results[3] as List<Map<String, dynamic>>;

      final activeApps = apps.where((a) => a.status == 'accepted' && a.task != null && (a.task!.status == TaskStatus.assigned || a.task!.status == TaskStatus.inProgress)).toList();

      // Real earnings totals, bucketed by the actual payout date.
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      double today = 0;
      double week = 0;
      double month = 0;
      final rows = (earnings['earnings'] as List?) ?? const [];
      for (final row in rows) {
        if (row is! Map) continue;
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final date =
            DateTime.tryParse(row['created_at']?.toString() ?? '') ?? now;
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          today += amount;
        }
        if (date.isAfter(weekAgo)) {
          week += amount;
        }
        if (date.year == now.year && date.month == now.month) {
          month += amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _availableTasks = tasks;
        _activeTasks = activeApps.map((a) => a.task!).toList();
        _bookings = bookings;
        _todayEarnings = today;
        _weekEarnings = week;
        _monthEarnings = month;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _openMessages() async {
    await Navigator.pushNamed(context, '/messages');
    // Conversations are marked read server-side when opened, so refresh the
    // badge on return.
    _loadChatUnread();
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _loadUnreadCount();
  }

  // Set at the start of build() so the context-free _buildXxx helpers below
  // can read localized strings.
  late AppL10n _l;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return _l.goodMorning;
    if (hour < 17) return _l.goodAfternoon;
    return _l.goodEvening;
  }

  // Real reputation-backed stats (fall back sensibly when unset).
  int get _completedJobs =>
      _state.user.reputation?.completedTasks ?? _state.user.totalReviews;
  int get _reliability =>
      (_state.user.reputation?.reliability ?? 100).round();
  String get _levelLabel {
    final label = _state.user.reputation?.levelLabel;
    return (label == null || label.isEmpty) ? _l.dashLevelNew : label;
  }


  @override
  Widget build(BuildContext context) {
    _l = AppL10n.of(context)!;
    return Scaffold(
        backgroundColor: T.bg,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                color: T.primary,
                                backgroundColor:
                                    T.primary.withValues(alpha: 0.12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _l.dashLoading,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: T.text3,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: T.primary,
                        onRefresh: () async {
                          await _loadData();
                        },
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: AnimatedOpacity(
                                opacity: _isLoading ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 500),
                                child: _buildEarningsCard(),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: AnimatedOpacity(
                                opacity: _isLoading ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 600),
                                child: _buildStatsRow(),
                              ),
                            ),
                            if (_bookings.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                  child: _sectionHeader(
                                      _l.myBookings,
                                      _l.dashAssigned(_bookings.length),
                                      '',
                                      () {})),
                              SliverToBoxAdapter(child: _buildBookings()),
                            ],
                            SliverToBoxAdapter(
                                child: _sectionHeader(
                                    _l.tasksNearYou,
                                    _l.dashAvailable(_availableTasks.length),
                                    _l.seeAll,
                                    () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const BrowseTasksScreen()),
                                        ))),
                            SliverToBoxAdapter(child: _buildPriorityTasks()),
                            SliverToBoxAdapter(
                                child: _sectionHeader(
                                    _l.myActiveJobs,
                                    _l.dashOngoing(_activeTasks.length),
                                    '',
                                    () {})),
                            SliverToBoxAdapter(child: _buildActiveJobs()),
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 28)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
  }

  // ═══════════════════════════════════════════════════════
  //  HEADER — Greeting + Availability + Icons + Location
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader() {
    final int unread = _unreadCount;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: T.panelDark.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 0: TaskTeddy wordmark logo (left) + icons (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_wordmark.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  _HeaderIconBtn(
                    icon: Icons.notifications_outlined,
                    badge: unread > 0 ? unread.toString() : '',
                    onTap: _openNotifications,
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconBtn(
                    icon: Icons.chat_bubble_outline,
                    badge: _chatUnread > 0 ? _chatUnread.toString() : '',
                    onTap: _openMessages,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 1: Greeting (name removed — the wordmark already brands the header)
              Text(
                _greeting,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  EARNINGS OVERVIEW CARD — with shimmer glow
  // ═══════════════════════════════════════════════════════
  Widget _buildEarningsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A67C5).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF5B7BD5).withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background gradient
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5B7BD5),
                    Color(0xFF4A67C5),
                    Color(0xFF3F5AB5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.trending_up_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _l.earningsOverview,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WalletScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _l.wallet,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _EarningItem(
                        label: _l.today,
                        value: '₹${_todayEarnings.toStringAsFixed(0)}',
                        icon: Icons.today_rounded,
                      ),
                      Container(
                        width: 1,
                        height: 42,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _EarningItem(
                        label: _l.thisWeek,
                        value: '₹${_weekEarnings.toStringAsFixed(0)}',
                        icon: Icons.date_range_rounded,
                      ),
                      Container(
                        width: 1,
                        height: 42,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      _EarningItem(
                        label: _l.thisMonth,
                        value: '₹${_monthEarnings.toStringAsFixed(0)}',
                        icon: Icons.calendar_month_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Shimmer / glow overlay
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  STATS ROW
  // ═══════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.star_rounded,
            value: _state.user.rating.toStringAsFixed(1),
            label: _l.statRating,
            color: T.star,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.check_circle_rounded,
            value: '$_completedJobs',
            label: _l.statTasks,
            color: T.green,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.verified_rounded,
            value: '$_reliability%',
            label: _l.dashStatReliability,
            color: T.blue,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.workspace_premium_rounded,
            value: _levelLabel,
            label: _l.dashStatLevel,
            color: T.gold,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════
  Widget _sectionHeader(
      String title, String subtitle, String action, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: T.text1,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: T.text3,
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (action.isNotEmpty)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: T.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: T.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: T.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_ios,
                        size: 10, color: T.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PRIORITY TASKS — horizontal scroll
  // ═══════════════════════════════════════════════════════
  Widget _buildPriorityTasks() {
    if (_availableTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: T.border),
          ),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: T.text3),
              const SizedBox(height: 10),
              Text(
                _l.noTasksAvailable,
                style: GoogleFonts.poppins(
                  color: T.text2,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _l.dashCheckBackSoon,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: T.text3, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: min(_availableTasks.length, 6),
        itemBuilder: (_, i) =>
            _PriorityTaskCard(task: _availableTasks[i]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BOOKINGS (admin-assigned service jobs)
  // ═══════════════════════════════════════════════════════
  Widget _buildBookings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _bookings
            .map((b) => _BookingCard(
                  booking: b,
                  onComplete: () => _markBookingComplete(b),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _markBookingComplete(Map<String, dynamic> booking) async {
    final otpCtrl = TextEditingController();
    final bookingId = booking['id']?.toString() ?? '';
    final serviceName =
        (booking['service'] is Map ? booking['service']['name'] : null)
                ?.toString() ??
            _l.dashThisBooking;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_l.dashCompleteBooking,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _l.dashBookingOtpPrompt(serviceName),
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w600, color: T.text3),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: _l.profileEnterOtp,
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l.actionCancel,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_l.dashComplete,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final otp = otpCtrl.text.trim();
    if (otp.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.completeBooking(bookingId, otp);
      await _loadData();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_l.dashBookingComplete,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: T.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: T.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  //  ACTIVE JOBS
  // ═══════════════════════════════════════════════════════
  Widget _buildActiveJobs() {
    if (_activeTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: T.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.work_off_outlined, size: 40, color: T.text3),
              const SizedBox(height: 10),
              Text(
                _l.noActiveJobs,
                style: GoogleFonts.poppins(
                    color: T.text2,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _l.dashBrowseStartEarning,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: T.text3,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children:
            _activeTasks.map((task) => _ActiveJobCard(task: task)).toList(),
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════
//  PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final String badge;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        if (badge.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: T.red,
                shape: BoxShape.circle,
                border: Border.all(
                    color: T.panel, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: T.red.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Earnings item for the gradient card ──────────────────
class _EarningItem extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _EarningItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.55), size: 16),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: T.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: T.text1,
                letterSpacing: -0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: T.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Priority task card — horizontal scroll ───────────────
class _PriorityTaskCard extends StatelessWidget {
  final TaskModel task;
  const _PriorityTaskCard({required this.task});

  String _deadlineLabel(AppL10n l) {
    final diff = task.deadline.difference(DateTime.now());
    if (diff.isNegative) return l.dashOverdue;
    if (diff.inHours < 1) return l.dashMinLeft(diff.inMinutes);
    if (diff.inHours < 24) return l.dashHrLeft(diff.inHours);
    return l.dashDayLeft(diff.inDays);
  }

  Color _deadlineColor() {
    final diff = task.deadline.difference(DateTime.now());
    if (diff.isNegative || diff.inHours < 3) return T.red;
    if (diff.inHours < 12) return T.yellow;
    return T.green;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: T.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + Budget
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: categoryColor(task.category.name).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon(task.category.name),
                        size: 13, color: categoryColor(task.category.name)),
                    const SizedBox(width: 5),
                    Text(
                      task.category.label,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: categoryColor(task.category.name),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '₹${task.budget.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: T.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: T.text1,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: T.text3),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    color: T.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Bottom row: deadline + applicants + apply
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _deadlineColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 11, color: _deadlineColor()),
                    const SizedBox(width: 3),
                    Text(
                      _deadlineLabel(l),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _deadlineColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l.dashApplied(task.applicantsCount),
                style: GoogleFonts.nunito(
                  fontSize: 10.5,
                  color: T.text3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [T.primary, T.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: T.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  l.actionApply,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active job card ──────────────────────────────────────
class _ActiveJobCard extends StatelessWidget {
  final TaskModel task;
  const _ActiveJobCard({required this.task});

  Color get _statusColor =>
      task.status == TaskStatus.inProgress ? Colors.orange : T.blue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: T.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _statusColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.status.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: categoryColor(task.category.name).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(categoryIcon(task.category.name),
                        size: 12, color: categoryColor(task.category.name)),
                    const SizedBox(width: 5),
                    Text(
                      task.category.label,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: categoryColor(task.category.name),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '₹${task.budget.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: T.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: T.text1,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: T.text3),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: T.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (task.postedBy.name.isNotEmpty) ...[
                const Icon(Icons.person_outline, size: 14, color: T.text3),
                const SizedBox(width: 3),
                Text(
                  task.postedBy.name.split(' ').first,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: T.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Booking card (admin-assigned service job) ────────────
class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onComplete;
  const _BookingCard({required this.booking, required this.onComplete});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatSchedule(AppL10n l, String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return l.dashScheduled;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${_months[dt.month - 1]}, $h:$min $ampm';
  }

  String _statusLabel(AppL10n l, String status) {
    switch (status) {
      case 'confirmed':
        return l.dashStatusConfirmed;
      case 'completed':
        return l.dashStatusCompleted;
      case 'cancelled':
        return l.dashStatusCancelled;
      default:
        return l.dashStatusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final service =
        booking['service'] is Map ? booking['service'] as Map : const {};
    final customer =
        booking['customer'] is Map ? booking['customer'] as Map : const {};
    final status = booking['status']?.toString() ?? 'pending';
    final serviceCategory = service['category']?.toString() ?? 'other';
    final serviceName = service['name']?.toString() ?? l.dashServiceFallback;
    final customerName = customer['name']?.toString() ?? l.dashCustomerFallback;
    final address = booking['address']?.toString() ?? '';
    final amount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
    final bookingRef = booking['booking_id']?.toString() ?? '';

    final Color statusColor = status == 'confirmed'
        ? T.green
        : status == 'completed'
            ? T.blue
            : status == 'cancelled'
                ? T.red
                : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: T.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIconChip(
                  category: serviceCategory, size: 44, iconSize: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: T.text1,
                      ),
                    ),
                    if (bookingRef.isNotEmpty)
                      Text(
                        bookingRef,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: T.text3,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel(l, status),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bookingRow(Icons.schedule_rounded,
              _formatSchedule(l, booking['scheduled_at']?.toString())),
          const SizedBox(height: 6),
          _bookingRow(Icons.person_outline, customerName),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _bookingRow(Icons.location_on_outlined, address),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: T.green,
                ),
              ),
              const Spacer(),
              if (status == 'confirmed')
                ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(l.dashMarkComplete,
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: T.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookingRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: T.text3),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: T.text2,
            ),
          ),
        ),
      ],
    );
  }
}
