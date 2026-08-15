import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../services/permission_service.dart';
import '../state/app_providers.dart';
import '../state/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.afterLogin = false});

  const SplashScreen.afterLogin({super.key}) : afterLogin = true;

  final bool afterLogin;

  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logo;
  late AnimationController _exit;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _logo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logo.forward();
    await PermissionService.requestStartupPermissions();

    if (widget.afterLogin) {
      await _runPostLoginFlow();
      return;
    }

    await _runStartupFlow();
  }

  Future<void> _runStartupFlow() async {
    _setStatus(AppL10n.of(context)!.splashLoadingWorkspace);
    await Future.delayed(const Duration(milliseconds: 1700));
    final auth = await ref.read(authControllerProvider.future);
    await _transitionTo(auth.isLoggedIn ? '/home' : '/login');
  }

  Future<void> _runPostLoginFlow() async {
    _setStatus(AppL10n.of(context)!.splashGettingReady);
    // Location capture must NEVER block entry — hard-cap it so a hung permission
    // dialog or GPS fix (common on emulators) can't freeze the splash.
    try {
      await _captureLocationForHome().timeout(const Duration(seconds: 4));
    } catch (_) {
      // Best-effort only.
    }

    if (!mounted) return;
    _setStatus(AppL10n.of(context)!.splashAlmostThere);
    await Future.delayed(const Duration(milliseconds: 300));
    await _transitionTo('/home');
  }

  Future<void> _transitionTo(String routeName) async {
    _exit.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  Future<void> _captureLocationForHome() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
      if (!serviceEnabled) {
        if (mounted) _setStatus(AppL10n.of(context)!.splashLocationOff);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _setStatus(AppL10n.of(context)!.splashLocationSkipped);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 18),
        ),
      ).timeout(const Duration(seconds: 22));

      if (position.isMocked) {
        if (mounted) _setStatus(AppL10n.of(context)!.splashUsingDefaultLocation);
        return;
      }

      final label = await _labelForCoordinates(
        position.latitude,
        position.longitude,
      );

      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString('detected_location', label);
      await prefs.setDouble('detected_location_lat', position.latitude);
      await prefs.setDouble('detected_location_lng', position.longitude);
      await prefs.setString(
        'detected_location_updated_at',
        DateTime.now().toIso8601String(),
      );
      if (mounted) _setStatus(AppL10n.of(context)!.splashLocationLocked(label));
    } catch (_) {
      if (mounted) _setStatus(AppL10n.of(context)!.splashLocationFailed);
    }
  }

  Future<String> _labelForCoordinates(double lat, double lng) async {
    final places = await placemarkFromCoordinates(lat, lng)
        .timeout(const Duration(seconds: 6));
    if (places.isEmpty) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }

    final place = places.first;
    final city = [
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
    ]
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    final state = place.administrativeArea ?? '';
    final country = place.country ?? '';
    final parts = [city, state.isNotEmpty ? state : country]
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    if (parts.isEmpty) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
    return parts.join(', ');
  }

  void _setStatus(String text) {
    if (!mounted) return;
    setState(() => _statusText = text);
  }

  @override
  void dispose() {
    _logo.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween(begin: .88, end: 1.0)
        .animate(CurvedAnimation(parent: _logo, curve: Curves.easeOutBack));
    final logoFade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logo, curve: Curves.easeOut));
    final exitFade = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exit, curve: Curves.easeIn));
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AnimatedBuilder(
      animation: _exit,
      builder: (_, child) => Opacity(opacity: exitFade.value, child: child),
      child: Scaffold(
        backgroundColor: const Color(0xFFFF6E6E),
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
                if (widget.afterLogin)
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
      ),
    );
  }
}
