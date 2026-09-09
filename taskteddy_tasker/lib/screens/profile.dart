import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../theme/category_icons.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/tasker_state.dart';
import 'edit_profile.dart';
import 'verification.dart';
import 'bank_payment.dart';
import 'wallet.dart';
import 'completed_tasks.dart';
import 'my_reviews.dart';
import 'help_support.dart';
import 'settings.dart';
import 'availability.dart';
import 'portfolio.dart';
import 'browse.dart'; // For ActiveTaskScreen

// ════════════════════════════════════════════════════════
//  MY APPLICATIONS
// ════════════════════════════════════════════════════════

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key, this.embedded = false});

  /// True when hosted as a bottom-nav tab (no back arrow — there is nothing to
  /// pop, and popping the shell crashes). False when pushed as its own route.
  final bool embedded;

  @override
  State<MyApplicationsScreen> createState() => _MyAppState();
}

class _MyAppState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = true;
  List<ApplicationModel> _apps = [];
  final TaskerState _state = TaskerState();
  int _lastAppsRev = 0;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _lastAppsRev = _state.applicationsRevision;
    _state.addListener(_onAppsChanged);
    _loadData();
    // Fallback poll (WS pushes handle the instant case via the refresh hub).
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _loadData();
    });
  }

  // As a kept-alive shell tab this screen never re-inits, so reload whenever a
  // bid/withdraw elsewhere bumps the applications revision.
  void _onAppsChanged() {
    if (!mounted) return;
    if (_state.applicationsRevision != _lastAppsRev) {
      _lastAppsRev = _state.applicationsRevision;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final data = await ApiService.getMyApplications();
    if (mounted) {
      setState(() {
        _apps = data;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _state.removeListener(_onAppsChanged);
    _tab.dispose();
    super.dispose();
  }

  // A completed job = an accepted application whose task is now completed.
  bool _isCompleted(ApplicationModel a) =>
      a.status == 'accepted' && a.task?.status == TaskStatus.completed;
  // "Accepted" now means an accepted job still in progress (not yet completed).
  bool _isActiveAccepted(ApplicationModel a) =>
      a.status == 'accepted' && a.task?.status != TaskStatus.completed;

  int get _pending => _apps.where((a) => a.status == 'pending').length;
  int get _accepted => _apps.where(_isActiveAccepted).length;
  int get _completed => _apps.where(_isCompleted).length;
  int get _rejected => _apps.where((a) => a.status == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
        backgroundColor: T.bg,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [T.primary, T.primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          // Only show a back arrow when this screen was pushed
                          // (e.g. from the profile menu). As a bottom-nav tab
                          // there's nothing to pop, and popping the shell crashes.
                          if (!widget.embedded) ...[
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 20),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(l.profileMyApplications,
                              style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                          const Spacer(),
                          IconButton(
                            tooltip: l.actionRetry,
                            onPressed: _loading ? null : _loadData,
                            icon: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.refresh_rounded,
                                    color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        _AppStat('${_apps.length}', l.profileTotal, Colors.white),
                        _AppStat('$_pending', l.profilePending, T.star),
                        _AppStat('$_accepted', l.profileAccepted, T.green),
                        _AppStat('$_completed', l.profileCompleted, T.blue),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      controller: _tab,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      labelStyle: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w800),
                      unselectedLabelStyle: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(text: l.profileAll),
                        Tab(text: l.profilePending),
                        Tab(text: l.profileAccepted),
                        Tab(text: l.profileCompleted),
                        Tab(text: l.profileRejected),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ── Tab Body ────────────────────────────────────────
            Expanded(
              child: _loading 
                  ? const Center(child: CircularProgressIndicator(color: T.primary))
                  : TabBarView(controller: _tab, children: [
                      _AppList(_apps, onRefresh: _loadData),
                      _AppList(_apps.where((a) => a.status == 'pending').toList(), onRefresh: _loadData),
                      _AppList(_apps.where(_isActiveAccepted).toList(), onRefresh: _loadData),
                      _AppList(_apps.where(_isCompleted).toList(), onRefresh: _loadData),
                      _AppList(_apps.where((a) => a.status == 'rejected').toList(), onRefresh: _loadData),
                    ]),
            ),
          ],
        ),
      );
  }
}

class _AppStat extends StatelessWidget {
  final String count, label;
  final Color color;
  const _AppStat(this.count, this.label, this.color);
  @override
  Widget build(BuildContext ctx) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
      ),
      child: Column(
        children: [
          Text(count,
              style: GoogleFonts.nunito(
                  color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label,
              style: GoogleFonts.nunito(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

class _AppList extends StatelessWidget {
  final List<ApplicationModel> apps;
  final Future<void> Function() onRefresh;
  const _AppList(this.apps, {required this.onRefresh});

  @override
  Widget build(BuildContext ctx) {
    final l = AppL10n.of(ctx)!;
    if (apps.isEmpty) {
      // Scrollable so pull-to-refresh works even with nothing to show.
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: T.primary,
        child: LayoutBuilder(
          builder: (ctx, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: T.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.assignment_outlined,
                          size: 34, color: T.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(l.profileNothingHere,
                        style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: T.text3)),
                    const SizedBox(height: 6),
                    Text(l.profileBrowseTasksStart,
                        style:
                            GoogleFonts.nunito(fontSize: 14, color: T.text3)),
                  ]),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: T.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: apps.length,
        itemBuilder: (_, i) => _AppCard(app: apps[i], onRefresh: onRefresh),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback onRefresh;
  const _AppCard({required this.app, required this.onRefresh});

  Future<void> _withdrawBid(BuildContext context) async {
    final l = AppL10n.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.profileWithdrawBid, style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: T.text1)),
        content: Text(l.profileWithdrawBidConfirm, style: GoogleFonts.nunito(color: T.text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel, style: GoogleFonts.nunito(color: T.text3, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: T.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(l.profileWithdraw, style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: T.primary)),
      );
      try {
        await ApiService.withdrawApplication(app.remoteId ?? app.id.toString());
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.profileBidWithdrawn, style: GoogleFonts.nunito())),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString(), style: GoogleFonts.nunito())),
          );
        }
      }
    }
  }

  // An accepted application whose task is now completed reads as "Completed".
  bool get _isDone =>
      app.status == 'accepted' && app.task?.status == TaskStatus.completed;

  Color get _statusColor {
    if (_isDone) return T.blue;
    switch (app.status) {
      case 'accepted': return T.green;
      case 'rejected': return T.red;
      default: return T.yellow;
    }
  }

  IconData get _statusIcon {
    switch (app.status) {
      case 'accepted': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  String _statusLabel(AppL10n l) {
    if (_isDone) return l.profileCompleted;
    switch (app.status) {
      case 'accepted': return l.profileAccepted;
      case 'rejected': return l.profileStatusNotSelected;
      default: return l.profileStatusUnderReview;
    }
  }

  String _fmtT(AppL10n l, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return l.timeMinutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.timeHoursAgo(d.inHours);
    return l.timeDaysAgo(d.inDays);
  }

  @override
  Widget build(BuildContext ctx) {
    final l = AppL10n.of(ctx)!;
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: app.status == 'accepted'
                  ? T.green.withValues(alpha: .3)
                  : app.status == 'rejected'
                      ? T.red.withValues(alpha: .2)
                      : T.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryIconChip(
                      category: app.task?.category.name ?? 'other',
                      size: 50,
                      iconSize: 24,
                      radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: T.primaryLight,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(app.task?.category.label ?? 'Other',
                              style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: T.primary)),
                        ),
                        const SizedBox(height: 4),
                        Text(app.task?.title ?? 'Unknown Task',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: T.text1)),
                        const SizedBox(height: 2),
                        Text(app.task?.location ?? 'Remote',
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: T.text3,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _statusColor.withValues(alpha: .25))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_statusIcon, color: _statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(_statusLabel(l),
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _statusColor)),
                    ]),
                  ),
                ],
              ),
            ),
            // ── Bid vs Budget row ──────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: T.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.profileYourBid,
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: T.text3,
                                fontWeight: FontWeight.w600)),
                        Text('₹${app.bidAmount.toInt()}',
                            style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: T.primary)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: T.border),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(l.profileTaskBudget,
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: T.text3,
                                fontWeight: FontWeight.w600)),
                        Text('₹${app.task?.budget.toInt() ?? 0}',
                            style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: T.text1)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: T.border),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l.profileYouEarn,
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: T.text3,
                                fontWeight: FontWeight.w600)),
                        Text('₹${(app.bidAmount * 0.90).toInt()}',
                            style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: T.green)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Progress Timeline ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatusTimeline(status: app.status),
            ),
            const SizedBox(height: 12),
            // ── Cover letter snippet ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(app.coverLetter,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: T.text2,
                      fontWeight: FontWeight.w500,
                      height: 1.4)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: T.text3),
                      const SizedBox(width: 4),
                      Text(l.profileAppliedAgo(_fmtT(l, app.appliedAt)),
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: T.text3,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (app.status == 'pending')
                    ElevatedButton(
                      onPressed: () => _withdrawBid(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: T.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(l.profileWithdrawBid,
                          style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ),
                  if (app.status == 'accepted' &&
                      app.task?.status == TaskStatus.completed)
                    // Job finished — show a completed banner, not "Start Task".
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: T.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 18, color: T.green),
                          const SizedBox(width: 8),
                          Text(l.profileCompleted,
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: T.green)),
                        ],
                      ),
                    )
                  else if (app.status == 'accepted')
                    // Single action — completion (OTP) happens inside the
                    // Active Task screen that "Start Task" opens.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: app.task == null
                            ? null
                            : () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ActiveTaskScreen(task: app.task!)),
                                ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(l.profileStartTask,
                            style: GoogleFonts.nunito(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: T.green,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext ctx) {
    final l = AppL10n.of(ctx)!;
    final steps = [l.profileApplied, l.profileStatusUnderReview, l.profileStepDecision];
    int activeIndex;
    switch (status) {
      case 'accepted':
      case 'rejected':
        activeIndex = 2;
        break;
      default:
        activeIndex = 1;
    }
    final finalColor = status == 'accepted' ? T.green : T.red;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final filled = (i ~/ 2) < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? T.primary : T.border,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isActive = stepIndex <= activeIndex;
        final isFinal = stepIndex == 2 && activeIndex == 2;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFinal
                    ? finalColor
                    : isActive
                        ? T.primary
                        : T.border,
              ),
              child: Icon(
                isFinal
                    ? (status == 'accepted'
                        ? Icons.check
                        : Icons.close)
                    : isActive
                        ? Icons.check
                        : Icons.circle,
                color: isActive ? Colors.white : Colors.white60,
                size: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(steps[stepIndex],
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? T.text1 : T.text3)),
          ],
        );
      }),
    );
  }
}       // ════════════════════════════════════════════════════════
//  EARNINGS SCREEN
// ════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _termsUrl = 'https://taskteddy.app/terms';
  static const _privacyUrl = 'https://taskteddy.app/privacy';
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.taskteddy.tasker';
  final TaskerState _state = TaskerState();

  List<Map<String, dynamic>> _portfolio = [];
  String? _availabilitySummary;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
    _state.loadUser();
    _loadPortfolio();
    _loadAvailabilitySummary();
  }

  Future<void> _loadPortfolio() async {
    try {
      final items = await ApiService.getPortfolio();
      if (mounted) setState(() => _portfolio = items);
    } catch (_) {
      // Non-blocking; leave the preview empty on failure.
    }
  }

  Future<void> _loadAvailabilitySummary() async {
    try {
      final data = await ApiService.getAvailability();
      final active = data.where((d) => d['is_available'] == true).toList();
      if (!mounted) return;
      final l = AppL10n.of(context)!;
      setState(() {
        _availabilitySummary =
            active.isEmpty ? l.profileNotSet : _summariseAvailability(l, active);
      });
    } catch (_) {
      // Leave summary null (menu row falls back to a generic label).
    }
  }

  String _summariseAvailability(AppL10n l, List<Map<String, dynamic>> active) {
    const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Clamp to 0..6 so an unexpected day_of_week from the API can never index
    // out of `short` and crash the whole profile screen.
    final days = active
        .map((d) => ((d['day_of_week'] as num?)?.toInt() ?? 0).clamp(0, 6))
        .toSet()
        .toList()
      ..sort();
    if (days.isEmpty) return l.profileNotSet;
    final contiguous = days.length == (days.last - days.first + 1);
    final dayLabel = days.length == 7
        ? l.profileEveryDay
        : contiguous
            ? '${short[days.first]}-${short[days.last]}'
            : days.map((d) => short[d]).join(', ');
    final firstStart = (active.first['start_minute'] as num?)?.toInt() ?? 540;
    final firstEnd = (active.first['end_minute'] as num?)?.toInt() ?? 1080;
    final same = active.every((d) =>
        ((d['start_minute'] as num?)?.toInt() ?? -1) == firstStart &&
        ((d['end_minute'] as num?)?.toInt() ?? -1) == firstEnd);
    if (same) {
      return '$dayLabel, ${_fmtMin(firstStart)}-${_fmtMin(firstEnd)}';
    }
    return '$dayLabel, ${l.profileHoursVary}';
  }

  String _fmtMin(int minutes) {
    final h24 = (minutes ~/ 60) % 24;
    final min = minutes % 60;
    final period = h24 < 12 ? 'AM' : 'PM';
    var h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${min.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _openPortfolio() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PortfolioScreen()));
    _loadPortfolio();
  }

  Future<void> _openAvailability() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AvailabilityScreen()));
    _loadAvailabilitySummary();
  }

  Future<void> _openLink(String url) async {
    final l = AppL10n.of(context)!;
    final uri = Uri.parse(url);
    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.profileRedirectTitle,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            l.profileRedirectBody(url),
            style: GoogleFonts.nunito(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionContinue,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (allow != true) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.profileCouldNotOpenLink)),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: source, maxWidth: 1024, imageQuality: 85);
    if (file == null || !mounted) return;
    final l = AppL10n.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.profileUploadingPhoto)));
    final error = await _state.uploadAvatar(file);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? l.profilePictureUpdated),
        backgroundColor: error == null ? T.green : T.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAvatarPicker() {
    final l = AppL10n.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.profileUpdatePicture,
                style:
                    GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: T.primary),
              title: Text(l.commonChooseGallery,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: T.primary),
              title: Text(l.commonTakePhoto,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _editBio() {
    final l = AppL10n.of(context)!;
    final c = TextEditingController(text: _state.bio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.profileEditAboutMe,
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: c,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: l.profileWriteAboutYourself,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _state.updateBio(c.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.profileBioUpdated)),
                );
              },
              child: Text(l.actionSave),
            ),
          ),
        ]),
      ),
    );
  }

  void _editSkills() {
    final l = AppL10n.of(context)!;
    final all = [
      'Cleaning',
      'Repair',
      'Delivery',
      'Errands',
      'Moving',
      'Cooking',
      'Tutoring',
      'Tech',
      'Photography',
      'Painting',
      'Gardening',
      'Electrical',
      'Plumbing',
      'Carpentry',
      'Laundry',
      'Pet Care',
      'Baby Sitting',
      'Car Washing',
      'Beauty & Makeup',
      'Event Decoration',
    ];
    final selected = List<String>.from(_state.skills);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.profileEditSkills,
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: all.map((s) {
                final on = selected.contains(s);
                return GestureDetector(
                  onTap: () => setSheetState(() {
                    on ? selected.remove(s) : selected.add(s);
                  }),
                  child: Container(
                     padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: on ? T.primary : T.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: on ? T.primary : T.border),
                    ),
                    child: Text(s,
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: on ? Colors.white : T.text2)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _state.updateSkills(List.from(selected));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.profileSkillsUpdated)),
                  );
                },
                child: Text(l.profileSaveSkills),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _redeemCoins() {
    final l = AppL10n.of(context)!;
    final u = _state.user;
    if (u.coins <= 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.profileNoCoins,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          content: Text(l.profileNoCoinsBody,
              style: GoogleFonts.nunito(fontSize: 14, color: T.text2)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.actionOk,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.profileRedeemCoins,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: T.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on_rounded,
                size: 34, color: T.primary),
          ),
          const SizedBox(height: 8),
          Text(l.profileCoinsValue(u.coins),
              style: GoogleFonts.nunito(
                  fontSize: 20, fontWeight: FontWeight.w900, color: T.primary)),
          const SizedBox(height: 8),
          Text(l.profileCoinsCredited,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 13, color: T.text3)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.actionCancel,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              final coinsToRedeem = u.coins;
              final success = _state.redeemCoins(coinsToRedeem);
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          l.profileCoinsWillCredit(coinsToRedeem))),
                );
              }
            },
            child: Text(l.profileRedeemAll,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Tier ordering used to compute the next level and its localized name.
  static const List<String> _repTiers = [
    'new',
    'bronze',
    'silver',
    'gold',
    'pro'
  ];

  Color _repColor(String level) {
    switch (level) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFF9CA3AF);
      case 'gold':
        return const Color(0xFFF5A623);
      case 'pro':
        return T.primary;
      case 'new':
      default:
        return const Color(0xFF94A3B8); // grey
    }
  }

  String _repLevelName(AppL10n l, String level) {
    switch (level) {
      case 'bronze':
        return l.reputationLevelBronze;
      case 'silver':
        return l.reputationLevelSilver;
      case 'gold':
        return l.reputationLevelGold;
      case 'pro':
        return l.reputationLevelPro;
      case 'new':
      default:
        return l.reputationLevelNew;
    }
  }

  Widget _buildReputationCard(AppL10n l, ReputationModel rep) {
    final level = rep.level;
    final color = _repColor(level);
    final label = _repLevelName(l, level);
    final reliability = rep.reliability.clamp(0, 100).toDouble();
    final completed = rep.completedTasks;

    // Next tier name (localized) from the ordering, when not already at top.
    String? nextTierName;
    final idx = _repTiers.indexOf(level);
    if (idx >= 0 && idx < _repTiers.length - 1) {
      nextTierName = _repLevelName(l, _repTiers[idx + 1]);
    }

    // Progress toward the next level.
    final int? nextAt = rep.nextLevelAt;
    final bool atTop = nextAt == null || nextTierName == null;
    double progress = 1.0;
    if (!atTop && nextAt > 0) {
      progress = (completed / nextAt).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.military_tech_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.reputationYourLevel,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: T.text3)),
                  const SizedBox(height: 2),
                  Text(label,
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: color)),
                ]),
          ),
          // Reliability chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Text('${reliability.toStringAsFixed(0)}%',
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(l.reputationReliability,
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: T.text3)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        // Progress bar toward next level
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: T.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 8),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.reputationJobsDone(completed),
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: T.text2)),
              Text(
                  atTop
                      ? l.reputationTopLevel
                      : l.reputationJobsToNext(
                          completed, nextAt, nextTierName),
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: atTop ? color : T.text3)),
            ]),
        const SizedBox(height: 8),
        Text(l.reputationExplainer,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: T.text3)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final u = _state.user;
    final myAppCount = mockMyApplications.length.toString();
    final verifiedCount = _state.verificationStatuses.values.where((v) => v == 'verified').length;
    final isFullyVerified = verifiedCount == _state.verificationStatuses.length;

    return Scaffold(
      backgroundColor: T.bg,
      body: SingleChildScrollView(
          child: Column(children: [
        // ── Header ───────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [T.primary, T.primaryDark],
            ),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
          child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.profileMyProfile,
                            style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        GestureDetector(
                            onTap: () => _push(const SettingsScreen()),
                            child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.settings_outlined,
                                    color: Colors.white, size: 18))),
                      ]),
                  const SizedBox(height: 20),
                  Stack(clipBehavior: Clip.none, children: [
                    // Avatar — tap to change photo
                    GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 3),
                        ),
                        child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            backgroundImage: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                                ? NetworkImage(u.avatarUrl!)
                                : null,
                            child: u.avatarUrl == null || u.avatarUrl!.isEmpty
                                ? Text(initialFor(u.name),
                                    style: GoogleFonts.nunito(
                                        color: T.primary,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900))
                                : null),
                      ),
                    ),
                    // Camera icon — change avatar
                    Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: _showAvatarPicker,
                          child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: T.star,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt, size: 15, color: Colors.white)),
                        )),
                    // Pencil icon — edit profile
                    Positioned(
                        bottom: 2,
                        left: 2,
                        child: GestureDetector(
                          onTap: () => _push(const EditProfileScreen()),
                          child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: T.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.edit_rounded, size: 15, color: Colors.white)),
                        )),
                    if (isFullyVerified)
                      Positioned(
                          top: 0,
                          right: -4,
                          child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                  color: T.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.check, color: Colors.white, size: 14))),
                  ]),
                  const SizedBox(height: 14),
                  Text(u.name,
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(u.email,
                      style: GoogleFonts.nunito(
                          color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ...List.generate(
                        5,
                        (i) => Icon(Icons.star_rounded,
                            color:
                                i < u.rating.floor() ? T.star : Colors.white30,
                            size: 18)),
                    const SizedBox(width: 6),
                    Text('${u.rating} (${l.profileReviewsCount(u.totalReviews)})',
                        style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat('24', l.profileTasksDone),
                          Container(
                              width: 1, height: 30, color: Colors.white24),
                          _Stat(
                              '₹${mockEarnings.fold(0.0, (s, e) => s + e.net).toStringAsFixed(0)}',
                              l.profileEarned),
                          Container(
                              width: 1, height: 30, color: Colors.white24),
                          GestureDetector(
                            onTap: _redeemCoins,
                            child: _Stat('${u.coins}', l.statCoins),
                          ),
                          Container(
                              width: 1, height: 30, color: Colors.white24),
                          _Stat('7', l.profileApplied),
                        ]),
                  ),
                ]),
              )),
        ),
        const SizedBox(height: 16),

        // ── Content ──────────────────────────────────────
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Reputation / level card (own tasker reputation)
              if (u.reputation != null) ...[
                _buildReputationCard(l, u.reputation!),
                const SizedBox(height: 16),
              ],

              // Quick stats card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.card(),
                child: Row(children: [
                  Expanded(
                      child: _QuickStat(
                    icon: Icons.trending_up_rounded,
                    iconColor: T.green,
                    iconBg: T.greenLight,
                    label: l.profileCompletion,
                    value: '96%',
                  )),
                  Container(width: 1, height: 40, color: T.border),
                  Expanded(
                      child: _QuickStat(
                    icon: Icons.speed_rounded,
                    iconColor: T.blue,
                    iconBg: T.blueLight,
                    label: l.profileAvgResponse,
                    value: '12 min',
                  )),
                  Container(width: 1, height: 40, color: T.border),
                  Expanded(
                      child: _QuickStat(
                    icon: Icons.calendar_month_rounded,
                    iconColor: T.primary,
                    iconBg: T.primaryLight,
                    label: l.profileMemberSince,
                    value: 'Jan 2024',
                  )),
                ]),
              ),
              const SizedBox(height: 16),

              // About me
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: AppTheme.card(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.profileAboutMe,
                                style: GoogleFonts.nunito(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: T.text1)),
                            GestureDetector(
                              onTap: _editBio,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: T.primaryLight,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(l.profileEdit,
                                    style: GoogleFonts.nunito(
                                        color: T.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                      const SizedBox(height: 10),
                      Text(
                          _state.bio,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: T.text2,
                              fontWeight: FontWeight.w500,
                              height: 1.6)),
                    ]),
              ),
              const SizedBox(height: 16),

              // My Skills
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.profileMySkills,
                        style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: T.text1)),
                    GestureDetector(
                      onTap: _editSkills,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: T.primaryLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(l.profileEdit,
                            style: GoogleFonts.nunito(
                                color: T.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
              const SizedBox(height: 10),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _state.skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: T.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: T.primary.withValues(alpha: .3))),
                            child: Text(s,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: T.primary)),
                          ))
                      .toList()),
              const SizedBox(height: 16),

              // My Work (portfolio preview strip)
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.profileMyWork,
                        style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: T.text1)),
                    GestureDetector(
                      onTap: _openPortfolio,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: T.primaryLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_portfolio.isEmpty ? l.profileAdd : l.profileViewAll,
                            style: GoogleFonts.nunito(
                                color: T.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
              const SizedBox(height: 10),
              _PortfolioStrip(items: _portfolio, onOpen: _openPortfolio),
              const SizedBox(height: 16),

              // ── Menu Sections ──────────────────────────
              _MenuSec(l.profileSecAccount, [
                _MI(Icons.person_outline, l.profileEditProfile,
                    onTap: () => _push(const EditProfileScreen())),
                _MI(Icons.badge_outlined, l.profileVerificationDocuments,
                    onTap: () => _push(const VerificationScreen())),
                _MI(Icons.account_balance, l.profileBankPayment,
                    onTap: () => _push(const BankPaymentScreen())),
              ]),
              const SizedBox(height: 14),
              _MenuSec(l.profileSecWork, [
                _MI(Icons.assignment_outlined, l.profileMyApplications,
                    badge: myAppCount,
                    onTap: () => _push(const MyApplicationsScreen())),
                _MI(Icons.event_available_outlined, l.availability,
                    subtitle: _availabilitySummary ?? l.profileSetWorkingHours,
                    onTap: _openAvailability),
                _MI(Icons.photo_library_outlined, l.profileWorkPortfolio,
                    subtitle: _portfolio.isEmpty
                        ? l.profileShowcaseWork
                        : l.profilePhotoCount(_portfolio.length),
                    onTap: _openPortfolio),
                _MI(Icons.check_circle_outline, l.profileCompletedTasks,
                    onTap: () => _push(const CompletedTasksScreen())),
                _MI(Icons.star_outline, l.profileMyReviews,
                    onTap: () => _push(const MyReviewsScreen())),
                _MI(Icons.currency_rupee, l.profileEarningsPayouts,
                    onTap: () => _push(const WalletScreen())),
              ]),
              const SizedBox(height: 14),
              _MenuSec(l.profileSecSupportLegal, [
                _MI(Icons.help_outline, l.profileHelpSupport,
                    onTap: () => _push(const HelpSupportScreen())),
                _MI(Icons.description_outlined, l.profileTerms,
                    onTap: () => _openLink(_termsUrl)),
                _MI(Icons.privacy_tip_outlined, l.profilePrivacy,
                    onTap: () => _openLink(_privacyUrl)),
                _MI(Icons.star_rate_outlined, l.profileRateUs,
                    onTap: () => _openLink(_playStoreUrl)),
              ]),
              const SizedBox(height: 14),

              // Sign Out
              Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: AppTheme.card(),
                  child: _MI(Icons.logout, l.profileSignOut, destruct: true,
                      onTap: () async {
                    await Session.clear();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  })),
              const SizedBox(height: 20),

              // App version
              Center(
                child: Column(children: [
                  Text('TaskTeddy Tasker',
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: T.text3)),
                  const SizedBox(height: 2),
                  Text(l.profileVersion('1.0.0'),
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: T.text3.withValues(alpha: .6))),
                ]),
              ),
              const SizedBox(height: 28),
            ])),
      ])),
    );
  }
}

class _Stat extends StatelessWidget {
  final String v, l;
  const _Stat(this.v, this.l);
  @override
  Widget build(BuildContext ctx) => Column(children: [
        Text(v,
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900)),
        Text(l,
            style: GoogleFonts.nunito(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]);
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  const _QuickStat({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext ctx) => Column(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 7),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: T.text1)),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: T.text3)),
      ]);
}

class _PortfolioStrip extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onOpen;
  const _PortfolioStrip({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext ctx) {
    final l = AppL10n.of(ctx)!;
    if (items.isEmpty) {
      return GestureDetector(
        onTap: onOpen,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: T.border),
          ),
          child: Column(children: [
            const Icon(Icons.add_photo_alternate_outlined,
                color: T.primary, size: 30),
            const SizedBox(height: 8),
            Text(l.profileAddPhotosWork,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.text2)),
            const SizedBox(height: 2),
            Text(l.profilePortfolioHelps,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 12, color: T.text3)),
          ]),
        ),
      );
    }
    final preview = items.take(6).toList();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: preview.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final url =
              ApiService.resolveMediaUrl(preview[i]['image_url']?.toString());
          return GestureDetector(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 96,
                height: 96,
                child: url == null
                    ? Container(color: T.primaryLight)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: T.primaryLight,
                          child: const Icon(Icons.broken_image_outlined,
                              color: T.text3),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuSec extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MenuSec(this.title, this.items);
  @override
  Widget build(BuildContext ctx) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title.toUpperCase(), style: AppTheme.eyebrow())),
        Container(
            decoration: AppTheme.card(),
            clipBehavior: Clip.antiAlias,
            child: Column(
                children: List.generate(items.length * 2 - 1, (i) {
              if (i.isOdd) {
                return const Divider(height: 1, indent: 56, endIndent: 14);
              }
              return items[i ~/ 2];
            }))),
      ]);
}

class _MI extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final String? subtitle;
  final bool destruct, hi;
  final VoidCallback onTap;
  const _MI(this.icon, this.title,
      {this.badge,
      this.subtitle,
      this.destruct = false,
      this.hi = false,
      required this.onTap});
  @override
  Widget build(BuildContext ctx) => Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: destruct
                          ? T.redLight
                          : hi
                              ? T.greenLight
                              : T.primaryLight,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon,
                        size: 20,
                        color: destruct
                            ? T.red
                            : hi
                                ? T.green
                                : T.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: destruct ? T.red : T.text1)),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: T.text3)),
                        ],
                      ])),
                  if (badge != null)
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: T.primaryLight,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(badge!,
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: T.primary)))
                  else if (!destruct)
                    const Icon(Icons.chevron_right, color: T.text3, size: 22),
                ]))),
      );
}

