import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../state/favorites_controller.dart';
import '../theme/theme.dart';
import '../theme/category_icons.dart';
import '../widgets/level_chip.dart';
import '../widgets/verified_badge.dart';
import '../widgets/safety_actions.dart';
import 'service_detail.dart';

/// Saved services and taskers, split into two tabs. Services deep-link into
/// the booking flow; taskers open a public profile sheet.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<FavoriteItem> _services = [];
  List<FavoriteItem> _taskers = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = _services.isEmpty && _taskers.isEmpty;
        _error = false;
      });
    }
    try {
      final favorites = await ApiService.getFavorites();
      if (!mounted) return;
      setState(() {
        _services =
            favorites.where((f) => f.targetType == 'service').toList();
        _taskers = favorites.where((f) => f.targetType == 'tasker').toList();
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

  Future<void> _removeFavorite(FavoriteItem item) async {
    // Optimistic removal from the visible list.
    setState(() {
      _services = _services.where((f) => f.id != item.id).toList();
      _taskers = _taskers.where((f) => f.id != item.id).toList();
    });
    try {
      await ApiService.removeFavorite(item.targetType, item.targetId);
      if (item.targetType == 'service') {
        await ref.read(favoriteServiceIdsProvider.notifier).refresh();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(AppL10n.of(context)!.favSaved,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [C.primaryDark, C.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: C.primary,
                unselectedLabelColor: Colors.white.withValues(alpha: .95),
                labelStyle:
                    GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: AppL10n.of(context)!.favTabServices),
                  Tab(text: AppL10n.of(context)!.favTabTaskers),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.primary))
          : _error
              ? _ErrorState(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: C.primary,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _servicesTab(),
                      _taskersTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _servicesTab() {
    if (_services.isEmpty) {
      return _EmptyState(
        icon: Icons.favorite_border_rounded,
        title: AppL10n.of(context)!.favNoServices,
        subtitle: AppL10n.of(context)!.favNoServicesBody,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final item = _services[i];
        return _FavoriteServiceCard(
          service: item.service!,
          onRemove: () => _removeFavorite(item),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(service: item.service!),
            ),
          ),
        );
      },
    );
  }

  Widget _taskersTab() {
    if (_taskers.isEmpty) {
      return _EmptyState(
        icon: Icons.person_outline_rounded,
        title: AppL10n.of(context)!.favNoTaskers,
        subtitle: AppL10n.of(context)!.favNoTaskersBody,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _taskers.length,
      itemBuilder: (_, i) {
        final item = _taskers[i];
        return _FavoriteTaskerCard(
          tasker: item.tasker!,
          verified: item.taskerVerified,
          onRemove: () => _removeFavorite(item),
          onTap: () => _openTaskerProfile(item),
        );
      },
    );
  }

  void _openTaskerProfile(FavoriteItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TaskerProfileSheet(
        tasker: item.tasker!,
        verified: item.taskerVerified,
        onBlocked: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }
}

class _FavoriteServiceCard extends StatelessWidget {
  const _FavoriteServiceCard({
    required this.service,
    required this.onRemove,
    required this.onTap,
  });

  final ServiceModel service;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          categoryColor(service.category)
                              .withValues(alpha: 0.14),
                          categoryColor(service.category)
                              .withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: service.iconAsset == null
                        ? Center(
                            child: Icon(categoryIcon(service.category),
                                size: 44,
                                color: categoryColor(service.category)))
                        : Image.asset(service.iconAsset!, fit: BoxFit.contain),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: C.text1,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: C.star, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: C.text3,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '\u{20B9}${service.price.toInt()}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: C.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 6,
              right: 6,
              child: _HeartButton(filled: true, onTap: onRemove),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTaskerCard extends StatelessWidget {
  const _FavoriteTaskerCard({
    required this.tasker,
    required this.verified,
    required this.onRemove,
    required this.onTap,
  });

  final UserModel tasker;
  final bool verified;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = ApiService.resolveMediaUrl(tasker.avatarUrl);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: C.primaryLight,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Text(
                      tasker.name.isNotEmpty
                          ? tasker.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: C.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tasker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: C.text1,
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 5),
                        const VerifiedBadge(compact: true, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: C.star, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        '${tasker.rating.toStringAsFixed(1)} · ${AppL10n.of(context)!.reviewsCount(tasker.totalReviews)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: C.text3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _HeartButton(filled: true, onTap: onRemove),
          ],
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: filled ? C.red : C.text3,
          size: 19,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 80, 28, 24),
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.primaryLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: C.primary, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: C.text1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: C.text3,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: C.text3),
            const SizedBox(height: 14),
            Text(
              AppL10n.of(context)!.favLoadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: C.text2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppL10n.of(context)!.retry,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Public tasker profile: identity, portfolio, weekly availability and recent
/// reviews. Pulls from the /users/{id}/portfolio, /availability and /reviews
/// endpoints.
class TaskerProfileSheet extends StatefulWidget {
  const TaskerProfileSheet({
    super.key,
    required this.tasker,
    required this.verified,
    this.onBlocked,
  });

  final UserModel tasker;
  final bool verified;

  /// Called after the tasker is blocked so the host can refresh/hide them.
  final VoidCallback? onBlocked;

  @override
  State<TaskerProfileSheet> createState() => _TaskerProfileSheetState();
}

class _TaskerProfileSheetState extends State<TaskerProfileSheet> {
  List<String> _weekdayLabels(AppL10n l) => [
        l.weekdayMon,
        l.weekdayTue,
        l.weekdayWed,
        l.weekdayThu,
        l.weekdayFri,
        l.weekdaySat,
        l.weekdaySun,
      ];

  bool _loading = true;
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> _availability = [];
  List<Map<String, dynamic>> _reviews = [];

  String get _userId => widget.tasker.remoteId ?? widget.tasker.id.toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.getUserPortfolio(_userId),
      ApiService.getUserAvailability(_userId),
      ApiService.getUserReviews(_userId),
    ]);
    if (!mounted) return;
    setState(() {
      _portfolio = results[0];
      _availability = results[1];
      _reviews = results[2];
      _loading = false;
    });
  }

  String _minuteLabel(num minute) {
    final total = minute.toInt();
    final h = (total ~/ 60) % 24;
    final m = total % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final ampm = h >= 12 ? 'PM' : 'AM';
    return '$h12:${m.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ApiService.resolveMediaUrl(widget.tasker.avatarUrl);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
              CircleAvatar(
                radius: 30,
                backgroundColor: C.primaryLight,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        widget.tasker.name.isNotEmpty
                            ? widget.tasker.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          color: C.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
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
                            widget.tasker.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: C.text1,
                            ),
                          ),
                        ),
                        if (widget.verified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(size: 15),
                        ],
                        if (widget.tasker.reputation != null) ...[
                          const SizedBox(width: 6),
                          LevelChip(
                              reputation: widget.tasker.reputation!,
                              compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: C.star, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.tasker.rating.toStringAsFixed(1)} · ${AppL10n.of(context)!.reviewsCount(widget.tasker.totalReviews)}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: C.text3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafetyOverflowButton(
                reportedId: _userId,
                userName: widget.tasker.name,
                onBlocked: widget.onBlocked,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: C.primary)),
            )
          else ...[
            if (_portfolio.isNotEmpty) ...[
              _sectionTitle(AppL10n.of(context)!.portfolioTitle),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _portfolio.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final url = ApiService.resolveMediaUrl(
                        _portfolio[i]['image_url']?.toString());
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 130,
                        height: 110,
                        color: C.primaryLight.withValues(alpha: 0.4),
                        child: url == null
                            ? const Icon(Icons.image_outlined,
                                color: C.text3, size: 28)
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: C.text3),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            _sectionTitle(AppL10n.of(context)!.weeklyAvailability),
            const SizedBox(height: 10),
            _availabilityView(),
            const SizedBox(height: 20),
            _sectionTitle(AppL10n.of(context)!.recentReviews),
            const SizedBox(height: 10),
            if (_reviews.isEmpty)
              Text(
                AppL10n.of(context)!.noReviewsYet,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: C.text3,
                ),
              )
            else
              ..._reviews.take(10).map(_reviewCard),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: C.text1,
        ),
      );

  Widget _availabilityView() {
    if (_availability.isEmpty) {
      return Text(
        AppL10n.of(context)!.availabilityNotSet,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: C.text3,
        ),
      );
    }
    final weekdays = _weekdayLabels(AppL10n.of(context)!);
    final byDay = <int, Map<String, dynamic>>{};
    for (final row in _availability) {
      final dow = (row['day_of_week'] as num?)?.toInt();
      if (dow != null && dow >= 0 && dow <= 6) byDay[dow] = row;
    }
    return Column(
      children: List.generate(7, (day) {
        final row = byDay[day];
        final available = row != null && row['is_available'] == true;
        final start = (row?['start_minute'] as num?);
        final end = (row?['end_minute'] as num?);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                child: Text(
                  weekdays[day],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: C.text2,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: available ? C.greenLight : C.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  available && start != null && end != null
                      ? '${_minuteLabel(start)} - ${_minuteLabel(end)}'
                      : AppL10n.of(context)!.unavailable,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: available ? C.green : C.text3,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    final rating = double.tryParse(r['rating']?.toString() ?? '') ?? 0;
    final comment = r['comment']?.toString() ?? '';
    final reviewer =
        r['reviewer_name']?.toString() ?? AppL10n.of(context)!.reviewerCustomer;
    final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: C.star,
                  size: 15,
                ),
              ),
              const Spacer(),
              Text(
                reviewer,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: C.text2,
                ),
              ),
              if (createdAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMM').format(createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: C.text3,
                  ),
                ),
              ],
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: C.text2,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
