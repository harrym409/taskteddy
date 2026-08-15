import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _supportDialNumber = '+916239866862';
  static const _supportDisplayNumber = '+91 6239866862';
  static const _supportEmail = 'support@taskteddy.com';

  List<_SupportTopic> _topics(AppL10n l) => [
    _SupportTopic(
      kind: 'tasks',
      title: l.helpT1Title,
      subtitle: l.helpT1Sub,
      faqs: [
        _FaqItem(question: l.helpT1Q1, answer: l.helpT1A1),
        _FaqItem(question: l.helpT1Q2, answer: l.helpT1A2),
        _FaqItem(question: l.helpT1Q3, answer: l.helpT1A3),
        _FaqItem(question: l.helpT1Q4, answer: l.helpT1A4),
        _FaqItem(question: l.helpT1Q5, answer: l.helpT1A5),
        _FaqItem(question: l.helpT1Q6, answer: l.helpT1A6),
      ],
    ),
    _SupportTopic(
      kind: 'earnings',
      title: l.helpT2Title,
      subtitle: l.helpT2Sub,
      faqs: [
        _FaqItem(question: l.helpT2Q1, answer: l.helpT2A1),
        _FaqItem(question: l.helpT2Q2, answer: l.helpT2A2),
        _FaqItem(question: l.helpT2Q3, answer: l.helpT2A3),
        _FaqItem(question: l.helpT2Q4, answer: l.helpT2A4),
        _FaqItem(question: l.helpT2Q5, answer: l.helpT2A5),
      ],
    ),
    _SupportTopic(
      kind: 'verification',
      title: l.helpT3Title,
      subtitle: l.helpT3Sub,
      faqs: [
        _FaqItem(question: l.helpT3Q1, answer: l.helpT3A1),
        _FaqItem(question: l.helpT3Q2, answer: l.helpT3A2),
        _FaqItem(question: l.helpT3Q3, answer: l.helpT3A3),
        _FaqItem(question: l.helpT3Q4, answer: l.helpT3A4),
        _FaqItem(question: l.helpT3Q5, answer: l.helpT3A5),
      ],
    ),
    _SupportTopic(
      kind: 'safety',
      title: l.helpT4Title,
      subtitle: l.helpT4Sub,
      faqs: [
        _FaqItem(question: l.helpT4Q1, answer: l.helpT4A1),
        _FaqItem(question: l.helpT4Q2, answer: l.helpT4A2),
        _FaqItem(question: l.helpT4Q3, answer: l.helpT4A3),
        _FaqItem(question: l.helpT4Q4, answer: l.helpT4A4),
      ],
    ),
  ];

  void _openTicketComposer() {
    final l = AppL10n.of(context)!;
    final subject = TextEditingController();
    final message = TextEditingController();
    bool sending = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.helpMessageSupport,
                  style: GoogleFonts.nunito(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(l.helpRespond24,
                  style: GoogleFonts.nunito(fontSize: 14, color: T.text3)),
              const SizedBox(height: 14),
              TextField(
                controller: subject,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: l.helpSubject,
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: message,
                maxLines: 4,
                maxLength: 4000,
                decoration: InputDecoration(
                  hintText: l.helpDescribeIssue,
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: T.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: sending
                      ? null
                      : () async {
                          if (subject.text.trim().length < 3 ||
                              message.text.trim().length < 5) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text(l.helpAddSubjectDesc)),
                            );
                            return;
                          }
                          setSheet(() => sending = true);
                          try {
                            await ApiService.createSupportTicket(
                              subject: subject.text.trim(),
                              message: message.text.trim(),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.helpTicketSent),
                                backgroundColor: T.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } catch (e) {
                            setSheet(() => sending = false);
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text(e
                                      .toString()
                                      .replaceAll('Exception: ', ''))),
                            );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l.helpSend,
                          style: GoogleFonts.nunito(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMyTickets() {
    final l = AppL10n.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ApiService.getMyTickets(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final tickets = snap.data!;
            if (tickets.isEmpty) {
              return Center(
                child: Text(l.helpNoTickets,
                    style:
                        GoogleFonts.nunito(fontSize: 16, color: T.text3)),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = tickets[i];
                final resolved = t['status'] == 'resolved';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: T.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: T.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t['subject']?.toString() ?? '',
                                style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: resolved ? T.greenLight : T.yellowLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              resolved ? l.helpResolved : l.helpOpen,
                              style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: resolved ? T.green : T.yellow),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(t['message']?.toString() ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                              fontSize: 13.5, color: T.text2)),
                      if ((t['reply'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: T.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(l.helpSupportReply(t['reply'].toString()),
                              style: GoogleFonts.nunito(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: T.text1)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _supportDialNumber);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context)!.helpCouldNotDial)),
        );
      }
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=TaskTeddy Tasker Support',
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context)!.helpCouldNotEmail)),
        );
      }
    }
  }

  IconData _topicIcon(String kind) {
    switch (kind) {
      case 'tasks':
        return Icons.assignment_outlined;
      case 'earnings':
        return Icons.payments_outlined;
      case 'verification':
        return Icons.badge_outlined;
      case 'safety':
        return Icons.gpp_good_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _topicTint(String kind) {
    switch (kind) {
      case 'tasks':
        return T.primary;
      case 'earnings':
        return T.green;
      case 'verification':
        return T.blue;
      case 'safety':
        return T.yellow;
      default:
        return T.text2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(
        l.profileHelpSupport,
        actions: [
          IconButton(
            tooltip: l.helpMyTicketsTooltip,
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: _showMyTickets,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: T.border.withValues(alpha: .7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Text(
                  l.helpReachOut(_supportDisplayNumber, _supportEmail),
                  style: GoogleFonts.nunito(
                    color: T.text3,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _callSupport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: T.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l.helpCallUs,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _emailSupport,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: T.primary),
                        foregroundColor: T.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l.helpEmailUs,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openTicketComposer,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: T.border),
                    foregroundColor: T.text1,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.support_agent_rounded,
                      size: 20, color: T.primary),
                  label: Text(
                    l.helpMessageSupport,
                    style: GoogleFonts.nunito(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        children: [
          // ── Gradient Need Quick Help Card ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [T.primaryLight, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: T.primaryLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: T.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.helpNeedQuickHelp,
                        style: GoogleFonts.nunito(
                          color: T.text1,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l.helpFindAnswers,
                        style: GoogleFonts.nunito(
                          color: T.text3,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── My Tickets Card ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: T.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .03),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: T.blueLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: T.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.helpMyDisputes,
                        style: GoogleFonts.nunito(
                          color: T.text1,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l.helpNoDisputes,
                        style: GoogleFonts.nunito(
                          color: T.text3,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            l.helpBrowseTopics,
            style: GoogleFonts.nunito(
              color: T.text1,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          // ── Support Topics List ──
          ..._topics(l).map(
            (topic) {
              final tint = _topicTint(topic.kind);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _SupportTopicScreen(
                          title: topic.title,
                          faqs: topic.faqs,
                          onContactSupport: _callSupport,
                          onEmailSupport: _emailSupport,
                          supportPhoneDisplay: _supportDisplayNumber,
                          supportEmail: _supportEmail,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: T.border),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .025),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_topicIcon(topic.kind),
                              color: tint, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.title,
                                style: GoogleFonts.nunito(
                                  color: T.text1,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topic.subtitle,
                                style: GoogleFonts.nunito(
                                  color: T.text3,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: T.text3, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportTopic {
  final String kind, title, subtitle;
  final List<_FaqItem> faqs;
  const _SupportTopic({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.faqs,
  });
}

class _FaqItem {
  final String question, answer;
  const _FaqItem({
    required this.question,
    required this.answer,
  });
}

class _SupportTopicScreen extends StatefulWidget {
  const _SupportTopicScreen({
    required this.title,
    required this.faqs,
    required this.onContactSupport,
    required this.onEmailSupport,
    required this.supportPhoneDisplay,
    required this.supportEmail,
  });

  final String title;
  final List<_FaqItem> faqs;
  final Future<void> Function() onContactSupport;
  final Future<void> Function() onEmailSupport;
  final String supportPhoneDisplay;
  final String supportEmail;

  @override
  State<_SupportTopicScreen> createState() => _SupportTopicScreenState();
}

class _SupportTopicScreenState extends State<_SupportTopicScreen> {
  final Set<int> _expanded = <int>{};

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(widget.title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            l.helpRelatedTo(widget.title),
            style: GoogleFonts.nunito(
              color: T.text1,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(widget.faqs.length, (index) {
            final faq = widget.faqs[index];
            final open = _expanded.contains(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: T.bg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        if (open) {
                          _expanded.remove(index);
                        } else {
                          _expanded.add(index);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  faq.question,
                                  style: GoogleFonts.nunito(
                                    color: T.text1,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                open ? Icons.remove : Icons.add,
                                color: T.text2,
                                size: 24,
                              ),
                            ],
                          ),
                          if (open) ...[
                            const SizedBox(height: 10),
                            Text(
                              faq.answer,
                              style: GoogleFonts.nunito(
                                color: T.text2,
                                fontSize: 17,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),

          // ── "Can't find your answer?" support details card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: T.greenLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: T.green),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.helpCantFind,
                      style: GoogleFonts.nunito(
                        color: T.text1,
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l.helpTeamHere,
                      style: GoogleFonts.nunito(
                        color: T.text3,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: widget.onContactSupport,
                      child: Row(
                        children: [
                          const Icon(Icons.call, color: T.green, size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.supportPhoneDisplay,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                color: T.green,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: widget.onEmailSupport,
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: T.green, size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.supportEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                color: T.green,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final cta = InkWell(
                  onTap: widget.onContactSupport,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: T.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 34),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.support_agent,
                                color: T.green, size: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: cta),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.support_agent,
                          color: T.green, size: 38),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: details),
                    const SizedBox(width: 8),
                    cta,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

