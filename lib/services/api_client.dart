import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Error yang pesannya sudah ramah untuk ditampilkan ke pengguna.
class ApiException implements Exception {
  final String pesan;
  final int? kode;
  ApiException(this.pesan, [this.kode]);
  @override
  String toString() => pesan;
}

/// Sesi login dari Supabase Auth.
class Sesi {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final DateTime kedaluwarsa;
  Sesi(this.accessToken, this.refreshToken, this.userId, this.kedaluwarsa);

  factory Sesi.fromJson(Map<String, dynamic> j) => Sesi(
        j['access_token'] as String,
        j['refresh_token'] as String,
        (j['user'] as Map)['id'] as String,
        DateTime.now().add(Duration(seconds: (j['expires_in'] as num?)?.toInt() ?? 3600)),
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user': {'id': userId},
        'expires_in': kedaluwarsa.difference(DateTime.now()).inSeconds,
      };
}

/// Klien REST API Supabase memakai package http (materi Pertemuan 6).
///
/// - Auth   : /auth/v1/...
/// - Data   : /rest/v1/<tabel>   (GET, POST, PATCH, DELETE)
/// - Foto   : /storage/v1/object/<bucket>/<path>
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _kunciSesi = 'kulkasku_sesi';
  final String _base = AppConfig.supabaseUrl.endsWith('/')
      ? AppConfig.supabaseUrl.substring(0, AppConfig.supabaseUrl.length - 1)
      : AppConfig.supabaseUrl;
  Sesi? sesi;

  Map<String, String> _header({bool json = true, bool auth = true}) => {
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${auth && sesi != null ? sesi!.accessToken : AppConfig.supabaseAnonKey}',
        if (json) 'Content-Type': 'application/json',
      };

  // ---------------------------------------------------------------- sesi
  Future<void> muatSesi() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kunciSesi);
    if (raw == null) return;
    try {
      sesi = Sesi.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (sesi!.kedaluwarsa.isBefore(DateTime.now().add(const Duration(minutes: 2)))) {
        await perbaruiSesi();
      }
    } catch (_) {
      sesi = null;
      await p.remove(_kunciSesi);
    }
  }

  Future<void> _simpanSesi(Sesi? s) async {
    sesi = s;
    final p = await SharedPreferences.getInstance();
    if (s == null) {
      await p.remove(_kunciSesi);
    } else {
      await p.setString(_kunciSesi, jsonEncode(s.toJson()));
    }
  }

  Future<void> perbaruiSesi() async {
    final s = sesi;
    if (s == null) return;
    final res = await http.post(
      Uri.parse('$_base/auth/v1/token?grant_type=refresh_token'),
      headers: _header(auth: false),
      body: jsonEncode({'refresh_token': s.refreshToken}),
    );
    if (res.statusCode == 200) {
      await _simpanSesi(Sesi.fromJson(jsonDecode(res.body) as Map<String, dynamic>));
    } else {
      await _simpanSesi(null);
      throw ApiException('Sesi berakhir, silakan masuk lagi.', res.statusCode);
    }
  }

  // ---------------------------------------------------------------- auth
  Future<Sesi> masukEmail(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/v1/token?grant_type=password'),
      headers: _header(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) throw ApiException(_pesanAuth(res), res.statusCode);
    final s = Sesi.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    await _simpanSesi(s);
    return s;
  }

  /// Daftar akun baru. Data profil dikirim sebagai metadata; trigger di database
  /// otomatis membuat baris di tabel "profil".
  Future<void> daftar({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/v1/signup'),
      headers: _header(auth: false),
      body: jsonEncode({'email': email, 'password': password, 'data': metadata}),
    );
    if (res.statusCode != 200) throw ApiException(_pesanAuth(res), res.statusCode);
  }

  // ---------------------------------------------------------------- Google (OAuth)
  /// Alamat halaman login Google milik Supabase.
  String urlGoogle(String kembaliKe) =>
      '$_base/auth/v1/authorize?provider=google&redirect_to=${Uri.encodeComponent(kembaliKe)}';

  /// Membaca token dari alamat balik setelah login Google, lalu menyimpan sesi.
  Future<Sesi> sesiDariCallback(Uri u) async {
    final teks = u.fragment.isNotEmpty ? u.fragment : u.query;
    final p = Uri.splitQueryString(teks);
    if (p['error'] != null || p['error_description'] != null) {
      throw ApiException('Masuk dengan Google gagal: ${p['error_description'] ?? p['error']}');
    }
    final at = p['access_token'];
    final rt = p['refresh_token'];
    if (at == null || rt == null) throw ApiException('Masuk dengan Google dibatalkan.');
    final res = await http.get(
      Uri.parse('$_base/auth/v1/user'),
      headers: {'apikey': AppConfig.supabaseAnonKey, 'Authorization': 'Bearer $at'},
    );
    if (res.statusCode != 200) throw ApiException('Masuk dengan Google gagal. Coba lagi.', res.statusCode);
    final id = (jsonDecode(res.body) as Map<String, dynamic>)['id'] as String;
    final detik = int.tryParse(p['expires_in'] ?? '') ?? 3600;
    final s = Sesi(at, rt, id, DateTime.now().add(Duration(seconds: detik)));
    await _simpanSesi(s);
    return s;
  }

  Future<void> keluar() async {
    if (sesi != null) {
      try {
        await http.post(Uri.parse('$_base/auth/v1/logout'), headers: _header());
      } catch (_) {}
    }
    await _simpanSesi(null);
  }

  String _pesanAuth(http.Response res) {
    String raw = '';
    try {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      raw = (j['msg'] ?? j['error_description'] ?? j['message'] ?? j['error'] ?? '').toString();
    } catch (_) {}
    final m = raw.toLowerCase();
    if (m.contains('invalid login')) return 'Username/email atau kata sandi salah.';
    if (m.contains('email not confirmed')) return 'Email belum dikonfirmasi. Cek kotak masuk email kamu.';
    if (m.contains('already registered') || m.contains('already exists')) return 'Email ini sudah terdaftar.';
    if (m.contains('password')) return 'Kata sandi minimal 6 karakter.';
    if (m.contains('rate limit')) return 'Terlalu banyak percobaan. Tunggu sebentar, ya.';
    return raw.isEmpty ? 'Gagal terhubung ke server (${res.statusCode}).' : raw;
  }

  // ---------------------------------------------------------------- REST
  Future<http.Response> _kirim(Future<http.Response> Function() aksi) async {
    if (sesi != null && sesi!.kedaluwarsa.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      await perbaruiSesi();
    }
    var res = await aksi();
    if (res.statusCode == 401 && sesi != null) {
      await perbaruiSesi();
      res = await aksi();
    }
    if (res.statusCode >= 400) {
      String pesan = 'Server error (${res.statusCode}).';
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['message'] != null) pesan = j['message'].toString();
      } catch (_) {}
      throw ApiException(pesan, res.statusCode);
    }
    return res;
  }

  /// GET /rest/v1/<tabel>?<query>
  Future<List<Map<String, dynamic>>> get(String tabel, {String query = 'select=*'}) async {
    final res = await _kirim(() => http.get(Uri.parse('$_base/rest/v1/$tabel?$query'), headers: _header()));
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// POST /rest/v1/<tabel>  -> baris yang baru dibuat
  Future<Map<String, dynamic>> post(String tabel, Map<String, dynamic> body) async {
    final res = await _kirim(() => http.post(
          Uri.parse('$_base/rest/v1/$tabel'),
          headers: {..._header(), 'Prefer': 'return=representation'},
          body: jsonEncode(body),
        ));
    return Map<String, dynamic>.from((jsonDecode(res.body) as List).first as Map);
  }

  /// PATCH /rest/v1/<tabel>?id=eq.<id>
  Future<Map<String, dynamic>?> patch(String tabel, String id, Map<String, dynamic> body) async {
    final res = await _kirim(() => http.patch(
          Uri.parse('$_base/rest/v1/$tabel?id=eq.$id'),
          headers: {..._header(), 'Prefer': 'return=representation'},
          body: jsonEncode(body),
        ));
    final list = jsonDecode(res.body) as List;
    return list.isEmpty ? null : Map<String, dynamic>.from(list.first as Map);
  }

  /// DELETE /rest/v1/<tabel>?id=eq.<id>
  Future<void> delete(String tabel, String id) async {
    await _kirim(() => http.delete(Uri.parse('$_base/rest/v1/$tabel?id=eq.$id'), headers: _header()));
  }

  /// Memanggil fungsi database: POST /rest/v1/rpc/<nama>
  Future<dynamic> rpc(String nama, Map<String, dynamic> body) async {
    final res = await _kirim(() => http.post(
          Uri.parse('$_base/rest/v1/rpc/$nama'),
          headers: _header(),
          body: jsonEncode(body),
        ));
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  /// Hapus satu file foto di Storage (dipakai saat hapus akun).
  Future<void> hapusFoto(String urlPublik) async {
    const penanda = '/object/public/';
    final i = urlPublik.indexOf(penanda);
    if (i < 0) return;
    final path = urlPublik.substring(i + penanda.length); // avatar/<uid>/<file>.jpg
    try {
      await _kirim(() => http.delete(Uri.parse('$_base/storage/v1/object/$path'), headers: _header()));
    } catch (_) {}
  }

  /// Upload foto profil ke Storage, mengembalikan URL publiknya.
  Future<String> unggahFoto(String path, Uint8List bytes) async {
    final url = '$_base/storage/v1/object/${AppConfig.bucketFoto}/$path';
    await _kirim(() => http.post(
          Uri.parse(url),
          headers: {..._header(json: false), 'Content-Type': 'image/jpeg', 'x-upsert': 'true'},
          body: bytes,
        ));
    return '$_base/storage/v1/object/public/${AppConfig.bucketFoto}/$path';
  }
}
