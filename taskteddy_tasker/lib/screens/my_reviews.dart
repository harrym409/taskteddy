import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/category_icons.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

// ══════════════════════════════════════════════════════════
//  REVIEW MODEL
// ══════════════════════════════════════════════════════════

class _ReviewData {
  final String reviewer;
  final double rating;
  final String comment;
  final DateTime date;

  const _ReviewData({
    required this.reviewer,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory _ReviewData.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    return _ReviewData(
      reviewer: (reviewer?['name'] ?? 'TaskTeddy User').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: (json['comment'] ?? '').toString(),
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  MY REVIEWS SCREEN
// ══════════════════════════════════════════════════════════

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _loading = true;
  String? _error;
  List<_ReviewData> _reviews = [];

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
      final user = await Session.getUser();
      final userId = user?['id']?.toString();
      if (userId == null || userId.isEmpty) {
        throw Exception('Not signed in');
      }
      final rows = await ApiService.getUserReviews(userId);
      if (!mounted) return;
      setState(() {
        _reviews = rows.map((r) => _ReviewData.fromJson(r)).toList();
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
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(l.profileMyReviews),
      body: RefreshIndicator(
        color: T.primary,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(reviews: _reviews),
              const SizedBox(height: 20),
              Text(
                l.reviewsRecent,
                style: AppTheme.sectionHeader(size: 17),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                      child: CircularProgressIndicator(color: T.primary)),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: FriendlyState(
                    icon: Icons.cloud_off_rounded,
                    iconColor: T.text3,
                    title: _error!,
                  ),
                )
              else if (_reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: FriendlyState(
                    icon: Icons.reviews_outlined,
                    title: l.reviewsNone,
                  ),
                )
              else
                ..._reviews.map((r) => _ReviewCard(review: r)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SUMMARY CARD
// ══════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final List<_ReviewData> reviews;
  const _SummaryCard({required this.reviews});

  double get _overallRating {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<double>(0, (a, r) => a + r.rating);
    return sum / reviews.length;
  }

  int get _totalReviews => reviews.length;

  Map<int, int> get _starCounts {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final bucket = r.rating.round().clamp(1, 5);
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [T.primary, T.primaryDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Top row: rating + total reviews
          Row(
            children: [
              // Left: overall rating
              Column(
                children: [
                  Text(
                    _overallRating.toStringAsFixed(1),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      if (i < _overallRating.floor()) {
                        return const Icon(Icons.star_rounded,
                            color: T.star, size: 18);
                      } else if (i < _overallRating) {
                        return const Icon(Icons.star_half_rounded,
                            color: T.star, size: 18);
                      }
                      return Icon(Icons.star_rounded,
                          color: Colors.white.withValues(alpha: .3), size: 18);
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppL10n.of(context)!.profileReviewsCount(_totalReviews),
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Right: star distribution bars
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final star = 5 - index;
                    final count = _starCounts[star] ?? 0;
                    final fraction =
                        _totalReviews > 0 ? count / _totalReviews : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withValues(alpha: .15),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(T.star),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 22,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.nunito(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  REVIEW CARD
// ══════════════════════════════════════════════════════════

class _ReviewCard extends StatelessWidget {
  final _ReviewData review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + date
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: T.primaryLight,
                child: Text(
                  initialFor(review.reviewer),
                  style: GoogleFonts.nunito(
                    color: T.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: T.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Star rating
                    Row(
                      children: List.generate(5, (i) {
                        if (i < review.rating.floor()) {
                          return const Icon(Icons.star_rounded,
                              color: T.star, size: 15);
                        } else if (i < review.rating) {
                          return const Icon(Icons.star_half_rounded,
                              color: T.star, size: 15);
                        }
                        return const Icon(Icons.star_rounded,
                            color: T.border, size: 15);
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(AppL10n.of(context)!, review.date),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: T.text3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Comment
          Text(
            review.comment,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: T.text2,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(AppL10n l, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
    return l.timeDaysAgo(diff.inDays);
  }
}
