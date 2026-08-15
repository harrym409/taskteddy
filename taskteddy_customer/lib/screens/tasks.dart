import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../theme/category_icons.dart';
import '../models/models.dart';
import '../widgets/error_retry.dart';
import '../widgets/level_chip.dart';
import '../widgets/verified_badge.dart';
import '../widgets/safety_actions.dart';
import 'messages.dart';

/// First letter for an avatar fallback, safe when the name is empty.
/// (Calling `name.substring(0, 1)` on an empty string throws a RangeError and
/// crashes the whole build — e.g. a completed task whose tasker has no name.)
String _avatarInitial(String name) {
  final t = name.trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}

// ══════════════════════════════════════════════════════════
//  MY TASKS (tabbed)
// ══════════════════════════════════════════════════════════

/// A group of task statuses shown as one tab in [MyTasksScreen].
enum TaskSection { open, active, done, all }

extension _TaskSectionX on TaskSection {
  String label(AppL10n l) {
    switch (this) {
      case TaskSection.open:
        return l.statusOpen;
      case TaskSection.active:
        return l.statusActive;
      case TaskSection.done:
        return l.statusDone;
      case TaskSection.all:
        return l.statusAll;
    }
  }

  bool matches(TaskModel t) {
    switch (this) {
      case TaskSection.open:
        return t.status == TaskStatus.open ||
            t.status == TaskStatus.pendingReview;
      case TaskSection.active:
        return t.status == TaskStatus.assigned ||
            t.status == TaskStatus.inProgress;
      case TaskSection.done:
        return t.status == TaskStatus.completed ||
            t.status == TaskStatus.cancelled ||
            t.status == TaskStatus.rejected;
      case TaskSection.all:
        return true;
    }
  }
}

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key, this.sections = TaskSection.values});

  /// Which status groups to show as tabs. Defaults to all four (Open, Active,
  /// Done, All). The shell passes a focused subset per bottom-nav tab.
  final List<TaskSection> sections;

  @override
  State<MyTasksScreen> createState() => _MyTasksState();
}

enum _TaskSortMode { recent, dueSoon, budgetHigh }

/// Localized status label shown on a task's status badge.
String _taskStatusBadge(AppL10n l, TaskStatus status) {
  switch (status) {
    case TaskStatus.pendingReview:
      return l.taskStatusUnderReview;
    case TaskStatus.open:
      return l.taskStatusOpen;
    case TaskStatus.assigned:
      return l.taskStatusAssigned;
    case TaskStatus.inProgress:
      return l.taskStatusInProgress;
    case TaskStatus.completed:
      return l.taskStatusCompleted;
    case TaskStatus.cancelled:
      return l.taskStatusCancelled;
    case TaskStatus.rejected:
      return l.taskStatusNotApproved;
  }
}

extension _TaskSortModeX on _TaskSortMode {
  String labelFor(AppL10n l) {
    switch (this) {
      case _TaskSortMode.recent:
        return l.tasksSortNewest;
      case _TaskSortMode.dueSoon:
        return l.tasksSortDueSoon;
      case _TaskSortMode.budgetHigh:
        return l.tasksSortBudgetHigh;
    }
  }
}

class _MyTasksState extends State<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late final TextEditingController _search;
  List<TaskModel> _tasks = [];
  String _searchQuery = '';
  bool _bidsOnly = false;
  _TaskSortMode _sortMode = _TaskSortMode.recent;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.sections.length, vsync: this);
    _search = TextEditingController();
    _search.addListener(_onSearchChanged);
    _loadTasks();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _search.text.trim());
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final tasks = await ApiService.getTasks(throwOnError: true);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
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

  int get _withBidsCount => _tasks.where((t) => t.applicantsCount > 0).length;
  int get _upcomingCount =>
      _tasks.where((t) => t.deadline.isAfter(DateTime.now())).length;
  int _sectionCount(TaskSection s) => _tasks.where(s.matches).length;

  List<TaskModel> _applyFilters(Iterable<TaskModel> source) {
    final query = _searchQuery.toLowerCase();
    var items = source.where((task) {
      if (_bidsOnly && task.applicantsCount <= 0) return false;
      if (query.isEmpty) return true;
      final matchText = [
        task.title,
        task.description,
        task.location,
        task.category.label,
      ].join(' ').toLowerCase();
      return matchText.contains(query);
    }).toList();

    switch (_sortMode) {
      case _TaskSortMode.recent:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _TaskSortMode.dueSoon:
        items.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case _TaskSortMode.budgetHigh:
        items.sort((a, b) => b.budget.compareTo(a.budget));
        break;
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: Text(l.tasksMyTasks),
          automaticallyImplyLeading: Navigator.of(context).canPop(),
          actions: [
            IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PostTaskScreen())))
          ],
          bottom: PreferredSize(
            preferredSize:
                Size.fromHeight(widget.sections.length > 1 ? 76 : 44),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Row(
                    children: [
                      for (int i = 0; i < widget.sections.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _TaskCountPill(
                            label: widget.sections[i].label(l),
                            count: _sectionCount(widget.sections[i])),
                      ],
                    ],
                  ),
                ),
                if (widget.sections.length > 1)
                  TabBar(
                      controller: _tab,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: GoogleFonts.nunito(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      tabs: widget.sections
                          .map((s) => Tab(text: s.label(l)))
                          .toList()),
              ],
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: C.primary))
            : _error
                ? ErrorRetryView(
                    message: l.tasksLoadError,
                    onRetry: _loadTasks,
                  )
                : RefreshIndicator(
                onRefresh: _loadTasks,
                color: C.primary,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TaskInsightCard(
                              title: l.tasksTotalTasks,
                              value: '${_tasks.length}',
                              subtitle: l.tasksAcrossStatuses,
                              icon: Icons.assignment_outlined,
                              tint: C.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TaskInsightCard(
                              title: l.tasksWithBids,
                              value: '$_withBidsCount',
                              subtitle: l.tasksReadyForReview,
                              icon: Icons.people_outline,
                              tint: C.teal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TaskInsightCard(
                              title: l.tasksUpcoming,
                              value: '$_upcomingCount',
                              subtitle: l.tasksNotPastDeadline,
                              icon: Icons.schedule_outlined,
                              tint: C.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _search,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l.tasksSearchHint,
                          prefixIcon: const Icon(Icons.search,
                              color: C.text3, size: 20),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _search.clear();
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        children: [
                          FilterChip(
                            selected: _bidsOnly,
                            onSelected: (selected) {
                              setState(() => _bidsOnly = selected);
                            },
                            label: Text(l.tasksOnlyWithBids),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _sortMode == _TaskSortMode.recent,
                            onSelected: (_) {
                              setState(() => _sortMode = _TaskSortMode.recent);
                            },
                            label: Text(_TaskSortMode.recent.labelFor(l)),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _sortMode == _TaskSortMode.dueSoon,
                            onSelected: (_) {
                              setState(() => _sortMode = _TaskSortMode.dueSoon);
                            },
                            label: Text(_TaskSortMode.dueSoon.labelFor(l)),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _sortMode == _TaskSortMode.budgetHigh,
                            onSelected: (_) {
                              setState(
                                  () => _sortMode = _TaskSortMode.budgetHigh);
                            },
                            label: Text(_TaskSortMode.budgetHigh.labelFor(l)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tab,
                        children: widget.sections
                            .map((s) => _TList(
                                _applyFilters(_tasks.where(s.matches)),
                                onChanged: _loadTasks))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
      );
  }
}

class _TaskCountPill extends StatelessWidget {
  final String label;
  final int count;
  const _TaskCountPill({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: .25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: .92),
                ),
              ),
            ],
          ),
        ),
      );
}

class _TaskInsightCard extends StatelessWidget {
  const _TaskInsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final background = Color.lerp(Colors.white, tint, .08)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: C.text2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: C.text1,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: C.text3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TList extends StatelessWidget {
  final List<TaskModel> tasks;
  final VoidCallback? onChanged;
  const _TList(this.tasks, {this.onChanged});
  @override
  Widget build(BuildContext ctx) {
    if (tasks.isEmpty) {
      final l = AppL10n.of(ctx)!;
      return Center(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: C.primaryLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.assignment_outlined,
                size: 38, color: C.primary),
          ),
          const SizedBox(height: 18),
          Text(l.tasksNoTasksFound,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w700, color: C.text1)),
          const SizedBox(height: 6),
          Text(l.tasksEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: C.text3,
                  height: 1.4)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              onPressed: () => Navigator.push(ctx,
                  MaterialPageRoute(builder: (_) => const PostTaskScreen())),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l.postATask)),
        ]),
      ));
    }
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (_, i) => TaskCard(task: tasks[i], onChanged: onChanged));
  }
}

// ══════════════════════════════════════════════════════════
//  TASK CARD (shared)
// ══════════════════════════════════════════════════════════

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onChanged;
  const TaskCard({super.key, required this.task, this.onChanged});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () async {
        // TaskDetailScreen / EditTaskScreen pop `true` after cancel/accept/edit;
        // refresh the parent list so it doesn't show stale state.
        final changed = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskDetailScreen(task: task)));
        if (changed == true) onChanged?.call();
      },
      child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CategoryIconChip(
                  category: task.category.name, size: 44, radius: 12),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(task.category.label,
                        style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: C.primary)),
                    Text(task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: C.text1)),
                  ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${task.budget.toInt()}',
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: C.primary)),
                _StatusBadge(task.status),
              ]),
            ]),
            const SizedBox(height: 7),
            Text(task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: C.text3,
                    fontWeight: FontWeight.w500,
                    height: 1.45)),
            const SizedBox(height: 9),
            const Divider(height: 1, color: C.divider),
            const SizedBox(height: 9),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: C.text3),
              const SizedBox(width: 3),
              Expanded(
                  child: Text(task.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: C.text3,
                          fontWeight: FontWeight.w500))),
              const Icon(Icons.access_time, size: 13, color: C.text3),
              const SizedBox(width: 3),
              Text(AppL10n.of(context)!.taskDue(DateFormat('dd MMM').format(task.deadline)),
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: C.text3,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              const Icon(Icons.people_outline, size: 13, color: C.text3),
              const SizedBox(width: 3),
              Text(AppL10n.of(context)!.taskBidsCount(task.applicantsCount),
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: C.text3,
                      fontWeight: FontWeight.w500)),
            ]),
            if (task.status == TaskStatus.completed &&
                !task.reviewed &&
                task.assignedTo != null &&
                task.assignedTo!.remoteId != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.primary,
                    side: const BorderSide(color: C.primary),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _rateFromCard(context, task),
                  icon: const Icon(Icons.star_rounded, size: 16),
                  label: Text(AppL10n.of(context)!.taskRateName(task.assignedTo!.name),
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ])));

  Future<void> _rateFromCard(BuildContext context, TaskModel task) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewSheet(
        taskId: task.remoteId ?? task.id.toString(),
        taskTitle: task.title,
        taskerName: task.assignedTo!.name,
        reviewedUserId: task.assignedTo!.remoteId!,
      ),
    );
    if (done == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context)!.taskReviewThanks),
          backgroundColor: C.green,
        ),
      );
      onChanged?.call();
    }
  }
}

// ══════════════════════════════════════════════════════════
//  TASK DETAIL
// ══════════════════════════════════════════════════════════

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});
  
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _loading = false;
  List<ApplicationModel> _applications = [];
  late TaskModel _task;
  // Set once anything changes (bid accepted/rejected) so the parent list is
  // told to refresh when this screen is popped via the back button/gesture.
  bool _changed = false;

  // Live "tasker on the way" tracking. Polled every ~15s while an assigned
  // task's detail screen is open; the timer is cancelled in dispose.
  TaskerLocation? _taskerLocation;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadApplications();
    _maybeStartLocationPolling();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  bool get _isActive =>
      _task.status == TaskStatus.assigned ||
      _task.status == TaskStatus.inProgress;

  void _maybeStartLocationPolling() {
    if (!_isActive) return;
    if (_locationTimer != null) return;
    _pollTaskerLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollTaskerLocation(),
    );
  }

  Future<void> _pollTaskerLocation() async {
    final taskId = _task.remoteId ?? _task.id.toString();
    final loc = await ApiService.getTaskerLocation(taskId);
    if (!mounted) return;

    // No location while the task is meant to be active usually means the
    // assigned tasker backed out. Confirm with a fresh task fetch, and if it
    // has reopened, revert the screen to "choose another offer" (drop the
    // stale tracker + OTP) and stop polling.
    if (loc == null && _isActive) {
      final fresh = await ApiService.getTaskById(taskId);
      if (!mounted) return;
      if (fresh != null &&
          (fresh.status == TaskStatus.open ||
              fresh.status == TaskStatus.cancelled)) {
        _locationTimer?.cancel();
        _locationTimer = null;
        setState(() {
          _task = fresh;
          _taskerLocation = null;
        });
        _loadApplications();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppL10n.of(context)!.taskTaskerCancelledReview),
            backgroundColor: C.yellow,
          ),
        );
        return;
      }
    }
    setState(() => _taskerLocation = loc);
  }

  /// Great-circle distance (km) between the task location and the tasker's
  /// last-known coordinate, using the haversine formula. Null when either
  /// coordinate is missing.
  double? _distanceKm() {
    final tLat = _task.latitude;
    final tLng = _task.longitude;
    final kLat = _taskerLocation?.latitude;
    final kLng = _taskerLocation?.longitude;
    if (tLat == null || tLng == null || kLat == null || kLng == null) {
      return null;
    }
    const earthRadiusKm = 6371.0;
    double toRad(double d) => d * math.pi / 180.0;
    final dLat = toRad(kLat - tLat);
    final dLng = toRad(kLng - tLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(toRad(tLat)) *
            math.cos(toRad(kLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static String _relativeSince(AppL10n l, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return l.taskJustNow;
    if (diff.inMinutes < 60) return l.taskMinutesAgoFull(diff.inMinutes);
    if (diff.inHours < 24) return l.taskHoursAgoFull(diff.inHours);
    return l.taskDaysAgoFull(diff.inDays);
  }

  /// Ordinal rank for a reputation tier (higher = better). Unknown/absent
  /// reputation ranks lowest so it never outranks a graded tasker.
  static int _levelRank(ApplicationModel app) {
    switch (app.applicant.reputation?.level) {
      case 'pro':
        return 4;
      case 'gold':
        return 3;
      case 'silver':
        return 2;
      case 'bronze':
        return 1;
      case 'new':
        return 0;
      default:
        return -1;
    }
  }

  /// Default offer sort, best-first: verified taskers first, then higher
  /// reputation level, then higher rating, then more reviews.
  static List<ApplicationModel> _sortOffers(List<ApplicationModel> offers) {
    final sorted = [...offers];
    sorted.sort((a, b) {
      final av = a.applicant.isVerified ? 1 : 0;
      final bv = b.applicant.isVerified ? 1 : 0;
      if (av != bv) return bv - av;
      final lvl = _levelRank(b).compareTo(_levelRank(a));
      if (lvl != 0) return lvl;
      final r = b.applicant.rating.compareTo(a.applicant.rating);
      if (r != 0) return r;
      return b.applicant.totalReviews.compareTo(a.applicant.totalReviews);
    });
    return sorted;
  }

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    final taskId = widget.task.remoteId ?? widget.task.id.toString();
    final apps = await ApiService.getTaskOffers(taskId);
    if (mounted) {
      setState(() {
        _applications = _sortOffers(apps);
        _loading = false;
      });
    }
  }

  Future<void> _acceptApplication(ApplicationModel app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.handshake_outlined, color: C.primary, size: 22),
            const SizedBox(width: 8),
            Text(AppL10n.of(context)!.taskAcceptOffer,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          AppL10n.of(context)!
              .taskAcceptOfferBody(app.applicant.name, app.bidAmount.toInt()),
          style: GoogleFonts.nunito(fontSize: 14, color: C.text2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppL10n.of(context)!.cancel,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppL10n.of(context)!.accept,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final appId = app.remoteId ?? app.id.toString();
      await ApiService.acceptOffer(appId);
      _changed = true;
      // Re-fetch the task in place so its status flips to assigned and the
      // completion OTP section appears without leaving the screen.
      final taskId = widget.task.remoteId ?? widget.task.id.toString();
      final refreshed = await ApiService.getTaskById(taskId);
      final apps = await ApiService.getTaskOffers(taskId);
      if (!mounted) return;
      setState(() {
        if (refreshed != null) _task = refreshed;
        _applications = _sortOffers(apps);
        _loading = false;
      });
      _maybeStartLocationPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context)!.taskOfferAccepted),
          backgroundColor: C.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: C.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectApplication(ApplicationModel app) async {
    setState(() => _loading = true);
    try {
      final appId = app.remoteId ?? app.id.toString();
      await ApiService.rejectOffer(appId);
      _changed = true;
      final taskId = widget.task.remoteId ?? widget.task.id.toString();
      final apps = await ApiService.getTaskOffers(taskId);
      if (!mounted) return;
      setState(() {
        _applications = _sortOffers(apps);
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context)!.taskOfferDeclined),
          backgroundColor: C.text2,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: C.red,
          ),
        );
      }
    }
  }

  Future<void> _showApplicantProfile(ApplicationModel app) async {
    final userId = app.applicant.remoteId ?? app.applicant.id.toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ApplicantProfileSheet(
        app: app,
        userId: userId,
        onBlocked: () {
          Navigator.pop(context);
          _loadApplications();
        },
      ),
    );
  }

  /// Opens the cancel-reason sheet, then cancels the task with the chosen
  /// reason. Works for OPEN and ASSIGNED tasks; the sheet warns that an
  /// assigned tasker will be notified.
  Future<void> _showCancelSheet(TaskModel task) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CancelReasonSheet(
        taskTitle: task.title,
        isAssigned: task.status == TaskStatus.assigned ||
            task.status == TaskStatus.inProgress,
      ),
    );

    if (reason == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final taskId = task.remoteId ?? task.id.toString();
      await ApiService.cancelTask(taskId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context)!.taskCancelledSuccess,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
            backgroundColor: C.green,
          ),
        );
        Navigator.pop(context, true); // Refresh parent list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''),
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
            backgroundColor: C.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Rate the tasker who completed this task (stars + optional comment).
  Future<void> _openReviewSheet(TaskModel task) async {
    final tasker = task.assignedTo;
    if (tasker == null || tasker.remoteId == null) return;
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewSheet(
        taskId: task.remoteId ?? task.id.toString(),
        taskTitle: task.title,
        taskerName: tasker.name,
        reviewedUserId: tasker.remoteId!,
      ),
    );
    if (done == true && mounted) {
      _changed = true;
      // Re-fetch so `reviewed` flips true and the Rate button hides right away.
      final fresh = await ApiService.getTaskById(
          task.remoteId ?? task.id.toString());
      if (!mounted) return;
      if (fresh != null) setState(() => _task = fresh);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context)!.taskReviewThanks),
          backgroundColor: C.green,
        ),
      );
    }
  }

  /// Explanatory banner for the two review states:
  ///  - pendingReview: reassures the customer the task is being screened.
  ///  - rejected: shows the review reason. Returns an empty list otherwise.
  List<Widget> _buildReviewStateSection(TaskModel task) {
    final l = AppL10n.of(context)!;
    if (task.status == TaskStatus.pendingReview) {
      return [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.yellowLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.yellow.withValues(alpha: .6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule, color: C.yellow, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.taskUnderReviewTitle,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: C.text1)),
                    const SizedBox(height: 4),
                    Text(l.taskUnderReviewNote,
                        style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: C.text2,
                            height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];
    }
    if (task.status == TaskStatus.rejected) {
      final reason = task.reviewReason?.trim();
      return [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.red.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.red.withValues(alpha: .45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.block, color: C.red, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.taskNotApprovedTitle,
                        style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: C.text1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (reason != null && reason.isNotEmpty)
                    ? l.taskRejectedReason(reason)
                    : l.taskNotApprovedNote,
                style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: C.text2,
                    height: 1.45),
              ),
            ],
          ),
        ),
      ];
    }
    return const [];
  }

  /// The live-tracking card, shown only when an assigned task's tasker has set
  /// out (`on_the_way_at`). Returns an empty list otherwise.
  List<Widget> _buildTrackingSection(TaskModel task) {
    final onTheWay = _taskerLocation?.onTheWayAt ?? task.onTheWayAt;
    if (!_isActive || onTheWay == null) return const [];

    final l = AppL10n.of(context)!;
    final loc = _taskerLocation;
    final name = (loc?.taskerName?.trim().isNotEmpty == true)
        ? loc!.taskerName!
        : (task.assignedTo?.name ?? l.taskYourTasker);
    final avatarUrl =
        ApiService.resolveMediaUrl(loc?.taskerAvatarUrl ?? task.assignedTo?.avatarUrl);
    final distanceKm = _distanceKm();
    final lastAt = loc?.lastLocationAt;

    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [C.primaryLight, Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.primary.withValues(alpha: .45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: C.primary.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_run_rounded,
                      color: C.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Text(l.taskOnTheWay,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: C.brandInk)),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      const BoxDecoration(color: C.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(l.taskLive,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: C.green)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: C.primaryLight,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          _avatarInitial(name),
                          style: const TextStyle(
                              color: C.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: C.text1)),
                      const SizedBox(height: 2),
                      Text(l.taskOnTheWaySince(_relativeSince(l, onTheWay)),
                          style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: C.text2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: C.divider),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.my_location_outlined, size: 15, color: C.text3),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    lastAt != null
                        ? l.taskLocationUpdated(_relativeSince(l, lastAt))
                        : l.taskWaitingLocation,
                    style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: C.text3),
                  ),
                ),
                if (distanceKm != null) ...[
                  const Icon(Icons.near_me_outlined, size: 15, color: C.primary),
                  const SizedBox(width: 4),
                  Text(
                    distanceKm < 1
                        ? l.taskMetersAway((distanceKm * 1000).round())
                        : l.taskKmAway(distanceKm.toStringAsFixed(1)),
                    style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: C.primary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    final task = _task;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Return whether anything changed so the parent list refreshes.
        Navigator.pop(context, _changed);
      },
      child: Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: Text(AppL10n.of(context)!.taskDetailsTitle)),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // header card
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.border)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CategoryIconChip(
                            category: task.category.name,
                            size: 52,
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
                                      color: C.primaryLight,
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(task.category.label,
                                      style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: C.primary))),
                              const SizedBox(height: 4),
                              Text(task.title,
                                  style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: C.text1)),
                            ])),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _Chip('₹${task.budget.toInt()}', C.primary,
                            Icons.currency_rupee),
                        _Chip(DateFormat('dd MMM').format(task.deadline),
                            C.yellow, Icons.calendar_today),
                        _Chip(AppL10n.of(context)!.taskBidsCount(_applications.length > task.applicantsCount ? _applications.length : task.applicantsCount), C.blue,
                            Icons.people_outline),
                        _StatusBadge(task.status),
                      ]),
                    ])),
            const SizedBox(height: 16),
            _SH(AppL10n.of(context)!.sdDescription),
            const SizedBox(height: 8),
            _Card(Text(task.description,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: C.text2,
                    fontWeight: FontWeight.w500,
                    height: 1.65))),
            const SizedBox(height: 16),
            _SH(AppL10n.of(context)!.taskLocationLabel),
            const SizedBox(height: 8),
            _Card(Row(children: [
              const Icon(Icons.location_on, color: C.primary, size: 20),
              const SizedBox(width: 8),
              Text(task.location,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: C.text1)),
            ])),

            // Live "tasker on the way" tracking card.
            ..._buildTrackingSection(task),

            // Under-review / rejected review-state banner.
            ..._buildReviewStateSection(task),

            // offers
            if (task.status == TaskStatus.open || _applications.isNotEmpty || task.applicantsCount > 0) ...[
              const SizedBox(height: 16),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SH(AppL10n.of(context)!.taskOffers),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: C.blueLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(AppL10n.of(context)!.taskOffersCount(_applications.length > task.applicantsCount ? _applications.length : task.applicantsCount),
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: C.blue))),
                  ]),
              const SizedBox(height: 8),
              if (_loading && _applications.isEmpty)
                const _Card(Center(child: CircularProgressIndicator()))
              else if (_applications.isEmpty)
                _Card(Center(
                    child: Text(
                        AppL10n.of(context)!.taskNoOffers,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                            color: C.text3, fontWeight: FontWeight.w600))))
              else
                ..._applications.map((app) => _ApplicantCard(
                  app: app,
                  onAccept: () => _acceptApplication(app),
                  onReject: () => _rejectApplication(app),
                  onTapProfile: () => _showApplicantProfile(app),
                  onBlocked: _loadApplications,
                  isLoading: _loading,
                  taskCompleted: task.status == TaskStatus.completed,
                )),
            ],

            // OTP
            if ((task.status == TaskStatus.inProgress ||
                    task.status == TaskStatus.assigned) &&
                task.completionOtp != null) ...[
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: C.yellowLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.yellow.withValues(alpha: .6))),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.lock_clock, color: C.yellow),
                      const SizedBox(width: 8),
                      Text(AppL10n.of(context)!.taskCompletionOtp,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: C.yellow,
                              fontSize: 15)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        AppL10n.of(context)!.taskCompletionOtpHint,
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: C.text3,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: task.completionOtp!
                            .split('')
                            .map((d) => Container(
                                  width: 54,
                                  height: 62,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: C.yellow, width: 2)),
                                  child: Center(
                                      child: Text(d,
                                          style: GoogleFonts.nunito(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: C.yellow))),
                                ))
                            .toList()),
                  ])),
            ],

            const SizedBox(height: 24),
            if (task.status == TaskStatus.pendingReview)
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: C.red,
                          side: const BorderSide(color: C.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _showCancelSheet(task),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(AppL10n.of(context)!.taskCancelTask,
                          style: GoogleFonts.nunito(
                              fontSize: 15, fontWeight: FontWeight.w800))))
            else if (task.status == TaskStatus.rejected)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: C.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        final refreshed = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditTaskScreen(task: task),
                          ),
                        );
                        if (refreshed == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(AppL10n.of(context)!.taskPostAgain,
                          style: GoogleFonts.nunito(
                              fontSize: 15, fontWeight: FontWeight.w800))))
            else if (task.status == TaskStatus.open)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: C.text1,
                            side: const BorderSide(color: C.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () async {
                          final refreshed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditTaskScreen(task: task),
                            ),
                          );
                          if (refreshed == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        child: Text(AppL10n.of(context)!.taskEditTask,
                            style: GoogleFonts.nunito(
                                fontSize: 15, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: C.red,
                            side: const BorderSide(color: C.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => _showCancelSheet(task),
                        child: Text(AppL10n.of(context)!.taskCancelTask,
                            style: GoogleFonts.nunito(
                                fontSize: 15, fontWeight: FontWeight.w800))),
                  ),
                ],
              )
            else if (task.status == TaskStatus.assigned || task.status == TaskStatus.inProgress)
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: C.red,
                          side: const BorderSide(color: C.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _showCancelSheet(task),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(AppL10n.of(context)!.taskCancelTask,
                          style: GoogleFonts.nunito(
                              fontSize: 15, fontWeight: FontWeight.w800))))
            else if (task.status == TaskStatus.completed &&
                !task.reviewed &&
                task.assignedTo != null &&
                task.assignedTo!.remoteId != null)
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: C.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _openReviewSheet(task),
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: Text(AppL10n.of(context)!.taskRateName(task.assignedTo!.name),
                          style: GoogleFonts.nunito(
                              fontSize: 15, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 16),
          ])),
    ),
    );
  }
}

/// Bottom sheet that collects a cancellation reason (preset + optional note).
/// Pops the composed reason string, or null when dismissed.
class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet({required this.taskTitle, required this.isAssigned});
  final String taskTitle;
  final bool isAssigned;

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  static const _reasonIds = [
    'no_longer_needed',
    'posted_by_mistake',
    'found_help_elsewhere',
    'other',
  ];
  String? _selected;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _reasonLabel(AppL10n l, String id) {
    switch (id) {
      case 'no_longer_needed':
        return l.cancelReasonNoLongerNeeded;
      case 'posted_by_mistake':
        return l.cancelReasonPostedByMistake;
      case 'found_help_elsewhere':
        return l.cancelReasonFoundElsewhere;
      default:
        return l.reasonOther;
    }
  }

  void _confirm() {
    final id = _selected;
    if (id == null) return;
    final l = AppL10n.of(context)!;
    final label = _reasonLabel(l, id);
    final note = _note.text.trim();
    String reason;
    if (id == 'other') {
      reason = note.isNotEmpty ? note : label;
    } else {
      reason = note.isNotEmpty ? '$label — $note' : label;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_outlined, color: C.red, size: 22),
              const SizedBox(width: 8),
              Text(l.taskCancelTaskSheet,
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: C.text1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.taskCancelWhy(widget.taskTitle),
              style: GoogleFonts.nunito(
                  fontSize: 13, color: C.text3, fontWeight: FontWeight.w600)),
          if (widget.isAssigned) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.yellowLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.yellow.withValues(alpha: .5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: C.yellow, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.taskCancelAssignedWarning,
                      style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: C.text2,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          ..._reasonIds.map((r) {
            final selected = _selected == r;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selected = r),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: selected ? C.primaryLight : C.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? C.primary : C.border,
                        width: selected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? C.primary : C.text3,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(_reasonLabel(l, r),
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selected ? C.brandInk : C.text1)),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          TextField(
            controller: _note,
            maxLines: 2,
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: l.taskAddNoteOptional,
              hintStyle: GoogleFonts.nunito(fontSize: 13, color: C.text3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: C.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.text2,
                    side: const BorderSide(color: C.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.taskKeepTask,
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _selected == null ? null : _confirm,
                  child: Text(l.taskCancelTaskSheet,
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to rate a completed task's tasker. Pops `true` on success.
class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({
    required this.taskId,
    required this.taskTitle,
    required this.taskerName,
    required this.reviewedUserId,
  });
  final String taskId;
  final String taskTitle;
  final String taskerName;
  final String reviewedUserId;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  double _rating = 5;
  final _comment = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.submitReview(
        widget.taskId,
        widget.reviewedUserId,
        _rating,
        _comment.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      // A duplicate review means it's already recorded — treat as done.
      if (msg.toLowerCase().contains('already')) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: C.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppL10n.of(context)!.taskRateName(widget.taskerName),
              style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w900, color: C.text1)),
          const SizedBox(height: 4),
          Text(widget.taskTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: C.text3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: C.star,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: AppL10n.of(context)!.taskReviewHint,
              hintStyle: GoogleFonts.nunito(fontSize: 13, color: C.text3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: C.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: C.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(AppL10n.of(context)!.taskSubmitReview,
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel app;
  final VoidCallback onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTapProfile;
  final VoidCallback? onBlocked;
  final bool isLoading;
  // Once the task is completed, chat is closed — the job is done and we don't
  // want the two parties coordinating off-platform afterwards.
  final bool taskCompleted;

  const _ApplicantCard({
    required this.app,
    required this.onAccept,
    this.onReject,
    this.onTapProfile,
    this.onBlocked,
    required this.isLoading,
    this.taskCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: C.primaryLight,
                backgroundImage: app.applicant.avatarUrl != null
                    ? NetworkImage(app.applicant.avatarUrl!)
                    : null,
                child: app.applicant.avatarUrl == null
                    ? Text(
                        _avatarInitial(app.applicant.name),
                        style: const TextStyle(
                            color: C.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onTapProfile,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              app.applicant.name,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: C.text1,
                              ),
                            ),
                          ),
                          if (app.applicant.isVerified) ...[
                            const SizedBox(width: 5),
                            const VerifiedBadge(compact: true, size: 15),
                          ],
                          if (onTapProfile != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right,
                                size: 16, color: C.text3),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: C.yellow, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${app.applicant.rating} (${AppL10n.of(context)!.reviewsCount(app.applicant.totalReviews)})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: C.text3,
                              ),
                            ),
                          ),
                          if (app.applicant.reputation != null) ...[
                            const SizedBox(width: 6),
                            LevelChip(
                                reputation: app.applicant.reputation!,
                                compact: true),
                          ],
                        ],
                      ),
                      if (app.applicant.reputation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          AppL10n.of(context)!.reputationSummary(
                            app.applicant.reputation!.completedTasks,
                            app.applicant.reputation!.reliability,
                          ),
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: C.text2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${app.bidAmount.toInt()}',
                    style: GoogleFonts.nunito(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: C.primary,
                    ),
                  ),
                  if (app.status == 'accepted')
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: C.greenLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppL10n.of(context)!.taskStatusAccepted,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: C.green,
                        ),
                      ),
                    )
                  else if (app.status == 'rejected')
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: C.redLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppL10n.of(context)!.taskStatusRejected,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: C.red,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              SafetyOverflowButton(
                reportedId:
                    app.applicant.remoteId ?? app.applicant.id.toString(),
                userName: app.applicant.name,
                taskId: app.taskId ??
                    app.task?.remoteId ??
                    app.task?.id.toString(),
                onBlocked: onBlocked,
                iconSize: 18,
              ),
            ],
          ),
          if (app.coverLetter.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                app.coverLetter,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: C.text2,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (app.status == 'accepted' && !taskCompleted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final data = await ApiService.createConversation(
                    otherUserId: app.applicant.remoteId ??
                        app.applicant.id.toString(),
                    taskId: app.taskId ??
                        app.task?.remoteId ??
                        app.task?.id.toString() ??
                        '',
                  );
                  if (data != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversation: ChatConversation.fromJson(data),
                        ),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              AppL10n.of(context)!.taskFailedOpenChat)),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  AppL10n.of(context)!.taskChat,
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (app.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onReject != null) ...[
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: C.red,
                          side: const BorderSide(color: C.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : onReject,
                        child: Text(
                          AppL10n.of(context)!.taskReject,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading ? null : onAccept,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppL10n.of(context)!.taskAcceptBid,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet showing an applicant/tasker's public profile: name, rating and
/// their recent reviews (GET /api/reviews/user/{id}).
class _ApplicantProfileSheet extends StatefulWidget {
  const _ApplicantProfileSheet({
    required this.app,
    required this.userId,
    this.onBlocked,
  });
  final ApplicationModel app;
  final String userId;
  final VoidCallback? onBlocked;

  @override
  State<_ApplicantProfileSheet> createState() => _ApplicantProfileSheetState();
}

class _ApplicantProfileSheetState extends State<_ApplicantProfileSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await ApiService.getUserReviews(widget.userId);
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final applicant = widget.app.applicant;
    final rep = applicant.reputation;
    final jobs = rep?.completedTasks ?? applicant.totalReviews;
    final reliability = (rep?.reliability ?? 100).round();
    final rating = applicant.rating.toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: C.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: C.primaryLight,
                backgroundImage: applicant.avatarUrl != null
                    ? NetworkImage(applicant.avatarUrl!)
                    : null,
                child: applicant.avatarUrl == null
                    ? Text(
                        _avatarInitial(applicant.name),
                        style: const TextStyle(
                            color: C.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            applicant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: C.text1),
                          ),
                        ),
                        if (applicant.isVerified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(size: 15),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (rep != null) ...[
                          LevelChip(reputation: rep, compact: true),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            l.reviewsCount(applicant.totalReviews),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: C.text3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafetyOverflowButton(
                reportedId: widget.userId,
                userName: applicant.name,
                taskId: widget.app.taskId ??
                    widget.app.task?.remoteId ??
                    widget.app.task?.id.toString(),
                onBlocked: widget.onBlocked,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Reputation stats at a glance
          Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  icon: Icons.star_rounded,
                  color: C.yellow,
                  value: rating,
                  label: l.profileStatRating,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileStat(
                  icon: Icons.check_circle_rounded,
                  color: C.green,
                  value: '$jobs',
                  label: l.profileStatJobs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProfileStat(
                  icon: Icons.verified_user_rounded,
                  color: C.blue,
                  value: '$reliability%',
                  label: l.profileStatReliability,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Their offer
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: C.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_rounded,
                    color: C.primary, size: 20),
                const SizedBox(width: 10),
                Text(l.taskTheirOffer,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: C.text2)),
                const Spacer(),
                Text('₹${widget.app.bidAmount.toInt()}',
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: C.primary)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(l.recentReviews,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: C.text1)),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: C.primary)),
            )
          else if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(AppL10n.of(context)!.noReviewsYet,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: C.text3)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35),
              child: ListView(
                shrinkWrap: true,
                children: _reviews.take(10).map((r) {
                  final rating =
                      double.tryParse(r['rating']?.toString() ?? '') ?? 0;
                  final comment = r['comment']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: C.yellow,
                              size: 14,
                            ),
                          ),
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(comment,
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: C.text2,
                                  height: 1.4)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact stat tile (icon + value + label) used in the tasker profile sheet.
class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _ProfileStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: C.text1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: C.text3,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  POST TASK SCREEN
// ══════════════════════════════════════════════════════════

class PostTaskScreen extends StatefulWidget {
  const PostTaskScreen({super.key, this.onPosted, this.initialCategory});

  /// Called after a task is posted successfully when the screen is hosted as a
  /// bottom-nav tab (where there is nothing to pop). Lets the shell switch to
  /// the Tasks tab. When null (screen was pushed as a route) we pop instead.
  final VoidCallback? onPosted;

  /// Optionally preselect a task category (e.g. when the customer taps a
  /// category tile on the home screen). Falls back to [TaskCategory.other].
  final TaskCategory? initialCategory;

  @override
  State<PostTaskScreen> createState() => _PostTaskState();
}

class _PostTaskState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _loc = TextEditingController();
  final _budget = TextEditingController();
  final List<XFile> _taskImages = [];
  late TaskCategory _cat = widget.initialCategory ?? TaskCategory.other;
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  // Canonical English priority sent to the backend: Standard | Priority | Urgent.
  String _priority = 'Standard';
  bool _submitting = false;
  bool _detectingLocation = false;
  bool _uploadingImages = false;
  double? _locationLat;
  double? _locationLng;

  @override
  void initState() {
    super.initState();
    _title.addListener(_onFormInputChanged);
    _loc.addListener(_onFormInputChanged);
    _budget.addListener(_onFormInputChanged);
    _desc.addListener(_onFormInputChanged);
    _hydrateLocationFromHomeCache();
  }

  @override
  void dispose() {
    _title.removeListener(_onFormInputChanged);
    _loc.removeListener(_onFormInputChanged);
    _budget.removeListener(_onFormInputChanged);
    _desc.removeListener(_onFormInputChanged);
    _title.dispose();
    _desc.dispose();
    _loc.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _onFormInputChanged() {
    if (mounted) setState(() {});
  }

  // The task is due end-of-day on the chosen date (18:00 as a sensible default).
  DateTime get _finalDeadline => DateTime(
        _deadline.year,
        _deadline.month,
        _deadline.day,
        18,
        0,
      );

  double get _enteredBudget => double.tryParse(_budget.text.trim()) ?? 0;

  Future<void> _hydrateLocationFromHomeCache() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('detected_location');
    final lat = prefs.getDouble('detected_location_lat');
    final lng = prefs.getDouble('detected_location_lng');
    if (!mounted) return;
    setState(() {
      if (_loc.text.trim().isEmpty &&
          saved != null &&
          saved.trim().isNotEmpty) {
        _loc.text = saved;
      }
      _locationLat = lat;
      _locationLng = lng;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_detectingLocation) return;
    setState(() => _detectingLocation = true);
    try {
      final picked = await _getLiveLocation();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('detected_location', picked.label);
      await prefs.setDouble('detected_location_lat', picked.lat);
      await prefs.setDouble('detected_location_lng', picked.lng);
      await prefs.setString(
        'detected_location_updated_at',
        DateTime.now().toIso8601String(),
      );
      if (!mounted) return;
      setState(() {
        _loc.text = picked.label;
        _locationLat = picked.lat;
        _locationLng = picked.lng;
      });
      _showSnack(AppL10n.of(context)!.taskLocationUpdatedPosition);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<_DetectedLocation> _getLiveLocation() async {
    final l = AppL10n.of(context)!;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

    final label =
        await _labelForCoordinates(position.latitude, position.longitude);
    return _DetectedLocation(
      label: label,
      lat: position.latitude,
      lng: position.longitude,
    );
  }

  Future<String> _labelForCoordinates(double lat, double lng) async {
    final places = await placemarkFromCoordinates(lat, lng)
        .timeout(const Duration(seconds: 6));
    return _locationLabelFromPlacemark(places) ??
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  String? _locationLabelFromPlacemark(List<Placemark> places) {
    if (places.isEmpty) return null;
    final place = places.first;
    final city = [
      place.subLocality,
      place.locality,
      place.subAdministrativeArea
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

  Future<void> _openImagePickerSheet() async {
    if (_taskImages.length >= 6) {
      _showSnack(AppL10n.of(context)!.taskMaxPhotos, error: true);
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(
                AppL10n.of(context)!.taskTakePhoto,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                AppL10n.of(context)!.taskChooseGallery,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (source == ImageSource.camera) {
      await _captureFromCamera();
      return;
    }
    await _pickFromGallery();
  }

  Future<void> _captureFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1800,
      );
      if (image == null || !mounted) return;
      setState(() => _taskImages.add(image));
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppL10n.of(context)!.taskCameraError, error: true);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1800,
      );
      if (picked.isEmpty || !mounted) return;
      final remaining = 6 - _taskImages.length;
      if (remaining <= 0) return;
      setState(() => _taskImages.addAll(picked.take(remaining)));
      if (picked.length > remaining) {
        _showSnack(AppL10n.of(context)!.taskOnlyFirstPhotos(remaining));
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppL10n.of(context)!.taskGalleryError, error: true);
    }
  }

  String? _requiredText(String? value, String field) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppL10n.of(context)!.taskFieldRequired(field);
    return null;
  }

  String? _titleValidator(String? value) {
    final l = AppL10n.of(context)!;
    final base = _requiredText(value, l.taskFieldTitle);
    if (base != null) return base;
    if ((value?.trim().length ?? 0) < 8) {
      return l.taskTitleMin;
    }
    return null;
  }

  String? _descriptionValidator(String? value) {
    final l = AppL10n.of(context)!;
    final base = _requiredText(value, l.taskFieldDescription);
    if (base != null) return base;
    if ((value?.trim().length ?? 0) < 20) {
      return l.taskDescMin;
    }
    return null;
  }

  String? _budgetValidator(String? value) {
    final l = AppL10n.of(context)!;
    final base = _requiredText(value, l.taskFieldBudget);
    if (base != null) return base;
    final budget = double.tryParse(value!.trim());
    if (budget == null || budget <= 0) {
      return l.taskBudgetInvalid;
    }
    return null;
  }

  String _finalLocation() => _loc.text.trim();

  String _finalDescription() {
    final base = _desc.text.trim();
    // Standard priority is the default and needs no annotation.
    if (_priority == 'Standard') return base;
    return '$base\n\nPriority: $_priority';
  }

  void _showSnack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: error ? C.red : C.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Uploads picked images and returns their server URLs. On failure returns an
  /// empty list — we never fall back to local device file paths, which are not
  /// valid task image URLs and would be rejected/broken server-side.
  Future<List<String>> _uploadTaskImagesIfNeeded() async {
    if (_taskImages.isEmpty) return const [];
    setState(() => _uploadingImages = true);
    try {
      return await ApiService.uploadTaskImages(
        imagePaths: _taskImages.map((e) => e.path).toList(),
      );
    } catch (_) {
      return const [];
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      _showSnack(AppL10n.of(context)!.taskCompleteRequired, error: true);
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() => _submitting = true);
    try {
      final hadImages = _taskImages.isNotEmpty;
      final imagePayload = await _uploadTaskImagesIfNeeded();
      if (hadImages && imagePayload.isEmpty && mounted) {
        _showSnack(AppL10n.of(context)!.taskPhotosUploadFailed, error: true);
      }
      await ApiService.createTask(
        title: _title.text.trim(),
        description: _finalDescription(),
        category: _cat.name,
        budget: _enteredBudget,
        location: _finalLocation(),
        deadline: _finalDeadline,
        images: imagePayload,
      );
      if (!mounted) return;
      final action = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _PostSuccessSheet(title: _title.text.trim()),
      );
      if (!mounted) return;
      // If "View My Tasks" was pressed, go to the task list. As a bottom-nav
      // tab there is nothing to pop, so hand off to the shell to switch tabs;
      // when pushed as a route, pop back with `true` to trigger a refresh.
      if (action == 'view') {
        if (widget.onPosted != null) {
          widget.onPosted!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    const quickBudgets = [500, 1000, 1500, 2500];
    final priorities = <String, String>{
      'Standard': l.taskUrgencyStandard,
      'Priority': l.taskUrgencyPriority,
      'Urgent': l.taskUrgencyUrgent,
    };
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: Text(l.postATask)),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. What do you need done? ──
                _PostSectionCard(
                  title: l.taskSecBasics,
                  subtitle: l.taskSecBasicsSub,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SH(l.taskTitleLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _title,
                        maxLength: 70,
                        validator: _titleValidator,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(hintText: l.taskTitleHint),
                      ),
                      const SizedBox(height: 4),
                      _SH(l.taskDescLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _desc,
                        maxLength: 500,
                        minLines: 3,
                        maxLines: 5,
                        validator: _descriptionValidator,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, height: 1.45),
                        decoration: InputDecoration(hintText: l.taskDescHint),
                      ),
                      const SizedBox(height: 4),
                      _SH(l.taskCategoryLabel),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TaskCategory.values.map((cat) {
                          final selected = _cat == cat;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) => setState(() => _cat = cat),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(categoryIcon(cat.name),
                                    size: 16,
                                    color: selected ? C.primary : C.text3),
                                const SizedBox(width: 6),
                                Text(cat.label,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: selected ? C.primary : C.text2)),
                              ],
                            ),
                            backgroundColor: Colors.white,
                            selectedColor: C.primaryLight,
                            side: BorderSide(
                                color: selected ? C.primary : C.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      _SH(l.taskUrgencyLabel),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: priorities.entries.map((e) {
                          final selected = _priority == e.key;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _priority = e.key),
                            label: Text(e.value,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: selected ? C.primary : C.text2)),
                            backgroundColor: Colors.white,
                            selectedColor: C.primaryLight,
                            side: BorderSide(
                                color: selected ? C.primary : C.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── 2. Photos (optional) ──
                _PostSectionCard(
                  title: l.taskSecPhotos,
                  subtitle: l.taskSecPhotosSub,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _taskImages.isEmpty
                                  ? l.taskNoPhotos
                                  : l.taskPhotosAdded(_taskImages.length),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: C.text2),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openImagePickerSheet,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text(l.taskAddPhotos,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (_taskImages.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _taskImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, index) {
                              final image = _taskImages[index];
                              return Stack(
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: C.border),
                                    ),
                                    child: Image.file(File(image.path),
                                        fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _taskImages.removeAt(index)),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: .62),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── 3. Budget, location & date ──
                _PostSectionCard(
                  title: l.taskSecBudget,
                  subtitle: l.taskSecBudgetSub,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SH(l.taskFieldBudget),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _budget,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: _budgetValidator,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          hintText: '1200',
                          prefixIcon:
                              Icon(Icons.currency_rupee, color: C.text3),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: quickBudgets.map((preset) {
                          return ActionChip(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: C.border),
                            avatar: const Icon(Icons.flash_on,
                                size: 14, color: C.primary),
                            label: Text('₹$preset',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: C.text2,
                                    fontWeight: FontWeight.w600)),
                            onPressed: () => setState(
                                () => _budget.text = preset.toString()),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _SH(l.taskServiceLocationLabel)),
                          OutlinedButton.icon(
                            onPressed:
                                _detectingLocation ? null : _useCurrentLocation,
                            icon: _detectingLocation
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location, size: 16),
                            label: Text(l.addrUseCurrent,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _loc,
                        validator: (value) =>
                            _requiredText(value, l.taskFieldLocation),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: l.taskLocationHint,
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: C.text3),
                        ),
                      ),
                      if (_locationLat != null && _locationLng != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 13, color: C.green),
                            const SizedBox(width: 4),
                            Text(
                              l.taskGps(_locationLat!.toStringAsFixed(4),
                                  _locationLng!.toStringAsFixed(4)),
                              style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: C.text3,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      _InlineSelect(
                        label: l.taskDeadlineLabel,
                        value: DateFormat('EEE, dd MMM').format(_deadline),
                        icon: Icons.calendar_today,
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _deadline,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (d != null) setState(() => _deadline = d);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _submitting || _uploadingImages ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _uploadingImages
                                ? l.taskUploadingPhotos
                                : l.taskPostTask,
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
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

class _DetectedLocation {
  final String label;
  final double lat;
  final double lng;
  const _DetectedLocation({
    required this.label,
    required this.lat,
    required this.lng,
  });
}

class _PostSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _PostSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: C.text1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: C.text3,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _InlineSelect extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _InlineSelect({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SH(label),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: C.text3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: C.text1,
                        fontWeight: FontWeight.w600,
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

// ── Helpers & shared widgets ───────────────────────────────

class _SH extends StatelessWidget {
  final String t;
  const _SH(this.t);
  @override
  Widget build(BuildContext ctx) => Text(t,
      style: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w800, color: C.text1));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card(this.child);
  @override
  Widget build(BuildContext ctx) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.border)),
      child: child);
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _Chip(this.text, this.color, this.icon);
  @override
  Widget build(BuildContext ctx) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]));
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext ctx) {
    final c = switch (status) {
      TaskStatus.pendingReview => C.yellow,
      TaskStatus.open => C.green,
      TaskStatus.assigned => C.blue,
      TaskStatus.inProgress => C.yellow,
      TaskStatus.completed => C.teal,
      TaskStatus.cancelled => C.red,
      TaskStatus.rejected => C.red,
    };
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            color: c.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(6)),
        child: Text(_taskStatusBadge(AppL10n.of(ctx)!, status).toUpperCase(),
            style: GoogleFonts.nunito(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: c,
                letterSpacing: .3)));
  }
}

class _PostSuccessSheet extends StatelessWidget {
  final String title;
  const _PostSuccessSheet({required this.title});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const _AnimatedSuccessIcon(),
        const SizedBox(height: 14),
        Text(AppL10n.of(context)!.taskPostedTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 22, fontWeight: FontWeight.w900, color: C.text1)),
        const SizedBox(height: 8),
        Text(AppL10n.of(context)!.taskPostedBody(title),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 14,
                color: C.text2,
                fontWeight: FontWeight.w700,
                height: 1.5)),
        const SizedBox(height: 8),
        Text(AppL10n.of(context)!.taskPostedReviewNote,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: C.text3,
                fontWeight: FontWeight.w500,
                height: 1.5)),
        const SizedBox(height: 24),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, 'view');
                },
                child: Text(AppL10n.of(context)!.taskViewMyTasks,
                    style: GoogleFonts.nunito(
                        fontSize: 15, fontWeight: FontWeight.w800)))),
        const SizedBox(height: 10),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppL10n.of(context)!.taskPostAnother,
                style: GoogleFonts.nunito(
                    color: C.primary, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
      ]));
}

class _AnimatedSuccessIcon extends StatelessWidget {
  const _AnimatedSuccessIcon();
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: C.primaryLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: C.primary.withValues(alpha: 0.3 * val),
                  blurRadius: 20 * val,
                  spreadRadius: 5 * val,
                ),
              ],
            ),
            child: const Icon(Icons.celebration_rounded,
                size: 48, color: C.primary),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  EDIT TASK SCREEN
// ══════════════════════════════════════════════════════════

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _loc;
  late final TextEditingController _budget;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task.title);
    _desc = TextEditingController(text: widget.task.description);
    _loc = TextEditingController(text: widget.task.location);
    _budget = TextEditingController(text: widget.task.budget.toInt().toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _loc.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final payload = {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'location': _loc.text.trim(),
        'budget': double.tryParse(_budget.text.trim()) ?? 0,
      };
      final taskId = widget.task.remoteId ?? widget.task.id.toString();
      await ApiService.updateTask(taskId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context)!.taskUpdatedSuccess),
          backgroundColor: C.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: C.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: Text(AppL10n.of(context)!.taskEditTask),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SH(AppL10n.of(context)!.taskEditTitle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: AppL10n.of(context)!.taskEditTitleHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppL10n.of(context)!.taskEditTitleRequired;
                  if (val.trim().length < 8) return AppL10n.of(context)!.taskTitleMin;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _SH(AppL10n.of(context)!.sdDescription),
              const SizedBox(height: 8),
              TextFormField(
                controller: _desc,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: AppL10n.of(context)!.taskEditDescHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppL10n.of(context)!.taskEditDescRequired;
                  if (val.trim().length < 20) return AppL10n.of(context)!.taskEditDescMin;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _SH(AppL10n.of(context)!.taskLocationLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _loc,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: AppL10n.of(context)!.taskEditLocHint,
                  prefixIcon: const Icon(Icons.location_on_outlined, color: C.text3),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppL10n.of(context)!.taskEditLocRequired;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _SH(AppL10n.of(context)!.taskEditBudgetLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budget,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_rupee, size: 18, color: C.text3),
                  hintText: AppL10n.of(context)!.taskEditBudgetHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: C.border)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return AppL10n.of(context)!.taskEditBudgetRequired;
                  final b = double.tryParse(val.trim());
                  if (b == null || b <= 0) return AppL10n.of(context)!.taskEditBudgetInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(AppL10n.of(context)!.taskSaveChanges,
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
}
