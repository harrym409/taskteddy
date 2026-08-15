import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../theme/category_icons.dart';
import '../l10n/app_localizations.dart';

// Report reason codes (backend). Labels are resolved via [_reasonLabel].
const List<String> _reportReasonCodes = [
  'inappropriate_behaviour',
  'no_show',
  'safety_concern',
  'fraud_or_scam',
  'poor_quality',
  'spam',
  'other',
];

// Human label for a backend report-reason code, in the active locale.
String _reasonLabel(AppL10n l, String code) {
  switch (code) {
    case 'inappropriate_behaviour':
      return l.reportReasonInappropriate;
    case 'no_show':
      return l.reportReasonNoShow;
    case 'safety_concern':
      return l.reportReasonSafety;
    case 'fraud_or_scam':
      return l.reportReasonFraud;
    case 'poor_quality':
      return l.reportReasonPoorQuality;
    case 'spam':
      return l.reportReasonSpam;
    default:
      return l.reportReasonOther;
  }
}

/// A themed overflow menu (report / block) shown wherever the tasker sees a
/// customer as a person (task detail, chat header). [iconColor] lets the caller
/// match a coloured app bar. [onBlocked] fires after a successful block so the
/// host screen can pop or refresh.
class SafetyMenuButton extends StatelessWidget {
  final String reportedId;
  final String reportedName;
  final String? taskId;
  final Color iconColor;
  final VoidCallback? onBlocked;

  const SafetyMenuButton({
    super.key,
    required this.reportedId,
    required this.reportedName,
    this.taskId,
    this.iconColor = T.text2,
    this.onBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final disabled = reportedId.trim().isEmpty;
    return PopupMenuButton<String>(
      enabled: !disabled,
      icon: Icon(Icons.more_vert, color: iconColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'report') {
          showReportSheet(context,
              reportedId: reportedId, reportedName: reportedName, taskId: taskId);
        } else if (value == 'block') {
          showBlockConfirm(context,
              blockedId: reportedId, name: reportedName, onBlocked: onBlocked);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'report',
          child: Row(children: [
            const Icon(Icons.flag_outlined, size: 18, color: T.text2),
            const SizedBox(width: 10),
            Text(l.actionReport,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: T.text1)),
          ]),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(children: [
            const Icon(Icons.block, size: 18, color: T.red),
            const SizedBox(width: 10),
            Text(l.actionBlock,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: T.red)),
          ]),
        ),
      ],
    );
  }
}

/// Bottom sheet: pick a reason (+ optional detail) and file a safety report.
Future<void> showReportSheet(
  BuildContext context, {
  required String reportedId,
  required String reportedName,
  String? taskId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReportSheet(
      reportedId: reportedId,
      reportedName: reportedName,
      taskId: taskId,
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  final String reportedId;
  final String reportedName;
  final String? taskId;
  const _ReportSheet({
    required this.reportedId,
    required this.reportedName,
    this.taskId,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _detailCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _submitting = true);
    final l = AppL10n.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.reportUser(
        reportedId: widget.reportedId,
        reason: _reason!,
        detail: _detailCtrl.text,
        taskId: widget.taskId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.reportSubmitted,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: T.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
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
    final name = widget.reportedName.trim().isEmpty
        ? l.reportThisUser
        : widget.reportedName.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            Text(l.reportUserTitle(name),
                style: GoogleFonts.nunito(
                    fontSize: 20, fontWeight: FontWeight.w900, color: T.text1)),
            const SizedBox(height: 4),
            Text(l.reportChooseReason,
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w600, color: T.text3)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reportReasonCodes.map((code) {
                final label = _reasonLabel(l, code);
                final sel = _reason == code;
                return GestureDetector(
                  onTap: () => setState(() => _reason = code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? T.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? T.primary : T.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      label,
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
            Text(l.reportDetailsOptional,
                style: GoogleFonts.nunito(
                    fontSize: 14, fontWeight: FontWeight.w800, color: T.text1)),
            const SizedBox(height: 8),
            TextField(
              controller: _detailCtrl,
              maxLines: 3,
              maxLength: 300,
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: l.reportDetailHint,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_reason == null || _submitting) ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: T.primary),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(l.reportSubmit,
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirm dialog then block the user. Calls [onBlocked] after success.
Future<void> showBlockConfirm(
  BuildContext context, {
  required String blockedId,
  required String name,
  VoidCallback? onBlocked,
}) async {
  final l = AppL10n.of(context)!;
  final display = name.trim().isEmpty ? l.reportThisUser : name.trim();
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l.blockConfirmTitle(display),
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      content: Text(
        l.blockConfirmBody,
        style: GoogleFonts.nunito(color: T.text2, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.actionCancel,
              style: GoogleFonts.nunito(
                  color: T.text3, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.actionBlock,
              style: GoogleFonts.nunito(
                  color: T.red, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );

  if (confirm != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ApiService.blockUser(blockedId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.blockedSuccess(display),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: T.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    onBlocked?.call();
  } catch (e) {
    messenger.showSnackBar(
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

// ── Blocked users management screen ─────────────────────────────────────────

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _blocks = [];

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
      final rows = await ApiService.getBlocks();
      if (!mounted) return;
      setState(() {
        _blocks = rows;
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

  /// Extract the blocked user's map + id + name from a flexible payload shape.
  Map<String, String> _blockedIdAndName(Map<String, dynamic> row) {
    final user = row['blocked'] is Map
        ? Map<String, dynamic>.from(row['blocked'] as Map)
        : row['blocked_user'] is Map
            ? Map<String, dynamic>.from(row['blocked_user'] as Map)
            : row;
    final id = (user['id'] ?? row['blocked_id'] ?? '').toString();
    final name = user['name']?.toString() ?? '';
    return {'id': id, 'name': name};
  }

  Future<void> _unblock(String id, String name) async {
    if (id.isEmpty) return;
    final l = AppL10n.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.unblockUser(id);
      if (!mounted) return;
      setState(() {
        _blocks = _blocks.where((r) {
          final info = _blockedIdAndName(r);
          return info['id'] != id;
        }).toList();
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              l.unblockedSuccess(name.trim().isEmpty ? l.blockedUserFallback : name.trim()),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: T.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
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
      appBar: AppBar(title: Text(l.blockedUsers)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: T.primary))
          : _error != null
              ? _errorView()
              : _blocks.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: T.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _blocks.length,
                        itemBuilder: (_, i) {
                          final info = _blockedIdAndName(_blocks[i]);
                          final name = info['name'] ?? '';
                          final id = info['id'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: T.border),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: T.primaryLight,
                                child: Text(
                                  initialFor(name),
                                  style: GoogleFonts.nunito(
                                      color: T.primary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name.trim().isEmpty ? l.blockedUserFallback : name.trim(),
                                  style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: T.text1),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => _unblock(id, name),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: T.primary,
                                  side: const BorderSide(color: T.primary),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(l.unblockAction,
                                    style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _emptyView() {
    final l = AppL10n.of(context)!;
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 52, color: T.text3),
            const SizedBox(height: 12),
            Text(l.noBlockedUsers,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: T.text3)),
            const SizedBox(height: 6),
            Text(l.blockedEmptyBody,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: T.text3)),
          ],
        ),
      );
  }

  Widget _errorView() {
    final l = AppL10n.of(context)!;
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52, color: T.text3),
            const SizedBox(height: 12),
            Text(_error ?? l.notifSomethingWrong,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: T.text3)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: T.primary),
              child: Text(l.actionRetry,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      );
  }
}
