import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/scanner/barcode_scanner_service.dart';
import '../services/scanner/scan_event.dart';

/// The single app-wide keyboard-wedge listener.
///
/// Attached once for the lifetime of the app: its key handler always returns
/// false, so leaving it attached costs nothing and no screen has to remember to
/// hook it up.
final barcodeScannerProvider = Provider<BarcodeScannerService>((ref) {
  final service = BarcodeScannerService()..attach();
  ref.onDispose(service.dispose);
  return service;
});

/// Completed scans. Screens watch this to react to a scan.
final scanStreamProvider = StreamProvider<ScanResult>(
  (ref) => ref.watch(barcodeScannerProvider).scans,
);
