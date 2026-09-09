import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';
import 'dashboard.dart';
import 'browse.dart';
import 'profile.dart';
import 'wallet.dart';
import '../services/tasker_state.dart';
import '../services/realtime_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _ShellState();
}

class _ShellState extends State<MainShell> {
  int _idx = 0;
  final TaskerState _state = TaskerState();

  final List<Widget> _screens = const [
    DashboardScreen(),
    BrowseTasksScreen(),
    MyApplicationsScreen(embedded: true),
    WalletScreen(),
    ProfileScreen(),
  ];

  StreamSubscription? _rtSub;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
    RealtimeService().start(); // live task/bid updates
    // Bridge live "applications changed" pushes to the refresh hub so the
    // Applied tab reloads instantly when a bid is accepted/rejected.
    _rtSub = RealtimeService().events.listen((e) {
      if (e['type'] == 'applications.changed') {
        _state.notifyApplicationsChanged();
      }
    });
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  // Honour a tab-switch request from anywhere (e.g. "View My Applications").
  void _onStateChange() {
    final req = _state.requestedTab;
    if (req >= 0 && req != _idx && mounted) {
      _state.consumeTabRequest();
      setState(() => _idx = req);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: T.primary,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: IndexedStack(index: _idx, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: T.border)),
            boxShadow: [
              BoxShadow(
                color: T.primary.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: l.navHome,
                    active: _idx == 0,
                    onTap: () => setState(() => _idx = 0),
                  ),
                  _NavItem(
                    icon: Icons.search_outlined,
                    activeIcon: Icons.search_rounded,
                    label: l.navBrowse,
                    active: _idx == 1,
                    onTap: () => setState(() => _idx = 1),
                  ),
                  _NavItem(
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment_rounded,
                    label: l.navApplied,
                    active: _idx == 2,
                    onTap: () => setState(() => _idx = 2),
                  ),
                  _NavItem(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet_rounded,
                    label: l.navEarnings,
                    active: _idx == 3,
                    onTap: () => setState(() => _idx = 3),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: l.navProfile,
                    active: _idx == 4,
                    onTap: () => setState(() => _idx = 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: active ? T.primaryLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    color: active ? T.primary : T.text3,
                    size: 22,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: T.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight:
                    active ? FontWeight.w800 : FontWeight.w600,
                color: active ? T.primary : T.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
