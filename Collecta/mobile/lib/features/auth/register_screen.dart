import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/collecta_logo.dart';

/// Sign-up flow: provisions a new organization + its first treasurer account,
/// then the auth gate drops the user straight onto the dashboard.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _org = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _org.dispose();
    _email.dispose();
    _phone.dispose();
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            fullName: _name.text.trim(),
            organizationName: _org.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            secret: _pin.text.trim(),
          );
      // On success the router's auth gate redirects to /dashboard.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CollectaWordmark(caption: 'TREASURY & LEDGER ENGINE'),
                const SizedBox(height: AppSpacing.lg),
                Text('Set up your organization', style: AppType.headlineMd),
                const SizedBox(height: 6),
                Text(
                    'Create the treasurer account that manages your group, '
                    "chama or church collections. You'll be signed in right away.",
                    style: AppType.bodyMd
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                _field(
                  label: 'Your full name',
                  controller: _name,
                  hint: 'e.g. Stephen Deron',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                _field(
                  label: 'Organization name',
                  controller: _org,
                  hint: 'e.g. PCEA Kimuchu Church',
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter the organization name'
                      : null,
                ),
                _field(
                  label: 'Work email',
                  controller: _email,
                  hint: 'treasury@org.co.ke',
                  keyboard: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Enter your email';
                    final ok =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                    return ok ? null : 'Enter a valid email';
                  },
                ),
                _field(
                  label: 'Phone number',
                  controller: _phone,
                  hint: '07XX XXX XXX',
                  keyboard: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 9)
                      ? 'Enter a valid phone number'
                      : null,
                ),
                _field(
                  label: 'Security PIN / password',
                  controller: _pin,
                  hint: 'At least 4 characters',
                  obscure: _obscure,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: AppColors.slateMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v == null || v.trim().length < 4)
                      ? 'Use at least 4 characters'
                      : null,
                ),
                _field(
                  label: 'Confirm PIN / password',
                  controller: _confirm,
                  hint: 'Re-enter to confirm',
                  obscure: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  validator: (v) =>
                      (v != _pin.text) ? 'PINs do not match' : null,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1, size: 18),
                              SizedBox(width: 8),
                              Text('Create account & sign in'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Already have an account?',
                          style: AppType.bodyMd
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        child: Text('Sign in',
                            style: AppType.labelLg
                                .copyWith(color: AppColors.emeraldDeep)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.labelMd),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            obscureText: obscure,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}
