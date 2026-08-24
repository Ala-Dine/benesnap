import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';

class BeneSnapApp extends ConsumerWidget {
  const BeneSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BeneSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
      builder: (context, child) => _DebugShortcut(
        router: router,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Ctrl+Shift+D opens the hidden scanner diagnostics screen.
///
/// Registered above the router so it works from any screen, and deliberately
/// undocumented in the UI — it is a tuning aid for whoever installs the
/// scanner, not a feature for shop staff.
class _DebugShortcut extends StatelessWidget {
  const _DebugShortcut({required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.keyD,
          control: true,
          shift: true,
        ): () =>
            unawaited(router.pushNamed(Routes.scannerDebug)),
      },
      // An ancestor Focus node catches keys that a focused descendant left
      // unhandled. `autofocus` covers the kiosk screen, where nothing else
      // wants focus; `skipTraversal` keeps it out of the Tab order.
      child: Focus(autofocus: true, skipTraversal: true, child: child),
    );
  }
}
