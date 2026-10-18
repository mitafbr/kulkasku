/// Notifikasi pengingat sayur & buah.
///
/// - Android: pengingat_io.dart (flutter_local_notifications, terjadwal walau aplikasi ditutup).
/// - Web    : pengingat_web.dart (notifikasi browser selama tab Kulkasku terbuka).
library;

export 'pengingat_stub.dart'
    if (dart.library.io) 'pengingat_io.dart'
    if (dart.library.js_interop) 'pengingat_web.dart';
