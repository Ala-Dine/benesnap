import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/exceptions.dart';
import '../../data/models/home_text.dart';
import '../../data/models/home_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import '../../services/auth_service.dart';
import '../../widgets/labeled_field.dart';

/// Admin-only: customize the kiosk's homepage text and update the signed-in
/// admin's own username/password.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _maxTitleChars = 42;
  static const _minPasswordLength = 8;

  final _welcomeTitleController = TextEditingController();
  final _extraLineController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  HomeThemeKey _selectedTheme = defaultHomeThemeKey;

  bool _isSavingHomeText = false;
  bool _homeTextSaved = false;
  String? _homeTextError;

  bool _isUpdatingCredentials = false;
  bool _credentialsSuccess = false;
  String? _credentialsError;

  @override
  void initState() {
    super.initState();
    _usernameController.text = ref.read(authSessionProvider) ?? '';
    _loadHomeText();
  }

  @override
  void dispose() {
    _welcomeTitleController.dispose();
    _extraLineController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeText() async {
    try {
      final raw = await ref.read(settingsRepositoryProvider).rawHomeText();
      if (!mounted) return;
      setState(() {
        _welcomeTitleController.text = raw?.welcomeTitle ?? '';
        _extraLineController.text = raw?.extraLine ?? '';
        _selectedTheme = raw?.themeKey ?? defaultHomeThemeKey;
      });
    } on AppException {
      // The fields just stay empty; saving still works from a blank slate.
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inventory');
    }
  }

  // Also the live preview and character counter's rebuild trigger — both
  // read the controllers directly rather than through a Listenable, so
  // every keystroke needs a setState regardless of whether the "saved" flag
  // was actually set.
  void _handleHomeTextChanged(String _) =>
      setState(() => _homeTextSaved = false);

  // Same setState requirement as _handleHomeTextChanged: the counter and
  // live preview read the controller directly, and setting .text
  // programmatically doesn't reliably fire TextField's onChanged.
  void _resetWelcomeTitleToDefault() {
    setState(() {
      _welcomeTitleController.text = defaultWelcomeTitle;
      _homeTextSaved = false;
    });
  }

  void _selectTheme(HomeThemeKey theme) {
    if (theme == _selectedTheme) return;
    setState(() {
      _selectedTheme = theme;
      _homeTextSaved = false;
    });
  }

  Future<void> _saveHomeText() async {
    if (_isSavingHomeText) return;

    setState(() {
      _isSavingHomeText = true;
      _homeTextError = null;
    });

    try {
      await ref
          .read(settingsRepositoryProvider)
          .updateHomeText(
            welcomeTitle: _welcomeTitleController.text,
            extraLine: _extraLineController.text,
            themeKey: _selectedTheme,
          );
      if (!mounted) return;
      setState(() {
        _isSavingHomeText = false;
        _homeTextSaved = true;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingHomeText = false;
        _homeTextError = e.message;
      });
    }
  }

  void _clearCredentialsStatus() {
    if (_credentialsSuccess || _credentialsError != null) {
      setState(() {
        _credentialsSuccess = false;
        _credentialsError = null;
      });
    }
  }

  Future<void> _updateCredentials() async {
    if (_isUpdatingCredentials) return;

    final newUsername = _usernameController.text.trim();
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newUsername.isEmpty) {
      setState(() => _credentialsError = 'أدخل اسم المستخدم.');
      return;
    }

    final changingPassword =
        newPassword.isNotEmpty || confirmPassword.isNotEmpty;
    if (changingPassword) {
      if (newPassword != confirmPassword) {
        setState(() => _credentialsError = 'كلمتا المرور غير متطابقتين.');
        return;
      }
      if (newPassword.length < _minPasswordLength) {
        setState(
          () => _credentialsError =
              'يجب أن تتكوّن كلمة المرور من $_minPasswordLength أحرف على الأقل.',
        );
        return;
      }
      if (currentPassword.isEmpty) {
        setState(
          () => _credentialsError = 'أدخل كلمة المرور الحالية لتغييرها.',
        );
        return;
      }
    }

    final currentUsername = ref.read(authSessionProvider);
    if (currentUsername == null) return; // unreachable: screen is admin-only

    setState(() {
      _isUpdatingCredentials = true;
      _credentialsError = null;
      _credentialsSuccess = false;
    });

    try {
      final failure = await ref
          .read(authServiceProvider)
          .updateCredentials(
            currentUsername: currentUsername,
            newUsername: newUsername,
            currentPassword: changingPassword ? currentPassword : null,
            newPassword: changingPassword ? newPassword : null,
          );

      if (!mounted) return;

      if (failure != null) {
        setState(() {
          _isUpdatingCredentials = false;
          _credentialsError = failure.reason == LoginFailureReason.lockedOut
              ? 'محاولات كثيرة جدًا. حاول مرة أخرى بعد '
                    '${failure.lockoutRemaining!.inSeconds} ثانية.'
              : 'كلمة المرور الحالية غير صحيحة.';
        });
        return;
      }

      // The username may have just changed — keep the session (and its
      // lockout bookkeeping) pointed at the account that now exists.
      ref.read(authSessionProvider.notifier).signIn(newUsername);

      setState(() {
        _isUpdatingCredentials = false;
        _credentialsSuccess = true;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingCredentials = false;
        _credentialsError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.formCanvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 22, 40, 22),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tokens.imagePanelBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.shadowColor.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      iconSize: 18,
                      tooltip: 'رجوع',
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        fixedSize: const Size(40, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإعدادات',
                        style: AppTheme.weighted(
                          theme.textTheme.headlineSmall,
                          FontWeight.w700,
                        ).copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'خصص نصوص الصفحة الرئيسية وبيانات دخول المدير.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
                child: Align(
                  alignment: Alignment.topCenter,
                  // The cards' content is shorter than the space available
                  // at most window sizes; stretching them to fill it left a
                  // dead empty strip at the bottom of each card.
                  // IntrinsicHeight sizes both to the taller card's natural
                  // content height instead, so they still match each other
                  // without padding out to the full remaining height.
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildHomeTextCard(context)),
                        const SizedBox(width: 26),
                        Expanded(child: _buildAdminAccountCard(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTextCard(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return _SettingsCard(
      // Scrollable rather than relying on a fixed card height: at a small
      // window size there isn't always room for every field plus the
      // preview plus the button, and a RenderFlex overflow is worse than a
      // scrollbar.
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(
              icon: Icons.auto_awesome_rounded,
              title: 'الصفحة الرئيسية',
              caption: 'النص الذي يراه الزبون عند فتح التطبيق.',
            ),
            LabeledField(
              label: 'عنوان الترحيب',
              controller: _welcomeTitleController,
              hintText: defaultWelcomeTitle,
              maxLength: _maxTitleChars,
              onChanged: _handleHomeTextChanged,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_welcomeTitleController.text.length} / $_maxTitleChars حرفًا',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.faint,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetWelcomeTitleToDefault,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'استعادة النص الافتراضي',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.goldDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'سطر إضافي (اختياري)',
              controller: _extraLineController,
              hintText: 'مثال: جودة عالية وأسعار تنافسية كل يوم',
              onChanged: _handleHomeTextChanged,
            ),
            const SizedBox(height: 16),
            Text(
              'لون التطبيق',
              style: AppTheme.weighted(
                theme.textTheme.bodyMedium,
                FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final key in HomeThemeKey.values) ...[
                  _ThemeSwatch(
                    themeKey: key,
                    selected: key == _selectedTheme,
                    onTap: () => _selectTheme(key),
                  ),
                  if (key != HomeThemeKey.values.last)
                    const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 100),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                color: _selectedTheme.bg,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _welcomeTitleController.text.trim().isEmpty
                        ? defaultWelcomeTitle
                        : _welcomeTitleController.text,
                    textAlign: TextAlign.center,
                    style:
                        AppTheme.weighted(
                          theme.textTheme.titleLarge,
                          FontWeight.w700,
                        ).copyWith(
                          fontSize: 24,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Color(0x47785A23),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                  ),
                  if (_extraLineController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _extraLineController.text.trim(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _selectedTheme.subtitle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSavingHomeText ? null : _saveHomeText,
              style: AppTheme.darkButtonStyle(
                context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
              ),
              child: _isSavingHomeText
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Text('حفظ نصوص الصفحة'),
            ),
            if (_homeTextError != null) ...[
              const SizedBox(height: 12),
              _StatusPill(message: _homeTextError!, isError: true),
            ] else if (_homeTextSaved) ...[
              const SizedBox(height: 12),
              const _StatusPill(
                message: 'تم حفظ نصوص الصفحة بنجاح.',
                isError: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAccountCard(BuildContext context) {
    return _SettingsCard(
      // Scrollable for the same reason as the homepage-text card: a fixed
      // "pinned to the bottom" footer needs a bounded card height, and this
      // card's content doesn't always fit one at a small window size.
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(
              icon: Icons.lock_outline_rounded,
              title: 'حساب المدير',
              caption: 'بيانات الدخول إلى لوحة المخزون.',
            ),
            LabeledField(
              label: 'اسم المستخدم',
              controller: _usernameController,
              onChanged: (_) => _clearCredentialsStatus(),
            ),
            const SizedBox(height: 16),
            Divider(color: AppTokens.of(context).divider, height: 1),
            const SizedBox(height: 16),
            Text(
              'اترك الحقول التالية فارغة إذا لم ترغب بتغيير كلمة المرور.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTokens.of(context).muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'كلمة المرور الحالية',
              controller: _currentPasswordController,
              obscureText: true,
              onChanged: (_) => _clearCredentialsStatus(),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'كلمة المرور الجديدة',
                    controller: _newPasswordController,
                    obscureText: true,
                    onChanged: (_) => _clearCredentialsStatus(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LabeledField(
                    label: 'تأكيد كلمة المرور',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    onChanged: (_) => _clearCredentialsStatus(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_credentialsError != null) ...[
              _StatusPill(message: _credentialsError!, isError: true),
              const SizedBox(height: 16),
            ] else if (_credentialsSuccess) ...[
              const _StatusPill(
                message: 'تم تحديث بيانات الدخول بنجاح.',
                isError: false,
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isUpdatingCredentials ? null : _updateCredentials,
              style: AppTheme.darkButtonStyle(
                context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
              ),
              child: _isUpdatingCredentials
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Text('تحديث بيانات الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

/// One colour-theme choice: a solid-fill circle, ringed and checked when
/// selected. The check icon uses the theme's own [HomeThemeKey.title]
/// colour rather than a fixed black/white, since that's already tuned for
/// contrast against that theme's [HomeThemeKey.bg].
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.themeKey,
    required this.selected,
    required this.onTap,
  });

  final HomeThemeKey themeKey;
  final bool selected;
  final VoidCallback onTap;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: themeKey.name,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: themeKey.bg,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: theme.colorScheme.onSurface, width: 2)
                : null,
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 18, color: themeKey.title)
              : null,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: tokens.imagePanelBorder),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.iconBadgeBg,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, size: 18, color: tokens.goldDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.weighted(
                    theme.textTheme.titleMedium,
                    FontWeight.w700,
                  ).copyWith(fontSize: 18),
                ),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.muted,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? tokens.dangerBg : tokens.successBg,
        border: Border.all(
          color: isError ? tokens.dangerBorder : tokens.successBorder,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError ? theme.colorScheme.error : tokens.successFg,
          height: 1.4,
        ),
      ),
    );
  }
}
