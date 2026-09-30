import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/tasker_state.dart';
import '../l10n/app_localizations.dart';

/// In-app notification center, styled to the tasker "work console" look:
/// compact rows, a per-type leading icon in a tinted chip, unread rows
/// highlighted, relative timestamps, pull-to-refresh, mark-all-read, and
/// swipe-to-delete.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ApiService.getNotifications(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  int get _unread => _items.where((n) => n['is_read'] != true).length;

  Future<void> _markAllRead() async {
    // Optimistic: flip all rows locally, then persist.
    setState(() {
      _items = _items.map((n) => {...n, 'is_read': true}).toList();
    });
    try {
      await ApiService.markAllNotificationsRead();
    } catch (_) {
      // Refresh to reconcile if the server rejected it.
      _load();
    }
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['is_read'] == true) return;
    final id = n['id']?.toString();
    if (id == null) return;
    setState(() {
      final i = _items.indexOf(n);
      if (i != -1) _items[i] = {...n, 'is_read': true};
    });
    try {
      await ApiService.markNotificationRead(id);
    } catch (_) {}
  }

  /// Mark read and deep-link to the relevant screen/tab based on type.
  Future<void> _onTap(Map<String, dynamic> n) async {
    await _markRead(n);
    if (!mounted) return;
    final type = (n['type'] ?? '').toString();
    switch (type) {
      case 'chat':
        Navigator.pushNamed(context, '/messages');
        break;
      case 'task_available':
      case 'bid':
        Navigator.pop(context); // back to the shell
        TaskerState().requestTab(1); // Browse
        break;
      case 'task':
      case 'applied':
        Navigator.pop(context);
        TaskerState().requestTab(2); // Applied
        break;
      default:
        break; // announcements / general — nothing to open
    }
  }

  Future<void> _delete(Map<String, dynamic> n) async {
    final id = n['id']?.toString();
    setState(() => _items.remove(n));
    if (id == null) return;
    try {
      await ApiService.deleteNotification(id);
    } catch (_) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: T.primary))
                : _error != null
                    ? _buildError()
                    : _items.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: T.primary,
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => _buildRow(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l = AppL10n.of(context)!;
    return GradientHeader(
      title: l.notifTitle,
      subtitle: _unread > 0 ? l.notifUnreadCount(_unread) : l.notifAllCaughtUp,
      actions: [
        if (_unread > 0)
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all_rounded,
                color: Colors.white, size: 18),
            label: Text(
              l.notifMarkAll,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(Map<String, dynamic> n) {
    final l = AppL10n.of(context)!;
    final type = (n['type'] ?? '').toString();
    final title = (n['title'] ?? '').toString();
    final body = (n['body'] ?? '').toString();
    final isRead = n['is_read'] == true;
    final created = DateTime.tryParse(n['created_at']?.toString() ?? '');
    final meta = _typeMeta(type);

    return Dismissible(
      key: ValueKey(n['id'] ?? n.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: T.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: T.red),
      ),
      onDismissed: (_) => _delete(n),
      child: GestureDetector(
        onTap: () => _onTap(n),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : T.primaryLight.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: isRead ? T.border : T.primary.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(meta.icon, color: meta.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w700,
                              color: T.text1,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          const StatusDot(color: T.primary, size: 7, glow: false),
                        ],
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: T.text2,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(l, created),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: T.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final l = AppL10n.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: FriendlyState(
            icon: Icons.notifications_none_rounded,
            title: l.notifNoNotifications,
            body: l.notifEmptyBody,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final l = AppL10n.of(context)!;
    return FriendlyState(
      icon: Icons.cloud_off_rounded,
      iconColor: T.text3,
      title: _error ?? l.notifSomethingWrong,
      action: ElevatedButton(
        onPressed: _load,
        child: Text(l.actionRetry,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      ),
    );
  }

  String _relativeTime(AppL10n l, DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return l.notifJustNow;
    if (d.inMinutes < 60) return l.timeMinutesAgo(d.inMinutes);
    if (d.inHours < 24) return l.timeHoursAgo(d.inHours);
    if (d.inDays < 7) return l.timeDaysAgo(d.inDays);
    final w = d.inDays ~/ 7;
    return l.timeWeeksAgo(w);
  }

  /// Maps a notification `type` to a leading icon + tint.
  _NotifMeta _typeMeta(String type) {
    switch (type.toLowerCase().trim()) {
      case 'job':
      case 'lead':
        return const _NotifMeta(Icons.work_outline_rounded, T.blue);
      case 'booking':
        return const _NotifMeta(Icons.event_available_rounded, T.primary);
      case 'task':
        return const _NotifMeta(Icons.assignment_turned_in_rounded, T.blue);
      case 'message':
      case 'chat':
        return const _NotifMeta(Icons.chat_bubble_outline_rounded, T.teal);
      case 'payment':
      case 'earning':
        return const _NotifMeta(Icons.payments_rounded, T.online);
      case 'withdrawal':
      case 'payout':
        return const _NotifMeta(Icons.account_balance_rounded, T.pending);
      case 'review':
      case 'rating':
        return const _NotifMeta(Icons.star_rounded, T.star);
      case 'promo':
      case 'offer':
        return const _NotifMeta(Icons.local_offer_rounded, T.star);
      case 'system':
        return const _NotifMeta(Icons.info_outline_rounded, T.offline);
      default:
        return const _NotifMeta(Icons.notifications_none_rounded, T.primary);
    }
  }
}

class _NotifMeta {
  final IconData icon;
  final Color color;
  const _NotifMeta(this.icon, this.color);
}
