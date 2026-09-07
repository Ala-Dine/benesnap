import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../providers/auth_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/labeled_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  String? _errorText;

  /// The live lockout countdown. A ValueNotifier rather than plain state
  /// because it changes once a second and only one Text reads it: a
  /// setState per tick rebuilt both fields and repainted the card's 56px
  /// blur shadow to change a single number.
  final _lockoutRemaining = ValueNotifier<Duration?>(null);
  bool _isSubmitting = false;
  Timer? _lockoutTicker;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _lockoutTicker?.cancel();
    _lockoutRemaining.dispose();
    super.dispose();
  }

  bool get _isLocked => _lockoutRemaining.value != null;

  String? _displayError(Duration? lockoutRemaining) {
    if (lockoutRemaining != null) {
      return 'محاولات كثيرة جدًا. حاول مرة أخرى بعد '
          '${lockoutRemaining.inSeconds} ثانية.';
    }
    return _errorText;
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isLocked) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'أدخل اسم المستخدم وكلمة المرور.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final failure = await ref
        .read(authServiceProvider)
        .login(username, password);
    if (!mounted) return;

    if (failure == null) {
      ref.read(authSessionProvider.notifier).signIn(username);
      setState(() => _isSubmitting = false);
      context.go('/inventory');
      return;
    }

    setState(() => _isSubmitting = false);

    if (failure.reason == LoginFailureReason.lockedOut) {
      _startLockoutCountdown(failure.lockoutRemaining!);
    } else {
      setState(() => _errorText = 'اسم المستخدم أو كلمة المرور غير صحيحة.');
    }
  }

  void _startLockoutCountdown(Duration remaining) {
    _lockoutTicker?.cancel();
    // Entering and leaving the lockout disable and re-enable the fields and
    // the submit button, so those two transitions do need a full rebuild.
    // The seconds in between don't: they only change the message.
    setState(() => _lockoutRemaining.value = remaining);

    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next =
          (_lockoutRemaining.value ?? Duration.zero) -
          const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        setState(() => _lockoutRemaining.value = null);
      } else {
        _lockoutRemaining.value = next;
      }
    });
  }

  void _goBack() => context.popOr('/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final fieldsEnabled = !_isSubmitting && !_isLocked;

    return Scaffold(
      // A lockout message adds a line of text on top of the two fields —
      // at the app's own enforced 700px minimum window height, or with a
      // larger OS text-scale setting, that's enough to no longer fit.
      // LayoutBuilder + a min-height ConstrainedBox keeps this centered
      // exactly as before when it fits, and lets it scroll instead of
      // hard-overflowing when it doesn't.
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
                    constraints: const BoxConstraints(maxWidth: 400),
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
                                Icons.lock_outline_rounded,
                                size: 24,
                                color: tokens.goldDeep,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'تسجيل الدخول',
                          textAlign: TextAlign.center,
                          style: AppTheme.weighted(
                            theme.textTheme.headlineSmall,
                            FontWeight.w700,
                          ).copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'سجّل الدخول لإدارة المتجر.',
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
                          enabled: fieldsEnabled,
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'كلمة المرور',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          focusNode: _passwordFocus,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          enabled: fieldsEnabled,
                        ),
                        ValueListenableBuilder<Duration?>(
                          valueListenable: _lockoutRemaining,
                          builder: (context, remaining, _) {
                            final error = _displayError(remaining);
                            if (error == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                error,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryActionButton(
                            label: 'تسجيل الدخول',
                            busy: _isSubmitting,
                            onPressed: fieldsEnabled ? _submit : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _isSubmitting ? null : _goBack,
                            style: TextButton.styleFrom(
                              foregroundColor: tokens.muted,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('رجوع'),
                          ),
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
