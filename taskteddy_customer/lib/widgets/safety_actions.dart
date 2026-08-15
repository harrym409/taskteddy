import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';

/// Report reason wire values accepted by POST /api/safety/report (backend enum).
const List<String> kReportReasonValues = [
  'inappropriate_behaviour',
  'no_show',
  'safety_concern',
  'fraud_or_scam',
  'poor_quality',
  'spam',
  'other',
];

/// Localized, human-readable label for a report reason wire value.
String reportReasonLabel(AppL10n l, String value) {
  switch (value) {
    case 'inappropriate_behaviour':
      return l.reasonInappropriate;
    case 'no_show':
      return l.reasonNoShow;
    case 'safety_concern':
      return l.reasonSafety;
    case 'fraud_or_scam':
      return l.reasonFraud;
    case 'poor_quality':
      return l.reasonPoorQuality;
    case 'spam':
      return l.reasonSpam;
    default:
      return l.reasonOther;
  }
}

/// Opens the report sheet for [reportedId]. Returns true when a report was
/// submitted successfully.
Future<bool> showReportUserSheet(
  BuildContext context, {
  required String reportedId,
  String? userName,
  String? taskId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReportSheet(
      reportedId: reportedId,
      userName: userName,
      taskId: taskId,
    ),
  );
  return result == true;
}

/// Confirms and blocks [blockedId]. Returns true when the user was blocked so
/// the caller can refresh and hide their content.
Future<bool> confirmAndBlockUser(
  BuildContext context, {
  required String blockedId,
  String? userName,
}) async {
  final l = AppL10n.of(context)!;
  final name = (userName != null && userName.trim().isNotEmpty)
      ? userName.trim()
      : l.safetyThisUser;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.block, color: C.red, size: 22),
          const SizedBox(width: 8),
          Text(l.safetyBlockUser,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ],
      ),
      content: Text(
        l.safetyBlockBody(name),
        style: GoogleFonts.nunito(fontSize: 14, color: C.text2, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: C.red,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.block,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  try {
    await ApiService.blockUser(blockedId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.safetyUserBlocked(name),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: C.text1,
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: C.red,
        ),
      );
    }
    return false;
  }
}

/// Overflow (three-dot) menu offering Report / Block for a person. Call
/// [onBlocked] after a successful block so the host can refresh.
class SafetyOverflowButton extends StatelessWidget {
  const SafetyOverflowButton({
    super.key,
    required this.reportedId,
    this.userName,
    this.taskId,
    this.onBlocked,
    this.iconColor = C.text3,
    this.iconSize = 20,
  });

  final String reportedId;
  final String? userName;
  final String? taskId;
  final VoidCallback? onBlocked;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l.safetyMoreOptions,
      icon: Icon(Icons.more_vert, color: iconColor, size: iconSize),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      onSelected: (value) async {
        if (value == 'report') {
          await showReportUserSheet(
            context,
            reportedId: reportedId,
            userName: userName,
            taskId: taskId,
          );
        } else if (value == 'block') {
          final blocked = await confirmAndBlockUser(
            context,
            blockedId: reportedId,
            userName: userName,
          );
          if (blocked) onBlocked?.call();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, size: 18, color: C.text2),
              const SizedBox(width: 10),
              Text(l.report,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, color: C.text1)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              const Icon(Icons.block, size: 18, color: C.red),
              const SizedBox(width: 10),
              Text(l.block,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, color: C.red)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.reportedId,
    this.userName,
    this.taskId,
  });

  final String reportedId;
  final String? userName;
  final String? taskId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _detail = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    final l = AppL10n.of(context)!;
    setState(() => _submitting = true);
    try {
      await ApiService.reportUser(
        reportedId: widget.reportedId,
        reason: _reason!,
        detail: _detail.text,
        taskId: widget.taskId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.safetyReportThanks,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: C.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: C.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final name = (widget.userName != null && widget.userName!.trim().isNotEmpty)
        ? widget.userName!.trim()
        : null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: C.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name == null ? l.safetyReportUser : l.safetyReportUserNamed(name),
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: C.text1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.safetyReportSubtitle,
            style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w600, color: C.text3),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kReportReasonValues.map((value) {
              final selected = _reason == value;
              return ChoiceChip(
                label: Text(reportReasonLabel(l, value)),
                selected: selected,
                onSelected: (_) => setState(() => _reason = value),
                labelStyle: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : C.text2,
                ),
                selectedColor: C.primary,
                backgroundColor: C.bg,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(C.rChip),
                  side: BorderSide(
                      color: selected ? C.primary : C.border),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _detail,
            maxLines: 3,
            maxLength: 500,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: l.safetyReportDetailHint,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_reason == null || _submitting) ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(l.safetySubmitReport,
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
