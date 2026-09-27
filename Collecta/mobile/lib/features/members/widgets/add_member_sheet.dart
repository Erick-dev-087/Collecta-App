import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class AddMemberSheet extends ConsumerStatefulWidget {
  const AddMemberSheet({super.key});

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _group = 'Choir';
  bool _busy = false;

  static const _groups = [
    'Choir',
    'Youth Guild',
    "Men's Fellowship",
    'Women',
    'Brigade',
    'Elders Session',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and phone are required')));
      return;
    }
    setState(() => _busy = true);
    await ref.read(collectaApiProvider).createMember({
      'fullName': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'group': _group,
    });
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
              Text('Add Member', style: AppType.headlineMd),
              const SizedBox(height: 4),
              Text('New contributors are STK-ready once their Safaricom number '
                  'is saved.',
                  style: AppType.bodyMd.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              _label('Full name'),
              TextField(
                  controller: _name,
                  decoration:
                      const InputDecoration(hintText: 'e.g. Grace Muthoni')),
              const SizedBox(height: AppSpacing.md),
              _label('Phone number'),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '07XX XXX XXX'),
              ),
              const SizedBox(height: AppSpacing.md),
              _label('Email (optional)'),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'member@email.com'),
              ),
              const SizedBox(height: AppSpacing.md),
              _label('Fellowship / group'),
              DropdownButtonFormField<String>(
                initialValue: _group,
                items: [
                  for (final g in _groups)
                    DropdownMenuItem(value: g, child: Text(g)),
                ],
                onChanged: (v) => setState(() => _group = v ?? _group),
              ),
              const SizedBox(height: AppSpacing.lg),
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
                      : const Text('Save Member'),
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
