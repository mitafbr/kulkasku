import 'package:url_launcher/url_launcher.dart';

import '../data/katalog.dart';
import '../data/logic.dart';
import '../data/models.dart';

/// Membuka Google Calendar (aplikasi Kalender di HP, atau browser di web)
/// dengan acara "X layu" yang sudah terisi tanggalnya. Tinggal tekan Simpan.
Future<bool> simpanKeKalender(Bahan b) {
  final l = Hitung.tanggalLayu(b);
  final besok = tambahHari(l, 1);
  String f(DateTime d) => isoTanggal(d).replaceAll('-', '');
  final uri = Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': '${b.nama} layu (Kulkasku)',
    'dates': '${f(l)}/${f(besok)}',
    'details': 'Segera dimasak sebelum layu. Disimpan di ${tempatLabel[b.tempat] ?? b.tempat}. Pengingat dari aplikasi Kulkasku.',
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
