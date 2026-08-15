import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../theme/category_icons.dart';
import '../services/api_service.dart';
import '../services/tasker_state.dart';
import '../models/models.dart';
import 'messages.dart';
import 'verification.dart';
import 'safety.dart';

/// A horizontal strip of the photos the customer attached to a task. Returns an
/// empty widget when there are none. Tapping a thumbnail opens it full-screen.
Widget taskPhotosSection(
    BuildContext context, List<String> images, String label) {
  if (images.isEmpty) return const SizedBox.shrink();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: T.text3,
          letterSpacing: .4,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final url = ApiService.resolveMediaUrl(images[i]);
            if (url == null) return const SizedBox(width: 88, height: 88);
            return GestureDetector(
              onTap: () => _openTaskPhoto(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 88,
                    height: 88,
                    color: T.primaryLight,
                    child: const Icon(Icons.broken_image_outlined,
                        color: T.primary),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

void _openTaskPhoto(BuildContext context, String url) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    ),
  ));
}

// ══════════════════════════════════════════════════════════
//  SHARED TRUST & PAYMENT HELPERS
// ══════════════════════════════════════════════════════════

/// Shown when applying is blocked by the KYC gate (unverified tasker, or a 403
/// from the apply endpoint). Routes to the verification screen.
Future<void> showVerificationRequiredDialog(
  BuildContext context, {
  String? message,
}) {
  final l = AppL10n.of(context)!;
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: T.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined,
                size: 36, color: T.primary),
          ),
          const SizedBox(height: 14),
          Text(l.verificationRequired,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 20, fontWeight: FontWeight.w900, color: T.text1)),
          const SizedBox(height: 8),
          Text(
            message?.trim().isNotEmpty == true
                ? message!.trim()
                : l.completeKyc,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: T.text3,
                height: 1.45),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerificationScreen()),
              );
            },
            child: Text(l.getVerified,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.browseNotNow,
                style: GoogleFonts.nunito(
                    color: T.text3, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );
}

/// Cash + commission result sheet, driven by the `earning` payload returned by
/// [ApiService.completeTask] ({gross, commission, net, method}).
Future<void> showEarningResultSheet(
  BuildContext context,
  Map<String, dynamic> earning,
) {
  final l = AppL10n.of(context)!;
  double num2(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
  final gross = num2(earning['gross']);
  final commission = num2(earning['commission']);
  final net = num2(earning['net']);
  final rawMethod = earning['method']?.toString() ?? 'cash';
  final method = rawMethod.trim().isEmpty ? 'cash' : rawMethod.trim();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: T.greenLight,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle_rounded, size: 44, color: T.green),
            ),
          ),
          const SizedBox(height: 14),
          Text(l.browseTaskCompleted,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 22, fontWeight: FontWeight.w900, color: T.text1)),
          const SizedBox(height: 6),
          Text(
            l.browseCollectedCash(gross.toStringAsFixed(0)),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: T.text3,
                height: 1.4),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: T.border),
            ),
            child: Column(children: [
              _EarningRow(
                label: l.browseCashCollected,
                value: '₹${gross.toStringAsFixed(0)}',
                valueColor: T.text1,
              ),
              const SizedBox(height: 10),
              _EarningRow(
                label: l.browsePlatformFeeMethod(method),
                value: '- ₹${commission.toStringAsFixed(0)}',
                valueColor: T.red,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: T.divider),
              ),
              _EarningRow(
                label: l.browseNetEarning,
                value: '₹${net.toStringAsFixed(0)}',
                valueColor: T.green,
                emphasise: true,
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: T.yellowLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: T.yellow.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: T.yellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.browseFeeDeducted(commission.toStringAsFixed(0)),
                  style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: T.yellow,
                      height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.browseDone,
                style: GoogleFonts.nunito(
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ),
  );
}

class _EarningRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool emphasise;
  const _EarningRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: emphasise ? 15 : 14,
                fontWeight: emphasise ? FontWeight.w800 : FontWeight.w600,
                color: T.text2)),
        Text(value,
            style: GoogleFonts.nunito(
                fontSize: emphasise ? 20 : 15,
                fontWeight: FontWeight.w900,
                color: valueColor)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
//  BROWSE TASKS SCREEN
// ══════════════════════════════════════════════════════════

class BrowseTasksScreen extends StatefulWidget {
  const BrowseTasksScreen({super.key});

  @override
  State<BrowseTasksScreen> createState() => _BrowseState();
}

class _BrowseState extends State<BrowseTasksScreen> {
  TaskCategory? _selectedCat;
  String _sort = 'latest';
  String _currentCity = 'Ludhiana';
  String _searchQuery = '';

  // Budget filter state
  double? _budgetMin;
  double? _budgetMax;
  String _budgetPreset = 'all';

  // Bookmarks — persisted across sessions; `_savedOnly` filters the feed to them.
  final Set<String> _savedTaskIds = {};
  bool _savedOnly = false;
  static const _savedPrefsKey = 'browse_saved_task_ids';

  // Stable key for a task (backend id preferred) used for saves + applied set.
  String _taskKey(TaskModel t) => t.remoteId ?? t.id.toString();

  Future<void> _loadSavedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_savedPrefsKey) ?? const [];
    if (!mounted) return;
    setState(() => _savedTaskIds
      ..clear()
      ..addAll(ids));
  }

  Future<void> _toggleSaved(TaskModel task) async {
    final key = _taskKey(task);
    setState(() {
      if (!_savedTaskIds.remove(key)) _savedTaskIds.add(key);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedPrefsKey, _savedTaskIds.toList());
  }

  // Leads the tasker dismissed this session (hidden locally, not applied to).
  final Set<String> _dismissedTaskIds = {};

  final _searchCtrl = TextEditingController();

  // Live data state
  List<TaskModel> _allTasks = [];
  bool _isLoading = true;
  String? _error;

  // Track tasks the tasker has already applied to
  Set<String> _appliedTaskIds = {};

  // KYC gate: optimistic until checked (the 403 handler is the backstop). When
  // known-false we swap Apply for a "Get verified" prompt.
  bool _isVerified = true;

  @override
  void initState() {
    super.initState();
    // Defer initial loads: _loadTasks() calls setState() before its first await,
    // and initState runs while the shell's IndexedStack builds every tab — a
    // synchronous setState there throws "setState called during build".
    _loadSavedTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadTasks();
      _loadMyApplications();
      _loadVerification();
    });
  }

  Future<void> _loadVerification() async {
    final verified = await ApiService.isVerified();
    if (mounted) setState(() => _isVerified = verified);
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Re-check verification on every (re)load so a freshly-verified tasker
    // stops seeing the "Get verified" prompt after a pull-to-refresh.
    _loadVerification();
    try {
      final tasks = await ApiService.getTasks(status: 'open');
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMyApplications() async {
    try {
      final apps = await ApiService.getMyApplications();
      if (mounted) {
        setState(() {
          _appliedTaskIds = apps
              .where((a) => a.task != null)
              .map((a) => a.task!.remoteId ?? a.task!.id.toString())
              .toSet();
        });
      }
    } catch (_) {}
  }

  /// Hide a lead locally (with an Undo). Nothing is sent to the backend.
  void _dismissTask(TaskModel task) {
    final l = AppL10n.of(context)!;
    final id = task.remoteId ?? task.id.toString();
    setState(() => _dismissedTaskIds.add(id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.browseLeadDismissed,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: l.browseUndo,
            textColor: Colors.white,
            onPressed: () => setState(() => _dismissedTaskIds.remove(id)),
          ),
        ),
      );
  }

  List<TaskModel> get _tasks {
    var list = _allTasks.where((t) => t.status == TaskStatus.open).toList();

    // Hide leads the tasker dismissed this session.
    if (_dismissedTaskIds.isNotEmpty) {
      list = list
          .where((t) =>
              !_dismissedTaskIds.contains(t.remoteId ?? t.id.toString()))
          .toList();
    }

    // "Saved" filter — show only bookmarked tasks.
    if (_savedOnly) {
      list = list.where((t) => _savedTaskIds.contains(_taskKey(t))).toList();
    }

    if (_selectedCat != null) {
      list = list.where((t) => t.category == _selectedCat).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.location.toLowerCase().contains(q);
      }).toList();
    }

    // Budget filter
    if (_budgetMin != null) {
      list = list.where((t) => t.budget >= _budgetMin!).toList();
    }
    if (_budgetMax != null) {
      list = list.where((t) => t.budget <= _budgetMax!).toList();
    }

    switch (_sort) {
      case 'budget':
        list.sort((a, b) => b.budget.compareTo(a.budget));
        break;
      case 'deadline':
        list.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'least bids':
        list.sort((a, b) => a.applicantsCount.compareTo(b.applicantsCount));
        break;
      default:
        // 'latest' — newest posted first.
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  void _showLocationPicker() {
    final l = AppL10n.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool detecting = false;
            String loadingText = '';

            void startAutoDetect() async {
              setSheetState(() {
                detecting = true;
                loadingText = l.browseGpsPinging;
              });
              await Future.delayed(const Duration(milliseconds: 600));
              if (!ctx.mounted) return;
              setSheetState(() {
                loadingText = l.browseGpsResolving;
              });
              await Future.delayed(const Duration(milliseconds: 600));
              if (!ctx.mounted) return;
              setSheetState(() {
                loadingText = l.browseGpsFetching;
              });
              await Future.delayed(const Duration(milliseconds: 500));
              if (!ctx.mounted) return;

              final cities = ['Chandigarh', 'Delhi NCR', 'Amritsar', 'Jalandhar', 'Mumbai'];
              cities.remove(_currentCity);
              final detected = cities.first;

              setState(() {
                _currentCity = detected;
              });

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.browseLocationDetected(detected),
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: T.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }

            final manualCities = ['Ludhiana', 'Chandigarh', 'Jalandhar', 'Amritsar', 'Delhi NCR', 'Mumbai'];

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: T.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.browseSelectLocation,
                    style: GoogleFonts.nunito(
                      color: T.text1,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    l.browseSelectLocationSub,
                    style: GoogleFonts.nunito(
                      color: T.text3,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: detecting ? null : startAutoDetect,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: detecting
                              ? [T.primaryLight, T.primaryLight.withValues(alpha: 0.7)]
                              : [T.primary, T.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: T.primary.withValues(alpha: detecting ? 0.05 : 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: detecting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: T.primary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detecting ? loadingText : l.browseAutoDetect,
                                  style: GoogleFonts.nunito(
                                    color: detecting ? T.primary : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  detecting ? l.browseAccessingGps : l.browseSimulateGps,
                                  style: GoogleFonts.nunito(
                                    color: detecting ? T.text3 : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!detecting)
                            const Icon(Icons.chevron_right, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    l.browsePopularCities,
                    style: GoogleFonts.nunito(
                      color: T.text3,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: manualCities.length,
                      itemBuilder: (context, idx) {
                        final city = manualCities[idx];
                        final active = _currentCity == city;
                        return GestureDetector(
                          onTap: detecting ? null : () {
                            setState(() {
                              _currentCity = city;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l.browseBrowsingNearest(city),
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: T.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: active ? T.primaryLight : T.bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: active ? T.primary : T.border,
                                width: active ? 1.5 : 1.0,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    city,
                                    style: GoogleFonts.nunito(
                                      color: active ? T.primary : T.text1,
                                      fontSize: 14,
                                      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                                    ),
                                  ),
                                  if (active) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle, color: T.primary, size: 14),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    final l = AppL10n.of(context)!;
    final minCtrl = TextEditingController(text: _budgetMin?.toInt().toString() ?? '');
    final maxCtrl = TextEditingController(text: _budgetMax?.toInt().toString() ?? '');
    String tempPreset = _budgetPreset;
    double? tempMin = _budgetMin;
    double? tempMax = _budgetMax;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            void applyPreset(String preset) {
              setSheet(() {
                tempPreset = preset;
                switch (preset) {
                  case 'under500':
                    tempMin = null;
                    tempMax = 500;
                    minCtrl.clear();
                    maxCtrl.text = '500';
                    break;
                  case '500to2000':
                    tempMin = 500;
                    tempMax = 2000;
                    minCtrl.text = '500';
                    maxCtrl.text = '2000';
                    break;
                  case 'above2000':
                    tempMin = 2000;
                    tempMax = null;
                    minCtrl.text = '2000';
                    maxCtrl.clear();
                    break;
                  default:
                    tempMin = null;
                    tempMax = null;
                    minCtrl.clear();
                    maxCtrl.clear();
                }
              });
            }

            String presetLabel(String code) {
              switch (code) {
                case 'under500':
                  return l.browsePresetUnder500;
                case '500to2000':
                  return l.browsePreset500to2000;
                case 'above2000':
                  return l.browsePresetAbove2000;
                default:
                  return l.browsePresetAll;
              }
            }

            final presets = ['all', 'under500', '500to2000', 'above2000'];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: T.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          l.filterTasks,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: T.text1,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setSheet(() {
                              tempPreset = 'all';
                              tempMin = null;
                              tempMax = null;
                              minCtrl.clear();
                              maxCtrl.clear();
                            });
                          },
                          child: Text(
                            l.browseReset,
                            style: GoogleFonts.nunito(
                              color: T.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.budgetRange,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: T.text1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Preset chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((p) {
                        final sel = tempPreset == p;
                        return GestureDetector(
                          onTap: () => applyPreset(p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? T.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? T.primary : T.border,
                                width: sel ? 1.5 : 1.0,
                              ),
                              boxShadow: sel
                                  ? [BoxShadow(color: T.primary.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
                                  : [],
                            ),
                            child: Text(
                              presetLabel(p),
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : T.text2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.browseMinBudget,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: T.text2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: minCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  prefixIcon: Icon(Icons.currency_rupee, color: T.primary, size: 18),
                                ),
                                onChanged: (v) {
                                  setSheet(() {
                                    tempMin = double.tryParse(v);
                                    tempPreset = 'all';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.browseMaxBudget,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: T.text2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: maxCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  hintText: l.browseHintAny,
                                  prefixIcon: const Icon(Icons.currency_rupee, color: T.primary, size: 18),
                                ),
                                onChanged: (v) {
                                  setSheet(() {
                                    tempMax = double.tryParse(v);
                                    tempPreset = 'all';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _budgetPreset = tempPreset;
                            _budgetMin = tempMin;
                            _budgetMax = tempMax;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          l.applyFilters,
                          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      body: Column(
        children: [
          _buildHeader(),
          _buildCatFilter(),
          _buildSortBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: T.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 52, color: T.text3),
                            const SizedBox(height: 12),
                            Text(
                              l.browseFailedLoad,
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: T.text3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadTasks,
                              style: ElevatedButton.styleFrom(backgroundColor: T.primary),
                              child: Text(l.actionRetry, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 52, color: T.text3),
                                const SizedBox(height: 12),
                                Text(
                                  l.noTasksFound,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: T.text3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l.tryAdjustingFilters,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: T.text3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadTasks,
                                  style: ElevatedButton.styleFrom(backgroundColor: T.primary),
                                  child: Text(l.browseRefresh, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTasks,
                            color: T.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _tasks.length,
                              itemBuilder: (_, i) => TaskBrowseCard(
                                task: _tasks[i],
                                isBookmarked:
                                    _savedTaskIds.contains(_taskKey(_tasks[i])),
                                isVerified: _isVerified,
                                hasApplied: _appliedTaskIds.contains(
                                    _tasks[i].remoteId ?? _tasks[i].id.toString()),
                                onBookmark: () => _toggleSaved(_tasks[i]),
                                onDismiss: () => _dismissTask(_tasks[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l = AppL10n.of(context)!;
    final hasActiveFilter = _budgetMin != null || _budgetMax != null;
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
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
            children: [
              Row(
                children: [
                  Text(
                    l.qaBrowseTasks,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showLocationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            _currentCity,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: T.text3, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: GoogleFonts.nunito(
                                color: T.text1,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: l.searchTasksHint,
                                hintStyle: GoogleFonts.nunito(
                                  color: T.text3,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                              ),
                              onChanged: (v) => setState(() => _searchQuery = v),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close, color: T.text3, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: hasActiveFilter ? Colors.white : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.tune,
                            color: hasActiveFilter ? T.primary : Colors.white,
                            size: 20,
                          ),
                          if (hasActiveFilter)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: T.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatFilter() {
    final l = AppL10n.of(context)!;
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _CatChip(
            label: l.browseCatAll,
            icon: Icons.grid_view_rounded,
            color: T.primary,
            selected: _selectedCat == null,
            onTap: () => setState(() => _selectedCat = null),
          ),
          ...TaskCategory.values.map(
            (cat) => _CatChip(
              label: cat.label,
              icon: categoryIcon(cat.name),
              color: categoryColor(cat.name),
              selected: _selectedCat == cat,
              onTap: () => setState(() => _selectedCat = cat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    final l = AppL10n.of(context)!;
    final opts = ['latest', 'budget', 'deadline', 'least bids'];
    String sortLabel() {
      switch (_sort) {
        case 'budget':
          return l.browseSortBudget;
        case 'deadline':
          return l.browseSortDeadline;
        case 'least bids':
          return l.browseSortLeastBids;
        default:
          return l.browseSortLatest;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: T.greenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l.browseOpenTasks(_tasks.length),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: T.green,
              ),
            ),
          ),
          const Spacer(),
          // Saved-tasks toggle (bookmark icon + count). Filters the feed to
          // bookmarked tasks when active.
          GestureDetector(
            onTap: () => setState(() => _savedOnly = !_savedOnly),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _savedOnly ? T.primary : T.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_savedOnly ? Icons.bookmark : Icons.bookmark_border,
                      size: 14, color: _savedOnly ? Colors.white : T.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${_savedTaskIds.length}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _savedOnly ? Colors.white : T.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              final i = opts.indexOf(_sort);
              _sort = opts[(i + 1) % opts.length];
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: T.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    l.browseSortLabel(sortLabel()),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: T.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_vert, color: T.primary, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  TASK BROWSE CARD
// ══════════════════════════════════════════════════════════

class TaskBrowseCard extends StatelessWidget {
  final TaskModel task;
  final bool isBookmarked;
  final bool hasApplied;
  final bool isVerified;
  final VoidCallback onBookmark;
  final VoidCallback onDismiss;

  static void _noop() {}

  // Relative "posted" time from the task's createdAt.
  String _postedAgo(AppL10n l) {
    final diff = DateTime.now().difference(task.createdAt);
    if (diff.inMinutes < 1) return l.browseJustNow;
    if (diff.inHours < 1) return l.timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l.timeHoursAgo(diff.inHours);
    return l.timeDaysAgo(diff.inDays);
  }

  const TaskBrowseCard({
    super.key,
    required this.task,
    this.isBookmarked = false,
    this.hasApplied = false,
    this.isVerified = true,
    this.onBookmark = _noop,
    this.onDismiss = _noop,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final daysLeft = task.deadline.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;

    Color bidsColor;
    if (task.applicantsCount < 5) {
      bidsColor = T.green;
    } else if (task.applicantsCount <= 10) {
      bidsColor = T.yellow;
    } else {
      bidsColor = T.red;
    }

    return GestureDetector(
      onTap: hasApplied ? null : () async {
        if (!isVerified) {
          showVerificationRequiredDialog(context);
          return;
        }
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ApplyScreen(task: task)),
        );
        if (result == true) {
          if (!context.mounted) return;
          final state = context.findAncestorStateOfType<_BrowseState>();
          state?._loadMyApplications();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card top row with urgency badge and bookmark
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryIconChip(category: task.category.name, size: 46),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.category.label,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: T.primary,
                          ),
                        ),
                        Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: T.text1,
                          ),
                        ),
                        Text(
                          l.browsePostedBy(task.postedBy.name),
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: T.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${task.budget.toInt()}',
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: T.primary,
                        ),
                      ),
                      Text(
                        l.browseBudgetSmall,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: T.text3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Bookmark button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: onBookmark,
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: isBookmarked ? T.primary : T.text3,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Urgency badge row
            if (isUrgent)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: T.redLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14, color: T.red),
                      const SizedBox(width: 2),
                      Text(
                        l.browseUrgent,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: T.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysLeft == 0
                            ? l.browseDueToday
                            : daysLeft == 1
                                ? l.browseDueTomorrow
                                : l.browseDueInDays(daysLeft),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: T.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: T.text3,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 12, color: T.text3),
                  const SizedBox(width: 4),
                  Text(
                    l.browsePosted(_postedAgo(l)),
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      color: T.text3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Divider(height: 1, color: T.divider),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: T.text3),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      task.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: T.text3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.access_time, size: 13, color: T.text3),
                  const SizedBox(width: 3),
                  Text(
                    l.browseDue(DateFormat('dd MMM').format(task.deadline)),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: T.text3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.people_outline, size: 13, color: T.text3),
                  const SizedBox(width: 3),
                  Text(
                    l.browseBids(task.applicantsCount),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: bidsColor,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: hasApplied
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: T.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: T.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: T.green, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l.profileApplied,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: T.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          OutlinedButton(
                            onPressed: onDismiss,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: T.text3,
                              side: const BorderSide(color: T.border),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 11, horizontal: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              l.browseDismiss,
                              style: GoogleFonts.nunito(
                                  fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: isVerified
                                ? DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [T.primary, T.primaryDark],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              T.primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ApplyScreen(task: task)),
                                        );
                                        if (result == true) {
                                          if (!context.mounted) return;
                                          final state = context
                                              .findAncestorStateOfType<
                                                  _BrowseState>();
                                          state?._loadMyApplications();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 11),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            l.quickApply,
                                            style: GoogleFonts.nunito(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(width: 5),
                                          const Icon(Icons.arrow_forward_rounded,
                                              size: 16, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () =>
                                        showVerificationRequiredDialog(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: T.primary,
                                      side: const BorderSide(
                                          color: T.primary, width: 1.5),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 11),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.verified_user_outlined,
                                            size: 15, color: T.primary),
                                        const SizedBox(width: 5),
                                        Text(
                                          l.getVerifiedToApply,
                                          style: GoogleFonts.nunito(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  APPLY SCREEN
// ══════════════════════════════════════════════════════════

class ApplyScreen extends StatefulWidget {
  final TaskModel task;
  const ApplyScreen({super.key, required this.task});

  @override
  State<ApplyScreen> createState() => _ApplyState();
}

class _ApplyState extends State<ApplyScreen> {
  final _bidCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  bool _loading = false;
  double _myBid = 0;
  int _coverLength = 0;

  static const int _maxCoverLength = 300;

  void _apply() async {
    final l = AppL10n.of(context)!;
    if (_bidCtrl.text.isEmpty || _coverCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.bankFillAllFields,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: T.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.applyForTask(
        taskId: widget.task.remoteId ?? widget.task.id.toString(),
        bidAmount: double.tryParse(_bidCtrl.text) ?? 0,
        coverLetter: _coverCtrl.text.trim(),
      );
      // Signal the Applied tab to refetch so the new bid shows up there.
      TaskerState().notifyApplicationsChanged();
      if (!mounted) return;
      setState(() => _loading = false);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _SuccessSheet(task: widget.task),
      ).then((_) {
        if (mounted) {
          Navigator.pop(context, true); // Pop ApplyScreen with result
        }
      });
    } on VerificationRequiredException catch (e) {
      // KYC gate hit on submit — route to verification instead of a generic error.
      if (!mounted) return;
      setState(() => _loading = false);
      showVerificationRequiredDialog(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bidCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final budget = widget.task.budget;
    final avgBid = budget * 0.9;

    Color? hintColor;
    String hintText = '';
    if (_myBid > 0) {
      if (_myBid < budget) {
        hintColor = T.green;
        hintText = l.browseBidLower((budget - _myBid).toInt().toString());
      } else if (_myBid > budget) {
        hintColor = T.yellow;
        hintText = l.browseBidAbove;
      } else {
        hintColor = T.blue;
        hintText = l.browseBidMatches;
      }
    }

    // Competitive analysis
    String competitiveText = '';
    Color competitiveColor = T.green;
    if (_myBid > 0 && avgBid > 0) {
      final diffPct = ((_myBid - avgBid) / avgBid * 100).abs().toStringAsFixed(0);
      if (_myBid < avgBid) {
        competitiveText = l.browseCompBelow(diffPct);
        competitiveColor = T.green;
      } else if (_myBid > avgBid) {
        competitiveText = l.browseCompAbove(diffPct);
        competitiveColor = T.yellow;
      } else {
        competitiveText = l.browseCompMatches;
        competitiveColor = T.blue;
      }
    }

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(widget.task.category.label),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task summary card with gradient header strip
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: T.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Gradient header strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [T.primary, T.primaryDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      children: [
                        Icon(categoryIcon(widget.task.category.name),
                            size: 24, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.task.title,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${budget.toInt()}',
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Card body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.postedBy.name,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: T.text3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.task.description,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: T.text2,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        taskPhotosSection(
                            context, widget.task.images, l.browsePhotos),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _InfoChip(widget.task.location,
                                icon: Icons.location_on_outlined),
                            _InfoChip(
                                l.browseDue(DateFormat('dd MMM').format(widget.task.deadline)),
                                icon: Icons.event_outlined),
                            _InfoChip(l.browseBids(widget.task.applicantsCount),
                                icon: Icons.people_outline),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SecLabel(l.browseYourBidAmount),
            const SizedBox(height: 8),
            TextField(
              controller: _bidCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 20),
              decoration: InputDecoration(
                hintText: '${budget.toInt()}',
                prefixIcon: const Icon(Icons.currency_rupee, color: T.primary, size: 22),
              ),
              onChanged: (v) {
                setState(() => _myBid = double.tryParse(v) ?? 0);
              },
            ),
            if (_myBid > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hintColor!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hintText,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hintColor,
                  ),
                ),
              ),
            ],

            // Competitive analysis bar
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: T.blueLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: T.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          size: 16, color: T.blue),
                      const SizedBox(width: 5),
                      Text(
                        l.browseCompetitiveAnalysis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: T.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _AnalysisChip(
                        label: l.budget,
                        value: '₹${budget.toInt()}',
                        color: T.text2,
                      ),
                      const SizedBox(width: 10),
                      _AnalysisChip(
                        label: l.browseAvgBid,
                        value: '₹${avgBid.toInt()}',
                        color: T.blue,
                      ),
                      const SizedBox(width: 10),
                      _AnalysisChip(
                        label: l.profileYourBid,
                        value: _myBid > 0 ? '₹${_myBid.toInt()}' : '—',
                        color: _myBid > 0 ? T.primary : T.text3,
                      ),
                    ],
                  ),
                  if (_myBid > 0 && competitiveText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      competitiveText,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: competitiveColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Estimated earnings card
            if (_myBid > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: T.greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: T.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_rounded, size: 24, color: T.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.browseEstTakeHome,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: T.green,
                            ),
                          ),
                          Text(
                            '₹${(_myBid * 0.90).toInt()}',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: T.green,
                            ),
                          ),
                          Text(
                            l.browseAfterFee,
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: T.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            _SecLabel(l.browseCoverLetter),
            const SizedBox(height: 8),
            TextField(
              controller: _coverCtrl,
              maxLines: 5,
              maxLength: _maxCoverLength,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
              decoration: InputDecoration(
                hintText: l.browseCoverHint,
                counterText: '',
              ),
              onChanged: (v) {
                setState(() => _coverLength = v.length);
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    l.browseCoverTip,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: T.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$_coverLength/$_maxCoverLength',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: _coverLength >= _maxCoverLength ? T.red : T.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: T.yellowLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: T.yellow.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: T.yellow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.browseFeeNote,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: T.yellow,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _apply,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        l.browseSubmitApplication,
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  ACTIVE TASK SCREEN (OTP verification)
// ══════════════════════════════════════════════════════════

class ActiveTaskScreen extends StatefulWidget {
  final TaskModel task;
  const ActiveTaskScreen({super.key, required this.task});

  @override
  State<ActiveTaskScreen> createState() => _ActiveTaskState();
}

class _ActiveTaskState extends State<ActiveTaskScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  // "On my way" + live location sharing.
  bool _onTheWay = false;
  bool _otwLoading = false;
  Timer? _locTimer;

  // Back-out (cancel) state.
  bool _cancelling = false;

  String get _taskId => widget.task.remoteId ?? widget.task.id.toString();

  Future<void> _markOnTheWay() async {
    if (_otwLoading || _onTheWay) return;
    final l = AppL10n.of(context)!;
    final taskId = widget.task.remoteId;
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.browseTaskRefMissing)),
      );
      return;
    }
    setState(() => _otwLoading = true);
    String? error;
    try {
      await ApiService.markOnTheWay(taskId);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    }
    if (!mounted) return;
    setState(() {
      _otwLoading = false;
      _onTheWay = error == null;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: T.red),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.browseCustomerNotifiedSharing)),
    );
    // Push an immediate fix, then keep it fresh while this screen is open.
    _pushLocation();
    _locTimer?.cancel();
    _locTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _pushLocation(),
    );
  }

  Future<void> _pushLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 15),
        ),
      ).timeout(const Duration(seconds: 18));
      if (!mounted) return;
      await ApiService.updateLocation(position.latitude, position.longitude);
    } catch (_) {
      // Location sharing is best-effort; ignore transient failures.
    }
  }

  Future<void> _cancelJob() async {
    final l = AppL10n.of(context)!;
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CancelJobSheet(),
    );
    if (result == null || !mounted) return;

    final taskId = widget.task.remoteId;
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.browseTaskRefMissing)),
      );
      return;
    }
    setState(() => _cancelling = true);
    String? error;
    try {
      await ApiService.cancelAssignedTask(taskId, reason: result['reason']);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: T.red),
      );
      return;
    }
    _locTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.browseBackedOut)),
    );
    Navigator.pop(context, 'cancelled');
  }

  void _verify() async {
    if (_otpCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    // Complete on the server: verifies the OTP, marks the task completed. This
    // is a cash job — the tasker collected the gross in cash and the platform
    // commission is deducted from their wallet.
    Map<String, dynamic>? earning;
    String? error;
    try {
      final taskId = widget.task.remoteId;
      if (taskId == null) throw Exception('Task reference missing');
      final res = await ApiService.completeTask(
        taskId,
        _otpCtrl.text.trim(),
        paymentMethod: 'cash',
      );
      earning = res['earning'] is Map
          ? Map<String, dynamic>.from(res['earning'] as Map)
          : <String, dynamic>{};
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _loading = false);

    if (earning == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? AppL10n.of(context)!.browseInvalidOtp), backgroundColor: T.red),
      );
      return;
    }

    _locTimer?.cancel();

    // Show the cash + commission breakdown, then prompt a rating of the
    // customer before leaving the active task screen.
    await showEarningResultSheet(context, earning);
    if (!mounted) return;
    final customerId =
        widget.task.postedBy.remoteId ?? widget.task.postedBy.id.toString();
    await showRateCustomerSheet(
      context,
      taskId: _taskId,
      customerId: customerId,
      customerName: widget.task.postedBy.name,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _locTimer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(
        l.browseActiveTask,
        actions: [
          SafetyMenuButton(
            reportedId: widget.task.postedBy.remoteId ??
                widget.task.postedBy.id.toString(),
            reportedName: widget.task.postedBy.name,
            taskId: widget.task.remoteId ?? widget.task.id.toString(),
            iconColor: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: T.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryIconChip(
                          category: widget.task.category.name,
                          size: 48,
                          iconSize: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.title,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: T.text1,
                              ),
                            ),
                            Text(
                              widget.task.postedBy.name,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: T.text3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${widget.task.budget.toInt()}',
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: T.primary,
                            ),
                          ),
                          Text(
                            l.browseYouEarnAmt((widget.task.budget * 0.90).toInt().toString()),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: T.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Text(
                    widget.task.description,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: T.text2,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  taskPhotosSection(context, widget.task.images, l.browsePhotos),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: T.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        widget.task.location,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: T.text1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: T.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: T.primaryLight,
                    child: Text(
                      initialFor(widget.task.postedBy.name),
                      style: GoogleFonts.nunito(
                        color: T.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.postedBy.name,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: T.text1,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: T.star, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              l.browseRatingLabel(widget.task.postedBy.rating.toString()),
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: T.text3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final data = await ApiService.createConversation(
                        otherUserId: widget.task.postedBy.remoteId ?? widget.task.postedBy.id.toString(),
                        taskId: widget.task.remoteId ?? widget.task.id.toString(),
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
                          SnackBar(content: Text(l.browseFailedOpenChat)),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text(
                      l.browseChat,
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // On my way + live location sharing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: T.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _onTheWay
                            ? Icons.near_me_rounded
                            : Icons.near_me_outlined,
                        color: T.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.browseHeadingToCustomer,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: T.text1,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _onTheWay
                        ? l.browseOtwActiveBody
                        : l.browseOtwIdleBody,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: T.text2,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: _onTheWay
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: T.greenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: T.green, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l.browseCustomerNotified,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: T.green,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _otwLoading ? null : _markOnTheWay,
                            icon: _otwLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.near_me_rounded, size: 16),
                            label: Text(
                              _otwLoading ? l.browseNotifying : l.actionOnMyWay,
                              style: GoogleFonts.nunito(
                                  fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Back out of the job
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancelJob,
                icon: _cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: T.red, strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined, size: 16),
                label: Text(
                  _cancelling ? l.browseCancelling : l.browseCancelJob,
                  style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: T.red,
                  side: const BorderSide(color: T.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // OTP entry
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: T.greenLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: T.primary.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_open_outlined, color: T.primary),
                      const SizedBox(width: 8),
                      Text(
                        l.browseEnterCompletionOtp,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: T.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.browseOtpPrompt,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: T.text2,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12,
                      color: T.primary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '• • • •',
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 22,
                        color: T.text3,
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: T.primary, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: T.primary, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: T.primary, width: 3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _verify,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              l.browseVerifyComplete,
                              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Back-out (cancel job) sheet ────────────────────────────

class _CancelJobSheet extends StatefulWidget {
  const _CancelJobSheet();

  @override
  State<_CancelJobSheet> createState() => _CancelJobSheetState();
}

class _CancelJobSheetState extends State<_CancelJobSheet> {
  static const _reasonCodes = [
    'emergency',
    'too_far',
    'schedule',
    'other',
  ];
  String _selected = _reasonCodes.first;
  final _noteCtrl = TextEditingController();

  String _reasonLabel(AppL10n l, String code) {
    switch (code) {
      case 'too_far':
        return l.browseReasonTooFar;
      case 'schedule':
        return l.browseReasonSchedule;
      case 'other':
        return l.browseReasonOther;
      default:
        return l.browseReasonEmergency;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: T.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.browseBackOutTitle,
            style: GoogleFonts.nunito(
                fontSize: 20, fontWeight: FontWeight.w900, color: T.text1),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: T.yellowLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: T.yellow.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: T.yellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.browseBackOutWarning,
                  style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: T.yellow,
                      height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text(
            l.browseReason,
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w800, color: T.text1),
          ),
          const SizedBox(height: 8),
          ..._reasonCodes.map((r) {
            final selected = _selected == r;
            return InkWell(
              onTap: () => setState(() => _selected = r),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? T.primary : T.text3,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _reasonLabel(l, r),
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: T.text1),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w600, color: T.text1),
            decoration: InputDecoration(
              hintText: l.browseAddNote,
              hintStyle: GoogleFonts.nunito(fontSize: 13, color: T.text3),
              filled: true,
              fillColor: T.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: T.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: T.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: T.text2,
                  side: const BorderSide(color: T.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l.browseKeepJob,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final note = _noteCtrl.text.trim();
                  final label = _reasonLabel(l, _selected);
                  final reason = note.isNotEmpty && _selected == 'other'
                      ? note
                      : (note.isNotEmpty ? '$label: $note' : label);
                  Navigator.pop(context, {'reason': reason});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: T.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l.browseCancelJob,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Rate-the-customer sheet ────────────────────────────────

/// Prompt the tasker to rate the customer after a completed job.
/// Posts to /reviews/ with the customer as `reviewed_user_id`.
Future<void> showRateCustomerSheet(
  BuildContext context, {
  required String taskId,
  required String customerId,
  required String customerName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RateCustomerSheet(
      taskId: taskId,
      customerId: customerId,
      customerName: customerName,
    ),
  );
}

class _RateCustomerSheet extends StatefulWidget {
  final String taskId;
  final String customerId;
  final String customerName;
  const _RateCustomerSheet({
    required this.taskId,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<_RateCustomerSheet> createState() => _RateCustomerSheetState();
}

class _RateCustomerSheetState extends State<_RateCustomerSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _submitting) return;
    final l = AppL10n.of(context)!;
    setState(() => _submitting = true);
    String? error;
    try {
      await ApiService.submitReview(
        widget.taskId,
        widget.customerId,
        _rating,
        _commentCtrl.text,
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: T.red),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.browseThanksRating)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: T.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l.browseRateCustomer(widget.customerName),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 20, fontWeight: FontWeight.w900, color: T.text1),
          ),
          const SizedBox(height: 6),
          Text(
            l.browseRateExperience,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: T.text3,
                height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? T.star : T.text3,
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w600, color: T.text1),
            decoration: InputDecoration(
              hintText: l.browseAddComment,
              hintStyle: GoogleFonts.nunito(fontSize: 13, color: T.text3),
              filled: true,
              fillColor: T.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: T.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: T.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_rating == 0 || _submitting) ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(l.browseSubmitRating,
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: Text(l.portfolioSkip,
                style: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w700, color: T.text3)),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: T.text1),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _InfoChip(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: T.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: T.primary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w600, color: T.primary),
          ),
        ],
      ),
    );
  }
}

class _AnalysisChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AnalysisChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? T.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? T.primary : T.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: T.primary.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : T.text3),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? T.primary : T.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final TaskModel task;
  const _SuccessSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AnimatedSuccessIcon(),
          const SizedBox(height: 14),
          Text(
            l.browseAppSubmitted,
            style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: T.text1),
          ),
          const SizedBox(height: 8),
          Text(
            l.browseAppSubmittedBody(task.title),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: T.text3,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: T.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l.browseAppSubmittedNote,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: T.green,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Ask the shell to switch to the Applied tab (index 2), then
                // close the sheet + ApplyScreen so that tab is revealed.
                TaskerState().requestTab(2);
                Navigator.pop(context); // Pop sheet; .then() pops ApplyScreen
              },
              child: Text(
                l.browseViewMyApps,
                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.browseBrowseMore,
              style: GoogleFonts.nunito(color: T.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
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
              color: T.primaryLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: T.primary.withValues(alpha: 0.3 * val),
                  blurRadius: 20 * val,
                  spreadRadius: 5 * val,
                ),
              ],
            ),
            child: const Icon(Icons.celebration_rounded,
                size: 48, color: T.primary),
          ),
        );
      },
    );
  }
}
