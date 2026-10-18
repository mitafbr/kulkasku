import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import 'api_client.dart';
import 'url_stub.dart' if (dart.library.js_interop) 'url_web.dart';

/// Masuk / daftar dengan akun Google lewat Supabase Auth (OAuth).
///
/// - Web : halaman dialihkan ke Google, lalu kembali ke Kulkasku membawa token di alamat web.
/// - APK : Google dibuka di browser, lalu kembali ke aplikasi lewat alamat kulkasku://login-callback.
class GoogleLogin {
  static const skema = 'kulkasku';

  /// Alamat web saat Kulkasku pertama dibuka. Harus dicatat di awal main(),
  /// karena Flutter web langsung mengganti bagian "#..." di alamat (tempat token Google).
  static Uri? _urlAwal;
  static void catatUrlAwal() => _urlAwal = Uri.base;
  static const redirectApk = '$skema://login-callback';

  static void _cekSiap() {
    if (!AppConfig.pakaiSupabase) {
      throw ApiException('Masuk dengan Google aktif setelah Supabase disambungkan (lihat PANDUAN.md bagian 2 & 2b).');
    }
  }

  /// Mulai masuk dengan Google.
  /// Mengembalikan true kalau sesi sudah tersimpan (APK). Di web, halaman akan berpindah ke Google.
  static Future<bool> mulai() async {
    _cekSiap();
    final api = ApiClient.instance;
    if (kIsWeb) {
      final kembali = '${Uri.base.origin}${Uri.base.path}';
      await launchUrl(Uri.parse(api.urlGoogle(kembali)), webOnlyWindowName: '_self');
      return false;
    }
    final String hasil;
    try {
      hasil = await FlutterWebAuth2.authenticate(url: api.urlGoogle(redirectApk), callbackUrlScheme: skema);
    } catch (_) {
      throw ApiException('Masuk dengan Google dibatalkan.');
    }
    await api.sesiDariCallback(Uri.parse(hasil));
    return true;
  }

  /// Web: dipanggil saat Kulkasku dibuka. Kalau alamat web membawa token dari Google, sesi disimpan.
  static Future<bool> tangkapDariUrl() async {
    if (!kIsWeb || !AppConfig.pakaiSupabase) return false;
    final awal = _urlAwal ?? Uri.base;
    _urlAwal = null; // hanya dipakai sekali
    final f = awal.fragment;
    if (!f.contains('access_token') && !f.contains('error')) return false;
    try {
      await ApiClient.instance.sesiDariCallback(awal);
      return true;
    } finally {
      bersihkanUrl();
    }
  }
}
