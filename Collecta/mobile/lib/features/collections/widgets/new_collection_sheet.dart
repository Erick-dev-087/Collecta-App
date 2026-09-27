import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class NewCollectionSheet extends ConsumerStatefulWidget {
  const NewCollectionSheet({super.key});

  @override
  ConsumerState<NewCollectionSheet> createState() => _NewCollectionSheetState();
}

class _NewCollectionSheetState extends ConsumerState<NewCollectionSheet> {
  final _title = TextEditingController();
  final _defaultAmount = TextEditingController();
  final _target = TextEditingController();
  final _memberTarget = TextEditingController();
  final _shortcode = TextEditingController();
  final _account = TextEditingController();
  String _category = 'Trips & Events';
  bool _allowCustom = true;
  bool _useCustomChannel = false;
  String _destType = 'paybill';
  bool _busy = false;

  static const _categories = [
    'Trips & Events',
    'Capital Projects',
    'Youth & Camps',
    'Welfare',
  ];

  @override
  void dispose() {
    _title.dispose();
    _defaultAmount.dispose();
    _target.dispose();
    _memberTarget.dispose();
    _shortcode.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('A title is required')));
      return;
    }
    if (_useCustomChannel && _shortcode.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the payment shortcode')));
      return;
    }
    setState(() => _busy = true);
    final data = <String, dynamic>{
      'title': _title.text.trim(),
      'category': _category,
      'defaultAmount': num.tryParse(_defaultAmount.text.trim()),
      'targetAmount': num.tryParse(_target.text.trim()),
      'memberTarget': num.tryParse(_memberTarget.text.trim()),
      'allowCustomAmount': _allowCustom,
    };
    if (_useCustomChannel) {
      data['paymentDestinationType'] = _destType;
      data['paymentShortcode'] = _shortcode.text.trim();
      if (_destType == 'paybill' && _account.text.trim().isNotEmpty) {
        data['paymentAccountNumber'] = _account.text.trim();
      }
    }
    await ref.read(collectaApiProvider).createCollection(data);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.slateBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('New Collection', style: AppType.headlineMd),
              const SizedBox(height: 4),
              Text('Set a target quota and start reconciling M-Pesa STK payments.',
                  style: AppType.bodyMd.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              _label('Collection title'),
              TextField(
                controller: _title,
                decoration: const InputDecoration(hintText: 'e.g. Youth Camp Retreat'),
              ),
              const SizedBox(height: AppSpacing.md),
              _label('Category'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Amount / member'),
                        TextField(
                          controller: _defaultAmount,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                              prefixText: 'KES ', hintText: '3000'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Members'),
                        TextField(
                          controller: _memberTarget,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(hintText: '50'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _label('Campaign goal'),
              TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(prefixText: 'KES ', hintText: '150000'),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.emeraldDeep,
                value: _allowCustom,
                onChanged: (v) => setState(() => _allowCustom = v),
                title: Text('Allow custom amounts', style: AppType.labelLg),
                subtitle: Text('Let contributors pay a different amount',
                    style: AppType.bodySm),
              ),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.emeraldDeep,
                value: _useCustomChannel,
                onChanged: (v) => setState(() => _useCustomChannel = v),
                title: Text('Use custom payment channel', style: AppType.labelLg),
                subtitle: Text(
                    'Override the org default with a different Till or Paybill',
                    style: AppType.bodySm),
              ),
              if (_useCustomChannel) ...[
                const SizedBox(height: AppSpacing.sm),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(_destType == 'paybill'
                              ? 'Business number'
                              : 'Till number'),
                          TextField(
                            controller: _shortcode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                                hintText:
                                    _destType == 'paybill' ? '522522' : '123456'),
                          ),
                        ],
                      ),
                    ),
                    if (_destType == 'paybill') ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Account number'),
                            TextField(
                              controller: _account,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. FUND-2026'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Create Collection'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: AppType.labelMd),
      );
}
