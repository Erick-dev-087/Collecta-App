import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/analytics.dart';
import '../../data/models/collection.dart';
import '../../data/models/enums.dart';
import '../../data/models/organization.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../utils/ledger.dart';
import '../../utils/whatsapp.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/ui.dart';
import '../../widgets/whatsapp_icon.dart';
import 'widgets/audit_stream.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key, this.initialEventId, this.standalone = false});

  final String? initialEventId;
  final bool standalone;

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String? _eventId;
  PaidStatus? _filter; // null = All

  @override
  void initState() {
    super.initState();
    _eventId = widget.initialEventId;
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final body = collectionsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.emeraldDeep)),
      error: (e, _) =>
          AsyncStateView(message: 'Could not load ledger.\n$e', isError: true),
      data: (collections) {
        if (collections.isEmpty) {
          return const AsyncStateView(message: 'No collections yet.');
        }
        final eventId = _eventId ?? collections.first.id;
        final collection =
            collections.firstWhere((c) => c.id == eventId, orElse: () => collections.first);
        return _content(collections, collection);
      },
    );

    if (widget.standalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('WhatsApp Ledger'),
          leading: const BackButton(),
        ),
        body: SafeArea(top: false, child: body),
      );
    }
    return Scaffold(body: SafeArea(bottom: false, child: body));
  }

  Widget _content(List<Collection> collections, Collection collection) {
    final ledgerAsync = ref.watch(ledgerProvider(collection.id));
    final orgAsync = ref.watch(organizationProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ledgerProvider(collection.id));
        ref.invalidate(paymentsProvider(collection.id));
      },
      color: AppColors.emeraldDeep,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          if (!widget.standalone)
            const CollectaHeader(
              title: 'WhatsApp Ledgers',
              subtitle:
                  'Review reconciled attendees and broadcast formatted lists to WhatsApp.',
            ),
          if (!widget.standalone) const SizedBox(height: AppSpacing.md),
          _selector(collections, collection),
          const SizedBox(height: AppSpacing.md),
          _summary(collection),
          const SizedBox(height: AppSpacing.md),
          ledgerAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.emeraldDeep)),
            ),
            error: (e, _) => AsyncStateView(message: '$e', isError: true),
            data: (entries) => Column(
              children: [
                _filterTabs(entries),
                const SizedBox(height: AppSpacing.md),
                _entriesCard(entries),
                const SizedBox(height: AppSpacing.md),
                orgAsync.maybeWhen(
                  data: (org) => _payloadCard(org, collection, entries),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AuditStream(eventId: collection.id),
        ],
      ),
    );
  }

  Widget _selector(List<Collection> collections, Collection selected) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: collections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = collections[i];
          final isSel = c.id == selected.id;
          return GestureDetector(
            onTap: () => setState(() {
              _eventId = c.id;
              _filter = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? AppColors.mintNeon : AppColors.panel,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: isSel ? AppColors.mintNeon : AppColors.slateBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14,
                      color: isSel ? AppColors.slateInk : AppColors.slateMuted),
                  const SizedBox(width: 6),
                  Text(c.title,
                      style: AppType.labelMd.copyWith(
                          color:
                              isSel ? AppColors.slateInk : AppColors.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summary(Collection c) {
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: AppType.headlineSm),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.verified,
                        size: 15, color: AppColors.matchedText),
                    const SizedBox(width: 4),
                    Text('${c.contributorCount} attending',
                        style: AppType.labelMd),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(kes(c.totalCollected), style: AppType.currencyMd),
              Text('Reconciled', style: AppType.labelSm),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showRecordCashSheet(context, c),
                icon: const Icon(Icons.money, size: 16),
                label: const Text('Add Cash'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecordCashSheet(BuildContext context, Collection collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl),
        child: _RecordCashForm(collection: collection),
      ),
    );
  }

  Widget _filterTabs(List<LedgerEntry> entries) {
    int count(PaidStatus? s) =>
        s == null ? entries.length : entries.where((e) => e.status == s).length;
    final tabs = <(String, PaidStatus?)>[
      ('All', null),
      ('Full', PaidStatus.full),
      ('Partial', PaidStatus.partial),
      ('Pending', PaidStatus.pending),
    ];
    return Row(
      children: [
        for (final t in tabs)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filter = t.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _filter == t.$2
                        ? AppColors.emeraldDeep
                        : AppColors.panel,
                    borderRadius: BorderRadius.circular(AppRadius.base),
                    border: Border.all(
                        color: _filter == t.$2
                            ? AppColors.emeraldDeep
                            : AppColors.slateBorder),
                  ),
                  child: Text('${t.$1} ${count(t.$2)}',
                      style: AppType.labelMd.copyWith(
                          color: _filter == t.$2
                              ? Colors.white
                              : AppColors.textSecondary)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _entriesCard(List<LedgerEntry> entries) {
    final filtered = _filter == null
        ? entries
        : entries.where((e) => e.status == _filter).toList();
    if (filtered.isEmpty) {
      return const SectionCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: AsyncStateView(message: 'No contributors in this filter.'),
        ),
      );
    }
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < filtered.length; i++) ...[
            _entryRow(filtered[i]),
            if (i != filtered.length - 1)
              const Divider(height: 1, color: AppColors.slateBorder),
          ],
        ],
      ),
    );
  }

  Widget _entryRow(LedgerEntry e) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          InitialsAvatar(initials: e.member.initials, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.member.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelLg),
                const SizedBox(height: 2),
                Text(
                    e.receipt != null
                        ? e.receipt!
                        : 'Expected ${kes(e.expected)}',
                    style: AppType.tabular.copyWith(color: AppColors.slateMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(kes(e.paid),
                  style: AppType.currencyMd.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              StatusPill.paid(e.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payloadCard(
      Organization org, Collection collection, List<LedgerEntry> entries) {
    final payload = buildWhatsAppPayload(org, collection, entries);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 18, color: AppColors.emeraldDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text('WhatsApp Ready Text Payload',
                    style: AppType.headlineSm.copyWith(fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Auto-formatted with receipts', style: AppType.labelSm),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.slateBorder),
            ),
            child: SelectableText(
              payload,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.5,
                color: AppColors.slateInk,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await copyToClipboard(payload);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ledger copied to clipboard')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () async {
                    final ok = await shareToWhatsApp(payload);
                    if (!ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('WhatsApp is not available on this device')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.base)),
                  ),
                  icon: const WhatsAppIcon(size: 18, color: Colors.white),
                  label: const Text('Send to WhatsApp'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordCashForm extends ConsumerStatefulWidget {
  const _RecordCashForm({required this.collection});
  final Collection collection;

  @override
  ConsumerState<_RecordCashForm> createState() => _RecordCashFormState();
}

class _RecordCashFormState extends ConsumerState<_RecordCashForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.collection.defaultAmount != null) {
      _amountController.text = widget.collection.defaultAmount.toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(apiProvider).recordCash(
            eventId: widget.collection.id,
            phone: _phoneController.text.trim(),
            amount: int.parse(_amountController.text.trim()),
            payerName: _nameController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash payment recorded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record cash: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Record Cash', style: AppType.headlineSm),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Payer Name (Optional)',
              hintText: 'e.g. John Doe',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '07XX XXX XXX',
            ),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                v == null || v.isEmpty ? 'Phone number is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (KES)',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Amount is required';
              if (int.tryParse(v) == null) return 'Enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _submitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Cash Entry'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
