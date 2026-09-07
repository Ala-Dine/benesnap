import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/scanner_providers.dart';
import '../../services/scanner/barcode_scanner_service.dart';
import '../../services/scanner/scan_event.dart';

/// Hidden diagnostics screen, reachable with Ctrl+Shift+D.
///
/// Shows raw keystrokes and the gap between them so the shop can compare their
/// scanner's real timings against the configured thresholds and adjust
/// `maxKeyInterval` if their hardware is slower than the 60ms default.
class ScannerDebugScreen extends ConsumerStatefulWidget {
  const ScannerDebugScreen({super.key});

  @override
  ConsumerState<ScannerDebugScreen> createState() => _ScannerDebugScreenState();
}

class _ScannerDebugScreenState extends ConsumerState<ScannerDebugScreen> {
  static const _maxRows = 200;

  final List<KeystrokeSample> _samples = [];
  final List<ScanResult> _scans = [];
  StreamSubscription<KeystrokeSample>? _keySub;
  StreamSubscription<ScanResult>? _scanSub;

  @override
  void initState() {
    super.initState();
    final scanner = ref.read(barcodeScannerProvider);

    _keySub = scanner.keystrokes.listen((sample) {
      if (!mounted) return;
      setState(() {
        _samples.insert(0, sample);
        if (_samples.length > _maxRows) _samples.removeLast();
      });
    });

    _scanSub = scanner.scans.listen((result) {
      if (!mounted) return;
      setState(() {
        _scans.insert(0, result);
        if (_scans.length > 20) _scans.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _keySub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = ref.read(barcodeScannerProvider);
    final theme = Theme.of(context);

    // This diagnostics screen shows raw keystroke timings and stays
    // LTR/monospace regardless of the app's Arabic RTL locale — reading a
    // chronological character-by-character trace right-to-left would defeat
    // its purpose.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scanner diagnostics'),
          leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() {
                _samples.clear();
                _scans.clear();
              }),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ThresholdsCard(scanner: scanner),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _Panel(
                        title: 'Keystrokes (newest first)',
                        child: _samples.isEmpty
                            ? const _Hint(
                                text:
                                    'Scan something, or type, to see timings.',
                              )
                            : ListView.builder(
                                itemCount: _samples.length,
                                itemBuilder: (context, i) => _KeystrokeRow(
                                  sample: _samples[i],
                                  maxKeyInterval: scanner.maxKeyInterval,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _Panel(
                        title: 'Accepted scans',
                        child: _scans.isEmpty
                            ? const _Hint(
                                text: 'No scan has been accepted yet.',
                              )
                            : ListView.builder(
                                itemCount: _scans.length,
                                itemBuilder: (context, i) {
                                  final scan = _scans[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      scan.code,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    subtitle: Text(
                                      '${scan.keystrokes} keys in '
                                      '${scan.duration.inMilliseconds}ms'
                                      '${scan.rawCode == scan.code ? '' : '  •  raw: ${scan.rawCode}'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Buffer: ${scanner.buffer.isEmpty ? '(empty)' : scanner.buffer}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThresholdsCard extends StatelessWidget {
  const _ThresholdsCard({required this.scanner});

  final BarcodeScannerService scanner;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Configured thresholds',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 32,
          runSpacing: 8,
          children: [
            _Stat(
              label: 'Max key interval',
              value: '${scanner.maxKeyInterval.inMilliseconds} ms',
            ),
            _Stat(
              label: 'Stale buffer timeout',
              value: '${scanner.staleBufferTimeout.inMilliseconds} ms',
            ),
            _Stat(label: 'Min code length', value: '${scanner.minCodeLength}'),
            _Stat(label: 'Listening', value: scanner.enabled ? 'yes' : 'no'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _KeystrokeRow extends StatelessWidget {
  const _KeystrokeRow({required this.sample, required this.maxKeyInterval});

  final KeystrokeSample sample;
  final Duration maxKeyInterval;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = sample.gap.inMilliseconds;
    final tooSlow = sample.gap > maxKeyInterval && ms > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(sample.character, style: theme.textTheme.titleSmall),
          ),
          SizedBox(
            width: 90,
            child: Text(
              ms == 0 ? '—' : '$ms ms',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tooSlow ? theme.colorScheme.error : null,
                fontWeight: tooSlow ? FontWeight.w700 : null,
              ),
            ),
          ),
          if (tooSlow)
            Text(
              'gap exceeded the threshold — buffer reset',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: tokens.cardRadius,
        boxShadow: tokens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
