import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_controller.dart';
import 'availability.dart';
import 'safety.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotif = true;
  bool _emailNotif = false;
  bool _smsNotif = true;
  bool _darkMode = false;
  final _localeController = LocaleController();

  // Short native label shown as the trailing value for the Language row.
  String _languageLabel(String code) {
    switch (code) {
      case 'hi':
        return 'हिन्दी';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final currentCode = _localeController.locale?.languageCode ?? 'en';
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(l.settings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionTitle(l.workPreferences),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _TapItem(
              icon: Icons.event_available_outlined,
              title: l.availability,
              trailing: l.setWeeklyHours,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AvailabilityScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _SectionTitle(l.safety.toUpperCase()),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _TapItem(
              icon: Icons.block,
              title: l.blockedUsers,
              trailing: l.manage,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          _SectionTitle(l.setNotifications),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _ToggleItem(
              icon: Icons.notifications_outlined,
              title: l.setPushNotif,
              subtitle: l.setPushNotifSub,
              value: _pushNotif,
              onChanged: (v) => setState(() => _pushNotif = v),
            ),
            const Divider(height: 1, indent: 46),
            _ToggleItem(
              icon: Icons.email_outlined,
              title: l.setEmailNotif,
              subtitle: l.setEmailNotifSub,
              value: _emailNotif,
              onChanged: (v) => setState(() => _emailNotif = v),
            ),
            const Divider(height: 1, indent: 46),
            _ToggleItem(
              icon: Icons.sms_outlined,
              title: l.setSmsNotif,
              subtitle: l.setSmsNotifSub,
              value: _smsNotif,
              onChanged: (v) => setState(() => _smsNotif = v),
            ),
          ]),
          const SizedBox(height: 20),

          _SectionTitle(l.setAppearance),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _ToggleItem(
              icon: Icons.dark_mode_outlined,
              title: l.setDarkMode,
              subtitle: l.setComingSoon,
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
            const Divider(height: 1, indent: 46),
            _TapItem(
              icon: Icons.language,
              title: l.language,
              trailing: _languageLabel(currentCode),
              onTap: () => _showLanguagePicker(),
            ),
          ]),
          const SizedBox(height: 20),

          _SectionTitle(l.setDataStorage),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _TapItem(
              icon: Icons.cached,
              title: l.setClearCache,
              trailing: '12 MB',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.setCacheCleared)),
                );
              },
            ),
            const Divider(height: 1, indent: 46),
            _TapItem(
              icon: Icons.download_outlined,
              title: l.setDownloadData,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l.setDataExportEmailed)),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          _SectionTitle(l.setDangerZone),
          const SizedBox(height: 8),
          _SettingsCard(children: [
            _TapItem(
              icon: Icons.delete_outline,
              title: l.setDeleteAccount,
              isDestructive: true,
              onTap: () => _showDeleteConfirm(),
            ),
          ]),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }

  void _showLanguagePicker() {
    final l = AppL10n.of(context)!;
    final options = <String, String>{
      'en': l.langEnglish,
      'hi': l.langHindi,
      'pa': l.langPunjabi,
    };
    final currentCode = _localeController.locale?.languageCode ?? 'en';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.selectLanguage,
              style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...options.entries.map((e) => ListTile(
                title: Text(e.value,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                trailing: currentCode == e.key
                    ? const Icon(Icons.check_circle, color: T.primary)
                    : null,
                onTap: () async {
                  await _localeController.setLocale(Locale(e.key));
                  if (mounted) setState(() {});
                  if (context.mounted) Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showDeleteConfirm() {
    final l = AppL10n.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.setDeleteAccountTitle,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            l.setDeleteAccountBody,
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.actionCancel,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l.setDeletionSubmitted)),
              );
            },
            child: Text(l.setDelete,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: T.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(title.toUpperCase(),
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: T.text3,
                letterSpacing: 1.0)),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        decoration: AppTheme.card(),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: T.primaryLight,
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: T.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: T.text1)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: T.text3)),
              ])),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: T.primary,
          ),
        ]),
      );
}

class _TapItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool isDestructive;
  final VoidCallback onTap;
  const _TapItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.isDestructive = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: isDestructive ? T.redLight : T.primaryLight,
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(icon,
                    size: 19, color: isDestructive ? T.red : T.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDestructive ? T.red : T.text1))),
              if (trailing != null)
                Text(trailing!,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: T.text3)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: isDestructive ? T.red : T.text3, size: 20),
            ]),
          ),
        ),
      );
}
