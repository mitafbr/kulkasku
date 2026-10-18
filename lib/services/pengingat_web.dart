import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../data/logic.dart';
import '../data/models.dart';

/// Notifikasi browser (versi web) memakai Web Notification API.
///
/// Catatan: browser hanya bisa memunculkan notifikasi selama tab Kulkasku
/// terbuka (boleh di latar belakang). Saat Kulkasku dibuka, ringkasan bahan
/// yang hampir layu langsung dikirim sebagai notifikasi.
@JS('Notification')
extension type _Notifikasi._(JSObject _) implements JSObject {
  external factory _Notifikasi(String judul, _Opsi opsi);
  external static String get permission;
  external static JSPromise<JSString> requestPermission();
}

extension type _Opsi._(JSObject _) implements JSObject {
  external factory _Opsi({String body, String icon, String tag});
}

class PengingatService {
  PengingatService._();
  static final PengingatService instance = PengingatService._();

  final List<Timer> _timer = [];
  bool _ringkasanTerkirim = false;

  bool get didukung => globalContext.has('Notification');

  /// 'granted', 'denied', atau 'default' (belum ditanya).
  String get izin => didukung ? _Notifikasi.permission : 'denied';

  Future<void> init() async {}

  Future<void> mintaIzin() async {
    if (!didukung || izin != 'default') return;
    try {
      await _Notifikasi.requestPermission().toDart;
    } catch (_) {}
  }

  void _tampil(String judul, String isi, String tag) {
    if (!didukung || izin != 'granted') return;
    try {
      _Notifikasi(judul, _Opsi(body: isi, icon: 'icons/Icon-192.png', tag: tag));
    } catch (_) {}
  }

  Future<void> jadwalkan(List<Bahan> bahan, {required String jam, required bool aktif}) async {
    for (final t in _timer) {
      t.cancel();
    }
    _timer.clear();
    if (!aktif || !didukung) return;
    if (izin == 'default') await mintaIzin();
    if (izin != 'granted') return;

    final bagian = jam.split(':');
    final hh = int.tryParse(bagian.first) ?? 7;
    final mm = bagian.length > 1 ? int.tryParse(bagian[1]) ?? 0 : 0;
    final sekarang = DateTime.now();
    final jadwal = Hitung.jadwal(bahan);

    // 1. ringkasan sekali tiap kali Kulkasku dibuka
    if (!_ringkasanTerkirim) {
      final penting = jadwal.where((p) => !p.tanggal.isAfter(hariIni())).toList();
      if (penting.isNotEmpty) {
        final nama = penting.map((p) => p.bahan.nama).toSet().take(4).join(', ');
        _tampil(
          '${penting.length} pengingat dari Kulkasku',
          'Cek sekarang: $nama${penting.length > 4 ? ', dan lainnya' : ''}.',
          'kulkasku-ringkasan',
        );
      }
      _ringkasanTerkirim = true;
    }

    // 2. pengingat terjadwal (H-1 & hari-H) selama tab masih terbuka
    for (final p in jadwal) {
      final waktu = DateTime(p.tanggal.year, p.tanggal.month, p.tanggal.day, hh, mm);
      final tunggu = waktu.difference(sekarang);
      if (tunggu.isNegative || tunggu > const Duration(days: 2)) continue;
      _timer.add(Timer(tunggu, () => _tampil(p.judul, p.pesan, 'kulkasku-${p.bahan.id}-${p.jenis}')));
    }
  }
}
