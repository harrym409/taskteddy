import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../theme/category_icons.dart';
import '../models/models.dart';
import 'service_detail.dart';
import 'tasks.dart';
import 'profile.dart';

/// Localized, human-readable label for a booking status wire value.
String bookingStatusLabel(AppL10n l, String status) {
  switch (status) {
    case 'pending':
      return l.bookingStatusPending;
    case 'confirmed':
      return l.bookingStatusConfirmed;
    case 'completed':
      return l.bookingStatusCompleted;
    case 'cancelled':
      return l.bookingStatusCancelled;
    default:
      return status.toUpperCase();
  }
}

// ══════════════════════════════════════════════════════════
//  BOOKINGS SCREEN
// ══════════════════════════════════════════════════════════

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsState();
}

class _BookingsState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    final bookings = await ApiService.getBookings();
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _loading = false;
    });
  }

  Future<void> _cancelBooking(BookingModel b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppL10n.of(context)!.bookingCancelTitle,
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          AppL10n.of(context)!.bookingCancelBody(b.service.name,
              DateFormat('d MMM, hh:mm a').format(b.scheduledAt)),
          style: GoogleFonts.poppins(fontSize: 13, color: C.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppL10n.of(context)!.bookingKeepIt,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: C.text3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppL10n.of(context)!.bookingCancelConfirm,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: C.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || b.remoteId == null) return;

    try {
      final res = await ApiService.cancelBooking(b.remoteId!);
      if (!mounted) return;
      final refunded = (res['refunded'] as num?)?.toDouble() ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              refunded > 0
                  ? AppL10n.of(context)!
                      .bookingCancelledRefund(refunded.toInt())
                  : AppL10n.of(context)!.bookingCancelled,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: refunded > 0 ? C.green : C.text1,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: C.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rescheduleBooking(BookingModel b) async {
    if (b.remoteId == null) return;
    final today = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day + i));
    const slotHours = [9, 11, 13, 15, 17, 19];
    int dayIndex = 0;
    int? slotHour;

    String slotLabel(int h) =>
        '${h > 12 ? h - 12 : h}:00 ${h >= 12 ? 'PM' : 'AM'}';
    bool slotDisabled(int h) => dayIndex == 0 && DateTime.now().hour >= h - 1;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppL10n.of(context)!.bookingRescheduleTitle(b.service.name),
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: C.text1)),
              const SizedBox(height: 14),
              SizedBox(
                height: 68,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  itemBuilder: (_, i) {
                    final d = days[i];
                    final sel = i == dayIndex;
                    final label = i == 0
                        ? AppL10n.of(context)!.dateToday
                        : i == 1
                            ? AppL10n.of(context)!.dateTomorrowShort
                            : DateFormat('EEE').format(d);
                    return GestureDetector(
                      onTap: () => setSheet(() {
                        dayIndex = i;
                        if (slotHour != null && slotDisabled(slotHour!)) {
                          slotHour = null;
                        }
                      }),
                      child: Container(
                        width: 58,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: sel ? C.primary : C.bg,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: sel ? C.primary : C.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(label,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : C.text3)),
                            Text('${d.day}',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: sel ? Colors.white : C.text1)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slotHours.map((h) {
                  final sel = slotHour == h;
                  final dis = slotDisabled(h);
                  return GestureDetector(
                    onTap: dis ? null : () => setSheet(() => slotHour = h),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: dis
                            ? C.divider
                            : sel
                                ? C.primary
                                : C.bg,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: sel ? C.primary : C.border),
                      ),
                      child: Text(slotLabel(h),
                          style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: dis
                                  ? C.text3
                                  : sel
                                      ? Colors.white
                                      : C.text2)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  onPressed: () {
                    if (slotHour == null) return;
                    final d = days[dayIndex];
                    Navigator.pop(
                        ctx, DateTime(d.year, d.month, d.day, slotHour!));
                  },
                  child: Text(AppL10n.of(context)!.bookingConfirmNewTime,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null) return;
    try {
      await ApiService.rescheduleBooking(b.remoteId!, picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppL10n.of(context)!.bookingRescheduledTo(
                  DateFormat('d MMM, hh:mm a').format(picked)),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: C.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: C.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: Text(
            AppL10n.of(context)!.bookingsTitle,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          automaticallyImplyLeading: Navigator.of(context).canPop(),
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [C.primaryDark, C.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: C.primary,
                  unselectedLabelColor: Colors.white.withValues(alpha: .95),
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: AppL10n.of(context)!.bookingsTabUpcoming),
                    Tab(text: AppL10n.of(context)!.bookingsTabCompleted),
                    Tab(text: AppL10n.of(context)!.bookingsTabCancelled)
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: C.primary))
            : RefreshIndicator(
                onRefresh: _loadBookings,
                color: C.primary,
                child: TabBarView(controller: _tab, children: [
                  _BList(
                    _bookings
                        .where((b) =>
                            b.status == 'confirmed' || b.status == 'pending')
                        .toList(),
                    onCancel: _cancelBooking,
                    onReschedule: _rescheduleBooking,
                  ),
                  _BList(
                      _bookings.where((b) => b.status == 'completed').toList()),
                  _BList(
                      _bookings.where((b) => b.status == 'cancelled').toList()),
                ]),
              ),
      );
}

class _BList extends StatelessWidget {
  final List<BookingModel> items;
  final Future<void> Function(BookingModel)? onCancel;
  final Future<void> Function(BookingModel)? onReschedule;
  const _BList(this.items, {this.onCancel, this.onReschedule});
  @override
  Widget build(BuildContext ctx) {
    if (items.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 26),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.border),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: C.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.event_note_outlined,
                  color: C.primary, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              AppL10n.of(ctx)!.bookingsEmptyTitle,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: C.text1),
            ),
            const SizedBox(height: 2),
            Text(
              AppL10n.of(ctx)!.bookingsEmptyBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w500, color: C.text3),
            ),
          ]),
        ),
      );
    }
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => _BookingCard(
            booking: items[i],
            onCancel: onCancel,
            onReschedule: onReschedule));
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel b;
  final Future<void> Function(BookingModel)? onCancel;
  final Future<void> Function(BookingModel)? onReschedule;
  const _BookingCard(
      {required BookingModel booking, this.onCancel, this.onReschedule})
      : b = booking;

  bool get _upcoming => b.status == 'pending' || b.status == 'confirmed';

  void _showDetails(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CategoryIconChip(
                  category: b.service.category, size: 44, radius: 12),
              const SizedBox(width: 10),
              Expanded(
                child: Text(b.service.name,
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: C.text1)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: C.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(bookingStatusLabel(AppL10n.of(ctx)!, b.status),
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: C.primaryDark)),
              ),
            ]),
            const SizedBox(height: 16),
            _detailRow(AppL10n.of(ctx)!.bookingDetailId, b.bookingId),
            _detailRow(AppL10n.of(ctx)!.bookingDetailScheduled,
                DateFormat('EEE, d MMM yyyy • hh:mm a').format(b.scheduledAt)),
            _detailRow(AppL10n.of(ctx)!.bookingDetailAddress, b.address),
            if (b.notes.isNotEmpty)
              _detailRow(AppL10n.of(ctx)!.bookingDetailNotes, b.notes),
            _detailRow(AppL10n.of(ctx)!.bookingDetailAmount,
                '₹${b.amount.toInt()}'),
            _detailRow(
                AppL10n.of(ctx)!.bookingDetailPayment,
                b.paidWithWallet
                    ? AppL10n.of(ctx)!.bookingPaidFromWallet
                    : AppL10n.of(ctx)!.sdPayAfterService),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: C.text3)),
            ),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: C.text1)),
            ),
          ],
        ),
      );
  Color get _sc {
    switch (b.status) {
      case 'confirmed':
        return C.green;
      case 'pending':
        return C.yellow;
      case 'completed':
        return C.teal;
      default:
        return C.red;
    }
  }

  @override
  Widget build(BuildContext ctx) => GestureDetector(
      onTap: () => _showDetails(ctx),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CategoryIconChip(
              category: b.service.category, size: 52, radius: 14),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(b.service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: C.text1)),
                Text(AppL10n.of(ctx)!.sdBookingId(b.bookingId),
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: C.text3,
                        fontWeight: FontWeight.w500)),
              ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${b.amount.toInt()}',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: C.primary)),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _sc.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(bookingStatusLabel(AppL10n.of(ctx)!, b.status),
                    style: GoogleFonts.poppins(
                        fontSize: 9, fontWeight: FontWeight.w700, color: _sc))),
          ]),
        ]),
        const Divider(height: 18, color: C.divider),
        Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today, size: 13, color: C.text3),
          ),
          const SizedBox(width: 8),
          Text(DateFormat('dd MMM yyyy, hh:mm a').format(b.scheduledAt),
              style: GoogleFonts.poppins(
                  fontSize: 12, color: C.text3, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 13, color: C.text3),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(b.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: C.text3,
                      fontWeight: FontWeight.w500))),
        ]),
        if (b.status == 'completed') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(service: b.service),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.primary,
                side: BorderSide(color: C.primary.withValues(alpha: .45)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: Text(AppL10n.of(ctx)!.bookingBookAgain,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        if (_upcoming && (onCancel != null || onReschedule != null)) ...[
          const SizedBox(height: 12),
          Row(children: [
            if (onReschedule != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onReschedule!(b),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.primary,
                    side:
                        BorderSide(color: C.primary.withValues(alpha: .45)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.schedule_rounded, size: 16),
                  label: Text(AppL10n.of(ctx)!.bookingReschedule,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            if (onReschedule != null && onCancel != null)
              const SizedBox(width: 10),
            if (onCancel != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onCancel!(b),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.red,
                    side: BorderSide(color: C.red.withValues(alpha: .4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(AppL10n.of(ctx)!.cancel,
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ],
      ])));
}

// ══════════════════════════════════════════════════════════
//  NOTIFICATIONS
// ══════════════════════════════════════════════════════════

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotifModel> _items = [];
  bool _loading = true;

  int get _unread => _items.where((n) => !n.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final fallbackTitle = AppL10n.of(context)!.notificationFallbackTitle;
    if (mounted && _items.isEmpty) setState(() => _loading = true);
    try {
      // Outer timeout guards the whole fetch (incl. token read), so the
      // spinner can never hang even if something upstream stalls.
      final rows = await ApiService.getNotifications().timeout(
        const Duration(seconds: 15),
        onTimeout: () => <Map<String, dynamic>>[],
      );
      final next = rows.map((row) {
        final rawId = row['id']?.toString();
        return NotifModel(
          id: int.tryParse(rawId ?? '') ?? (rawId?.hashCode.abs() ?? 0),
          remoteId: rawId,
          title: row['title']?.toString() ?? fallbackTitle,
          body: row['body']?.toString() ?? '',
          emoji: row['emoji']?.toString() ?? '',
          type: row['type']?.toString() ?? 'general',
          relatedId: row['related_id']?.toString(),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
              DateTime.now(),
          isRead: row['is_read'] == true,
        );
      }).toList();
      if (!mounted) return;
      setState(() => _items = next);
    } finally {
      // Always clear the loading state so the screen can never hang on the
      // spinner, even if the fetch times out or something above throws.
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    if (_unread == 0) return;
    // Optimistic update — the badge/list flip instantly.
    setState(() => _items = _items.map((n) => n.copyWith(isRead: true)).toList());
    await ApiService.markAllNotificationsRead();
  }

  Future<void> _markOneRead(NotifModel item) async {
    if (item.isRead || item.remoteId == null) return;
    setState(() {
      _items = [
        for (final n in _items)
          n.remoteId == item.remoteId ? n.copyWith(isRead: true) : n,
      ];
    });
    await ApiService.markNotificationRead(item.remoteId!);
  }

  /// Tapping an alert marks it read and deep-links to the relevant screen
  /// based on its type + related id.
  Future<void> _onNotifTap(NotifModel n) async {
    await _markOneRead(n);
    if (!mounted) return;
    final id = n.relatedId;
    switch (n.type) {
      case 'verify_email':
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ClaimBonusScreen()));
        break;
      case 'bonus':
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TaskTeddyBonusScreen()));
        break;
      case 'chat':
        await Navigator.pushNamed(context, '/messages');
        break;
      case 'task':
      case 'bid':
      case 'task_available':
        if (id != null && id.isNotEmpty) {
          final task = await ApiService.getTaskById(id);
          if (!mounted || task == null) return;
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
        }
        break;
      default:
        break; // announcements / general — nothing to open
    }
  }

  Future<void> _delete(NotifModel item) async {
    setState(() =>
        _items = _items.where((n) => n.remoteId != item.remoteId).toList());
    if (item.remoteId != null) {
      await ApiService.deleteNotification(item.remoteId!);
    }
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: Text(AppL10n.of(ctx)!.notificationsTitle),
          actions: [
            if (_unread > 0)
              TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all_rounded,
                    color: Colors.white, size: 18),
                label: Text(AppL10n.of(ctx)!.notificationsMarkAllRead,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: C.primary))
            : _items.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: C.primary,
                    child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          return Dismissible(
                            key: ValueKey(n.remoteId ?? n.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _delete(n),
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: C.redLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: C.red),
                            ),
                            child: _NotifCard(
                              n: n,
                              onTap: () => _onNotifTap(n),
                            ),
                          );
                        }),
                  ),
      );

  Widget _emptyState() => LayoutBuilder(
        builder: (ctx, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: C.primaryLight,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.notifications_none_rounded,
                        size: 42, color: C.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(AppL10n.of(ctx)!.notificationsEmptyTitle,
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: C.text1)),
                  const SizedBox(height: 6),
                  Text(AppL10n.of(ctx)!.notificationsEmptyBody,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: C.text3)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _NotifCard extends StatelessWidget {
  final NotifModel n;
  final VoidCallback? onTap;
  const _NotifCard({required this.n, this.onTap});
  @override
  Widget build(BuildContext ctx) {
    final tint = notifTypeColor(n.type);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: n.isRead ? Colors.white : C.primaryLight.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: n.isRead ? C.border : C.primary.withValues(alpha: .28)),
            boxShadow: n.isRead
                ? null
                : [
                    BoxShadow(
                        color: C.primary.withValues(alpha: .06),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: tint.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(notifTypeIcon(n.type), color: tint, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(n.title,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: C.text1)),
                if (n.body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: C.text2,
                          fontWeight: FontWeight.w500,
                          height: 1.4)),
                ],
                const SizedBox(height: 5),
                Text(_fmtT(AppL10n.of(ctx)!, n.createdAt),
                    style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: C.text3,
                        fontWeight: FontWeight.w600)),
              ])),
          if (!n.isRead)
            Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 6),
                decoration: const BoxDecoration(
                    color: C.accent2, shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  String _fmtT(AppL10n l, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return l.timeJustNow;
    if (d.inMinutes < 60) return l.timeMinutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.timeHoursAgo(d.inHours);
    if (d.inDays < 7) return l.timeDaysAgo(d.inDays);
    return DateFormat('d MMM').format(t);
  }
}
