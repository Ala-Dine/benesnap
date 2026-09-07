/// Failures the UI is expected to explain to a shop assistant.
///
/// Every one carries a [message] written in plain language: raw exception
/// strings must never reach the screen.
sealed class AppException implements Exception {
  const AppException();

  String get message;

  @override
  String toString() => message;
}

/// The barcode is already on another product. The scanner looks products up by
/// barcode, so two rows sharing one would make a scan ambiguous.
class DuplicateBarcodeException extends AppException {
  const DuplicateBarcodeException(this.barcode);

  final String barcode;

  @override
  String get message =>
      'الرمز $barcode مستخدم بالفعل في منتج آخر. امسح أو اكتب رمزًا مختلفًا.';
}

/// A product was expected but is no longer there — usually deleted in another
/// window between navigating and loading.
class ProductNotFoundException extends AppException {
  const ProductNotFoundException();

  @override
  String get message => 'هذا المنتج لم يعد موجودًا في الكتالوج.';
}

/// The username is taken.
class DuplicateUsernameException extends AppException {
  const DuplicateUsernameException(this.username);

  final String username;

  @override
  String get message => 'اسم المستخدم "$username" مستخدم بالفعل.';
}

/// A tag label already exists in the same category. Labels are unique per
/// category so the form's chip list never shows a confusing duplicate.
class DuplicateTagException extends AppException {
  const DuplicateTagException(this.label);

  final String label;

  @override
  String get message => 'الوسم "$label" موجود بالفعل في هذه الفئة.';
}

/// A tag was expected but is no longer there — usually deleted in another
/// window between loading the form and saving it.
class TagNotFoundException extends AppException {
  const TagNotFoundException();

  @override
  String get message => 'هذا الوسم لم يعد موجودًا.';
}

/// The signed-in admin's own row is gone — practically unreachable in a
/// single-admin kiosk, but guards the settings screen's credential update
/// against a concurrent deletion instead of failing silently.
class AdminNotFoundException extends AppException {
  const AdminNotFoundException();

  @override
  String get message => 'تعذّر العثور على حساب المشرف الحالي.';
}

/// A picked image couldn't be copied into the app's own `images/` folder —
/// an unreadable file, a full disk, a path that isn't really an image.
class ImageException extends AppException {
  const ImageException(this.cause);

  final Object cause;

  @override
  String get message => 'تعذّر استخدام هذه الصورة. جرّب ملفًا آخر.';
}

/// Anything unexpected from the storage layer. The underlying error is kept in
/// [cause] for logging but never shown.
class StorageException extends AppException {
  const StorageException(this.cause);

  final Object cause;

  @override
  String get message =>
      'تعذّر الوصول إلى قاعدة بيانات المنتجات. أعد المحاولة، '
      'وإذا استمرت المشكلة أعد تشغيل التطبيق.';
}
