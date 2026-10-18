import 'package:flutter/material.dart';

import 'pages/splash_page.dart';
import 'services/google_login.dart';
import 'services/pengingat_service.dart';
import 'services/suara.dart';
import 'theme.dart';

/// Kulkasku — pengingat sayur & buah di kulkas sebelum layu.
/// Dibuat oleh Miftachul Jannah Wigno Febriyani (Mita), Tugas Akhir BTNG 2026 Divisi Mobile.
/// MIT License © 2026 Mita.
void main() {
  // Catat alamat web sebelum Flutter berjalan (berisi token setelah login Google).
  GoogleLogin.catatUrlAwal();
  WidgetsFlutterBinding.ensureInitialized();
  PengingatService.instance.init();
  Suara.i.init();
  runApp(const KulkaskuApp());
}

class KulkaskuApp extends StatelessWidget {
  const KulkaskuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kulkasku',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Tampilan menyesuaikan layar: HP = tampilan mobile, laptop/PC = landscape.
      // Batasnya diatur di widgets/common.dart (batasLebar).
      // setiap ketukan berbunyi "pop", lagu mulai saat sentuhan pertama
      builder: (context, child) => PendengarKetukan(child: child ?? const SizedBox()),
      home: const SplashPage(),
    );
  }
}
