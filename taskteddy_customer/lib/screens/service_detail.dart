import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/category_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../state/favorites_controller.dart';
import 'other.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final ServiceModel service;
  const ServiceDetailScreen({super.key, required this.service});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailState();
}

class _ServiceDetailState extends ConsumerState<ServiceDetailScreen> {
  // Next 7 days shown as chips.
  late final List<DateTime> _days;
  int _dayIndex = 0;

  // Time slots (24h start hours) shown as chips.
  static const _slotHours = [9, 11, 13, 15, 17, 19];
  int? _slotHour;

  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _booking = false;

  // Payment selection for the confirm sheet.
  double? _walletBalance;
  bool _payWithWallet = false;

  // Saved address book for one-tap checkout.
  List<AddressModel> _savedAddresses = [];
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day + i));
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    List<AddressModel> addresses = const [];
    try {
      addresses = await ApiService.getAddresses();
    } catch (_) {
      addresses = const [];
    }
    if (!mounted) return;
    setState(() => _savedAddresses = addresses);

    // Prefill the default saved address; fall back to the detected location.
    if (_addressCtrl.text.trim().isEmpty && addresses.isNotEmpty) {
      final defaultAddr = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );
      setState(() {
        _addressCtrl.text = defaultAddr.address;
        _selectedAddressId = defaultAddr.id;
      });
      return;
    }
    await _prefillFromDetectedLocation();
  }

  Future<void> _prefillFromDetectedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('detected_location');
    if (mounted &&
        saved != null &&
        saved.isNotEmpty &&
        _addressCtrl.text.isEmpty) {
      setState(() => _addressCtrl.text = saved);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await ref
          .read(favoriteServiceIdsProvider.notifier)
          .toggle(widget.service.id.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _openAddressPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: C.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(AppL10n.of(context)!.sdSavedAddresses,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: C.text1)),
            const SizedBox(height: 12),
            ..._savedAddresses.map((address) {
              final selected = address.id == _selectedAddressId;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _addressCtrl.text = address.address;
                    _selectedAddressId = address.id;
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? C.primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: selected ? C.primary : C.border,
                        width: selected ? 1.6 : 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        address.label.toLowerCase() == 'work'
                            ? Icons.work_outline
                            : address.label.toLowerCase() == 'other'
                                ? Icons.place_outlined
                                : Icons.home_outlined,
                        color: C.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(address.label,
                                    style: GoogleFonts.nunito(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: C.text1)),
                                if (address.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: C.greenLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(AppL10n.of(context)!.sdDefault,
                                        style: GoogleFonts.nunito(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: C.green)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(address.address,
                                style: GoogleFonts.nunito(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: C.text3)),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle,
                            color: C.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _slotDisabled(int hour) {
    // Past slots are disabled when booking for today.
    if (_dayIndex != 0) return false;
    return DateTime.now().hour >= hour - 1;
  }

  String _slotLabel(int hour) {
    final h12 = hour > 12 ? hour - 12 : hour;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h12:00 $ampm';
  }

  DateTime get _scheduledAt {
    final d = _days[_dayIndex];
    return DateTime(d.year, d.month, d.day, _slotHour ?? 9);
  }

  double get _discount =>
      (widget.service.originalPrice > widget.service.price)
          ? widget.service.originalPrice - widget.service.price
          : 0;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: C.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── STEP 1: validate + show confirmation sheet ────────────────
  Future<void> _reviewBooking() async {
    if (_slotHour == null) {
      _showError(AppL10n.of(context)!.sdPickTimeSlotError);
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      _showError(AppL10n.of(context)!.sdEnterAddressError);
      return;
    }
    FocusScope.of(context).unfocus();
    // Fetch the wallet balance so the sheet can offer wallet payment.
    try {
      _walletBalance = await ApiService.getWalletBalance();
    } catch (_) {
      _walletBalance = null;
    }
    _payWithWallet = false;
    if (!mounted) return;
    _openConfirmSheet();
  }

  void _openConfirmSheet() {
    final s = widget.service;
    final when = DateFormat('EEE, d MMM • ').format(_scheduledAt) +
        _slotLabel(_slotHour!);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: C.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(AppL10n.of(context)!.sdConfirmBooking,
                  style: GoogleFonts.nunito(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: C.text1)),
              const SizedBox(height: 14),
              _summaryRow(Icons.receipt_long_rounded, s.name),
              _summaryRow(Icons.event_rounded, when),
              _summaryRow(Icons.place_rounded, _addressCtrl.text.trim()),
              if (_notesCtrl.text.trim().isNotEmpty)
                _summaryRow(Icons.notes_rounded, _notesCtrl.text.trim()),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _priceRow(AppL10n.of(context)!.sdServicePrice,
                        '₹${s.originalPrice.toInt()}'),
                    if (_discount > 0) ...[
                      const SizedBox(height: 6),
                      _priceRow(AppL10n.of(context)!.sdDiscount,
                          '-₹${_discount.toInt()}',
                          valueColor: C.green),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _priceRow(
                        _payWithWallet
                            ? AppL10n.of(context)!.sdTotalFromWallet
                            : AppL10n.of(context)!.sdTotalPayAfter,
                        '₹${s.price.toInt()}',
                        bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(AppL10n.of(context)!.sdPaymentMethod,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: C.text1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _payTile(
                      selected: !_payWithWallet,
                      icon: Icons.payments_rounded,
                      title: AppL10n.of(context)!.sdPayAfterService,
                      subtitle: AppL10n.of(context)!.sdPayAfterServiceSub,
                      onTap: () => setSheet(() => _payWithWallet = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(builder: (_) {
                      final balance = _walletBalance;
                      final enough =
                          balance != null && balance >= s.price;
                      return _payTile(
                        selected: _payWithWallet,
                        icon: Icons.account_balance_wallet_rounded,
                        title: AppL10n.of(context)!.sdWallet,
                        subtitle: balance == null
                            ? AppL10n.of(context)!.unavailable
                            : enough
                                ? AppL10n.of(context)!
                                    .sdWalletAvailable(balance.toInt())
                                : AppL10n.of(context)!
                                    .sdWalletLow(balance.toInt()),
                        disabled: !enough,
                        onTap: () => setSheet(() => _payWithWallet = true),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _booking
                      ? null
                      : () async {
                          setSheet(() => _booking = true);
                          try {
                            final res = await ApiService.createBooking(
                              serviceId: widget.service.id.toString(),
                              scheduledAt: _scheduledAt,
                              address: _addressCtrl.text.trim(),
                              notes: _notesCtrl.text.trim(),
                              payWithWallet: _payWithWallet,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx); // close sheet
                            _showSuccess(
                              ref: (res['booking_id'] ?? '').toString(),
                              when: when,
                              paidFromWallet:
                                  res['paid_with_wallet'] == true,
                            );
                          } on UnauthorizedException {
                            // Expired session: clear it and send back to login.
                            if (ctx.mounted) Navigator.pop(ctx);
                            await Session.clear();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppL10n.of(context)!.sessionExpired),
                                backgroundColor: C.red,
                              ),
                            );
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login', (route) => false);
                          } catch (e) {
                            setSheet(() => _booking = false);
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceAll('Exception: ', '')),
                                backgroundColor: C.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _booking = false);
                            }
                          }
                        },
                  child: _booking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          AppL10n.of(context)!.sdConfirmAndBook(s.price.toInt()),
                          style: GoogleFonts.nunito(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payTile({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool disabled = false,
  }) =>
      GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: disabled
                ? C.divider
                : selected
                    ? C.primaryLight
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected && !disabled ? C.primary : C.border,
                width: selected && !disabled ? 1.6 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 22,
                  color: disabled
                      ? C.text3
                      : selected
                          ? C.primary
                          : C.text2),
              const SizedBox(height: 6),
              Text(title,
                  style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: disabled ? C.text3 : C.text1)),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: C.text3)),
            ],
          ),
        ),
      );

  Widget _summaryRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: C.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: C.text2),
              ),
            ),
          ],
        ),
      );

  Widget _priceRow(String label, String value,
          {bool bold = false, Color? valueColor}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: bold ? 15 : 13.5,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  color: bold ? C.text1 : C.text3)),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: bold ? 16 : 14,
                  fontWeight: FontWeight.w900,
                  color: valueColor ?? (bold ? C.primary : C.text1))),
        ],
      );

  // ── STEP 2: success dialog ────────────────────────────────────
  void _showSuccess({
    required String ref,
    required String when,
    bool paidFromWallet = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                      color: C.greenLight, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: C.green, size: 44),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppL10n.of(context)!.sdBookingConfirmed,
                  style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: C.text1)),
              const SizedBox(height: 6),
              Text(when,
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: C.text3)),
              if (paidFromWallet) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        size: 15, color: C.green),
                    const SizedBox(width: 5),
                    Text(
                        AppL10n.of(context)!
                            .sdPaidFromWallet(widget.service.price.toInt()),
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: C.green)),
                  ],
                ),
              ],
              if (ref.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: C.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(AppL10n.of(context)!.sdBookingId(ref),
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: C.primaryDark)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // dialog
                    Navigator.pop(context); // detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BookingsScreen()),
                    );
                  },
                  child: Text(AppL10n.of(context)!.sdViewMyBookings,
                      style: GoogleFonts.nunito(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // dialog
                  Navigator.pop(context); // detail screen
                },
                child: Text(AppL10n.of(context)!.done,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: C.text3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: C.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: C.primary,
              actions: [
                Builder(builder: (context) {
                  final isFavorite = ref
                          .watch(favoriteServiceIdsProvider)
                          .valueOrNull
                          ?.contains(widget.service.id.toString()) ??
                      false;
                  return IconButton(
                    onPressed: _toggleFavorite,
                    tooltip: isFavorite
                        ? AppL10n.of(context)!.sdRemoveFromSaved
                        : AppL10n.of(context)!.save,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? C.red : Colors.white,
                    ),
                  );
                }),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [C.primary, C.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: widget.service.iconAsset == null
                        ? Icon(
                            categoryIcon(widget.service.category),
                            size: 92,
                            color: Colors.white.withValues(alpha: 0.92),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              widget.service.iconAsset!,
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.service.isHot)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: C.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department,
                                        size: 13, color: C.red),
                                    const SizedBox(width: 4),
                                    Text(AppL10n.of(context)!.badgeHot,
                                        style: GoogleFonts.nunito(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: C.red)),
                                  ],
                                ),
                              ),
                            if (widget.service.isNew)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: C.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(AppL10n.of(context)!.badgeNew,
                                    style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: C.green)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.service.name,
                          style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: C.text1),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: C.star, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.service.rating}',
                              style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: C.text1),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${AppL10n.of(context)!.reviewsCount(widget.service.reviewCount)})',
                              style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: C.text3,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              '₹${widget.service.price.toInt()}',
                              style: GoogleFonts.nunito(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: C.primary),
                            ),
                            const SizedBox(width: 10),
                            if (_discount > 0) ...[
                              Text(
                                '₹${widget.service.originalPrice.toInt()}',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: C.text3,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: C.greenLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppL10n.of(context)!.percentOff(
                                      (_discount /
                                              widget.service.originalPrice *
                                              100)
                                          .round()),
                                  style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: C.green),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppL10n.of(context)!.sdDescription,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: C.text1)),
                        const SizedBox(height: 8),
                        Text(
                          widget.service.description,
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: C.text3,
                              fontWeight: FontWeight.w500,
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppL10n.of(context)!.sdWhatsIncluded,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: C.text1)),
                        const SizedBox(height: 12),
                        ...widget.service.includes.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: C.green, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          color: C.text2,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppL10n.of(context)!.sdPickDate,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: C.text1)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 74,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _days.length,
                            itemBuilder: (_, i) {
                              final d = _days[i];
                              final selected = i == _dayIndex;
                              final label = i == 0
                                  ? AppL10n.of(context)!.dateToday
                                  : i == 1
                                      ? AppL10n.of(context)!.dateTomorrowShort
                                      : DateFormat('EEE').format(d);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _dayIndex = i;
                                  // Clear a now-invalid past slot.
                                  if (_slotHour != null &&
                                      _slotDisabled(_slotHour!)) {
                                    _slotHour = null;
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  width: 62,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color:
                                        selected ? C.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: selected
                                            ? C.primary
                                            : C.border),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(label,
                                          style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: selected
                                                  ? Colors.white
                                                  : C.text3)),
                                      const SizedBox(height: 2),
                                      Text('${d.day}',
                                          style: GoogleFonts.nunito(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: selected
                                                  ? Colors.white
                                                  : C.text1)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(AppL10n.of(context)!.sdPickTimeSlot,
                            style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: C.text1)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _slotHours.map((h) {
                            final selected = _slotHour == h;
                            final disabled = _slotDisabled(h);
                            return GestureDetector(
                              onTap: disabled
                                  ? null
                                  : () => setState(() => _slotHour = h),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: disabled
                                      ? C.divider
                                      : selected
                                          ? C.primary
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: selected
                                          ? C.primary
                                          : C.border),
                                ),
                                child: Text(
                                  _slotLabel(h),
                                  style: GoogleFonts.nunito(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: disabled
                                        ? C.text3
                                        : selected
                                            ? Colors.white
                                            : C.text2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(AppL10n.of(context)!.sdAddress,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: C.text2)),
                            const Spacer(),
                            if (_savedAddresses.isNotEmpty)
                              GestureDetector(
                                onTap: _openAddressPicker,
                                child: Row(
                                  children: [
                                    const Icon(Icons.bookmark_outline,
                                        color: C.primary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(AppL10n.of(context)!.sdUseSaved,
                                        style: GoogleFonts.nunito(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: C.primary)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addressCtrl,
                          onChanged: (_) {
                            // Typing a custom address clears the saved-address
                            // selection so it's treated as manual entry.
                            if (_selectedAddressId != null) {
                              setState(() => _selectedAddressId = null);
                            }
                          },
                          onTapOutside: (_) =>
                              FocusScope.of(context).unfocus(),
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: AppL10n.of(context)!.sdAddressHint,
                            prefixIcon: const Icon(Icons.location_on_outlined,
                                color: C.primary, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: C.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: C.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(AppL10n.of(context)!.sdNotesOptional,
                            style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: C.text2)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesCtrl,
                          onTapOutside: (_) =>
                              FocusScope.of(context).unfocus(),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: AppL10n.of(context)!.sdNotesHint,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: C.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: C.border),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _booking ? null : _reviewBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                        AppL10n.of(context)!
                            .sdBookNow(widget.service.price.toInt()),
                        style: GoogleFonts.nunito(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
    );
  }
}
