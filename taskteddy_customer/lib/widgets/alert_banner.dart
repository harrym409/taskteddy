import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../theme/theme.dart';
import '../screens/tasks.dart';
import '../screens/profile.dart';

/// Root navigator key so the banner can route from above the Navigator.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class _AlertData {
  final String title;
  final String body;
  final String emoji;
  final String type;
  final String relatedId;
  const _AlertData(this.title, this.body, this.emoji, this.type, this.relatedId);

  factory _AlertData.fromMap(Map<String, dynamic> m) => _AlertData(
        (m['title'] ?? '').toString(),
        (m['body'] ?? '').toString(),
        (m['emoji'] ?? '').toString(),
        (m['notif_type'] ?? 'general').toString(),
        (m['related_id'] ?? '').toString(),
      );
}

/// Wraps the app and shows a transient heads-up banner (a few seconds) whenever
/// a live notification arrives over the realtime socket. Tapping it deep-links.
class AlertBannerHost extends StatefulWidget {
  final Widget child;
  const AlertBannerHost({super.key, required this.child});

  @override
  State<AlertBannerHost> createState() => _AlertBannerHostState();
}

class _AlertBannerHostState extends State<AlertBannerHost> {
  StreamSubscription? _sub;
  Timer? _dismiss;
  _AlertData? _current;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _sub = RealtimeService().events.listen(_onEvent);
  }

  void _onEvent(Map<String, dynamic> e) {
    if (e['type'] != 'alert' || e['alert'] is! Map) return;
    if (!mounted) return;
    setState(() {
      _current = _AlertData.fromMap(Map<String, dynamic>.from(e['alert'] as Map));
      _visible = true;
    });
    _dismiss?.cancel();
    _dismiss = Timer(const Duration(seconds: 4), _hide);
  }

  void _hide() {
    if (!mounted) return;
    setState(() => _visible = false);
    Timer(const Duration(milliseconds: 320), () {
      if (mounted && !_visible) setState(() => _current = null);
    });
  }

  Future<void> _handleTap() async {
    final a = _current;
    if (a == null) return;
    _dismiss?.cancel();
    _hide();
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    switch (a.type) {
      case 'verify_email':
        nav.push(MaterialPageRoute(builder: (_) => const ClaimBonusScreen()));
        break;
      case 'bonus':
        nav.push(MaterialPageRoute(builder: (_) => const TaskTeddyBonusScreen()));
        break;
      case 'chat':
        nav.pushNamed('/messages');
        break;
      case 'task':
      case 'bid':
      case 'task_available':
        if (a.relatedId.isNotEmpty) {
          final task = await ApiService.getTaskById(a.relatedId);
          if (task != null) {
            nav.push(
                MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -1.4),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: _banner(_current!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _banner(_AlertData a) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: C.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(a.emoji.isEmpty ? '🔔' : a.emoji,
                        style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(a.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: C.text1)),
                        if (a.body.isNotEmpty)
                          Text(a.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: C.text3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: C.text3),
                ],
              ),
            ),
          ),
        ),
      );
}
