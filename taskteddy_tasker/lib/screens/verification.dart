import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../services/tasker_state.dart';
import '../l10n/app_localizations.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TaskerState _state = TaskerState();
  String? _aadhaarMasked;
  String? _panMasked;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    // Masked KYC numbers the admin entered during verification (last 4 digits).
    try {
      final profile = await ApiService.getTaskerProfile();
      if (mounted) {
        _aadhaarMasked = profile['aadhaar_masked']?.toString();
        _panMasked = profile['pan_masked']?.toString();
      }
    } catch (_) {}
    try {
      final docs = await ApiService.getKycDocuments();
      if (!mounted) return;
      for (final d in docs) {
        final key = d['doc_type']?.toString() ?? '';
        final status = switch (d['status']?.toString()) {
          'approved' => 'verified',
          'rejected' => 'rejected',
          _ => 'pending',
        };
        _state.uploadDocument(key, status);
        if (status == 'rejected' && d['reason'] != null) {
          _rejectionReasons[key] = d['reason'].toString();
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      // Offline / not logged in: keep local view.
    }
  }

  final Map<String, String> _rejectionReasons = {};

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _onDocTap(String key, String title) {
    final l = AppL10n.of(context)!;
    final currentStatus = _state.verificationStatuses[key];
    if (currentStatus == 'verified') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.verifAlreadyVerified(title))),
      );
      return;
    }

    // The selfie must be a live capture (anti-fraud) — go straight to the
    // camera, no gallery option.
    if (key == 'selfie') {
      _pickAndUpload(key, title, ImageSource.camera);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.verifUploadTitle(title),
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: T.primary),
              title: Text(l.commonChooseGallery, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(key, title, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: T.primary),
              title: Text(l.commonTakePhoto, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(key, title, ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
      String key, String title, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
      // Selfies open the front camera by default.
      preferredCameraDevice:
          key == 'selfie' ? CameraDevice.front : CameraDevice.rear,
    );
    if (file == null || !mounted) return;

    final l = AppL10n.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.verifUploading(title))),
    );
    try {
      await ApiService.uploadKycDocument(docType: key, file: file);
      if (!mounted) return;
      _state.uploadDocument(key, 'pending');
      _rejectionReasons.remove(key);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l.verifSubmitted(title)),
          backgroundColor: T.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: T.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final verificationStatuses = _state.verificationStatuses;
    final totalDocs = verificationStatuses.length;
    final verifiedDocs = verificationStatuses.values.where((status) => status == 'verified').length;
    final double progress = verifiedDocs / totalDocs;

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(l.verifTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Progress card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.panelGradient,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: T.primary.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.verified_user, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l.verifProgress,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(l.verifDocsVerified(verifiedDocs, totalDocs),
                          style: GoogleFonts.nunito(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ])),
                Text('${(progress * 100).toInt()}%',
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 6,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          Text(l.verifDocuments.toUpperCase(),
              style: AppTheme.eyebrow()),
          const SizedBox(height: 10),

          _DocItem(
            icon: Icons.badge,
            title: l.verifAadhaar,
            subtitle: (_aadhaarMasked?.isNotEmpty ?? false)
                ? _aadhaarMasked!
                : (verificationStatuses['aadhaar'] == 'pending'
                    ? l.verifUnderReview
                    : l.verifAadhaarUpload),
            status: verificationStatuses['aadhaar'] ?? 'not_submitted',
            onTap: () => _onDocTap('aadhaar', l.verifAadhaar),
          ),
          const SizedBox(height: 10),
          _DocItem(
            icon: Icons.credit_card,
            title: l.verifPan,
            subtitle: (_panMasked?.isNotEmpty ?? false)
                ? _panMasked!
                : (verificationStatuses['pan'] == 'pending'
                    ? l.verifUnderReview
                    : l.verifPanUpload),
            status: verificationStatuses['pan'] ?? 'not_submitted',
            onTap: () => _onDocTap('pan', l.verifPan),
          ),
          const SizedBox(height: 10),
          _DocItem(
            icon: Icons.home_outlined,
            title: l.verifAddressProof,
            subtitle: verificationStatuses['address'] == 'verified'
                ? l.verifAddressVerified
                : verificationStatuses['address'] == 'pending'
                    ? l.verifUnderReview
                    : l.verifAddressUpload,
            status: verificationStatuses['address'] ?? 'not_submitted',
            onTap: () => _onDocTap('address', l.verifAddressProof),
          ),
          const SizedBox(height: 10),
          _DocItem(
            icon: Icons.camera_alt_outlined,
            title: l.verifSelfie,
            subtitle: verificationStatuses['selfie'] == 'verified'
                ? l.verifIdentityConfirmed
                : verificationStatuses['selfie'] == 'pending'
                    ? l.verifUnderReview
                    : l.verifSelfieUpload,
            status: verificationStatuses['selfie'] ?? 'not_submitted',
            onTap: () => _onDocTap('selfie', l.verifSelfie),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: T.blueLight,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: T.blue.withValues(alpha: .3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: T.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      l.verifUnlockPremium,
                      style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: T.blue))),
            ]),
          ),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, status;
  final VoidCallback onTap;
  const _DocItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case 'verified':
        return T.green;
      case 'pending':
        return T.yellow;
      case 'rejected':
        return T.red;
      default:
        return T.text3;
    }
  }

  Color get _statusBg {
    switch (status) {
      case 'verified':
        return T.greenLight;
      case 'pending':
        return T.yellowLight;
      case 'rejected':
        return T.redLight;
      default:
        return T.bg;
    }
  }

  String _statusText(AppL10n l) {
    switch (status) {
      case 'verified':
        return l.verifStatusVerified;
      case 'pending':
        return l.verifStatusPending;
      case 'rejected':
        return l.verifStatusRejected;
      default:
        return l.verifStatusUpload;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'verified':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.upload_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.card(),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: T.primaryLight,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: T.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: GoogleFonts.nunito(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: T.text1)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style: GoogleFonts.nunito(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: T.text3)),
                  ])),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_statusIcon, size: 13, color: _statusColor),
                  const SizedBox(width: 4),
                  Text(_statusText(l),
                      style: GoogleFonts.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _statusColor)),
                ]),
              ),
            ]),
          ),
        ),
      );
  }
}
