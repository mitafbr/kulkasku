import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mumu.dart';

const _faq = <(String, String, String)>[
  ('daun', 'Bagaimana Kulkasku tahu kapan sayur layu?',
      'Setiap sayur dan buah punya perkiraan umur simpan sesuai tempatnya (misalnya sawi ±4 hari di laci sayur, apel ±30 hari, stroberi ±3 hari; di freezer sekitar 3× lebih lama). Tanggal layu = tanggal beli + umur simpan, lalu disesuaikan dengan suhu kulkasmu. Angkanya bisa kamu geser saat menambah bahan.'),
  ('termo', 'Kenapa suhu kulkas perlu diatur?',
      'Tiap kulkas beda. Kulkas 4°C ideal untuk sayur. Kalau kulkasmu lebih hangat (misalnya 8°C), sayur lebih cepat layu, jadi Kulkasku memajukan tanggal layu dan pengingatnya. Ubah lewat label suhu di pintu kulkas atau di Profil.'),
  ('lonceng', 'Kapan notifikasi dikirim?',
      'Dua kali untuk tiap bahan: sehari sebelum layu (H-1) dan pada hari layunya (hari-H), di jam pengingat yang kamu atur di Profil (bawaan 07.00). Di APK Android notifikasi muncul walau aplikasi ditutup. Di versi web, izinkan notifikasi browser di halaman Notifikasi; pengingat muncul selama tab Kulkasku terbuka.'),
  ('kalender', 'Apakah tanggalnya masuk ke kalender HP?',
      'Ya, kalau “Sinkron Kalender HP” aktif. Setelah menambah sayur, tekan “Ke Kalender”, atau tekan “+ Kalender HP” di halaman detail. Google Calendar terbuka dengan acara tanggal layu yang sudah terisi, tinggal tekan Simpan.'),
  ('tunas', 'Sayurku ternyata masih segar padahal sudah “layu”. Bagaimana?',
      'Buka detail bahannya, lalu tekan “Masih segar? Tambah 2 hari”. Tanggal layu dan notifikasi ikut digeser.'),
  ('centang', 'Apa bedanya “Sudah dipakai” dan “Buang”?',
      'Keduanya mengeluarkan bahan dari kulkas. “Sudah dipakai” dihitung sebagai bahan yang diselamatkan, sedangkan “Buang” tercatat sebagai bahan terbuang. Persentasenya tampil di Riwayat. Kalau cuma salah input, pakai “Hapus dari kulkas (salah input)” di halaman edit.'),
  ('brokoli', 'Bahan apa saja yang bisa dicatat?',
      'Lebih dari 170 jenis sayur dan buah, ditambah isi kulkas lain di kategori Lainnya: susu, keju, mentega, telur, roti, daging sapi, ayam, ikan, udang, dan cumi.'),
  ('salad', 'Dari mana ide olahannya?',
      'Daftar sayur, umur simpan, tips, dan ide olahan diambil dari data katalog lewat API saat aplikasi dibuka. Kalau internet mati, aplikasi memakai salinan katalog bawaan.'),
  ('kaca', 'Apa arti gambar sayur yang berbeda-beda?',
      'Gambar normal = segar. Pucat, terkulai, dan berkeringat = hampir layu (0–2 hari lagi). Gelap, berjamur, dan dikerubungi lalat = basi, segera buang.'),
  ('kamera', 'Bagaimana mengganti foto profil?',
      'Buka Profil → Edit profil & foto, lalu ketuk foto bulat di atas. Pilih foto dari galeri, atau pilih salah satu avatar sayur, lalu tekan Simpan.'),
  ('pintu', 'Bagaimana cara mulai memakai Kulkasku?',
      'Pengguna baru buka tab Daftar, isi nama, username, email, dan kata sandi, lalu tekan Daftar. Setelah itu cukup Masuk dengan username atau email dan kata sandimu.'),
  ('hp', 'Apakah nomor HP wajib?', 'Tidak. Untuk masuk cukup username atau email dan kata sandi. Nomor HP boleh dikosongkan.'),
  ('kulkas', 'Apakah data tersimpan kalau aplikasi ditutup?',
      'Ya. Akun, isi kulkas (jenis sayur, jumlah, tanggal beli, tempat), riwayat, catatan, pengaturan suhu, dan foto profil tersimpan di server (database Supabase), jadi tetap ada saat aplikasi dibuka lagi dan bisa dibuka dari HP maupun laptop dengan akun yang sama. Kalau aplikasi sedang di mode lokal (tertulis di Profil), data hanya tersimpan di perangkat itu saja.'),
  ('jamur', 'Siapa Mumu?',
      'Mumu adalah maskot Kulkasku, jamur dongeng bertopi merah bintik putih yang menjaga sayur & buahmu. Dia muncul saat kamu masuk, saat kulkas kosong, dan ikut sedih kalau ada yang basi. Jamur bertopi merah seperti Mumu di dunia nyata tidak boleh dimakan ya; jamur yang aman dimakan (jamur kancing, tiram, shiitake) bisa kamu simpan lewat menu Tambah.'),
];

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IsiTengah(maxWidth: 720, child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            const Align(alignment: Alignment.centerLeft, child: TombolKembali()),
            const SizedBox(height: 10),
            const PageHead('Pertanyaan umum', 'FAQ.', ikon: MumuMini(size: 64, mood: MumuMood.tanya)),
            const SizedBox(height: 14),
            for (var i = 0; i < _faq.length; i++)
              Naik(
                delayMs: i * 40,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: leafRadius(22), border: Border.all(color: AppColors.line)),
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: i == 0,
                      leading: Emo(_faq[i].$1, size: 26),
                      title: Text(_faq[i].$2, style: AppText.body(14.5, weight: FontWeight.w900)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      children: [
                        Text(_faq[i].$3, style: AppText.body(13.5, color: AppColors.muted, weight: FontWeight.w600, height: 1.55)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      )),
    );
  }
}

class _Halaman extends StatelessWidget {
  final String label;
  final String judul;
  final List<Widget> isi;
  const _Halaman({required this.label, required this.judul, required this.isi});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: IsiTengah(maxWidth: 720, child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              const Align(alignment: Alignment.centerLeft, child: TombolKembali()),
              const SizedBox(height: 10),
              PageHead(label, judul, ikon: const MumuMini(size: 64)),
              const SizedBox(height: 16),
              ...isi,
            ],
          ),
        )),
      );
}

Widget _kartu(String judul, String isi) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: leafRadius(22), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(judul, style: AppText.body(15, weight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(isi, style: AppText.body(13.5, color: AppColors.muted, weight: FontWeight.w600, height: 1.55)),
      ]),
    );

class TentangPage extends StatelessWidget {
  const TentangPage({super.key});
  @override
  Widget build(BuildContext context) => _Halaman(
        label: 'Tentang aplikasi',
        judul: 'Kulkasku.',
        isi: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3C9446), Color(0xFF1F5A28)]), borderRadius: leafRadius(28)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DIBUAT OLEH', style: AppText.label(color: AppColors.leafLight, size: 10)),
              const SizedBox(height: 6),
              Text('Miftachul Jannah Wigno Febriyani (Mita)', style: AppText.display(24, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Tugas Akhir BTNG 2026 · Divisi Mobile\nDNCC · Universitas Dian Nuswantoro',
                  style: AppText.body(13, color: Colors.white70, weight: FontWeight.w700, height: 1.5)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(AppConfig.linkRepo), mode: LaunchMode.externalApplication),
                child: Text('github.com/${AppConfig.githubRepo}',
                    style: AppText.body(13, color: AppColors.leafLight, weight: FontWeight.w800).copyWith(decoration: TextDecoration.underline)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _kartu('Apa itu Kulkasku?',
              'Aplikasi pengingat isi kulkas khusus sayur & buah. Kulkasku menghitung tanggal layu dari tanggal beli dan suhu kulkas, mengirim pengingat H-1 dan hari-H, lalu mencatat berapa banyak bahan yang berhasil diselamatkan.'),
          _kartu('Lisensi', 'MIT License © 2026 Mita.\nBoleh dipakai dan dikembangkan ulang, dengan syarat tetap mencantumkan nama pembuat dan teks lisensi ini.'),
          _kartu('Kredit aset & teknologi',
              '• Gambar sayur & ikon 3D: Fluent Emoji © Microsoft Corporation, MIT License (sebagian diubah warna & susunannya).\n'
              '• Font: DM Serif Display & Nunito (Google Fonts, SIL Open Font License).\n'
              '• Lagu latar & suara klik: dibuat khusus untuk Kulkasku (komposisi asli).\n'
              '• Dibangun dengan Flutter & Dart, package http, shared_preferences, image_picker, flutter_local_notifications, timezone, url_launcher.\n'
              '• Data akun disimpan di Supabase.\n'
              '• Maskot Mumu, desain kulkas, dan navbar ranting adalah karya asli Kulkasku.'),
          _kartu('Versi', '1.0.0'),
        ],
      );
}

class PrivasiPage extends StatelessWidget {
  const PrivasiPage({super.key});
  @override
  Widget build(BuildContext context) => _Halaman(
        label: 'Data pribadimu',
        judul: 'Privasi.',
        isi: [
          _kartu('Data yang disimpan',
              'Nama, username, email, nomor HP (opsional), foto profil (opsional), isi kulkas, riwayat, catatan, dan pengaturan (suhu, jam pengingat).'),
          _kartu('Untuk apa',
              'Hanya untuk menjalankan fitur Kulkasku: menghitung tanggal layu, menampilkan pengingat, dan menyimpan isi kulkasmu. Data tidak dijual atau dibagikan ke pihak lain.'),
          _kartu('Di mana disimpan',
              'Di server Supabase. Setiap akun hanya bisa membaca datanya sendiri (dikunci dengan Row Level Security). Kata sandi disimpan terenkripsi oleh Supabase Auth dan tidak bisa dilihat siapa pun, termasuk pembuat aplikasi. Pada mode lokal, data hanya tersimpan di perangkatmu.'),
          _kartu('Hak kamu',
              'Kamu bisa mengubah data kapan saja di Edit profil, dan menghapus akun beserta seluruh datanya lewat Profil → “Hapus akun & semua data”. Kebijakan ini mengikuti semangat UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi.'),
          _kartu('Kontak', 'Pertanyaan soal data: buka github.com/${AppConfig.githubRepo} lalu buat “Issue”.'),
        ],
      );
}
