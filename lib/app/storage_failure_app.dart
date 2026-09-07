import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme.dart';

/// Shown instead of the app when the database can't be opened at all.
///
/// This is the one failure the rest of the app has no way to report: every
/// screen, provider and repository is built on an open database, so if
/// `main()` can't get one there is nothing left to show an error inside.
/// Without this the process would run with `runApp` never called — a blank
/// window, no message, nothing for the shop to pass on to whoever installed
/// the kiosk.
class StorageFailureApp extends StatelessWidget {
  const StorageFailureApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeneSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final tokens = AppTokens.of(context);

          return Scaffold(
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 44,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'تعذّر فتح قاعدة بيانات المنتجات.',
                        textAlign: TextAlign.center,
                        style: AppTheme.weighted(
                          theme.textTheme.headlineSmall,
                          FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'أعد تشغيل التطبيق. إذا استمرت المشكلة، أبلغ من ثبّت '
                        'التطبيق وأره التفاصيل التالية.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.muted,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Deliberately the raw error, unlike everywhere else in
                      // the app: there is no AppException to translate it
                      // into here, and this text is for whoever installed the
                      // kiosk rather than for a shop assistant.
                      SelectableText(
                        '$error',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.faint,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
