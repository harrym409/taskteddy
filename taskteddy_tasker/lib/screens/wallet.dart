import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/tasker_state.dart';
import '../l10n/app_localizations.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override State<WalletScreen> createState() => _WalletState();
}

class _WalletState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late AppL10n _l;
  final TaskerState _state = TaskerState();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _state.addListener(_onStateChange);
    _state.loadWallet();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          if (_state.walletBalance < 0)
            SliverToBoxAdapter(child: _buildDuesBanner()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: T.primary,
                labelColor: T.primary,
                unselectedLabelColor: T.text3,
                labelStyle: GoogleFonts.nunito(fontSize: 14.5, fontWeight: FontWeight.w800),
                unselectedLabelStyle: GoogleFonts.nunito(fontSize: 14.5, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: _l.walletTransactions),
                  Tab(text: _l.walletEarnings),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _TransactionsList(),
                _EarningsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // One cohesive gradient hero: title, the balance, month/jobs mini-stats, and
  // the withdraw action — replaces the old stacked app-bar + balance card.
  Widget _buildHero() {
    final negative = _state.walletBalance < 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _l.walletMyWallet,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                _l.walletTotalBalance,
                style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                negative
                    ? '– ₹${_state.walletBalance.abs().toStringAsFixed(2)}'
                    : '₹${_state.walletBalance.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: _l.thisMonth,
                        value: '₹${_state.thisMonthEarnings.toStringAsFixed(0)}',
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.25)),
                    Expanded(
                      child: _MiniStat(
                        label: _l.walletTasksDone,
                        value: '${_state.completedTaskCount}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Withdraw — white pill that pops against the gradient.
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _showWithdrawSheet,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_upward_rounded,
                              color: T.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _l.walletWithdraw,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: T.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A wallet can go negative when cash-job platform fees are deducted but the
  /// wallet wasn't topped up. Surface it clearly as dues owed to the platform.
  Widget _buildDuesBanner() {
    final dues = _state.walletBalance.abs();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.redLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: T.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: T.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: T.red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_l.walletPlatformDues(dues.toStringAsFixed(2)),
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: T.red)),
                const SizedBox(height: 4),
                Text(
                  _l.walletDuesBody,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: T.red,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final transactions = TaskerState().transactions;
    if (transactions.isEmpty) {
      return FriendlyState(
        icon: Icons.receipt_long_outlined,
        iconColor: T.text3,
        title: l.walletNoTransactions,
        body: l.walletNoTransactionsBody,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (_, i) {
        final tx = transactions[i];
        final isEarning = tx['type'] == 'earning';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.card(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEarning ? T.green.withValues(alpha: 0.15) : T.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEarning ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isEarning ? T.green : T.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['desc'] as String,
                      style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: T.text1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _formatTime(l, tx['time'] as DateTime),
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        color: T.text3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isEarning ? '+' : ''}₹${(tx['amount'] as double).abs()}',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isEarning ? T.green : T.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(AppL10n l, DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays);
    return DateFormat('MMM dd').format(t);
  }
}

/// Earnings analytics: a 7-day bar chart plus headline stats, all computed
/// from the real /wallet/earnings payload.
class _EarningsList extends StatefulWidget {
  @override
  State<_EarningsList> createState() => _EarningsListState();
}

class _EarningsListState extends State<_EarningsList> {
  bool _loading = true;
  String? _error;

  double _total = 0;
  double _thisMonth = 0;
  double _thisWeek = 0;
  int _completed = 0;
  double _avgPerJob = 0;

  // Last 7 days, oldest first.
  List<double> _dailyTotals = List.filled(7, 0);
  List<String> _dailyLabels = const [];

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
      final rows = ((data['earnings'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 6));

      final daily = List<double>.filled(7, 0);
      double week = 0;
      for (final r in rows) {
        final amount = (r['amount'] as num?)?.toDouble() ?? 0;
        final date = DateTime.tryParse(r['created_at']?.toString() ?? '');
        if (date == null) continue;
        final day = DateTime(date.year, date.month, date.day);
        if (!day.isBefore(weekAgo) && !day.isAfter(today)) {
          final idx = day.difference(weekAgo).inDays;
          if (idx >= 0 && idx < 7) daily[idx] += amount;
          week += amount;
        }
      }

      final total = (data['total_earnings'] as num?)?.toDouble() ?? 0;
      final completed =
          (data['completed_tasks'] as num?)?.toInt() ?? rows.length;

      if (!mounted) return;
      setState(() {
        _total = total;
        _thisMonth = (data['this_month_earnings'] as num?)?.toDouble() ?? 0;
        _thisWeek = week;
        _completed = completed;
        _avgPerJob = completed > 0 ? total / completed : 0;
        _dailyTotals = daily;
        _dailyLabels = List.generate(7, (i) {
          final d = weekAgo.add(Duration(days: i));
          return DateFormat('E').format(d).substring(0, 1);
        });
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

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: T.primary));
    }
    if (_error != null) {
      return FriendlyState(
        icon: Icons.cloud_off_rounded,
        iconColor: T.text3,
        title: _error!,
        action: ElevatedButton(
          onPressed: _load,
          child: Text(l.actionRetry,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: T.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _chartCard(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _statTile(l.thisWeek,
                    '₹${_thisWeek.toStringAsFixed(0)}', T.blue)),
            const SizedBox(width: 12),
            Expanded(
                child: _statTile(l.thisMonth,
                    '₹${_thisMonth.toStringAsFixed(0)}', T.green)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _statTile(l.walletTotalEarned,
                    '₹${_total.toStringAsFixed(0)}', T.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _statTile(l.walletJobsCompleted, '$_completed', T.teal)),
          ]),
          const SizedBox(height: 12),
          _statTile(l.walletAvgPerJob, '₹${_avgPerJob.toStringAsFixed(0)}',
              T.star,
              fullWidth: true),
        ],
      ),
    );
  }

  Widget _chartCard() {
    final l = AppL10n.of(context)!;
    final peak = _dailyTotals.fold<double>(0, (m, v) => v > m ? v : m);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.walletEarningsLast7,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: T.text1)),
              Text('₹${_thisWeek.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: T.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: peak <= 0
                ? Center(
                    child: Text(l.walletNoEarnings7Days,
                        style:
                            GoogleFonts.nunito(fontSize: 14, color: T.text3)),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, 150),
                    painter: _BarChartPainter(
                      values: _dailyTotals,
                      labels: _dailyLabels,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_up, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        color: T.text3,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value,
                    style: AppTheme.metric(size: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight bar chart drawn with a CustomPainter (no chart dependency).
class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  _BarChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final peak = values.fold<double>(0, (m, v) => v > m ? v : m);
    if (peak <= 0) return;

    const labelHeight = 22.0;
    final chartHeight = size.height - labelHeight;
    final slot = size.width / values.length;
    final barWidth = slot * 0.5;

    final barPaint = Paint()..style = PaintingStyle.fill;
    final trackPaint = Paint()..color = T.divider;

    for (var i = 0; i < values.length; i++) {
      final cx = slot * i + slot / 2;
      final left = cx - barWidth / 2;

      // Track (full-height faint background bar).
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, barWidth, chartHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Value bar.
      final ratio = values[i] / peak;
      final barHeight = (chartHeight * ratio).clamp(ratio > 0 ? 4.0 : 0.0, chartHeight);
      if (barHeight > 0) {
        barPaint.shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [T.primary, T.primaryDark],
        ).createShader(
            Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight));
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight),
          const Radius.circular(6),
        );
        canvas.drawRRect(barRect, barPaint);
      }

      // Weekday label.
      final label = i < labels.length ? labels[i] : '';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.nunito(
              fontSize: 12, fontWeight: FontWeight.w700, color: T.text3),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(cx - tp.width / 2, chartHeight + (labelHeight - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.labels != labels;
}

class _WithdrawSheet extends StatelessWidget {
  final _amountCtrl = TextEditingController();
  final TaskerState _state = TaskerState();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.walletWithdrawMoney,
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: T.text1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l.walletAmount,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: T.text2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0',
                  prefixStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 18, color: T.text1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.walletAvailableBalance(_state.user.walletBalance.toStringAsFixed(2)),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: T.text3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = _amountCtrl.text.trim();
                    final amt = double.tryParse(text);
                    if (amt == null || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.walletEnterValidAmount)),
                      );
                      return;
                    }
                    if (amt > _state.walletBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.walletInsufficientBalance)),
                      );
                      return;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    final error = await _state.withdraw(amt);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (error == null) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            l.walletWithdrawalRequested(amt.toStringAsFixed(2)),
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                          ),
                          backgroundColor: T.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(error,
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  child: Text(
                    l.walletWithdraw,
                    style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: T.bg, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
