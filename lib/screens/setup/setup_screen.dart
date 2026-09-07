import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/exceptions.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/labeled_field.dart';

/// Shown once, the first time the app is opened with no admin account yet.
/// There is no default password to ship, so the shop has to set its own here
/// before anything can be managed.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  static const _minPasswordLength = 8;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (username.isEmpty) {
      setState(() => _errorText = 'أدخل اسم المستخدم.');
      return;
    }
    if (password.length < _minPasswordLength) {
      setState(
        () => _errorText =
            'يجب أن تتكوّن كلمة المرور من $_minPasswordLength أحرف على الأقل.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = 'كلمتا المرور غير متطابقتين.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref.read(authServiceProvider).createAdmin(username, password);
      // The router caches this answer; creating the first admin is the one
      // moment in the app's life that changes it.
      ref.invalidate(hasAdminProvider);
      if (!mounted) return;
      ref.read(authSessionProvider.notifier).signIn(username);
      context.go('/inventory');
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Scaffold(
      // Three password fields plus an error line is the tallest form in the
      // app — at the app's own enforced 700px minimum window height, or
      // with a larger OS text-scale setting, that's enough to no longer
      // fit. LayoutBuilder + a min-height ConstrainedBox keeps this
      // centered exactly as before when it fits, and lets it scroll
      // instead of hard-overflowing when it doesn't.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(36, 40, 36, 34),
                  borderRadius: AppRadii.hero,
                  boxShadow: tokens.modalShadow,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tokens.iconBadgeBg,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Icon(
                                Icons.person_add_alt_rounded,
                                size: 24,
                                color: tokens.goldDeep,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'إنشاء حساب المشرف',
                          textAlign: TextAlign.center,
                          style: AppTheme.weighted(
                            theme.textTheme.headlineSmall,
                            FontWeight.w700,
                          ).copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يتم هذا مرة واحدة فقط، عند أول فتح للتطبيق في المتجر.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.muted,
                          ),
                        ),
                        const SizedBox(height: 30),
                        LabeledField(
                          label: 'اسم المستخدم',
                          controller: _usernameController,
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          enabled: !_isSubmitting,
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'كلمة المرور',
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _confirmFocus.requestFocus(),
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'تأكيد كلمة المرور',
                          controller: _confirmController,
                          focusNode: _confirmFocus,
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          enabled: !_isSubmitting,
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        PrimaryActionButton(
                          label: 'إنشاء الحساب',
                          busy: _isSubmitting,
                          fillWidth: true,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
