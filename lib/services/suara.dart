import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Suara klik & lagu latar Kulkasku (web dan APK).
///
/// Browser tidak mengizinkan lagu berbunyi sebelum pengguna menyentuh layar,
/// jadi lagu baru dimulai saat sentuhan pertama.
class Suara extends ChangeNotifier {
  Suara._();
  static final Suara i = Suara._();

  static const _kKlik = 'kulkasku_suara_klik';
  static const _kMusik = 'kulkasku_suara_musik';
  static const _volMusik = .32;

  bool klikAktif = true;
  bool musikAktif = true;

  final AudioPlayer _lagu = AudioPlayer(playerId: 'kulkasku-lagu');
  final List<AudioPlayer> _klik = List.generate(3, (n) => AudioPlayer(playerId: 'kulkasku-klik-$n'));
  int _giliran = 0;
  bool _laguJalan = false;
  bool _sudahDisentuh = false;

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      klikAktif = p.getBool(_kKlik) ?? true;
      musikAktif = p.getBool(_kMusik) ?? true;
      await _lagu.setReleaseMode(ReleaseMode.loop);
      for (final k in _klik) {
        await k.setReleaseMode(ReleaseMode.stop);
        await k.setSource(AssetSource('audio/klik.mp3'));
      }
    } catch (_) {}
  }

  /// Bunyi "pop" kecil.
  void klik() {
    if (!klikAktif) return;
    try {
      final p = _klik[_giliran];
      _giliran = (_giliran + 1) % _klik.length;
      p.stop().then((_) => p.play(AssetSource('audio/klik.mp3'), volume: .55));
    } catch (_) {}
  }

  /// Dipanggil setiap layar disentuh.
  void disentuh() {
    if (!_sudahDisentuh) {
      _sudahDisentuh = true;
      _mulaiLagu();
    }
  }

  Future<void> _mulaiLagu() async {
    if (!musikAktif || _laguJalan) return;
    try {
      _laguJalan = true;
      await _lagu.play(AssetSource('audio/lagu.mp3'), volume: _volMusik);
    } catch (_) {
      _laguJalan = false;
    }
  }

  Future<void> _hentikanLagu() async {
    _laguJalan = false;
    try {
      await _lagu.stop();
    } catch (_) {}
  }

  /// Saat aplikasi ditutup sementara / pindah tab.
  void jeda() {
    if (_laguJalan) _lagu.pause().catchError((_) {});
  }

  void lanjut() {
    if (_laguJalan && musikAktif) _lagu.resume().catchError((_) {});
  }

  Future<void> aturKlik(bool v) async {
    klikAktif = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kKlik, v);
  }

  Future<void> aturMusik(bool v) async {
    musikAktif = v;
    notifyListeners();
    if (v) {
      _sudahDisentuh = true;
      await _mulaiLagu();
    } else {
      await _hentikanLagu();
    }
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMusik, v);
  }
}

/// Membungkus seluruh aplikasi: setiap ketukan (bukan geser) berbunyi "pop".
class PendengarKetukan extends StatefulWidget {
  final Widget child;
  const PendengarKetukan({super.key, required this.child});
  @override
  State<PendengarKetukan> createState() => _PendengarKetukanState();
}

class _PendengarKetukanState extends State<PendengarKetukan> with WidgetsBindingObserver {
  final Map<int, (Offset, DateTime)> _turun = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      Suara.i.lanjut();
    } else if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      Suara.i.jeda();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _turun[e.pointer] = (e.position, DateTime.now());
        Suara.i.disentuh();
      },
      onPointerUp: (e) {
        final d = _turun.remove(e.pointer);
        if (d == null) return;
        final geser = (e.position - d.$1).distance;
        final lama = DateTime.now().difference(d.$2);
        if (geser < 12 && lama < const Duration(milliseconds: 450)) Suara.i.klik();
      },
      onPointerCancel: (e) => _turun.remove(e.pointer),
      child: widget.child,
    );
  }
}
