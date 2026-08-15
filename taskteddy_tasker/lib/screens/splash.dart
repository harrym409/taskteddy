import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.afterLogin = false});

  const SplashScreen.afterLogin({super.key}) : afterLogin = true;

  final bool afterLogin;

  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _brandBlue = Color(0xFF6384DB);

  String? _statusText;
  late final AnimationController _logo;

  @override
  void initState() {
    super.initState();
    _logo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _run();
  }

  @override
  void dispose() {
    _logo.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 350));

    if (widget.afterLogin) {
      await _runPostLoginFlow();
      return;
    }

    await _runStartupFlow();
  }

  Future<void> _runStartupFlow() async {
    if (!mounted) return;
    _setStatus(AppL10n.of(context)!.splashGettingReady);
    await Future.delayed(const Duration(milliseconds: 1150));

    final isLoggedIn = await Session.isLoggedIn();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/login');
  }

  Future<void> _runPostLoginFlow() async {
    if (!mounted) return;
    _setStatus(AppL10n.of(context)!.splashGettingThingsReady);

    // Location capture must NEVER block entry into the app — hard-cap it so a
    // hung permission dialog or GPS fix on an emulator can't freeze the splash.
    try {
      await _captureLocationForHome().timeout(const Duration(seconds: 4));
    } catch (_) {
      // Ignore any error/timeout — location is best-effort.
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _captureLocationForHome() async {
    if (!mounted) return;
    final l = AppL10n.of(context)!;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!enabled) {
        _setStatus(l.splashLocationOff);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setStatus(l.splashLocationSkipped);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 18),
        ),
      ).timeout(const Duration(seconds: 22));

      final label =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('detected_location', label);
      await prefs.setDouble('detected_location_lat', position.latitude);
      await prefs.setDouble('detected_location_lng', position.longitude);
      await prefs.setString(
        'detected_location_updated_at',
        DateTime.now().toIso8601String(),
      );

      _setStatus(l.splashLocationLocked(label));
    } catch (_) {
      _setStatus(l.splashLocationFailed);
    }
  }

  void _setStatus(String value) {
    if (!mounted) return;
    setState(() => _statusText = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween(begin: .88, end: 1.0)
        .animate(CurvedAnimation(parent: _logo, curve: Curves.easeOutBack));
    final logoFade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logo, curve: Curves.easeOut));
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: _brandBlue,
      body: Center(
        child: AnimatedBuilder(
          animation: _logo,
          builder: (_, child) => FadeTransition(
            opacity: logoFade,
            child: Transform.scale(scale: scale.value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_wordmark.png',
                width: screenWidth * 0.72,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _statusText ?? AppL10n.of(context)!.splashPreparing,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
