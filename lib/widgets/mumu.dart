import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme.dart';

/// Ekspresi Mumu.
enum MumuMood { idle, senang, sedih, tanya, malu, intip, geli }

/// Pose lengkap Mumu yang digambar oleh [MumuPainter].
class MumuPose {
  final MumuMood mood;
  final double capDy; // topi turun (menutup mata) / naik (angkat topi)
  final double capRot; // radian
  final double kedip; // 1 = mata terbuka, 0 = tertutup
  final Offset pupil; // arah lirikan (-1..1)
  final Offset tanganKiri;
  final Offset tanganKanan;
  final double tanganBesar;
  final double napas; // 0..1
  final double lompat; // piksel ke atas (dalam viewBox 200)

  const MumuPose({
    this.mood = MumuMood.idle,
    this.capDy = 0,
    this.capRot = 0,
    this.kedip = 1,
    this.pupil = Offset.zero,
    this.tanganKiri = Offset.zero,
    this.tanganKanan = Offset.zero,
    this.tanganBesar = 1,
    this.napas = 0,
    this.lompat = 0,
  });
}

/// Penggambar maskot Mumu (jamur dongeng bertopi merah bintik putih).
/// Koordinat memakai kotak 200 x 200 lalu diskalakan.
class MumuPainter extends CustomPainter {
  final MumuPose p;
  MumuPainter(this.p);

  static const _ol = AppColors.mumuOutline;

  Path _blob(double x, double y, double r, double rotDeg) {
    final path = Path()
      ..moveTo(-r, 0)
      ..cubicTo(-r, -r * .8, -r * .3, -r * .95, r * .2, -r * .9)
      ..cubicTo(r * .9, -r * .8, r * 1.05, -r * .1, r * .85, r * .4)
      ..cubicTo(r * .6, r * .95, -r * .4, r * .95, -r * .8, r * .55)
      ..cubicTo(-r, r * .35, -r, r * .2, -r, 0)
      ..close();
    return path.transform(Matrix4.rotationZ(rotDeg * math.pi / 180).storage).shift(Offset(x, y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 200;
    canvas.save();
    canvas.scale(k, k);

    // bayangan
    final bayangSkala = 1 - (p.lompat / 60).clamp(0.0, .5);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 190), width: 104 * bayangSkala, height: 14 * bayangSkala),
      Paint()..color = const Color(0xFF5A4026).withValues(alpha: .16 * bayangSkala),
    );

    canvas.save();
    canvas.translate(0, -p.lompat);
    // napas: sedikit melebar & memendek dari bawah
    final sx = 1 + .012 * p.napas, sy = 1 - .012 * p.napas;
    canvas.translate(100, 188);
    canvas.scale(sx, sy);
    canvas.translate(-100, -188);

    final garis = Paint()
      ..color = _ol.withValues(alpha: .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // kaki
    for (final x in [80.0, 120.0]) {
      final r = Rect.fromCenter(center: Offset(x, 184), width: 24, height: 12);
      canvas.drawOval(r, Paint()..color = const Color(0xFFE3CFB0));
      canvas.drawOval(r, garis..strokeWidth = 1.5);
    }

    // batang (badan)
    final batang = Path()
      ..moveTo(64, 96)
      ..cubicTo(54, 128, 52, 156, 62, 172)
      ..cubicTo(72, 186, 128, 186, 138, 172)
      ..cubicTo(148, 156, 146, 128, 136, 96)
      ..close();
    canvas.drawPath(
      batang,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFEFE0C6), Color(0xFFFFFBF3), Color(0xFFEBD9BB)], stops: [0, .45, 1])
            .createShader(const Rect.fromLTWH(52, 96, 96, 90)),
    );
    canvas.drawPath(batang, garis..strokeWidth = 2);

    // bayangan di bawah topi (menyatukan topi & badan)
    final bawahTopi = Path()
      ..moveTo(62, 110)
      ..cubicTo(80, 122, 120, 122, 138, 110)
      ..lineTo(138, 126)
      ..cubicTo(120, 134, 80, 134, 62, 126)
      ..close();
    canvas.drawPath(
      bawahTopi,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFB98A5C).withValues(alpha: .35), const Color(0xFFB98A5C).withValues(alpha: 0)],
        ).createShader(const Rect.fromLTWH(62, 110, 76, 24)),
    );

    // pipi
    for (final x in [66.0, 134.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 160), width: 22, height: 13),
          Paint()..color = AppColors.blush.withValues(alpha: .6));
    }

    _mata(canvas);
    _mulut(canvas);

    if (p.mood == MumuMood.sedih) {
      final tetes = Path()
        ..moveTo(142, 112)
        ..cubicTo(138, 120, 138, 124, 142, 125)
        ..cubicTo(146, 124, 146, 120, 142, 112)
        ..close();
      canvas.drawPath(tetes, Paint()..color = const Color(0xFFCFE9F5));
    }

    // tangan
    _tangan(canvas, const Offset(52, 150) + p.tanganKiri);
    _tangan(canvas, const Offset(148, 148) + p.tanganKanan);

    // topi
    canvas.save();
    canvas.translate(0, p.capDy);
    canvas.translate(100, 112);
    canvas.rotate(p.capRot);
    canvas.translate(-100, -112);
    final topi = Path()
      ..moveTo(24, 108)
      ..cubicTo(18, 62, 56, 28, 100, 28)
      ..cubicTo(144, 28, 182, 62, 176, 108)
      ..cubicTo(178, 118, 160, 122, 148, 116)
      ..cubicTo(128, 108, 72, 108, 52, 116)
      ..cubicTo(40, 122, 22, 118, 24, 108)
      ..close();
    canvas.drawPath(
      topi,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.24, -.44),
          radius: .9,
          colors: [Color(0xFFFF7A66), Color(0xFFE9402F), Color(0xFFC82E22)],
          stops: [0, .55, 1],
        ).createShader(const Rect.fromLTWH(18, 28, 164, 96)),
    );
    canvas.drawPath(
        topi,
        Paint()
          ..color = _ol
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round);
    final putih = Paint()..color = const Color(0xFFFFF7EC);
    for (final b in [
      [64.0, 62.0, 13.0, 10.0],
      [112.0, 46.0, 9.0, -20.0],
      [146.0, 80.0, 11.0, 30.0],
      [42.0, 94.0, 7.0, 0.0],
      [96.0, 84.0, 8.0, 60.0],
      [134.0, 102.0, 6.0, 0.0],
      [162.0, 100.0, 5.0, 0.0],
    ]) {
      canvas.drawPath(_blob(b[0], b[1], b[2], b[3]), putih);
    }
    final kilau = Path()
      ..moveTo(46, 72)
      ..cubicTo(56, 50, 74, 38, 92, 36);
    canvas.drawPath(
        kilau,
        Paint()
          ..color = Colors.white.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  void _tangan(Canvas canvas, Offset c) {
    final r = Rect.fromCenter(center: c, width: 18 * p.tanganBesar, height: 20 * p.tanganBesar);
    canvas.drawOval(r, Paint()..color = const Color(0xFFFFF6E8));
    canvas.drawOval(
        r,
        Paint()
          ..color = _ol.withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
  }

  void _mata(Canvas canvas) {
    final tutup = p.mood == MumuMood.malu || p.mood == MumuMood.senang;
    final hitam = Paint()..color = AppColors.mumuEye;
    if (tutup) {
      final g = Paint()
        ..color = AppColors.mumuEye
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      for (final x in [82.0, 118.0]) {
        final path = Path()
          ..moveTo(x - 11, 141)
          ..quadraticBezierTo(x, 132, x + 11, 141);
        canvas.drawPath(path, g);
      }
      return;
    }
    final intip = p.mood == MumuMood.intip;
    for (final x in [82.0, 118.0]) {
      if (intip && x == 82) {
        final g = Paint()
          ..color = AppColors.mumuEye
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
            Path()
              ..moveTo(x - 11, 141)
              ..quadraticBezierTo(x, 132, x + 11, 141),
            g);
        continue;
      }
      canvas.save();
      canvas.translate(x, 140);
      canvas.scale(1, p.kedip.clamp(0.08, 1.0));
      canvas.translate(p.pupil.dx * 4, p.pupil.dy * 3.5);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 24, height: 28), hitam);
      canvas.drawOval(Rect.fromCenter(center: const Offset(-4, -6), width: 10, height: 11.2), Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(5, 6), 2.2, Paint()..color = Colors.white.withValues(alpha: .9));
      canvas.drawOval(Rect.fromCenter(center: const Offset(0, 7.7), width: 14, height: 6),
          Paint()..color = const Color(0xFF6B4A3A).withValues(alpha: .45));
      canvas.restore();
    }
    if (p.mood == MumuMood.sedih) {
      final alis = Paint()
        ..color = AppColors.mumuEye
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(70, 121), const Offset(88, 126), alis);
      canvas.drawLine(const Offset(130, 121), const Offset(112, 126), alis);
    }
  }

  void _mulut(Canvas canvas) {
    final garis = Paint()
      ..color = const Color(0xFF6B2E24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final isi = Paint()..color = const Color(0xFFB5473A);
    switch (p.mood) {
      case MumuMood.senang:
      case MumuMood.geli:
        final m = Path()
          ..moveTo(89, 157)
          ..quadraticBezierTo(100, 175, 111, 157)
          ..quadraticBezierTo(100, 162, 89, 157)
          ..close();
        canvas.drawPath(m, isi);
        canvas.drawPath(m, garis);
      case MumuMood.sedih:
        canvas.drawPath(
            Path()
              ..moveTo(91, 167)
              ..quadraticBezierTo(100, 158, 109, 167),
            garis);
      case MumuMood.tanya:
        canvas.drawOval(Rect.fromCenter(center: const Offset(100, 163), width: 8, height: 10), isi);
      case MumuMood.malu:
      case MumuMood.intip:
        canvas.drawPath(
            Path()
              ..moveTo(90, 158)
              ..quadraticBezierTo(100, 169, 110, 158),
            garis);
      case MumuMood.idle:
        canvas.drawPath(
            Path()
              ..moveTo(92, 160)
              ..quadraticBezierTo(96, 165, 100, 160)
              ..quadraticBezierTo(104, 165, 108, 160),
            garis);
    }
  }

  @override
  bool shouldRepaint(MumuPainter old) => true;
}

/// Mumu kecil (statis tapi melayang pelan) untuk layar kosong, kartu basi, FAQ, dll.
class MumuMini extends StatefulWidget {
  final double size;
  final MumuMood mood;
  const MumuMini({super.key, this.size = 80, this.mood = MumuMood.idle});

  @override
  State<MumuMini> createState() => _MumuMiniState();
}

class _MumuMiniState extends State<MumuMini> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mumu',
      image: true,
      child: RepaintBoundary(child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * math.pi * 2;
          final napas = .5 - .5 * math.cos(t);
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: MumuPainter(MumuPose(
                    mood: widget.mood,
                    napas: napas,
                    lompat: 4 * napas,
                    capRot: widget.mood == MumuMood.sedih ? .07 : 0,
                    capDy: widget.mood == MumuMood.sedih ? 4 : 0,
                  )),
                ),
              ),
              if (widget.mood == MumuMood.tanya)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Text('?', style: AppText.display(widget.size * .28, color: AppColors.mumuRed, italic: false)),
                ),
              if (widget.mood == MumuMood.senang)
                Positioned(
                  right: widget.size * .02,
                  top: widget.size * .05,
                  child: Icon(Icons.auto_awesome, size: widget.size * .2, color: const Color(0xFFFFC93C)),
                ),
            ]),
          );
        },
      )),
    );
  }
}

/// Mumu interaktif untuk halaman Masuk/Daftar.
/// Panggil method-nya lewat GlobalKey<MumuHidupState>.
class MumuHidup extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  const MumuHidup({super.key, this.size = 172, this.onTap});

  @override
  State<MumuHidup> createState() => MumuHidupState();
}

class MumuHidupState extends State<MumuHidup> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _waktu = Duration.zero;
  final _rnd = math.Random();

  MumuMood mood = MumuMood.idle;
  bool _malu = false;
  bool _intip = false;
  bool _angkatTopi = false;
  bool _lambai = true;
  double _lompatT = -1; // detik sejak mulai lompat, -1 = tidak lompat
  double _geliT = -1;
  double _sedihT = -1;

  // nilai yang dihaluskan
  double _capDy = 0, _capRot = 0, _kedip = 1;
  Offset _pupil = Offset.zero, _pupilTarget = Offset.zero;
  Offset _tKiri = Offset.zero, _tKanan = Offset.zero;
  double _tBesar = 1;
  Offset? _kunciLirik;
  Timer? _kedipTimer;
  Timer? _lambaiTimer;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      final dt = (d - _waktu).inMicroseconds / 1e6;
      _waktu = d;
      _langkah(dt.clamp(0, .05).toDouble());
    })
      ..start();
    _jadwalKedip();
    _lambaiTimer = Timer(const Duration(milliseconds: 2000), () => _lambai = false);
  }

  void _jadwalKedip() {
    _kedipTimer = Timer(Duration(milliseconds: 1800 + _rnd.nextInt(3200)), () {
      if (!mounted) return;
      if (!_malu) {
        setState(() => _kedip = 0.08);
        Timer(const Duration(milliseconds: 130), () {
          if (mounted) setState(() => _kedip = 1);
        });
      }
      _jadwalKedip();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _kedipTimer?.cancel();
    _lambaiTimer?.cancel();
    super.dispose();
  }

  double _halus(double now, double target, double dt, [double kecepatan = 10]) =>
      now + (target - now) * (1 - math.exp(-kecepatan * dt));
  Offset _halusO(Offset now, Offset target, double dt, [double kecepatan = 10]) =>
      Offset(_halus(now.dx, target.dx, dt, kecepatan), _halus(now.dy, target.dy, dt, kecepatan));

  void _langkah(double dt) {
    if (!mounted) return;
    final t = _waktu.inMicroseconds / 1e6;
    // target topi
    double capDy = 0, capRot = 0;
    if (_malu) {
      capDy = _intip ? 18 : 32;
      capRot = _intip ? -.28 : 0;
    } else if (_angkatTopi) {
      capDy = -14;
      capRot = -.14;
    } else if (_sedihT >= 0) {
      capDy = 7;
      capRot = .07;
    }
    // target tangan
    Offset kiri = Offset.zero, kanan = Offset.zero;
    double besar = 1;
    if (_malu) {
      kiri = const Offset(14, -40);
      kanan = _intip ? const Offset(-4, -22) : const Offset(-14, -42);
      besar = 1.4;
    } else if (_lompatT >= 0 || _angkatTopi) {
      kiri = const Offset(-6, -40);
      kanan = const Offset(6, -42);
    } else if (_lambai) {
      kanan = Offset(6, -30 + 6 * math.sin(t * 14));
    }
    _capDy = _halus(_capDy, capDy, dt, 9);
    _capRot = _halus(_capRot, capRot, dt, 9);
    _tKiri = _halusO(_tKiri, kiri, dt, 12);
    _tKanan = _lambai && !_malu ? kanan : _halusO(_tKanan, kanan, dt, 12);
    _tBesar = _halus(_tBesar, besar, dt, 10);
    _pupil = _halusO(_pupil, _kunciLirik ?? _pupilTarget, dt, 8);

    if (_lompatT >= 0) _lompatT += dt;
    if (_lompatT > 1.5) _lompatT = -1;
    if (_geliT >= 0) _geliT += dt;
    if (_geliT > .9) _geliT = -1;
    if (_sedihT >= 0) _sedihT += dt;
    if (_sedihT > 1.8) {
      _sedihT = -1;
      if (mood == MumuMood.sedih) mood = MumuMood.idle;
    }
    setState(() {});
  }

  // ---------------------------------------------------------------- API
  void lirik(Offset globalPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final c = box.localToGlobal(Offset(box.size.width / 2, box.size.height * .7));
    final d = globalPos - c;
    final jarak = d.distance;
    if (jarak < 1) return;
    final k = (jarak / 160).clamp(0.0, 1.0);
    _pupilTarget = Offset(d.dx / jarak * k, d.dy / jarak * k);
  }

  void kunciLirik(Offset? arah) => _kunciLirik = arah;

  void malu(bool on, {bool intip = false}) {
    _malu = on;
    _intip = on && intip;
    mood = on ? (intip ? MumuMood.intip : MumuMood.malu) : MumuMood.idle;
  }

  void sedih() {
    _malu = false;
    _intip = false;
    _sedihT = 0;
    mood = MumuMood.sedih;
  }

  void senang({bool angkatTopi = true}) {
    _malu = false;
    _angkatTopi = angkatTopi;
    _lompatT = 0;
    mood = MumuMood.senang;
  }

  void geli() {
    _geliT = 0;
    _angkatTopi = true;
    mood = MumuMood.geli;
    Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      _angkatTopi = false;
      if (mood == MumuMood.geli) mood = MumuMood.idle;
    });
  }

  void kaget() => mood = MumuMood.tanya;
  void biasa() => mood = MumuMood.idle;

  @override
  Widget build(BuildContext context) {
    final t = _waktu.inMicroseconds / 1e6;
    final napas = .5 - .5 * math.cos(t * math.pi * 2 / 3.4);
    final melayang = 8 * (.5 - .5 * math.cos(t * math.pi * 2 / 4.2));
    double lompat = 0;
    if (_lompatT >= 0) {
      final u = (_lompatT % .75) / .75;
      lompat = 30 * math.sin(u * math.pi);
    }
    double goyang = 0;
    if (_geliT >= 0) goyang = .08 * math.exp(-4 * _geliT) * math.sin(_geliT * 22);
    final skalaGeli = _geliT >= 0 ? 1 + .08 * math.exp(-5 * _geliT) * math.cos(_geliT * 18) : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Transform.translate(
        offset: Offset(0, -melayang * widget.size / 172),
        child: Transform.rotate(
          angle: goyang,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scaleX: skalaGeli,
            scaleY: 2 - skalaGeli,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: MumuPainter(MumuPose(
                mood: mood,
                capDy: _capDy,
                capRot: _capRot,
                kedip: _kedip,
                pupil: _pupil,
                tanganKiri: _tKiri,
                tanganKanan: _tKanan,
                tanganBesar: _tBesar,
                napas: napas,
                lompat: lompat,
              )),
            ),
          ),
        ),
      ),
    );
  }
}
