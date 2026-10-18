import 'package:flutter/material.dart';

import 'models.dart';

/// Perhitungan inti Kulkasku: kapan sayur layu, statusnya, dan jadwal pengingat.
class Hitung {
  /// Suhu kulkas & freezer milik pengguna (diisi dari profil).
  static int suhuKl = 4;
  static int suhuFz = -18;

  /// Faktor umur simpan menurut suhu. Kulkas 4°C dan freezer -18°C = 1.0.
  static double faktorSuhu(String tempat) {
    if (tempat == 'freezer') {
      return (1 - (suhuFz + 18) * 0.035).clamp(0.5, 1.1).toDouble();
    }
    return (1 - (suhuKl - 4) * 0.12).clamp(0.5, 1.15).toDouble();
  }

  static int awetEfektif(Bahan b) => (b.awet * faktorSuhu(b.tempat)).round().clamp(1, 999).toInt();

  /// Tanggal layu = tanggal beli + umur simpan (disesuaikan suhu).
  static DateTime tanggalLayu(Bahan b) => tambahHari(b.beli, awetEfektif(b));

  /// Sisa hari sampai layu. Negatif berarti sudah basi.
  static int sisaHari(Bahan b) => tanggalLayu(b).difference(hariIni()).inHours ~/ 24;

  static Status status(Bahan b) {
    final s = sisaHari(b);
    if (s < 0) return Status.basi;
    if (s <= 2) return Status.layu;
    return Status.segar;
  }

  /// 0..1, seberapa segar (dipakai cincin persen).
  static double kesegaran(Bahan b) => (sisaHari(b) / awetEfektif(b)).clamp(0.0, 1.0).toDouble();

  static String sisaLabel(Bahan b) {
    final s = sisaHari(b);
    if (s < 0) return 'Basi ${-s} hari';
    if (s == 0) return 'Layu hari ini';
    if (s == 1) return 'Layu besok';
    return '$s hari lagi';
  }

  /// Pengingat H-1, hari-H, dan pengingat harian untuk yang sudah basi.
  static List<Pengingat> jadwal(List<Bahan> bahan) {
    final out = <Pengingat>[];
    final h0 = hariIni();
    for (final b in bahan) {
      final l = tanggalLayu(b);
      final h1 = tambahHari(l, -1);
      if (!h1.isBefore(h0)) {
        out.add(Pengingat(h1, b, 'h1', '${b.nama} layu besok', 'Layu ${tglHari(l)}. Masak hari ini atau besok, ya.'));
      }
      if (!l.isBefore(h0)) {
        out.add(Pengingat(l, b, 'h0', '${b.nama} layu hari ini', 'Hari terakhir masih segar. Yuk dimasak sekarang.'));
      } else {
        out.add(Pengingat(h0, b, 'lewat', '${b.nama} sudah basi, buang ya',
            'Basi sejak ${tglHari(l)}. Pengingat ini muncul tiap hari sampai dibuang.'));
      }
    }
    out.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    return out;
  }
}

enum Status { segar, layu, basi }

extension StatusX on Status {
  String get label => switch (this) {
        Status.segar => 'Segar',
        Status.layu => 'Hampir layu',
        Status.basi => 'Basi',
      };
  Color get warna => switch (this) {
        Status.segar => const Color(0xFF2F7D3A),
        Status.layu => const Color(0xFFB8520A),
        Status.basi => const Color(0xFF5A4630),
      };
  Color get cincin => switch (this) {
        Status.segar => const Color(0xFF2F7D3A),
        Status.layu => const Color(0xFFE8701A),
        Status.basi => const Color(0xFF6B5A3A),
      };
  Color get muda => switch (this) {
        Status.segar => const Color(0xFFDDEFC8),
        Status.layu => const Color(0xFFFFE6CF),
        Status.basi => const Color(0xFFE9DFCF),
      };
}

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _hr = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String tgl(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';
String tglHari(DateTime d) => '${_hr[d.weekday - 1]}, ${tgl(d)}';
String namaHari(DateTime d) => _hari[d.weekday - 1];
String hariSingkat(DateTime d) => _hr[d.weekday - 1];

String formatSuhu(int t) => '${t < 0 ? '−' : ''}${t.abs()}°C';
