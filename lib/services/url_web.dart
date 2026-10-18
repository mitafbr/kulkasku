import 'dart:js_interop';

@JS('history.replaceState')
external void _gantiState(JSAny? data, String judul, String url);

/// Menghapus token login Google dari alamat web (bagian setelah #).
void bersihkanUrl() {
  try {
    _gantiState(null, '', Uri.base.replace(fragment: '').toString().replaceAll('#', ''));
  } catch (_) {}
}
