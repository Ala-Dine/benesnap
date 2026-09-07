import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../data/models/product.dart';

/// A yes/no dialog whose confirming action is destructive.
///
/// Returns true only if the shop assistant actually confirmed — dismissing
/// the dialog by tapping outside it counts as "no".
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'إلغاء',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: AppTheme.dangerButtonStyle(context),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Deleting a product is reachable from both the inventory grid and the edit
/// form, and a shop assistant should meet identical wording either way.
Future<bool> confirmDeleteProduct(BuildContext context, Product product) {
  return confirmDestructive(
    context,
    title: 'حذف هذا المنتج؟',
    message:
        'سيتم حذف "${product.displayName}" من الكتالوج. '
        'لا يمكن التراجع عن هذا الإجراء.',
    confirmLabel: 'حذف',
  );
}
