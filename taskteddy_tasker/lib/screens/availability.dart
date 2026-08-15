import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

// ════════════════════════════════════════════════════════
//  AVAILABILITY SCHEDULE EDITOR
//  Weekly working hours, one row per weekday. Times are stored
//  as minutes-from-midnight (e.g. 540 = 09:00, 1080 = 18:00).
// ════════════════════════════════════════════════════════

const List<String> _dayShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// A single editable weekday row.
class _DayRow {
  final int dayOfWeek; // 0 = Mon .. 6 = Sun
  bool isAvailable;
  int startMinute;
  int endMinute;
  _DayRow({
    required this.dayOfWeek,
    required this.isAvailable,
    required this.startMinute,
    required this.endMinute,
  });
}

String _fmtMinutes(int minutes) {
  final m = minutes.clamp(0, 24 * 60);
  final h24 = (m ~/ 60) % 24;
  final min = m % 60;
  final period = h24 < 12 ? 'AM' : 'PM';
  var h12 = h24 % 12;
  if (h12 == 0) h12 = 12;
  final mm = min.toString().padLeft(2, '0');
  return '$h12:$mm $period';
}

/// Localized full weekday name for a 0=Mon..6=Sun index.
String _dayName(AppL10n l, int i) {
  switch (i) {
    case 0:
      return l.dayMonday;
    case 1:
      return l.dayTuesday;
    case 2:
      return l.dayWednesday;
    case 3:
      return l.dayThursday;
    case 4:
      return l.dayFriday;
    case 5:
      return l.daySaturday;
    default:
      return l.daySunday;
  }
}

/// Concise summary such as "Mon-Sat, 9:00 AM - 6:00 PM" for the rows.
String _availabilitySummary(AppL10n l, List<_DayRow> rows) {
  final on = rows.where((r) => r.isAvailable).toList();
  if (on.isEmpty) return l.availNotSetTap;
  // Contiguous weekday range label.
  final days = on.map((r) => r.dayOfWeek).toList()..sort();
  final bool contiguous = days.length == (days.last - days.first + 1);
  final String dayLabel = days.length == 7
      ? l.profileEveryDay
      : contiguous
          ? '${_dayShort[days.first]}-${_dayShort[days.last]}'
          : days.map((d) => _dayShort[d]).join(', ');
  // Common time range when all active days share the same window.
  final firstStart = on.first.startMinute;
  final firstEnd = on.first.endMinute;
  final sameHours =
      on.every((r) => r.startMinute == firstStart && r.endMinute == firstEnd);
  if (sameHours) {
    return '$dayLabel, ${_fmtMinutes(firstStart)} - ${_fmtMinutes(firstEnd)}';
  }
  return '$dayLabel - ${l.profileHoursVary}';
}

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<_DayRow> _rows = [];

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
      final data = await ApiService.getAvailability();
      final byDay = {for (final d in data) (d['day_of_week'] as num?)?.toInt(): d};
      // Always render 7 rows; fill any gaps with a sensible default.
      final rows = List.generate(7, (i) {
        final d = byDay[i];
        return _DayRow(
          dayOfWeek: i,
          isAvailable: d?['is_available'] == true,
          startMinute: (d?['start_minute'] as num?)?.toInt() ?? 540,
          endMinute: (d?['end_minute'] as num?)?.toInt() ?? 1080,
        );
      });
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  Future<void> _pickTime(_DayRow row, bool isStart) async {
    final l = AppL10n.of(context)!;
    final initialMin = isStart ? row.startMinute : row.endMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (initialMin ~/ 60) % 24, minute: initialMin % 60),
      helpText: isStart ? l.availStartTime : l.availEndTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: T.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (isStart) {
        row.startMinute = minutes;
        if (row.endMinute <= row.startMinute) {
          row.endMinute = (row.startMinute + 60).clamp(0, 24 * 60);
        }
      } else {
        if (minutes <= row.startMinute) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.availEndAfterStart,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              backgroundColor: T.red,
              behavior: SnackBarBehavior.floating,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        row.endMinute = minutes;
      }
    });
  }

  Future<void> _save() async {
    final l = AppL10n.of(context)!;
    setState(() => _saving = true);
    try {
      final payload = _rows
          .map((r) => {
                'day_of_week': r.dayOfWeek,
                'start_minute': r.startMinute,
                'end_minute': r.endMinute,
                'is_available': r.isAvailable,
              })
          .toList();
      await ApiService.updateAvailability(payload);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.availSaved,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: T.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: T.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(l.availability),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: T.primary))
          : _error != null
              ? FriendlyState(
                  icon: Icons.cloud_off_rounded,
                  iconColor: T.text3,
                  title: _error!,
                  action: ElevatedButton(
                    onPressed: _load,
                    child: Text(l.actionRetry,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                  ),
                )
              : Column(
                  children: [
                    _summaryBanner(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _rows.length,
                        itemBuilder: (_, i) => _dayCard(_rows[i]),
                      ),
                    ),
                  ],
                ),
      bottomSheet: (_loading || _error != null)
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: T.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(l.availSaveSchedule,
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
    );
  }

  Widget _summaryBanner() {
    final l = AppL10n.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.primary.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: T.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.availYourWeeklyHours,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: T.text3)),
                const SizedBox(height: 2),
                Text(_availabilitySummary(l, _rows),
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: T.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(_DayRow row) {
    final l = AppL10n.of(context)!;
    final on = row.isAvailable;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.card(
        borderColor: on ? T.primary.withValues(alpha: .35) : T.border,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_dayName(l, row.dayOfWeek),
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: on ? T.text1 : T.text3)),
              ),
              Text(on ? l.availAvailableDay : l.availOff,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: on ? T.green : T.text3)),
              const SizedBox(width: 6),
              Switch(
                value: on,
                activeThumbColor: T.green,
                onChanged: (v) => setState(() => row.isAvailable = v),
              ),
            ],
          ),
          if (on) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _timeButton(
                    label: l.availStart,
                    value: _fmtMinutes(row.startMinute),
                    onTap: () => _pickTime(row, true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward, size: 16, color: T.text3),
                ),
                Expanded(
                  child: _timeButton(
                    label: l.availEnd,
                    value: _fmtMinutes(row.endMinute),
                    onTap: () => _pickTime(row, false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: T.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: T.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: T.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: T.text3)),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: T.text1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
