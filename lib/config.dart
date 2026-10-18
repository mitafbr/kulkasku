/// =====================================================================
///  KONFIGURASI KULKASKU
/// =====================================================================
///
/// Isi dua nilai di bawah ini dari dashboard Supabase kamu:
///   Supabase > Project Settings > API
///     - Project URL      -> supabaseUrl
///     - anon public key  -> supabaseAnonKey
///
/// Kalau dua-duanya dibiarkan kosong, aplikasi berjalan dalam MODE LOKAL:
/// data tersimpan di HP / browser masing-masing (shared_preferences),
/// tidak ada akun bawaan; setiap orang (termasuk pembuat) wajib Daftar dulu.
///
/// Anon key memang aman ditaruh di kode (sudah dilindungi Row Level Security
/// di file supabase/setup.sql). JANGAN pernah menaruh "service_role" key di sini.
class AppConfig {
  static const String supabaseUrl = 'https://rqtfonlnsmqlrykvioyf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxdGZvbmxuc21xbHJ5a3Zpb3lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyOTMxMDMsImV4cCI6MjEwNzg2OTEwM30.kzCnpGoI3OOyuwQOEtu-HL13GlcNzWlMjDTDBRlurG8';

  /// Nama bucket Storage untuk foto profil (dibuat oleh supabase/setup.sql).
  static const String bucketFoto = 'avatar';

  /// Repo GitHub kamu (dipakai untuk link "Unduh APK" & halaman Tentang).
  static const String githubRepo = 'mitafbr/kulkasku';
  static String get linkApk => 'https://github.com/$githubRepo/releases/latest/download/app-release.apk';
  static String get linkRepo => 'https://github.com/$githubRepo';

  static bool get pakaiSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
