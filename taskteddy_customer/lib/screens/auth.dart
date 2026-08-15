import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../state/auth_controller.dart';
import '../state/auth_repository.dart';
import '../theme/theme.dart';

const _taskTeddyCoral = Color(0xFFFF6E6E);
const _taskTeddyCream = Color(0xFFF7F1E3);
const _taskTeddyWhite = Color(0xFFFFFFFF);
const _laneSpeedPxPerSecond = 14.0;
const _laneGap = 10.0;
const _laneCardWidth = 136.0;
const _laneCardHeight = 122.0;
const _topToLanesGap = 10.0;

const _landingImages = [
  'assets/images/services/bathroom_cleaning.png',
  'assets/images/services/fridge_cleaning.png',
  'assets/images/services/ironing_and_folding.png',
  'assets/images/services/kitchen_help.png',
  'assets/images/services/laundry.png',
  'assets/images/services/packing_and_unpacking.png',
  'assets/images/services/wardrobe.png',
  'assets/images/services/window_cleaning.png',
];

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PhoneAuthLanding();
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PhoneAuthLanding(showBack: true);
}

class _PhoneAuthLanding extends ConsumerStatefulWidget {
  const _PhoneAuthLanding({this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<_PhoneAuthLanding> createState() => _PhoneAuthLandingState();
}

class _PhoneAuthLandingState extends ConsumerState<_PhoneAuthLanding>
    with SingleTickerProviderStateMixin {
  final _phone = TextEditingController();
  final _smsCode = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _row1Controller = ScrollController();
  final _row2Controller = ScrollController();
  final _row3Controller = ScrollController();
  final _seededRows = <ScrollController>{};

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _otpSent = false;
  bool _panelLifted = false;
  String? _verificationId;
  String? _error;
  String? _notice;

  // OTP Timer
  int _otpCountdown = 0;
  bool _canResend = true;

  void _startOtpTimer() {
    _otpCountdown = 60;
    _canResend = false;
    _updateTimer();
  }

  void _updateTimer() {
    if (_otpCountdown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _otpCountdown--;
          });
          _updateTimer();
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_syncPanelWithFocus);
    _otpFocus.addListener(_syncPanelWithFocus);
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _ticker.start();
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_syncPanelWithFocus);
    _otpFocus.removeListener(_syncPanelWithFocus);
    _ticker.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _phone.dispose();
    _smsCode.dispose();
    _row1Controller.dispose();
    _row2Controller.dispose();
    _row3Controller.dispose();
    super.dispose();
  }

  void _syncPanelWithFocus() {
    if (!mounted) return;
    final shouldLift = _phoneFocus.hasFocus || _otpFocus.hasFocus || _otpSent;
    if (_panelLifted == shouldLift) return;
    setState(() => _panelLifted = shouldLift);
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    final dtMillis = (elapsed - _lastTick).inMilliseconds;
    _lastTick = elapsed;
    if (dtMillis <= 0 || dtMillis > 220) return;

    final dtSeconds = dtMillis / 1000.0;
    _advanceRow(_row1Controller, -_laneSpeedPxPerSecond * dtSeconds);
    _advanceRow(_row2Controller, _laneSpeedPxPerSecond * dtSeconds);
    _advanceRow(_row3Controller, -_laneSpeedPxPerSecond * dtSeconds);
  }

  void _advanceRow(ScrollController controller, double delta) {
    if (!controller.hasClients) return;
    final position = controller.position;
    final max = position.maxScrollExtent;
    if (max <= 0) return;

    if (!_seededRows.contains(controller)) {
      controller.jumpTo(max * 0.5);
      _seededRows.add(controller);
      return;
    }

    var next = controller.offset + delta;
    if (next <= 1 || next >= max - 1) next = max * 0.5;
    controller.jumpTo(next.clamp(0, max));
  }

  String get _fullPhone => ApiService.indiaPhoneNumber(_phone.text.trim());

  Future<void> _sendOtp() async {
    if (_phone.text.trim().length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _sendingOtp = true;
      _panelLifted = true;
      _error = null;
      _notice = 'Sending OTP to $_fullPhone';
    });

    try {
      // Request the OTP from the backend.
      final response =
          await ref.read(authRepositoryProvider).requestPhoneOtp(_fullPhone);
      if (!mounted) return;

      setState(() {
        _verificationId = 'backend-otp';
        _otpSent = true;
        _notice = 'OTP sent to $_fullPhone';
        // In local dev (no SMS provider) the backend returns the OTP so it can
        // be autofilled. This never happens in production or once an SMS
        // provider is configured, so the code is never shown to real users.
        final devOtp = response['otp'];
        if (devOtp != null && devOtp.toString().isNotEmpty) {
          _smsCode.text = devOtp.toString();
        }
      });
      _otpFocus.requestFocus();
      // Start 60s timer
      _startOtpTimer();
    } catch (e) {
      if (mounted) {
        // Clean error message for user
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = _cleanError(errorMsg));
      }
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  // Clean error messages for display
  String _cleanError(String error) {
    final lower = error.toLowerCase();

    // Network issues
    if (lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('socket')) {
      return 'Unable to connect. Please check your internet and try again.';
    }
    if (lower.contains('refused') || lower.contains('unreachable')) {
      return 'Cannot reach server. Please try again later.';
    }

    // Auth specific
    if (lower.contains('invalid otp') || lower.contains('wrong otp')) {
      return 'Invalid OTP. Please check and try again.';
    }
    if (lower.contains('expired otp')) {
      return 'OTP expired. Please request a new one.';
    }
    if (lower.contains('too many') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    // Default - show clean message
    return error.length > 100
        ? 'Something went wrong. Please try again.'
        : error;
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _smsCode.text.trim().isEmpty) {
      setState(() => _error = 'Enter the OTP sent to your mobile number');
      return;
    }
    if (_smsCode.text.trim().length != 6) {
      setState(() => _error = 'Please enter the full 6-digit OTP');
      return;
    }

    setState(() {
      _verifyingOtp = true;
      _error = null;
    });

    try {
      // Verify via Backend API - this returns full auth data
      final response = await ref.read(authRepositoryProvider).verifyPhoneOtp(
            phone: _fullPhone,
            otp: _smsCode.text.trim(),
          );
      final rawUser = response['user'];
      final user = rawUser is Map<String, dynamic>
          ? rawUser
          : rawUser is Map
              ? Map<String, dynamic>.from(rawUser)
              : <String, dynamic>{};
      // Store the token and user directly
      await ref.read(authControllerProvider.notifier).setSession(
            response['access_token'].toString(),
            user,
          );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/post-login-splash');
      }
      return;
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = _cleanError(errorMsg));
      }
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _taskTeddyCoral,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight;
              final formActive = _panelLifted;
              final collapsedHeight = _otpSent ? 326.0 : 274.0;
              const firstRowVisibleTop =
                  182.0 + _topToLanesGap + _laneCardHeight;
              final expandedHeight = (maxHeight - firstRowVisibleTop)
                  .clamp(360.0, maxHeight - 20.0);
              final maxPanelHeight = maxHeight;
              final panelHeight = (formActive ? expandedHeight : collapsedHeight)
                      .clamp(240.0, maxPanelHeight)
                      .toDouble();

              return Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        _Header(showBack: widget.showBack),
                        const SizedBox(height: _topToLanesGap),
                        RepaintBoundary(
                          child: Column(
                            children: [
                              _AutoImageRow(
                                controller: _row1Controller,
                                imageAssets: _landingImages,
                              ),
                              const SizedBox(height: _laneGap),
                              _AutoImageRow(
                                controller: _row2Controller,
                                imageAssets: _landingImages.reversed.toList(),
                              ),
                              const SizedBox(height: _laneGap),
                              _AutoImageRow(
                                controller: _row3Controller,
                                imageAssets: _landingImages,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      height: panelHeight,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: _FooterCard(
                        phoneController: _phone,
                        otpController: _smsCode,
                        phoneFocus: _phoneFocus,
                        otpFocus: _otpFocus,
                        otpSent: _otpSent,
                        sendingOtp: _sendingOtp,
                        verifyingOtp: _verifyingOtp,
                        error: _error,
                        notice: _notice,
                        onSendOtp: _sendOtp,
                        onVerifyOtp: _verifyOtp,
                        onResetPhone: () {
                          setState(() {
                            _otpSent = false;
                            _verificationId = null;
                            _smsCode.clear();
                            _error = null;
                            _notice = null;
                            _panelLifted = false;
                            _otpCountdown = 0;
                            _canResend = true;
                          });
                          _phoneFocus.requestFocus();
                        },
                        canResend: _canResend,
                        otpCountdown: _otpCountdown,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
        child: Column(
          children: [
            SizedBox(
              height: 36,
              child: Align(
                alignment: Alignment.centerLeft,
                child: showBack
                    ? IconButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: _taskTeddyCream,
                        tooltip: AppL10n.of(context)!.back,
                      )
                    : null,
              ),
            ),
            Image.asset(
              'assets/images/logo_wordmark.png',
              width: 292,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(height: 4),
            Text(
              AppL10n.of(context)!.authTagline,
              textAlign: TextAlign.center,
              style: GoogleFonts.varelaRound(
                color: _taskTeddyWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

class _AutoImageRow extends StatelessWidget {
  const _AutoImageRow({
    required this.controller,
    required this.imageAssets,
  });

  final ScrollController controller;
  final List<String> imageAssets;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _laneCardHeight,
        child: ListView.builder(
          controller: controller,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 120,
          itemBuilder: (context, index) {
            final asset = imageAssets[index % imageAssets.length];
            return Container(
              width: _laneCardWidth,
              margin: EdgeInsets.only(
                left: index == 0 ? 18 : 0,
                right: _laneGap,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .11),
                    blurRadius: 9,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            );
          },
        ),
      );
}

class _FooterCard extends StatelessWidget {
  const _FooterCard({
    required this.phoneController,
    required this.otpController,
    required this.phoneFocus,
    required this.otpFocus,
    required this.otpSent,
    required this.sendingOtp,
    required this.verifyingOtp,
    required this.error,
    required this.notice,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onResetPhone,
    required this.canResend,
    required this.otpCountdown,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final FocusNode phoneFocus;
  final FocusNode otpFocus;
  final bool otpSent;
  final bool sendingOtp;
  final bool verifyingOtp;
  final String? error;
  final String? notice;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onResetPhone;
  final bool canResend;
  final int otpCountdown;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Transform.translate(
                offset: const Offset(0, -3),
                child: Text(
                  AppL10n.of(context)!.authLoginOrSignup,
                  style: GoogleFonts.varelaRound(
                    color: const Color(0xFF2D2D2D),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            if (error != null) ...[
              _MessageBanner(
                message: error!,
                color: C.red,
                background: const Color(0xFFFFEEEC),
                border: const Color(0xFFFFD2CC),
                icon: Icons.error_outline,
              ),
              const SizedBox(height: 10),
            ],
            if (notice != null) ...[
              _MessageBanner(
                message: notice!,
                color: const Color(0xFF126B38),
                background: const Color(0xFFEAFAF1),
                border: const Color(0xFFBDEAD0),
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 10),
            ],
            _PhoneField(
              controller: phoneController,
              focusNode: phoneFocus,
              enabled: !otpSent,
            ),
            if (otpSent) ...[
              const SizedBox(height: 10),
              _OtpField(
                controller: otpController,
                focusNode: otpFocus,
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: sendingOtp || verifyingOtp
                    ? null
                    : (otpSent ? onVerifyOtp : onSendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _taskTeddyCoral,
                  foregroundColor: _taskTeddyCream,
                  disabledBackgroundColor:
                      _taskTeddyCoral.withValues(alpha: .6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: (sendingOtp || verifyingOtp)
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: _taskTeddyCream,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppL10n.of(context)!.continueLabel,
                        style: GoogleFonts.varelaRound(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (otpSent) ...[
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed:
                          sendingOtp || verifyingOtp ? null : onResetPhone,
                      child: Text(
                        AppL10n.of(context)!.authChangeNumber,
                        style: GoogleFonts.varelaRound(
                          color: _taskTeddyCoral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: (sendingOtp || verifyingOtp || !canResend)
                          ? null
                          : onSendOtp,
                      child: Text(
                        canResend
                            ? AppL10n.of(context)!.authResendOtp
                            : AppL10n.of(context)!.authResendIn(otpCountdown),
                        style: GoogleFonts.varelaRound(
                          color: canResend ? _taskTeddyCoral : C.grey3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Center(
              child: Text.rich(
                TextSpan(
                  text: AppL10n.of(context)!.authTermsIntro,
                  children: [
                    TextSpan(
                      text: AppL10n.of(context)!.authTerms,
                      style: GoogleFonts.varelaRound(
                        color: _taskTeddyCoral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: AppL10n.of(context)!.authAnd),
                    TextSpan(
                      text: AppL10n.of(context)!.authPrivacy,
                      style: GoogleFonts.varelaRound(
                        color: _taskTeddyCoral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.varelaRound(
                  color: C.text3,
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        enabled: enabled,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        style: GoogleFonts.varelaRound(
          color: C.text1,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: AppL10n.of(context)!.authMobileNumber,
          prefixText: '+91 ',
          prefixIcon: const Icon(Icons.phone_outlined, color: _taskTeddyCoral),
          prefixStyle: GoogleFonts.varelaRound(
            color: C.text1,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFFFF0ED),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF0D6D2)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFF0D6D2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _taskTeddyCoral, width: 1.4),
          ),
        ),
      );
}

class _OtpField extends StatefulWidget {
  const _OtpField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  final List<bool> _revealDigit = List<bool>.filled(6, false);
  final List<int> _revealVersion = List<int>.filled(6, 0);
  String _lastOtp = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onOtpChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _OtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onOtpChanged);
      widget.controller.addListener(_onOtpChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onOtpChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onOtpChanged() {
    final raw = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final otp = raw.length > 6 ? raw.substring(0, 6) : raw;

    for (var i = 0; i < 6; i++) {
      final prev = i < _lastOtp.length ? _lastOtp[i] : null;
      final next = i < otp.length ? otp[i] : null;

      if (next == null) {
        _revealVersion[i]++;
        _revealDigit[i] = false;
        continue;
      }

      if (prev == null || prev != next) {
        _revealDigit[i] = true;
        _revealVersion[i]++;
        final version = _revealVersion[i];
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted || _revealVersion[i] != version) return;
          setState(() => _revealDigit[i] = false);
        });
      }
    }

    _lastOtp = otp;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final otp = raw.length > 6 ? raw.substring(0, 6) : raw;
    final selectedIndex = otp.length.clamp(0, 5);
    final isFocused = widget.focusNode.hasFocus;

    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              color: Colors.transparent,
              fontSize: 0.01,
              height: 0.01,
            ),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              counterText: '',
            ),
          ),
          IgnorePointer(
            child: Row(
              children: List.generate(6, (index) {
                final isActive = isFocused && index == selectedIndex;
                final hasValue = index < otp.length;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index == 5 ? 0 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? _taskTeddyCoral
                            : const Color(0xFFF0D6D2),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        !hasValue
                            ? ''
                            : (_revealDigit[index] ? otp[index] : '•'),
                        style: GoogleFonts.varelaRound(
                          color: C.text1,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.color,
    required this.background,
    required this.border,
    required this.icon,
  });

  final String message;
  final Color color;
  final Color background;
  final Color border;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.varelaRound(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
