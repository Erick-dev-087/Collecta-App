import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_provider.dart';
import '../../data/models/enums.dart';
import '../../data/models/organization.dart';
import '../../state/auth_controller.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/page_header.dart';
import '../../widgets/ui.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  final _classification = TextEditingController();
  final _currency = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _shortcode = TextEditingController();
  final _account = TextEditingController();
  final _header = TextEditingController();
  final _footer = TextEditingController();
  bool _instantStk = true;
  bool _showReceipts = true;
  bool _includeLink = true;
  String _destType = 'paybill';
  bool _seeded = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _classification.dispose();
    _currency.dispose();
    _email.dispose();
    _phone.dispose();
    _shortcode.dispose();
    _account.dispose();
    _header.dispose();
    _footer.dispose();
    super.dispose();
  }

  void _seed(Organization org) {
    if (_seeded) return;
    _name.text = org.name;
    _classification.text = org.classification;
    _currency.text = org.currency;
    _email.text = org.treasuryEmail ?? '';
    _phone.text = org.verificationPhone ?? '';
    final dest = org.defaultDestination;
    _shortcode.text = dest?.shortcode ?? '';
    _account.text = dest?.accountNumber ?? '';
    _destType = dest?.type.wire ?? 'paybill';
    _header.text = org.ledgerHeader;
    _footer.text = org.ledgerFooter;
    _instantStk = org.instantStkTrigger;
    _showReceipts = org.showReceiptIds;
    _includeLink = org.includePayLink;
    _seeded = true;
  }

  Future<void> _save(Organization org) async {
    setState(() => _busy = true);

    // Rebuild destinations list with edited default destination values.
    final updatedDests = <PaymentDestination>[];
    final oldDest = org.defaultDestination;
    final editedDest = PaymentDestination(
      id: oldDest?.id ?? 'dest_default',
      type: PaymentDestinationType.fromString(_destType),
      shortcode: _shortcode.text.trim(),
      accountNumber: _account.text.trim().isEmpty
          ? null
          : _account.text.trim(),
      name: oldDest?.name,
      hasPasskey: oldDest?.hasPasskey ?? false,
      isActive: true,
      isDefault: true,
    );
    // Keep non-default destinations, replace or insert the default.
    for (final d in org.destinations) {
      if (d.id == editedDest.id) continue;
      updatedDests.add(d);
    }
    updatedDests.insert(0, editedDest);

    await ref.read(collectaApiProvider).updateOrganization(
          org.copyWith(
            name: _name.text.trim(),
            classification: _classification.text.trim(),
            currency: _currency.text.trim(),
            treasuryEmail: _email.text.trim(),
            verificationPhone: _phone.text.trim(),
            ledgerHeader: _header.text.trim(),
            ledgerFooter: _footer.text.trim(),
            instantStkTrigger: _instantStk,
            showReceiptIds: _showReceipts,
            includePayLink: _includeLink,
            destinations: updatedDests,
          ),
        );
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(organizationProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldDeep)),
          error: (e, _) =>
              AsyncStateView(message: 'Could not load settings.\n$e', isError: true),
          data: (org) {
            _seed(org);
            return _content(org);
          },
        ),
      ),
    );
  }

  Widget _content(Organization org) {
    final user = ref.watch(authControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
      children: [
        const CollectaHeader(
          title: 'Settings & Integrations',
          subtitle:
              'Organization profile, M-Pesa gateways, and WhatsApp ledger formatting.',
        ),
        const SizedBox(height: AppSpacing.md),

        // Organization profile
        _card('Organization Profile', Icons.badge_outlined, [
          _field('Organization legal name', _name),
          _field('Classification', _classification),
          _field('Operating currency', _currency),
          _field('Treasury email', _email, keyboard: TextInputType.emailAddress),
          _field('Verification phone', _phone, keyboard: TextInputType.phone),
        ]),
        const SizedBox(height: AppSpacing.md),

        // M-Pesa gateways
        _card('M-Pesa & Payment Gateways', Icons.account_balance_outlined, [
          _sectionLabel('Destination type'),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'paybill', label: Text('Paybill')),
              ButtonSegment(value: 'till', label: Text('Till')),
            ],
            selected: {_destType},
            onSelectionChanged: (v) => setState(() => _destType = v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.emeraldDeep,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _field(
                      _destType == 'paybill' ? 'Paybill number' : 'Till number',
                      _shortcode,
                      keyboard: TextInputType.number)),
              if (_destType == 'paybill') ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _field('Account number', _account)),
              ],
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.emeraldDeep,
            value: _instantStk,
            onChanged: (v) => setState(() => _instantStk = v),
            title: Text('Instant STK Push dispatch', style: AppType.labelLg),
            subtitle: Text('Prompt members automatically when added to a drive',
                style: AppType.bodySm),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),

        // WhatsApp templates
        _card('WhatsApp Ledger Templates', Icons.chat_outlined, [
          _field('Broadcast header', _header),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.emeraldDeep,
            value: _showReceipts,
            onChanged: (v) => setState(() => _showReceipts = v),
            title: Text('Show Safaricom receipt IDs', style: AppType.labelLg),
            subtitle: Text('Publishes the M-Pesa transaction hash for audit',
                style: AppType.bodySm),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.emeraldDeep,
            value: _includeLink,
            onChanged: (v) => setState(() => _includeLink = v),
            title: Text('Include payment link', style: AppType.labelLg),
            subtitle: Text('Appends a one-click STK link at the bottom',
                style: AppType.bodySm),
          ),
          _field('Ledger footer signature', _footer),
        ]),
        const SizedBox(height: AppSpacing.md),

        // Session / account
        SectionCard(
          child: Column(
            children: [
              Row(
                children: [
                  InitialsAvatar(initials: user?.initials ?? 'S', size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Treasurer',
                            style: AppType.labelLg),
                        Text((user?.roleTitle ?? 'Treasurer').toUpperCase(),
                            style: AppType.labelSm),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.discrepancyText,
                    side: const BorderSide(color: AppColors.discrepancyBg),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : () => _save(org),
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Save Configurations'),
          ),
        ),
      ],
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.emeraldDeep),
              const SizedBox(width: 8),
              Text(title, style: AppType.headlineSm.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.labelMd),
          const SizedBox(height: 6),
          TextField(controller: c, keyboardType: keyboard),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(t, style: AppType.labelMd),
      );
}
