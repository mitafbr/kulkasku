# Panduan Kulkasku (langkah demi langkah)

Panduan ini untuk laptop Windows yang sudah terpasang Flutter (misalnya di `E:\flutter`) dan Android SDK.

---

## 0. Yang perlu disiapkan

| Kebutuhan | Cara cek / pasang |
|---|---|
| Flutter | Buka CMD, ketik `flutter --version` |
| Git | Ketik `git --version`. Kalau belum ada, unduh di https://git-scm.com/download/win lalu install (klik Next terus) |
| VS Code + ekstensi **Flutter** | Di VS Code: Extensions → cari "Flutter" → Install |
| Akun GitHub | `mitafbr` |
| Akun Supabase (gratis) | Daftar di https://supabase.com pakai akun GitHub |

---

## 1. Buka proyek di VS Code

1. Ekstrak `Kulkasku-Flutter.zip`, misalnya ke `F:\CODINGAN\kulkasku-app`.
   - Kalau sebelumnya sudah ada folder Kulkasku versi lama, **hapus dulu folder lamanya**, baru ekstrak yang baru.
2. VS Code → **File → Open Folder** → pilih folder `kulkasku`.
3. Buka terminal: **Terminal → New Terminal**.
4. Jalankan **sekali saja** (membuat folder `android/` dan `web/`, lalu memasang ikon Mumu, izin notifikasi, dll.):

```bash
flutter create --org id.mitafbr --project-name kulkasku --platforms=android,web .
dart run tool/setup.dart
flutter pub get
```

5. Coba jalankan:

```bash
flutter run -d chrome      # versi web di Chrome
flutter run -d edge        # versi web di Edge
flutter run                # versi Android (HP via USB / emulator)
```

**Mau buka di Opera (atau browser lain)?**

```bash
flutter run -d web-server --web-port 8080 --release
```

Tunggu sampai muncul `http://localhost:8080`, lalu buka alamat itu di Opera.

> **Kenapa pakai `--release`?** Tanpa itu, Flutter berjalan dalam mode *debug*
> yang sengaja lambat (untuk memudahkan mencari error). Dengan `--release`,
> animasi jadi mulus dan web terasa jauh lebih cepat. Versi yang nanti tayang
> di GitHub Pages juga memakai mode release.
>
> Tampilan otomatis menyesuaikan layar: di HP tampil versi mobile, di laptop/PC
> tampil versi landscape (menu di kiri). Untuk mencoba tampilan HP di laptop,
> tekan **Ctrl + Shift + M** (Opera/Chrome/Edge) lalu pilih ukuran HP.

Saat `config.dart` masih kosong, aplikasi jalan di **mode lokal**: data hanya tersimpan di browser/HP itu saja. Belum ada akun bawaan: buka tab **Daftar** dan buat akunmu sendiri. Catat akunmu di **CATATAN-ADMIN.md** (file itu tidak ikut ter-upload ke GitHub).

> Kalau muncul error merah, salin seluruh pesannya ke Claude.
> Bisa juga jalankan `flutter analyze` untuk melihat semua masalah sekaligus.

---

## 2. Sambungkan ke Supabase (supaya data tersimpan online)

1. Di https://supabase.com → **New project**.
   - Name: `kulkasku`
   - Database Password: buat lalu **simpan baik-baik**
   - Region: **Southeast Asia (Singapore)**

> **Kenapa perlu Supabase?** Selama `config.dart` kosong, data cuma tersimpan di
> browser/HP masing-masing (mode lokal). Setelah Supabase diisi, **semua data
> tersimpan online**: akun, isi kulkas (jenis sayur, jumlah, tanggal beli, tempat),
> riwayat, catatan, suhu kulkas, dan foto profil. Datanya bisa dibuka dari HP
> maupun laptop dengan akun yang sama, dan kamu bisa melihatnya di Supabase →
> **Table Editor**.
2. Tunggu ±2 menit sampai project siap.
3. Menu kiri **SQL Editor** → **New query** → buka file `supabase/setup.sql`, salin **semua** isinya, tempel, lalu klik **Run**. Harus muncul "Success".
4. Menu **Authentication → Sign In / Providers → Email**:
   - Matikan **Confirm email** supaya akun baru bisa langsung masuk (untuk tugas ini lebih praktis).
5. Menu **Project Settings → API** (atau **Data API**). Salin dua nilai ini:
   - **Project URL**, contoh `https://abcdxyz.supabase.co`
   - **anon public** key (kunci panjang yang diawali `eyJ...`)
6. Buka `lib/config.dart`, lalu isi:

```dart
static const String supabaseUrl = 'https://abcdxyz.supabase.co';
static const String supabaseAnonKey = 'eyJ....';
```

7. Jalankan lagi `flutter run -d chrome`, lalu coba **Daftar** akun baru. Datanya akan muncul di Supabase → **Table Editor**.

> ⚠️ Yang boleh ditaruh di kode hanya **anon key**. **Service role key JANGAN PERNAH** ditaruh di kode atau di GitHub.
> Paket gratis Supabase "tidur" kalau 7 hari tidak dipakai. Kalau web tiba-tiba gagal masuk, buka dashboard Supabase lalu klik **Restore project**.

---

## 2b. (Opsional) Masuk / Daftar dengan Google

Tombol **Masuk dengan Google** baru berfungsi setelah langkah 2 (Supabase) selesai. Gratis, sekitar 10 menit.

**A. Buat kunci OAuth di Google Cloud**
1. Buka https://console.cloud.google.com → pilih/buat project baru, misalnya `kulkasku`.
2. Menu **APIs & Services → OAuth consent screen** (atau **Google Auth Platform → Branding**):
   - User type: **External**, App name: `Kulkasku`, isi email kamu → Save.
   - Di bagian **Audience**, klik **Publish app** (supaya semua akun Google bisa masuk, bukan hanya akun uji).
3. Menu **Credentials → Create credentials → OAuth client ID**:
   - Application type: **Web application**, Name: `Kulkasku Supabase`
   - **Authorized redirect URIs** → Add URI:
     `https://ID-PROJECT-KAMU.supabase.co/auth/v1/callback`
     (ganti dengan Project URL Supabase-mu, tambahkan `/auth/v1/callback`)
   - Create → salin **Client ID** dan **Client secret**.

**B. Nyalakan Google di Supabase**
1. Supabase → **Authentication → Sign In / Providers → Google** → Enable.
2. Tempel **Client ID** dan **Client secret** → Save.
3. Supabase → **Authentication → URL Configuration**:
   - **Site URL**: `https://mitafbr.github.io/kulkasku/`
   - **Redirect URLs** → tambahkan tiga alamat ini:
     - `http://localhost:8080/**` (untuk coba di laptop)
     - `https://mitafbr.github.io/kulkasku/**` (web publik)
     - `kulkasku://login-callback` (APK Android)

**C. Jalankan ulang**
```bash
dart run tool/setup.dart
flutter pub get
flutter run -d web-server --web-port 8080 --release
```
Akun Google otomatis dibuatkan profil (nama, email, dan foto dari Google). Username dibuat dari email.

> Saat mencoba di laptop, buka lewat `http://localhost:8080` (bukan 127.0.0.1) supaya cocok dengan Redirect URLs.

---

## 3. Upload ke GitHub

1. Buka https://github.com/new
   - Repository name: `kulkasku`
   - Pilih **Public**
   - **Jangan** centang "Add a README" (README sudah ada di proyek)
   - Klik **Create repository**
2. Di terminal VS Code (folder proyek), jalankan satu per satu:

```bash
git init
git add .
git commit -m "Kulkasku v1.0 - tugas akhir BTNG 2026 oleh Mita"
git branch -M main
git remote add origin https://github.com/mitafbr/kulkasku.git
git push -u origin main
```

Saat pertama push, akan muncul jendela login GitHub. Login saja, lalu tunggu sampai selesai.

> Kalau muncul `Author identity unknown`, jalankan dulu:
> `git config --global user.name "Mita"` dan
> `git config --global user.email "email-github-kamu"`

---

## 4. Tayangkan web + buat APK otomatis (gratis)

1. Di repo GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Buka tab **Actions**. Workflow **Build Kulkasku (Web + APK)** berjalan otomatis setiap kamu push. Tunggu ±5–8 menit sampai semuanya centang hijau ✅.
   - Kalau belum jalan, klik workflow-nya lalu **Run workflow**.
3. Hasilnya:
   - **Web**: `https://mitafbr.github.io/kulkasku/`
   - **APK**: halaman **Releases** di repo, file `app-release.apk`. Link unduh langsung:
     `https://github.com/mitafbr/kulkasku/releases/latest/download/app-release.apk`
   - Di versi web ada tombol **Unduh APK Android** yang memakai link itu.

Cara memasang APK di HP: unduh `app-release.apk`, buka file-nya, izinkan **Instal dari sumber tidak dikenal**, lalu Install.

> Kalau ada job yang merah ❌, klik job-nya, salin pesan error-nya, lalu kirim ke Claude.

---

## 5. Kalau ada perubahan kode

```bash
git add .
git commit -m "pesan perubahan"
git push
```

Web dan APK otomatis dibangun ulang.

---

## 6. Hak cipta & keamanan

- **LICENSE (MIT © 2026 Mita)**: siapa pun yang memakai kodenya **wajib** mencantumkan namamu dan teks lisensi. Namamu juga tampil di halaman **Tentang** di dalam aplikasi.
- Repo **public** berarti kodenya bisa dibaca orang. Itu yang membuat web gratis di GitHub Pages.
  - Kalau mau **kodenya private tapi web tetap online**, perlu GitHub Pro. Sebagai mahasiswa kamu bisa dapat **gratis** lewat **GitHub Student Developer Pack** (https://education.github.com/pack, daftar pakai email kampus).
- Yang tidak boleh bocor sudah diamankan:
  - Kata sandi pengguna dienkripsi oleh Supabase.
  - Tiap akun hanya bisa membaca datanya sendiri (Row Level Security).
  - File rahasia (`*.jks`, `key.properties`, `.env`) sudah masuk `.gitignore`.

---

## 7. (Opsional) Domain sendiri

Kalau nanti membeli domain (misalnya `kulkasku.my.id`):
1. Repo → **Settings → Pages → Custom domain** → isi `kulkasku.my.id` → Save.
2. Di panel DNS penjual domain, buat record **CNAME** `www` → `mitafbr.github.io`, dan record **A** untuk `@` ke IP GitHub Pages:
   `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`.
3. Ubah `--base-href` di `.github/workflows/build.yml` menjadi `"/"`, lalu push.
