import 'package:flutter/material.dart';

import '../theme.dart';

/// Ide olahan cepat untuk satu jenis sayur/buah.
class IdeOlah {
  final String nama;
  final String waktu;
  const IdeOlah({required this.nama, required this.waktu});

  factory IdeOlah.fromJson(Map<String, dynamic> json) =>
      IdeOlah(nama: json['nama'] as String? ?? '', waktu: json['waktu'] as String? ?? '');

  Map<String, dynamic> toJson() => {'nama': nama, 'waktu': waktu};
}

/// Satu jenis sayur/buah di katalog (diambil dari API "katalog").
class SayurInfo {
  final String id; // contoh: "bayam", sekaligus nama file gambar
  final String label;
  final String en; // nama Inggris (untuk pencarian), contoh: "spinach"
  final String kat; // "Sayur" / "Buah"
  final String grup; // contoh: "Sayur daun", "Buah beri"
  final int awet; // umur simpan (hari) di tempat default
  final String satuan;
  final String tempat; // freezer / rak / laci / pintu
  final Color tint;
  final String tips;
  final List<IdeOlah> ide;

  const SayurInfo({
    required this.id,
    required this.label,
    this.en = '',
    required this.kat,
    this.grup = '',
    required this.awet,
    required this.satuan,
    required this.tempat,
    required this.tint,
    required this.tips,
    required this.ide,
  });

  /// Materi Pertemuan 6: factory fromJson untuk mengubah JSON jadi objek Dart.
  factory SayurInfo.fromJson(Map<String, dynamic> json) {
    final ideRaw = json['ide'];
    return SayurInfo(
      id: json['id'] as String,
      label: json['label'] as String? ?? json['id'] as String,
      en: json['en'] as String? ?? '',
      kat: json['kat'] as String? ?? 'Sayur',
      grup: json['grup'] as String? ?? '',
      awet: (json['awet'] as num?)?.toInt() ?? 5,
      satuan: json['satuan'] as String? ?? 'buah',
      tempat: json['tempat'] as String? ?? 'rak',
      tint: AppColors.hex(json['tint'] as String? ?? '#EEF0E6'),
      tips: json['tips'] as String? ?? '',
      ide: ideRaw is List
          ? ideRaw.map((e) => IdeOlah.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : const [],
    );
  }
}

/// Katalog yang sudah dimuat. Diisi sekali saat aplikasi dibuka.
class Katalog {
  static final Map<String, SayurInfo> _data = {};

  static void isi(List<SayurInfo> list) {
    _data
      ..clear()
      ..addEntries(list.map((e) => MapEntry(e.id, e)));
  }

  static bool get kosong => _data.isEmpty;
  static List<SayurInfo> get semua => _data.values.toList();
  static List<SayurInfo> kategori(String kat) => _data.values.where((e) => e.kat == kat).toList();

  /// Daftar grup (urut sesuai katalog), misalnya untuk Buah: Buah tropis, Jeruk-jerukan, Buah beri, ...
  static List<String> grupDari(String kat) {
    final hasil = <String>[];
    for (final e in _data.values) {
      if (e.kat == kat && e.grup.isNotEmpty && !hasil.contains(e.grup)) hasil.add(e.grup);
    }
    return hasil;
  }

  static List<SayurInfo> diGrup(String grup) => _data.values.where((e) => e.grup == grup).toList();

  /// Cari berdasarkan nama Indonesia atau Inggris, contoh "rasp" -> Raspberry, "spinach" -> Bayam.
  static List<SayurInfo> cari(String kata) {
    final q = kata.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final cocok = _data.values.where((e) => e.label.toLowerCase().contains(q) || e.en.toLowerCase().contains(q) || e.id.contains(q)).toList();
    // yang namanya diawali kata kunci tampil lebih dulu
    cocok.sort((a, b) {
      final aa = a.label.toLowerCase().startsWith(q) ? 0 : 1;
      final bb = b.label.toLowerCase().startsWith(q) ? 0 : 1;
      return aa.compareTo(bb);
    });
    return cocok;
  }

  static SayurInfo info(String id) =>
      _data[id] ??
      SayurInfo(
        id: id,
        label: id,
        kat: 'Sayur',
        awet: 5,
        satuan: 'buah',
        tempat: 'rak',
        tint: const Color(0xFFEEF0E6),
        tips: '',
        ide: const [],
      );
}

const Map<String, String> tempatLabel = {
  'freezer': 'Freezer',
  'rak': 'Rak kulkas',
  'laci': 'Laci sayur',
  'pintu': 'Rak pintu',
};

const Map<String, String> tempatIkon = {
  'freezer': 'salju',
  'rak': 'keranjang',
  'laci': 'daun',
  'pintu': 'pintu',
};
