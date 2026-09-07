import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/settings_providers.dart';
import 'platform.dart';
import 'router.dart';
import 'theme.dart';

class BeneSnapApp extends ConsumerWidget {
  const BeneSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Drives every colour in the app — see AppTheme.forTheme. Always a real,
    // already-resolved value: `homeTextProvider` is seeded synchronously
    // from `initialHomeTextProvider` (see HomeTextNotifier.build), so there
    // is no loading state here to fall back from.
    // `select` so editing the welcome *text* doesn't rebuild MaterialApp —
    // and with it the whole tree — for a theme that hasn't changed.
    final themeKey = ref.watch(homeTextProvider.select((t) => t.themeKey));

    return MaterialApp.router(
      title: 'BeneSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forTheme(themeKey),
      routerConfig: router,
      // Arabic only — there is no locale switcher, so no reason to also
      // support English.  MaterialApp derives the ambient RTL Directionality
      // from this locale automatically; nothing else needs to set it.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _GlobalShortcuts(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// App-wide keyboard shortcuts that need to work from any screen regardless
/// of what currently has focus — registered above the router, once, rather
/// than duplicated per screen.
class _GlobalShortcuts extends StatelessWidget {
  const _GlobalShortcuts({required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  /// Toggles between the kiosk's default full-screen, chrome-less window and
  /// an ordinary resizable one — a customer at the counter should see a
  /// scanner, not a desktop app, but the shop's admin needs a normal window
  /// to actually edit the catalogue. Mirrors the convention browsers and
  /// most native apps already use for "toggle full screen," so it needs no
  /// on-screen hint.
  Future<void> _toggleFullScreen() async {
    if (!isDesktopPlatform) return;
    final isFullScreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullScreen);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.keyD,
          control: true,
          shift: true,
        ): () {
          // Held down, this fires on every repeat — without the check the
          // stack ends up N debug screens deep and needs N escapes back.
          final location = router.state.uri.path;
          if (location == '/debug/scanner') return;
          unawaited(router.pushNamed(Routes.scannerDebug));
        },
        const SingleActivator(LogicalKeyboardKey.f11): () =>
            unawaited(_toggleFullScreen()),
      },
      // An ancestor Focus node catches keys that a focused descendant left
      // unhandled. `autofocus` covers the kiosk screen, where nothing else
      // wants focus; `skipTraversal` keeps it out of the Tab order.
      child: Focus(autofocus: true, skipTraversal: true, child: child),
    );
  }
}
