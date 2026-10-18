import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../data/katalog.dart';
import '../data/logic.dart';
import '../data/models.dart';
import '../services/api_client.dart';
import '../services/google_login.dart';
import '../services/pengingat_service.dart';
import '../services/repository.dart';

/// Satu-satunya sumber data aplikasi. Halaman cukup mendengarkan perubahan
/// lewat ListenableBuilder(listenable: AppState.i, ...).
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState i = AppState._();

  final KulkasRepo repo = KulkasRepo.buat();
  final PengingatService _pengingat = PengingatService.instance;

  Profil? user;
  List<Bahan> bahan = [];
  List<Riwayat> riwayat = [];
  bool memuat = false;

  bool get masuk => user != null;

  // ------------------------------------------------------------ katalog
  Future<List<SayurInfo>>? _katalogFuture;

  /// Dipakai FutureBuilder di splash: GET katalog dari API.
  Future<List<SayurInfo>> muatKatalog() {
    final f = _katalogFuture ??= repo.ambilKatalog().then((list) {
      Katalog.isi(list);
      return list;
    });
    f.catchError((Object _) {
      _katalogFuture = null; // boleh dicoba lagi
      return <SayurInfo>[];
    });
    return f;
  }

  // ------------------------------------------------------------ sesi
  Future<bool> pulihkanSesi() async {
    try {
      await muatKatalog();
      // web: baru kembali dari halaman login Google?
      await GoogleLogin.tangkapDariUrl();
      final p = await repo.sesiTersimpan();
      if (p == null) return false;
      await _setUser(p);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setUser(Profil p) async {
    user = p;
    Hitung.suhuKl = p.suhuKl;
    Hitung.suhuFz = p.suhuFz;
    await muatData();
  }

  Future<void> muatData() async {
    memuat = true;
    notifyListeners();
    try {
      final hasil = await Future.wait([repo.ambilBahan(), repo.ambilRiwayat()]);
      bahan = hasil[0] as List<Bahan>;
      riwayat = hasil[1] as List<Riwayat>;
    } finally {
      memuat = false;
      notifyListeners();
    }
    _jadwalkanUlang();
  }

  Future<void> masukAkun(String userAtauEmail, String password) async {
    final p = await repo.masuk(userAtauEmail, password);
    await _setUser(p);
    _pengingat.mintaIzin();
  }

  /// Masuk / daftar dengan Google. Mengembalikan true kalau sudah masuk
  /// (di web, halaman berpindah ke Google dulu lalu kembali lewat splash).
  Future<bool> masukGoogle() async {
    final selesai = await GoogleLogin.mulai();
    if (!selesai) return false;
    final p = await repo.sesiTersimpan();
    if (p == null) throw ApiException('Profil Google belum siap. Coba masuk lagi.');
    await _setUser(p);
    _pengingat.mintaIzin();
    return true;
  }

  Future<void> daftarAkun({
    required String nama,
    required String username,
    required String email,
    required String hp,
    required String password,
  }) async {
    await repo.daftar(nama: nama, username: username, email: email, hp: hp, password: password);
    try {
      await masukAkun(email, password);
    } on ApiException catch (e) {
      if (e.pesan.contains('konfirmasi')) {
        throw ApiException('Akun jadi! Cek email untuk konfirmasi, lalu masuk.');
      }
      rethrow;
    }
  }

  Future<void> keluar() async {
    await repo.keluar();
    user = null;
    bahan = [];
    riwayat = [];
    await _pengingat.jadwalkan(const [], jam: '07:00', aktif: false);
    notifyListeners();
  }

  Future<void> hapusAkun() async {
    await repo.hapusAkun();
    user = null;
    bahan = [];
    riwayat = [];
    await _pengingat.jadwalkan(const [], jam: '07:00', aktif: false);
    notifyListeners();
  }

  // ------------------------------------------------------------ profil
  Future<void> simpanProfil(Profil p) async {
    user = await repo.simpanProfil(p);
    Hitung.suhuKl = user!.suhuKl;
    Hitung.suhuFz = user!.suhuFz;
    notifyListeners();
    _jadwalkanUlang();
  }

  Future<String> unggahFoto(Uint8List bytes) => repo.unggahFoto(user!.id, bytes);

  Future<void> ubahPengaturan(void Function(Profil p) ubah) async {
    final p = user!.salin();
    ubah(p);
    await simpanProfil(p);
  }

  // ------------------------------------------------------------ bahan
  List<Bahan> get urut => [...bahan]..sort((a, b) => Hitung.sisaHari(a).compareTo(Hitung.sisaHari(b)));
  List<Bahan> di(String tempat) => bahan.where((b) => b.tempat == tempat).toList();
  int hitung(Status s) => bahan.where((b) => Hitung.status(b) == s).length;
  int get perluPerhatian => bahan.where((b) => Hitung.status(b) != Status.segar).length;
  int get dipakai => riwayat.where((r) => r.aksi == 'dipakai').length;
  int get dibuang => riwayat.where((r) => r.aksi == 'dibuang').length;

  Bahan? cari(String id) {
    for (final b in bahan) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<Bahan> tambahBahan(Bahan b) async {
    final baru = await repo.tambahBahan(b);
    bahan = [...bahan, baru];
    notifyListeners();
    _jadwalkanUlang();
    return baru;
  }

  Future<void> ubahBahan(Bahan b) async {
    final hasil = await repo.ubahBahan(b);
    bahan = bahan.map((x) => x.id == hasil.id ? hasil : x).toList();
    notifyListeners();
    _jadwalkanUlang();
  }

  /// Hapus karena salah input (tidak tercatat di riwayat).
  Future<void> hapusBahan(Bahan b) async {
    await repo.hapusBahan(b.id);
    bahan = bahan.where((x) => x.id != b.id).toList();
    notifyListeners();
    _jadwalkanUlang();
  }

  /// Sayur keluar dari kulkas: "dipakai" atau "dibuang", lalu tercatat di riwayat.
  Future<void> keluarkan(Bahan b, String aksi) async {
    await repo.hapusBahan(b.id);
    final r = await repo.tambahRiwayat(Riwayat(
      id: '',
      nama: b.nama,
      jenis: b.jenis,
      jumlah: b.jumlah,
      satuan: b.satuan,
      aksi: aksi,
      waktu: DateTime.now(),
    ));
    bahan = bahan.where((x) => x.id != b.id).toList();
    riwayat = [r, ...riwayat];
    notifyListeners();
    _jadwalkanUlang();
  }

  Future<int> buangSemuaBasi() async {
    final xs = bahan.where((b) => Hitung.status(b) == Status.basi).toList();
    for (final b in xs) {
      await keluarkan(b, 'dibuang');
    }
    return xs.length;
  }

  /// Status izin notifikasi: 'granted', 'denied', atau 'default'.
  String get izinNotif => _pengingat.izin;
  bool get notifDidukung => _pengingat.didukung;

  /// Dipanggil dari tombol "Aktifkan notifikasi" (web) supaya browser meminta izin.
  Future<void> aktifkanNotif() async {
    await _pengingat.mintaIzin();
    _jadwalkanUlang();
    notifyListeners();
  }

  void _jadwalkanUlang() {
    final u = user;
    if (u == null) return;
    _pengingat.jadwalkan(bahan, jam: u.jam, aktif: u.pengingat);
  }
}
