import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import '../screens/debug/scanner_debug_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/product_detail/product_detail_screen.dart';
import '../screens/product_form/product_form_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/setup/setup_screen.dart';

abstract final class Routes {
  static const home = 'home';
  static const login = 'login';
  static const setup = 'setup';
  static const productDetail = 'productDetail';
  static const inventory = 'inventory';
  static const productNew = 'productNew';
  static const productEdit = 'productEdit';
  static const settings = 'settings';
  static const scannerDebug = 'scannerDebug';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) async {
      final isAdmin = ref.read(isAdminProvider);
      final location = state.matchedLocation;

      if (_isAdminRoute(location) && !isAdmin) return '/login';
      if (location == '/login' && isAdmin) return '/inventory';

      // No admin exists yet: the login screen isn't useful until one does,
      // and vice versa once it does.
      if (location == '/login' || location == '/setup') {
        final hasAdmin = !(await ref.read(adminRepositoryProvider).isEmpty());
        if (!hasAdmin && location == '/login') return '/setup';
        if (hasAdmin && location == '/setup') return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: Routes.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        name: Routes.productDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  "That link isn't valid.",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            );
          }
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/inventory',
        name: Routes.inventory,
        builder: (context, state) => const InventoryScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: Routes.productNew,
            builder: (context, state) =>
                ProductFormScreen(initialBarcode: state.extra as String?),
          ),
          GoRoute(
            path: ':id/edit',
            name: Routes.productEdit,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      "That link isn't valid.",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                );
              }
              return ProductFormScreen(productId: id);
            },
          ),
          GoRoute(
            path: 'settings',
            name: Routes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Hidden: reachable only via Ctrl+Shift+D. Lets the shop tune the
      // scanner timing thresholds against their actual hardware.
      GoRoute(
        path: '/debug/scanner',
        name: Routes.scannerDebug,
        builder: (context, state) => const ScannerDebugScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          "That screen doesn't exist.",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ),
  );
});

bool _isAdminRoute(String location) => location.startsWith('/inventory');

/// Bridges Riverpod auth changes into the [Listenable] go_router expects, so
/// signing in or out re-runs the redirect immediately.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    _subscription = ref.listen<bool>(
      isAdminProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<bool> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
