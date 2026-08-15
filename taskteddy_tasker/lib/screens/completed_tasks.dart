import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  double _total = 0;
  int _count = 0;

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
      final data = await ApiService.getEarnings();
      if (!mounted) return;
      setState(() {
        _rows = ((data['earnings'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _total = (data['total_earnings'] as num?)?.toDouble() ?? 0;
        _count = (data['completed_tasks'] as num?)?.toInt() ?? _rows.length;
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

  String _timeAgo(AppL10n l, String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return l.timeDaysAgo(diff.inDays);
    if (diff.inHours >= 1) return l.timeHoursAgo(diff.inHours);
    return l.notifJustNow;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      body: Column(children: [
        GradientHeader(title: l.profileCompletedTasks),
        Expanded(
          child: RefreshIndicator(
            color: T.primary,
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: T.primary))
                : _error != null
                    ? _centered(Icons.error_outline, _error!, retry: true)
                    : Column(children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.panelGradient,
                        borderRadius:
                            BorderRadius.circular(AppTheme.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: T.primary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SumItem('$_count', l.profileTasksDone),
                            Container(
                                width: 1,
                                height: 34,
                                color: Colors.white.withValues(alpha: .28)),
                            _SumItem('₹${_total.toStringAsFixed(0)}',
                                l.walletTotalEarned),
                          ]),
                    ),
                    Expanded(
                      child: _rows.isEmpty
                          ? _centered(Icons.checklist_rounded,
                              l.completedEmptyBody)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _rows.length,
                              itemBuilder: (_, i) {
                                final r = _rows[i];
                                final task = r['task'] is Map ? r['task'] as Map : null;
                                final title = (task?['title'] ??
                                        r['description'] ??
                                        'Completed task')
                                    .toString();
                                final amount =
                                    (r['amount'] as num?)?.toDouble() ?? 0;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: AppTheme.card(),
                                  child: Row(children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                          color: T.greenLight,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: const Center(
                                          child: Icon(Icons.check_circle_outline,
                                              color: T.green, size: 22)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.nunito(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: T.text1)),
                                          const SizedBox(height: 2),
                                          Text(_timeAgo(l, r['created_at']?.toString()),
                                              style: GoogleFonts.nunito(
                                                  fontSize: 13,
                                                  color: T.text3,
                                                  fontWeight: FontWeight.w500)),
                                        ])),
                                    const SizedBox(width: 8),
                                    Text('+₹${amount.toStringAsFixed(0)}',
                                        style: GoogleFonts.nunito(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: T.green)),
                                  ]),
                                );
                              },
                            ),
                    ),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _centered(IconData icon, String msg, {bool retry = false}) =>
      ListView(
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 48, color: T.text3),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 15, color: T.text3)),
          if (retry) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _load,
                child: Text(AppL10n.of(context)!.actionRetry,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700, color: T.primary)),
              ),
            ),
          ],
        ],
      );
}

class _SumItem extends StatelessWidget {
  final String value, label;
  const _SumItem(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85))),
      ]);
}
