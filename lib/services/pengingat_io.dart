import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/logic.dart';
import '../data/models.dart';

/// Notifikasi HP (H-1 & hari-H) dan kalender HP.
/// File ini hanya dipakai di Android (lihat pengingat_service.dart).
class PengingatService {
  PengingatService._();
  static final PengingatService instance = PengingatService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _siap = false;

  bool get didukung => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  String get izin => 'granted';

  Future<void> init() async {
    if (!didukung || _siap) return;
    try {
      tzdata.initializeTimeZones();
      final offset = DateTime.now().timeZoneOffset.inHours;
      final nama = switch (offset) {
        8 => 'Asia/Makassar',
        9 => 'Asia/Jayapura',
        _ => 'Asia/Jakarta',
      };
      tz.setLocalLocation(tz.getLocation(nama));
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      _siap = true;
    } catch (e) {
      debugPrint('Notifikasi tidak bisa disiapkan: $e');
    }
  }

  Future<void> mintaIzin() async {
    if (!didukung) return;
    await init();
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Menyusun ulang semua notifikasi terjadwal dari daftar bahan.
  Future<void> jadwalkan(List<Bahan> bahan, {required String jam, required bool aktif}) async {
    if (!didukung) return;
    await init();
    if (!_siap) return;
    try {
      await _plugin.cancelAll();
      if (!aktif) return;
      final bagian = jam.split(':');
      final hh = int.tryParse(bagian.first) ?? 7;
      final mm = bagian.length > 1 ? int.tryParse(bagian[1]) ?? 0 : 0;
      final now = tz.TZDateTime.now(tz.local);
      const detail = NotificationDetails(
        android: AndroidNotificationDetails(
          'pengingat_layu',
          'Pengingat sayur & buah',
          channelDescription: 'Pengingat H-1 dan hari-H sebelum sayur/buah layu',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      var id = 0;
      for (final p in Hitung.jadwal(bahan)) {
        if (id >= 48) break; // batas aman jumlah alarm
        var waktu = tz.TZDateTime(tz.local, p.tanggal.year, p.tanggal.month, p.tanggal.day, hh, mm);
        if (waktu.isBefore(now)) {
          if (p.jenis == 'h1') continue;
          waktu = now.add(const Duration(minutes: 1));
        }
        await _plugin.zonedSchedule(
          id++,
          p.judul,
          p.pesan,
          waktu,
          detail,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    }
  }
}
