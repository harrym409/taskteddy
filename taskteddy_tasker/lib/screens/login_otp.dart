import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';

const _taskTeddyBlue = Color(0xFF6384DB);
const _taskTeddyCream = Color(0xFFF7F1E3);
const _taskTeddyWhite = Color(0xFFFFFFFF);

const _termsUrl = 'https://taskteddy.com/terms';
const _privacyUrl = 'https://taskteddy.com/privacy';



class TaskerOtpLoginScreen extends StatefulWidget {
  const TaskerOtpLoginScreen({super.key});

  @override
  State<TaskerOtpLoginScreen> createState() => _TaskerOtpLoginScreenState();
}

class _TaskerOtpLoginScreenState extends State<TaskerOtpLoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

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
  Timer? _otpTimer;

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() {
      _otpCountdown = 60;
      _canResend = false;
    });
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpCountdown <= 1) {
        timer.cancel();
        setState(() {
          _otpCountdown = 0;
          _canResend = true;
        });
      } else {
        setState(() {
          _otpCountdown--;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_syncPanelWithFocus);
    _otpFocus.addListener(_syncPanelWithFocus);
  }

  @override
  void dispose() {
    _phoneFocus.removeListener(_syncPanelWithFocus);
    _otpFocus.removeListener(_syncPanelWithFocus);
    _otpTimer?.cancel();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _syncPanelWithFocus() {
    if (!mounted) return;
    final shouldLift = _phoneFocus.hasFocus || _otpFocus.hasFocus || _otpSent;
    if (_panelLifted == shouldLift) return;
    setState(() => _panelLifted = shouldLift);
  }

  String get _fullPhone => ApiService.indiaPhoneNumber(_phone.text.trim());

  Future<void> _openLink(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.of(context)!.profileCouldNotOpenLink)),
      );
    }
  }

  Future<void> _sendOtp() async {
    if (_phone.text.trim().length != 10) {
      setState(() => _error = AppL10n.of(context)!.enterValidMobile);
      return;
    }

    setState(() {
      _sendingOtp = true;
      _panelLifted = true;
      _error = null;
      _notice = AppL10n.of(context)!.loginSendingOtp(_fullPhone);
    });

    try {
      final response = await ApiService.sendOtpForTasker(_fullPhone);
      if (!mounted) return;

      setState(() {
        _verificationId = 'backend-otp';
        _otpSent = true;
        _notice = AppL10n.of(context)!.loginOtpSent(_fullPhone);
        // In local dev (no SMS provider) the backend returns the code so it can
        // be autofilled. Never happens in production / once a provider is set.
        final devOtp = response['otp'];
        if (devOtp != null && devOtp.toString().isNotEmpty) {
          _otp.text = devOtp.toString();
        }
      });
      _otpFocus.requestFocus();
      _startOtpTimer();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = _cleanError(AppL10n.of(context)!, errorMsg));
      }
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  String _cleanError(AppL10n l, String error) {
    final lower = error.toLowerCase();
    if (lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('socket')) {
      return l.loginErrConnect;
    }
    if (lower.contains('refused') || lower.contains('unreachable')) {
      return l.loginErrServer;
    }
    if (lower.contains('invalid otp') || lower.contains('wrong otp')) {
      return l.loginErrInvalidOtp;
    }
    if (lower.contains('expired otp')) {
      return l.loginErrExpiredOtp;
    }
    if (lower.contains('too many') || lower.contains('rate limit')) {
      return l.loginErrTooMany;
    }
    return error.length > 100
        ? l.loginErrGeneric
        : error;
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otp.text.trim().isEmpty) {
      setState(() => _error = AppL10n.of(context)!.loginEnterOtpSent);
      return;
    }
    if (_otp.text.trim().length != 6) {
      setState(() => _error = AppL10n.of(context)!.enterFullOtp);
      return;
    }

    setState(() {
      _verifyingOtp = true;
      _error = null;
    });

    try {
      final data = await ApiService.verifyOtp(_fullPhone, _otp.text.trim());
      await Session.setAuth(
          data['access_token'].toString(), data['user'] ?? {});
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/post-login-splash');
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() => _error = _cleanError(AppL10n.of(context)!, errorMsg));
      }
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final panelBottom = (keyboardInset - bottomSafeArea).clamp(0.0, 460.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _taskTeddyBlue,
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
              final expandedHeight = (maxHeight * 0.55)
                  .clamp(360.0, maxHeight - 20.0);
              final maxPanelHeight =
                  (maxHeight - panelBottom).clamp(240.0, maxHeight).toDouble();
              final panelHeight =
                  (formActive ? expandedHeight : collapsedHeight)
                      .clamp(240.0, maxPanelHeight)
                      .toDouble();

              return Stack(
                children: [
                  const Positioned.fill(
                    child: _Header(),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: panelBottom,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: panelHeight,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: _FooterCard(
                        phoneController: _phone,
                        otpController: _otp,
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
                            _otp.clear();
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
                        onOpenTerms: () => _openLink(_termsUrl),
                        onOpenPrivacy: () => _openLink(_privacyUrl),
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
  const _Header();

  @override
  Widget build(BuildContext context) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_wordmark.png',
                    width: 260,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppL10n.of(context)!.appTagline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.varelaRound(
                      color: _taskTeddyWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: const Alignment(0, -0.8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Image.asset(
                    'assets/images/tasker_heroes.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ],
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
    required this.onOpenTerms,
    required this.onOpenPrivacy,
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
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

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
                  AppL10n.of(context)!.loginOrSignup,
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
                color: T.red,
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
                  backgroundColor: _taskTeddyBlue,
                  foregroundColor: _taskTeddyCream,
                  disabledBackgroundColor:
                      _taskTeddyBlue.withValues(alpha: .6),
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
                        AppL10n.of(context)!.actionContinue,
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
                        AppL10n.of(context)!.changeNumber,
                        style: GoogleFonts.varelaRound(
                          color: _taskTeddyBlue,
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
                            ? AppL10n.of(context)!.resendOtp
                            : AppL10n.of(context)!.resendInSeconds(otpCountdown),
                        style: GoogleFonts.varelaRound(
                          color: canResend ? _taskTeddyBlue : const Color(0xFF6B7280),
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
                  text: AppL10n.of(context)!.loginTermsPrefix,
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: onOpenTerms,
                        child: Text(
                          AppL10n.of(context)!.profileTerms,
                          style: GoogleFonts.varelaRound(
                            color: _taskTeddyBlue,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: _taskTeddyBlue,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: AppL10n.of(context)!.loginAnd),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: onOpenPrivacy,
                        child: Text(
                          AppL10n.of(context)!.profilePrivacy,
                          style: GoogleFonts.varelaRound(
                            color: _taskTeddyBlue,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: _taskTeddyBlue,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: AppL10n.of(context)!.loginTermsSuffix),
                  ],
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.varelaRound(
                  color: const Color(0xFF757575),
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
          color: const Color(0xFF333333),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: AppL10n.of(context)!.mobileNumber,
          prefixText: '+91 ',
          prefixIcon: const Icon(Icons.phone_outlined, color: _taskTeddyBlue),
          prefixStyle: GoogleFonts.varelaRound(
            color: const Color(0xFF333333),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFFFF0ED),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE6FF)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDDE6FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _taskTeddyBlue, width: 1.4),
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
                            ? _taskTeddyBlue
                            : const Color(0xFFDDE6FF),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        !hasValue
                            ? ''
                            : (_revealDigit[index] ? otp[index] : '•'),
                        style: GoogleFonts.varelaRound(
                          color: const Color(0xFF333333),
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
