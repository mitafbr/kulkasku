import '../data/models.dart';

/// Versi web: tidak ada notifikasi terjadwal & kalender HP.
class PengingatService {
  PengingatService._();
  static final PengingatService instance = PengingatService._();

  bool get didukung => false;
  String get izin => 'denied';

  Future<void> init() async {}
  Future<void> mintaIzin() async {}
  Future<void> jadwalkan(List<Bahan> bahan, {required String jam, required bool aktif}) async {}
}
