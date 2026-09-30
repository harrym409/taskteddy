import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'home.dart';
import 'tasks.dart';
import 'profile.dart';
import '../services/realtime_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<MainShell> createState() => _ShellState();
}

class _ShellState extends State<MainShell> {
  late int _i;
  static const _tabCount = 5;
  int _activeCount = 0; // in-progress jobs → badge on the Active tab
  Timer? _countTimer;
  StreamSubscription? _rtSub;

  List<Widget> get _screens => [
        const HomeScreen(),
        // "Tasks" tab shows only open tasks (still awaiting a tasker).
        // Distinct keys are REQUIRED: both tabs are MyTasksScreen, so without
        // them Flutter reuses one State across configs and the TabController
        // keeps the wrong tab count (breaks the Done tab).
        const MyTasksScreen(
            key: ValueKey('tasks-open'), sections: [TaskSection.open]),
        // After a successful post, jump to the Tasks tab (rebuilt fresh so the
        // new task appears) instead of a dead-end pop.
        PostTaskScreen(onPosted: () => setState(() => _i = 1)),
        // "Active" tab shows in-progress jobs plus finished ones
        // (replaces the old service Bookings tab).
        const MyTasksScreen(
            key: ValueKey('tasks-active-done'),
            sections: [TaskSection.active, TaskSection.done]),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _i = widget.initialIndex.clamp(0, _tabCount - 1);
    RealtimeService().start(); // live bid updates on task detail
    _loadActiveCount();
    _countTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _loadActiveCount());
    // A bid accepted / task moving forward changes the active count — refresh.
    _rtSub = RealtimeService().events.listen((_) => _loadActiveCount());
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    _rtSub?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveCount() async {
    try {
      final tasks = await ApiService.getTasks();
      if (!mounted) return;
      final n = tasks
          .where((t) =>
              t.status == TaskStatus.assigned ||
              t.status == TaskStatus.inProgress)
          .length;
      if (n != _activeCount) setState(() => _activeCount = n);
    } catch (_) {
      // Best-effort badge; leave the last value on failure.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        body: _screens[_i],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                  color: C.border.withValues(alpha: 0.5), width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: SizedBox(
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _navButton(0)),
                        Expanded(child: _navButton(1)),
                        const SizedBox(width: 72),
                        Expanded(child: _navButton(3)),
                        Expanded(child: _navButton(4)),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -1),
                      child: _navButton(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _navButton(int i) => _NavBtn(
        icon: _navIcons[i],
        activeIcon: _navIconsActive[i],
        label: _navLabels(context)[i],
        active: _i == i,
        center: i == 2,
        badge: i == 3 ? _activeCount : 0, // Active tab count
        onTap: () => _onTapTab(i),
      );

  void _onTapTab(int i) {
    // Tapping the Home tab again while already on Home refreshes it.
    if (i == _i) {
      if (i == 0) homeTabRetap.value++;
      return;
    }
    setState(() => _i = i);
    _loadActiveCount();
  }

  static const _navIcons = [
    Icons.home_outlined,
    Icons.assignment_outlined,
    Icons.add_box_outlined,
    Icons.bolt_outlined,
    Icons.person_outline,
  ];

  static const _navIconsActive = [
    Icons.home,
    Icons.assignment,
    Icons.add_box,
    Icons.bolt,
    Icons.person,
  ];

  List<String> _navLabels(BuildContext context) {
    final t = AppL10n.of(context)!;
    return [
      t.navHome,
      t.navTasks,
      t.navPost,
      t.navActive,
      t.navProfile,
    ];
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool center;
  final int badge;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.center,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: center
            ? SizedBox(
                width: 68,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: active ? C.primaryDark : C.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: C.primary.withValues(alpha: .35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        active ? activeIcon : icon,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: C.primary,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: active
                                ? C.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            active ? activeIcon : icon,
                            size: 23,
                            color: active ? C.primary : C.text3,
                          ),
                        ),
                        if (badge > 0)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 18),
                              decoration: BoxDecoration(
                                color: C.accent2,
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  badge > 99 ? '99+' : '$badge',
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
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? C.primary : C.text3,
                      ),
                    ),
                  ],
                ),
              ),
      );
}
