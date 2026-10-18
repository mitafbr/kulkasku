# 🍄 Kulkasku

**Pengingat sayur & buah di kulkas sebelum layu.**
Tugas Akhir **BTNG 2026 · Divisi Mobile** (DNCC, Universitas Dian Nuswantoro).

Dibuat oleh **Miftachul Jannah Wigno Febriyani (Mita)** · [MIT License](LICENSE) © 2026 Mita

- 🌐 Web: https://mitafbr.github.io/kulkasku/
- 📱 APK Android: [unduh versi terbaru](https://github.com/mitafbr/kulkasku/releases/latest/download/app-release.apk)

---

## Fitur

- **Dapur interaktif**: kulkas dua pintu (freezer & kulkas) yang bisa dibuka. Isinya tampil di rak, laci sayur, dan rak pintu.
- **Tanggal layu otomatis** dari tanggal beli + umur simpan, disesuaikan dengan **suhu kulkas** milik pengguna.
- **Status visual**: segar, hampir layu (pucat & berkeringat), dan basi (berjamur & dikerubungi lalat). Ada tombol "Buang semua yang basi".
- **Pengingat H-1 & hari-H** di jam pilihan (notifikasi Android) dan **kalender HP**.
- **Catatan belanja** yang bisa diedit di pintu kulkas.
- Tambah, edit, dan hapus isi kulkas. Tandai **Sudah dipakai** atau **Buang**, lalu lihat persentasenya di **Riwayat**.
- **181 bahan**: 171 jenis sayur & buah dalam 13 grup (sayur daun, umbi, bumbu & rempah, jamur, buah tropis, jeruk, beri, dll.), plus kategori Lainnya: susu, keju, mentega, telur, roti, daging sapi, ayam, ikan, udang & cumi. Lengkap dengan tips simpan & ide olah cepat (diambil dari API katalog), dan bisa dicari dengan nama Indonesia maupun Inggris.
- **Profil polaroid**: upload foto sendiri atau pilih avatar sayur.
- Maskot **Mumu** yang bereaksi saat login: menutup mata saat sandi diisi, sedih saat salah, dan melompat saat berhasil.
- **Responsif**: di HP tampil versi mobile dengan navbar ranting pohon; di laptop/PC tampil versi landscape dengan menu ranting di samping.
- Animasi "masuk ke dapur": Mumu membawa keranjang dan sayur melompat masuk ke kulkas.
- Halaman FAQ, Tentang, Kebijakan Privasi, dan **Hapus akun**.

## Materi BTNG yang dipakai

| Pertemuan | Dipakai di |
|---|---|
| 2 · Basic widget (Stateless/Stateful, Scaffold, Container, Text, Image, Row/Column) | Semua halaman |
| 3 · Dart fundamental (variabel, function, null safety, List/Map, OOP, switch, try-catch) | `lib/data`, `lib/services` |
| 4 · Form & interaksi (TextField, Switch, Slider, Dialog, SnackBar, DatePicker, TimePicker) | Masuk/Daftar, Tambah, Profil, dialog suhu & catatan |
| 5 · Layout (Stack, Expanded, Padding, Wrap, ListView, GridView, MediaQuery, LayoutBuilder) | Dapur, daftar isi kulkas, profil, tampilan HP vs laptop |
| 6 · **Async & API** (async/await, Future, package `http`, `fromJson`, `FutureBuilder`) | `lib/services/api_client.dart`, `SayurInfo.fromJson`, `FutureBuilder` di splash |
| 7 · Navigasi (Navigator push/pop, bottom navigation) | `ShellPage`, navbar ranting |

## Arsitektur singkat

```
lib/
  config.dart            ← isi URL & anon key Supabase di sini
  data/                  ← model (fromJson/toJson) & perhitungan tanggal layu
  services/
    api_client.dart      ← REST API Supabase memakai package http
    repository.dart      ← SupabaseRepo (online) & LokalRepo (tanpa server)
    pengingat_*.dart     ← notifikasi & kalender (Android)
  state/app_state.dart   ← ChangeNotifier, sumber data semua halaman
  widgets/               ← Mumu, dapur & kulkas, navbar ranting, taman
  pages/                 ← halaman-halaman aplikasi
supabase/setup.sql       ← tabel, keamanan (RLS), fungsi, storage, isi katalog
.github/workflows/       ← build web (GitHub Pages) + APK (Releases) otomatis
```

Backend: **Supabase** (Postgres + Auth + Storage) diakses lewat REST API. Kalau `config.dart` kosong, aplikasi memakai **mode lokal** (data hanya tersimpan di perangkat/browser masing-masing). Pengguna baru wajib **Daftar** dulu sebelum bisa Masuk.

## Menjalankan

Lihat **[PANDUAN.md](PANDUAN.md)** untuk langkah lengkapnya. Ringkasnya:

```bash
flutter create --org id.mitafbr --project-name kulkasku --platforms=android,web .
dart run tool/setup.dart
flutter pub get
flutter run -d chrome
```

## Kredit

- Gambar sayur & ikon 3D: [Fluent Emoji](https://github.com/microsoft/fluentui-emoji) © Microsoft Corporation, MIT License.
- Font: DM Serif Display & Nunito, Google Fonts (SIL Open Font License).
- Maskot Mumu, desain kulkas, dan navbar ranting: karya asli Kulkasku.

## Lisensi

[MIT](LICENSE) © 2026 Mita. Boleh dipakai dan dikembangkan, **wajib mencantumkan nama pembuat** dan teks lisensi.
