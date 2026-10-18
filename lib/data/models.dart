import 'katalog.dart';

DateTime hariIni() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime tambahHari(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

DateTime _parseTanggal(dynamic v) {
  if (v is String && v.isNotEmpty) {
    final d = DateTime.parse(v);
    return DateTime(d.year, d.month, d.day);
  }
  return hariIni();
}

String isoTanggal(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Satu sayur/buah yang ada di kulkas.
class Bahan {
  final String id;
  String nama;
  String jenis;
  String kat;
  double jumlah;
  String satuan;
  String tempat;
  DateTime beli;
  int awet;

  Bahan({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.kat,
    required this.jumlah,
    required this.satuan,
    required this.tempat,
    required this.beli,
    required this.awet,
  });

  factory Bahan.fromJson(Map<String, dynamic> json) => Bahan(
        id: json['id'].toString(),
        nama: json['nama'] as String? ?? '',
        jenis: json['jenis'] as String? ?? 'bayam',
        kat: json['kat'] as String? ?? 'Sayur',
        jumlah: (json['jumlah'] as num?)?.toDouble() ?? 1,
        satuan: json['satuan'] as String? ?? 'buah',
        tempat: json['tempat'] as String? ?? 'rak',
        beli: _parseTanggal(json['beli']),
        awet: (json['awet'] as num?)?.toInt() ?? 5,
      );

  /// [denganId] false dipakai saat INSERT ke Supabase (id dibuat server).
  Map<String, dynamic> toJson({bool denganId = true}) => {
        if (denganId) 'id': id,
        'nama': nama,
        'jenis': jenis,
        'kat': kat,
        'jumlah': jumlah,
        'satuan': satuan,
        'tempat': tempat,
        'beli': isoTanggal(beli),
        'awet': awet,
      };

  Bahan salin() => Bahan.fromJson(toJson());

  String get jumlahTeks {
    final j = jumlah == jumlah.roundToDouble() ? jumlah.toInt().toString() : jumlah.toStringAsFixed(1);
    return '$j $satuan';
  }

  SayurInfo get info => Katalog.info(jenis);
}

/// Catatan bahan yang sudah keluar dari kulkas.
class Riwayat {
  final String id;
  final String nama;
  final String jenis;
  final double jumlah;
  final String satuan;
  final String aksi; // "dipakai" / "dibuang"
  final DateTime waktu;

  const Riwayat({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.jumlah,
    required this.satuan,
    required this.aksi,
    required this.waktu,
  });

  factory Riwayat.fromJson(Map<String, dynamic> json) => Riwayat(
        id: json['id'].toString(),
        nama: json['nama'] as String? ?? '',
        jenis: json['jenis'] as String? ?? 'bayam',
        jumlah: (json['jumlah'] as num?)?.toDouble() ?? 1,
        satuan: json['satuan'] as String? ?? '',
        aksi: json['aksi'] as String? ?? 'dipakai',
        waktu: DateTime.tryParse(json['waktu']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      );

  Map<String, dynamic> toJson({bool denganId = true}) => {
        if (denganId) 'id': id,
        'nama': nama,
        'jenis': jenis,
        'jumlah': jumlah,
        'satuan': satuan,
        'aksi': aksi,
        'waktu': waktu.toUtc().toIso8601String(),
      };

  String get jumlahTeks {
    final j = jumlah == jumlah.roundToDouble() ? jumlah.toInt().toString() : jumlah.toStringAsFixed(1);
    return '$j $satuan';
  }
}

/// Profil + pengaturan pengguna (satu baris tabel "profil").
class Profil {
  final String id;
  String username;
  String nama;
  String email;
  String hp;
  String? foto; // URL (Supabase Storage) atau data URI (mode lokal)
  String ava; // avatar sayur bawaan
  String catatan; // kertas catatan di pintu kulkas
  int suhuKl;
  int suhuFz;
  String jam; // "07:00"
  bool pengingat;
  bool kalender;

  Profil({
    required this.id,
    required this.username,
    required this.nama,
    required this.email,
    this.hp = '',
    this.foto,
    this.ava = 'brokoli',
    this.catatan = 'tahu\ndaun bawang\nsusu',
    this.suhuKl = 4,
    this.suhuFz = -18,
    this.jam = '07:00',
    this.pengingat = true,
    this.kalender = true,
  });

  factory Profil.fromJson(Map<String, dynamic> json) => Profil(
        id: json['id'].toString(),
        username: json['username'] as String? ?? '',
        nama: json['nama'] as String? ?? '',
        email: json['email'] as String? ?? '',
        hp: json['hp'] as String? ?? '',
        foto: (json['foto'] as String?)?.isEmpty == true ? null : json['foto'] as String?,
        ava: json['ava'] as String? ?? 'brokoli',
        catatan: json['catatan'] as String? ?? '',
        suhuKl: (json['suhu_kl'] as num?)?.toInt() ?? 4,
        suhuFz: (json['suhu_fz'] as num?)?.toInt() ?? -18,
        jam: json['jam'] as String? ?? '07:00',
        pengingat: json['pengingat'] as bool? ?? true,
        kalender: json['kalender'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nama': nama,
        'email': email,
        'hp': hp,
        'foto': foto,
        'ava': ava,
        'catatan': catatan,
        'suhu_kl': suhuKl,
        'suhu_fz': suhuFz,
        'jam': jam,
        'pengingat': pengingat,
        'kalender': kalender,
      };

  Profil salin() => Profil.fromJson(toJson());
}

/// Satu jadwal pengingat (dipakai halaman Notifikasi & notifikasi HP).
class Pengingat {
  final DateTime tanggal;
  final Bahan bahan;
  final String jenis; // h1 / h0 / lewat
  final String judul;
  final String pesan;
  const Pengingat(this.tanggal, this.bahan, this.jenis, this.judul, this.pesan);
}
