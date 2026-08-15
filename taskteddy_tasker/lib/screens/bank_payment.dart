import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/theme.dart';
import '../theme/app_theme.dart';
import '../services/tasker_state.dart';

class BankPaymentScreen extends StatefulWidget {
  const BankPaymentScreen({super.key});

  @override
  State<BankPaymentScreen> createState() => _BankPaymentScreenState();
}

class _BankPaymentScreenState extends State<BankPaymentScreen> {
  final TaskerState _state = TaskerState();

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    final methods = _state.payoutMethods;

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppTheme.gradientBar(l.bankTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.bankPayoutMethods.toUpperCase(), style: AppTheme.eyebrow()),
          const SizedBox(height: 10),

          if (methods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FriendlyState(
                icon: Icons.account_balance_wallet_outlined,
                title: l.bankNoMethods,
              ),
            )
          else
            ...methods.map((m) {
              final isBank = m['type'] == 'bank';
              return Column(
                children: [
                  _PaymentCard(
                    icon: isBank ? Icons.account_balance : Icons.qr_code,
                    title: m['name']?.toString() ?? '',
                    subtitle: m['details']?.toString() ?? '',
                    isDefault: m['isDefault'] == true,
                    onTap: () {},
                    onSetDefault: m['isDefault'] == true
                        ? null
                        : () {
                            _state.setDefaultPayoutMethod(m['name']?.toString() ?? '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.bankSetDefaultSuccess(m['name']?.toString() ?? ''))),
                            );
                          },
                    onDelete: () => _confirmDelete(context, m['name']?.toString() ?? ''),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),

          const SizedBox(height: 6),

          // Add new
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAddPaymentSheet(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: T.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border:
                      Border.all(color: T.primary.withValues(alpha: .3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: T.primary,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(l.bankAddPaymentMethod,
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: T.primary)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payout info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: T.blueLight,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: T.blue.withValues(alpha: .3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.info_outline, color: T.blue, size: 18),
                const SizedBox(width: 8),
                Text(l.bankPayoutInfo,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: T.blue)),
              ]),
              const SizedBox(height: 8),
              _InfoRow(l.bankProcessingTime, l.bankProcessingTimeVal),
              _InfoRow(l.bankMinWithdrawal, '₹100'),
              _InfoRow(l.bankPlatformFee, l.bankPlatformFeeVal),
              _InfoRow(l.bankPaymentCycle, l.bankPaymentCycleVal),
            ]),
          ),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String name) {
    final l = AppL10n.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.bankRemoveConfirmTitle(name),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(l.bankRemoveConfirmBody,
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
              _state.removePayoutMethod(name);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.bankMethodRemoved(name))),
              );
            },
            child: Text(l.commonRemove,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700, color: T.red)),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentSheet(BuildContext context) {
    final l = AppL10n.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.bankAddPaymentMethod,
              style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _AddOption(Icons.account_balance, l.bankBankAccount,
              l.bankBankAccountSub, () {
            Navigator.pop(context);
            _showBankForm(context);
          }),
          const SizedBox(height: 10),
          _AddOption(Icons.qr_code, l.bankUpiId, l.bankUpiSub, () {
            Navigator.pop(context);
            _showUpiForm(context);
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showBankForm(BuildContext context) {
    final l = AppL10n.of(context)!;
    final nameC = TextEditingController();
    final accC = TextEditingController();
    final ifscC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.bankAddBankAccount,
              style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
              controller: nameC,
              decoration: InputDecoration(
                  labelText: l.bankAccountHolderName,
                  prefixIcon: const Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextField(
              controller: accC,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: l.bankAccountNumber,
                  prefixIcon: const Icon(Icons.numbers))),
          const SizedBox(height: 12),
          TextField(
              controller: ifscC,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                  labelText: l.bankIfscCode,
                  prefixIcon: const Icon(Icons.code))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (nameC.text.trim().isEmpty || accC.text.trim().isEmpty || ifscC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.bankFillAllFields)),
                  );
                  return;
                }
                final last4 = accC.text.length > 4
                    ? accC.text.substring(accC.text.length - 4)
                    : accC.text;
                _state.addPayoutMethod({
                  'type': 'bank',
                  'name': nameC.text.trim(),
                  'details': l.bankSavingsMask(last4),
                  'isDefault': _state.payoutMethods.isEmpty,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.bankAccountAdded)),
                );
              },
              child: Text(l.bankAddBankAccount),
            ),
          ),
        ]),
      ),
    );
  }

  void _showUpiForm(BuildContext context) {
    final l = AppL10n.of(context)!;
    final upiC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.bankAddUpiId,
              style: GoogleFonts.nunito(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
              controller: upiC,
              decoration: InputDecoration(
                  labelText: l.bankUpiId,
                  hintText: l.bankUpiHint,
                  prefixIcon: const Icon(Icons.qr_code))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (upiC.text.trim().isEmpty || !upiC.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.bankEnterValidUpi)),
                  );
                  return;
                }
                _state.addPayoutMethod({
                  'type': 'upi',
                  'name': 'UPI (${upiC.text.trim().split('@')[0]})',
                  'details': upiC.text.trim(),
                  'isDefault': _state.payoutMethods.isEmpty,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.bankUpiAdded)),
                );
              },
              child: Text(l.bankAddUpiId),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;
  const _PaymentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDefault,
    required this.onTap,
    this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context)!;
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.card(
          borderColor: isDefault ? T.green.withValues(alpha: .4) : T.border,
        ),
        child: Column(children: [
          Row(children: [
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
                          color: T.text3,
                          fontWeight: FontWeight.w500)),
                ])),
            if (isDefault)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: T.greenLight,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(l.bankDefault,
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: T.green)),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (!isDefault && onSetDefault != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSetDefault,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(l.bankSetDefault,
                      style: GoogleFonts.nunito(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            if (!isDefault) const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16, color: T.red),
                label: Text(l.commonRemove,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: T.red)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: T.red,
                  side: BorderSide(color: T.red.withValues(alpha: .4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ]),
        ]),
      );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _AddOption(this.icon, this.title, this.subtitle, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: T.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: T.primaryLight,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: T.primary, size: 20),
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
                            color: T.text3,
                            fontWeight: FontWeight.w500)),
                  ])),
              const Icon(Icons.chevron_right_rounded, color: T.text3, size: 20),
            ]),
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: T.blue.withValues(alpha: .7),
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: T.blue,
                      fontWeight: FontWeight.w700)),
            ]),
      );
}
