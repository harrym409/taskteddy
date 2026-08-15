import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

static const _referralCode = 'TASKTEDDY';

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(l.referTitle),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeroIllustration(l),
            const SizedBox(height: 24),
            _buildHowItWorks(l),
            const SizedBox(height: 24),
            _buildReferralCodeCard(context, l),
            const SizedBox(height: 20),
            _buildShareButtons(context, l),
            const SizedBox(height: 24),
            _buildYourReferrals(l),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroIllustration(AppL10n l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [T.primary, T.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: T.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.referEarnHero,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.referInviteFriends,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(AppL10n l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.referHowItWorks,
          style: AppTheme.sectionHeader(size: 17),
        ),
        const SizedBox(height: 14),
        _StepTile(
          stepNumber: 1,
          icon: Icons.share,
          color: T.blue,
          title: l.referStep1,
        ),
        const SizedBox(height: 10),
        _StepTile(
          stepNumber: 2,
          icon: Icons.person_add,
          color: T.teal,
          title: l.referStep2,
        ),
        const SizedBox(height: 10),
        _StepTile(
          stepNumber: 3,
          icon: Icons.celebration,
          color: T.gold,
          title: l.referStep3,
        ),
      ],
    );
  }

  Widget _buildReferralCodeCard(BuildContext context, AppL10n l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.card(),
      child: Column(
        children: [
          Text(
            l.referYourCode,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: T.text3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: T.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: T.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _referralCode,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: T.primary,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 16),
                Material(
                  color: T.primary,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(text: _referralCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l.referCodeCopied,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: T.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButtons(BuildContext context, AppL10n l) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final message = l.referShareMessage(_referralCode);
                final uri = Uri.parse(
                  'https://wa.me/?text=${Uri.encodeComponent(message)}',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.chat, size: 20),
              label: Text(
                l.referShareWhatsApp,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l.referShareDialogOpened,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: T.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: T.primary,
              side: const BorderSide(color: T.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Icon(Icons.share, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildYourReferrals(AppL10n l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.referYourReferrals,
          style: AppTheme.sectionHeader(size: 17),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ReferralStatCard(
                icon: Icons.people_alt_rounded,
                label: l.referTotalReferrals,
                value: '5',
                color: T.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReferralStatCard(
                icon: Icons.account_balance_wallet_rounded,
                label: l.referEarningsFrom,
                value: '₹1000',
                color: T.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final int stepNumber;
  final IconData icon;
  final Color color;
  final String title;

  const _StepTile({
    required this.stepNumber,
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.card(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppL10n.of(context)!.referStep(stepNumber),
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: T.text3,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: T.text1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReferralStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: AppTheme.metric(size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: T.text3,
            ),
          ),
        ],
      ),
    );
  }
}
