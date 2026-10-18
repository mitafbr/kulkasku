import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/katalog.dart';
import '../data/models.dart';
import 'api_client.dart';

/// Kontrak penyimpanan data. Ada dua isi:
///  - [SupabaseRepo] : data disimpan online lewat REST API Supabase.
///  - [LokalRepo]    : data disimpan di HP/browser (kalau Supabase belum diisi).
abstract class KulkasRepo {
  static KulkasRepo buat() => AppConfig.pakaiSupabase ? SupabaseRepo() : LokalRepo();

  bool get online;

  /// Materi Pertemuan 6: GET data katalog dari API, lalu fromJson.
  Future<List<SayurInfo>> ambilKatalog();

  Future<Profil?> sesiTersimpan();
  Future<Profil> masuk(String usernameAtauEmail, String password);
  Future<void> daftar({
    required String nama,
    required String username,
    required String email,
    required String hp,
    required String password,
  });
  Future<void> keluar();
  Future<void> hapusAkun();

  Future<Profil> simpanProfil(Profil p);
  Future<String> unggahFoto(String userId, Uint8List bytes);

  Future<List<Bahan>> ambilBahan();
  Future<Bahan> tambahBahan(Bahan b);
  Future<Bahan> ubahBahan(Bahan b);
  Future<void> hapusBahan(String id);

  Future<List<Riwayat>> ambilRiwayat();
  Future<Riwayat> tambahRiwayat(Riwayat r);
}

Future<List<SayurInfo>> _katalogAsset() async {
  final raw = await rootBundle.loadString('assets/data/katalog.json');
  final list = jsonDecode(raw) as List;
  return list.map((e) => SayurInfo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
}

// =====================================================================
//  SUPABASE (online)
// =====================================================================
class SupabaseRepo implements KulkasRepo {
  final ApiClient api = ApiClient.instance;

  @override
  bool get online => true;

  String get _uid {
    final s = api.sesi;
    if (s == null) throw ApiException('Kamu belum masuk.');
    return s.userId;
  }

  @override
  Future<List<SayurInfo>> ambilKatalog() async {
    try {
      final rows = await api.get('katalog', query: 'select=*&order=urutan.asc');
      final bawaan = await _katalogAsset();
      if (rows.isEmpty) return bawaan;
      // Gabungkan: data server dipakai, bahan yang belum ada di server
      // (misalnya bahan baru) diambil dari katalog bawaan aplikasi.
      final server = rows.map(SayurInfo.fromJson).toList();
      final adaDiServer = server.map((e) => e.id).toSet();
      return [...server, ...bawaan.where((e) => !adaDiServer.contains(e.id))];
    } catch (_) {
      // Server tidak bisa dihubungi: pakai katalog bawaan aplikasi.
      return _katalogAsset();
    }
  }

  Future<Profil> _profil() async {
    final rows = await api.get('profil', query: 'select=*&id=eq.$_uid');
    if (rows.isEmpty) throw ApiException('Profil tidak ditemukan.');
    return Profil.fromJson(rows.first);
  }

  @override
  Future<Profil?> sesiTersimpan() async {
    await api.muatSesi();
    if (api.sesi == null) return null;
    try {
      return await _profil();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Profil> masuk(String usernameAtauEmail, String password) async {
    var email = usernameAtauEmail.trim();
    if (!email.contains('@')) {
      final hasil = await api.rpc('email_by_username', {'uname': email.toLowerCase()});
      if (hasil == null || hasil.toString().isEmpty) {
        throw ApiException('Username tidak ditemukan.');
      }
      email = hasil.toString();
    }
    await api.masukEmail(email, password);
    return _profil();
  }

  @override
  Future<void> daftar({
    required String nama,
    required String username,
    required String email,
    required String hp,
    required String password,
  }) async {
    final ada = await api.rpc('username_dipakai', {'uname': username});
    if (ada == true) throw ApiException('Username sudah dipakai, coba yang lain.');
    await api.daftar(
      email: email,
      password: password,
      metadata: {'nama': nama, 'username': username, 'hp': hp},
    );
  }

  @override
  Future<void> keluar() => api.keluar();

  @override
  Future<void> hapusAkun() async {
    try {
      final p = await _profil();
      final f = p.foto;
      if (f != null && f.startsWith('http')) await api.hapusFoto(f);
    } catch (_) {}
    await api.rpc('hapus_akun', {});
    await api.keluar();
  }

  @override
  Future<Profil> simpanProfil(Profil p) async {
    final body = p.toJson()..remove('id');
    final row = await api.patch('profil', p.id, body);
    return row == null ? p : Profil.fromJson(row);
  }

  @override
  Future<String> unggahFoto(String userId, Uint8List bytes) =>
      api.unggahFoto('$userId/${DateTime.now().millisecondsSinceEpoch}.jpg', bytes);

  @override
  Future<List<Bahan>> ambilBahan() async {
    final rows = await api.get('bahan', query: 'select=*&order=beli.asc');
    return rows.map(Bahan.fromJson).toList();
  }

  @override
  Future<Bahan> tambahBahan(Bahan b) async => Bahan.fromJson(await api.post('bahan', b.toJson(denganId: false)));

  @override
  Future<Bahan> ubahBahan(Bahan b) async {
    final row = await api.patch('bahan', b.id, b.toJson(denganId: false));
    return row == null ? b : Bahan.fromJson(row);
  }

  @override
  Future<void> hapusBahan(String id) => api.delete('bahan', id);

  @override
  Future<List<Riwayat>> ambilRiwayat() async {
    final rows = await api.get('riwayat', query: 'select=*&order=waktu.desc&limit=200');
    return rows.map(Riwayat.fromJson).toList();
  }

  @override
  Future<Riwayat> tambahRiwayat(Riwayat r) async =>
      Riwayat.fromJson(await api.post('riwayat', r.toJson(denganId: false)));
}

// =====================================================================
//  LOKAL (tanpa server) — data di SharedPreferences
// =====================================================================
class LokalRepo implements KulkasRepo {
  static const _kunci = 'kulkasku_lokal_v2';
  Map<String, dynamic> _db = {};
  String? _aktif;

  @override
  bool get online => false;

  String _id() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<void> _muat() async {
    if (_db.isNotEmpty) return;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kunci);
    if (raw != null) {
      _db = jsonDecode(raw) as Map<String, dynamic>;
    } else {
      // Mulai kosong: tidak ada akun bawaan. Setiap orang (termasuk pembuat) Daftar sendiri.
      _db = {'akun': <dynamic>[], 'data': <String, dynamic>{}, 'aktif': null};
      await _tulis();
    }
    _aktif = _db['aktif'] as String?;
  }

  Future<void> _tulis() async {
    _db['aktif'] = _aktif;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kunci, jsonEncode(_db));
  }

  List<dynamic> get _akun => _db['akun'] as List<dynamic>;
  Map<String, dynamic> get _data => _db['data'] as Map<String, dynamic>;

  Map<String, dynamic> _milik(String uid) =>
      (_data[uid] ??= <String, dynamic>{'bahan': <dynamic>[], 'riwayat': <dynamic>[]}) as Map<String, dynamic>;

  String get _uid {
    final a = _aktif;
    if (a == null) throw ApiException('Kamu belum masuk.');
    return a;
  }

  Map<String, dynamic>? _cariAkun(String userAtauEmail) {
    final q = userAtauEmail.trim().toLowerCase();
    for (final a in _akun) {
      final m = a as Map<String, dynamic>;
      if (m['username'] == q || (m['email'] as String).toLowerCase() == q) return m;
    }
    return null;
  }

  @override
  Future<List<SayurInfo>> ambilKatalog() async {
    // Disimulasikan seperti API: menunggu sebentar, lalu fromJson.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _katalogAsset();
  }

  @override
  Future<Profil?> sesiTersimpan() async {
    await _muat();
    final a = _aktif;
    if (a == null) return null;
    for (final x in _akun) {
      final m = x as Map<String, dynamic>;
      if (m['id'] == a) return Profil.fromJson(m);
    }
    return null;
  }

  @override
  Future<Profil> masuk(String usernameAtauEmail, String password) async {
    await _muat();
    final a = _cariAkun(usernameAtauEmail);
    if (a == null || a['password'] != password) {
      throw ApiException('Username/email atau kata sandi salah. Belum punya akun? Daftar dulu ya.');
    }
    _aktif = a['id'] as String;
    await _tulis();
    return Profil.fromJson(a);
  }

  @override
  Future<void> daftar({
    required String nama,
    required String username,
    required String email,
    required String hp,
    required String password,
  }) async {
    await _muat();
    if (_cariAkun(username) != null) throw ApiException('Username sudah dipakai, coba yang lain.');
    if (_cariAkun(email) != null) throw ApiException('Email ini sudah terdaftar.');
    final p = Profil(id: 'u-${_id()}', username: username, nama: nama, email: email, hp: hp);
    _akun.add({...p.toJson(), 'password': password});
    _milik(p.id);
    await _tulis();
  }

  @override
  Future<void> keluar() async {
    await _muat();
    _aktif = null;
    await _tulis();
  }

  @override
  Future<void> hapusAkun() async {
    final uid = _uid;
    _akun.removeWhere((a) => (a as Map)['id'] == uid);
    _data.remove(uid);
    _aktif = null;
    await _tulis();
  }

  @override
  Future<Profil> simpanProfil(Profil p) async {
    await _muat();
    for (var i = 0; i < _akun.length; i++) {
      final m = _akun[i] as Map<String, dynamic>;
      if (m['id'] == p.id) {
        _akun[i] = {...p.toJson(), 'password': m['password']};
      }
    }
    await _tulis();
    return p;
  }

  @override
  Future<String> unggahFoto(String userId, Uint8List bytes) async =>
      'data:image/jpeg;base64,${base64Encode(bytes)}';

  @override
  Future<List<Bahan>> ambilBahan() async {
    await _muat();
    final list = _milik(_uid)['bahan'] as List<dynamic>;
    return list.map((e) => Bahan.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<Bahan> tambahBahan(Bahan b) async {
    final baru = Bahan.fromJson({...b.toJson(), 'id': _id()});
    (_milik(_uid)['bahan'] as List<dynamic>).add(baru.toJson());
    await _tulis();
    return baru;
  }

  @override
  Future<Bahan> ubahBahan(Bahan b) async {
    final list = _milik(_uid)['bahan'] as List<dynamic>;
    final i = list.indexWhere((e) => (e as Map)['id'] == b.id);
    if (i >= 0) list[i] = b.toJson();
    await _tulis();
    return b;
  }

  @override
  Future<void> hapusBahan(String id) async {
    (_milik(_uid)['bahan'] as List<dynamic>).removeWhere((e) => (e as Map)['id'] == id);
    await _tulis();
  }

  @override
  Future<List<Riwayat>> ambilRiwayat() async {
    await _muat();
    final list = _milik(_uid)['riwayat'] as List<dynamic>;
    final out = list.map((e) => Riwayat.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    out.sort((a, b) => b.waktu.compareTo(a.waktu));
    return out;
  }

  @override
  Future<Riwayat> tambahRiwayat(Riwayat r) async {
    final baru = Riwayat.fromJson({...r.toJson(), 'id': _id()});
    (_milik(_uid)['riwayat'] as List<dynamic>).add(baru.toJson());
    await _tulis();
    return baru;
  }
}
