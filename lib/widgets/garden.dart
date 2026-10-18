import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';
import 'mumu.dart';

/// Taman kecil Mumu di halaman Masuk/Daftar.
class KebunScene extends StatefulWidget {
  final bool daftar;
  final GlobalKey<MumuHidupState> mumuKey;
  final VoidCallback onMumuTap;
  final ValueChanged<String> onPapanTap;
  const KebunScene({
    super.key,
    required this.daftar,
    required this.mumuKey,
    required this.onMumuTap,
    required this.onPapanTap,
    this.tinggi = 236,
    this.ukuranMumu = 172,
  });

  /// Tinggi taman (HP 236; di laptop dibuat setinggi layar).
  final double tinggi;
  final double ukuranMumu;

  @override
  State<KebunScene> createState() => KebunSceneState();
}

class KebunSceneState extends State<KebunScene> with TickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  late final AnimationController _pulang = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void dispose() {
    _t.dispose();
    _pulang.dispose();
    super.dispose();
  }

  /// Animasi setelah berhasil masuk: sayur masuk keranjang, Mumu berjalan ke dapur.
  Future<void> pulang() => _pulang.forward(from: 0);

  Offset _lerpJalur(List<Offset> titik, List<double> waktu, double u) {
    for (var i = 0; i < waktu.length - 1; i++) {
      if (u <= waktu[i + 1]) {
        final a = (u - waktu[i]) / (waktu[i + 1] - waktu[i]);
        final e = Curves.easeInOut.transform(a.clamp(0.0, 1.0));
        return Offset.lerp(titik[i], titik[i + 1], e)!;
      }
    }
    return titik.last;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = widget.tinggi;
      final m = widget.ukuranMumu;
      final km = m / 172; // skala Mumu & teman-temannya
      final sy = h / 236; // skala tinggi jalur terbang
      final tengah = w / 2;
      return SizedBox(
        height: h,
        child: AnimatedBuilder(
          animation: Listenable.merge([_t, _pulang]),
          builder: (context, _) {
            final t = _t.value;
            final p = _pulang.value;
            final keranjang = Curves.easeOutBack.transform((p / .25).clamp(0.0, 1.0));
            final masuk = Curves.easeInOut.transform(((p - .2) / .3).clamp(0.0, 1.0));
            final jalan = Curves.easeIn.transform(((p - .45) / .55).clamp(0.0, 1.0));
            final langkah = jalan > 0 ? math.sin(p * 40) * 5 : 0.0;

            // posisi kupu-kupu (hinggap di topi Mumu sekitar 34%-52% siklus)
            final topiMumu = Offset(tengah - 15 * km, h - m - 2);
            final kupu = _lerpJalur(
              [
                Offset(-40, 120 * sy),
                Offset(w * .15, 40 * sy),
                Offset(w * .3, 96 * sy),
                topiMumu,
                topiMumu,
                Offset(tengah + 70 * km, 30 * sy),
                Offset(math.min(w - 40, tengah + 140 * km), 90 * sy),
                Offset(w + 40, 20 * sy),
              ],
              const [0, .12, .24, .34, .52, .64, .78, 1],
              t,
            );
            final hinggap = t > .34 && t < .52;
            final lebah = _lerpJalur(
              [Offset(40, h - 36), Offset(110, h - 64), Offset(150, h - 42), Offset(w - 120, h - 56), Offset(w - 90, h - 70), Offset(180, h - 76), Offset(40, h - 36)],
              const [0, .2, .35, .5, .62, .8, 1],
              (t * 14 / 16) % 1,
            );

            return Stack(clipBehavior: Clip.none, children: [
              // langit, matahari, bukit jauh, pepohonan
              Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _LangitPainter(t, widget.daftar)))),
              // awan
              for (final a in [
                [16.0, 46.0, 1.0, 0.0],
                [62.0, 60.0, .8, .55],
                [34.0, 52.0, .7, .3],
              ])
                Positioned(
                  top: a[0] * sy,
                  left: ((t * 14 / a[1] + a[3]) % 1) * (w + 140) - 100,
                  child: Opacity(opacity: a[2], child: const _Awan()),
                ),
              // semak
              Positioned(left: -24, right: -24, bottom: 24, height: 60, child: CustomPaint(painter: _SemakPainter())),
              // tanah, rumput, bunga
              Positioned(
                left: -24,
                right: -24,
                bottom: -6,
                height: 70,
                child: CustomPaint(painter: _TanahPainter(t)),
              ),
              // papan kayu
              Positioned(
                left: 18,
                bottom: 22,
                child: JellyTap(
                  scale: .85,
                  onTap: () => widget.onPapanTap(widget.daftar ? 'Isi data, lalu tekan Daftar' : 'Selamat datang di dapurmu!'),
                  child: Transform.rotate(
                    angle: math.sin(t * math.pi * 2 * 3.5) * .035,
                    alignment: Alignment.bottomCenter,
                    child: _Papan(teks: widget.daftar ? 'DAFTAR ➜' : 'KULKASKU'),
                  ),
                ),
              ),
              // kerikil
              Positioned(left: 96, bottom: 6, child: _kerikil(14, 8)),
              Positioned(left: 110, bottom: 6, child: _kerikil(9, 6)),
              Positioned(right: 96, bottom: 6, child: _kerikil(12, 7)),
              // kepik
              Positioned(
                right: 30 + 10 * math.sin(t * math.pi * 4),
                bottom: 30 + 10 * (.5 - .5 * math.cos(t * math.pi * 4)),
                child: Transform.rotate(angle: math.sin(t * math.pi * 4) * .5, child: const _Kepik()),
              ),
              // teman sayur
              Positioned(
                left: tengah - 128 * km + (masuk * (82 + 28) * km),
                bottom: 6 + masuk * 70 - math.sin(masuk * math.pi) * -30,
                child: Opacity(
                  opacity: (1 - masuk * 1.2).clamp(0.0, 1.0),
                  child: Melayang(jarak: 6, fase: 0, child: Emo('tomat', size: 38 * km)),
                ),
              ),
              Positioned(
                left: tengah + 86 * km - masuk * 40 * km,
                bottom: 6 + masuk * 70,
                child: Opacity(
                  opacity: (1 - masuk * 1.2).clamp(0.0, 1.0),
                  child: Melayang(jarak: 6, fase: .4, child: Emo(widget.daftar ? 'tunas' : 'wortel', size: 40 * km)),
                ),
              ),
              // anak jamur saat Daftar
              if (widget.daftar) ...[
                Positioned(left: tengah - 98 * km, bottom: 4, child: _AnakJamur(size: 34 * km, tunda: 500)),
                Positioned(left: tengah + 66 * km, bottom: 4, child: _AnakJamur(size: 28 * km, tunda: 750)),
              ],
              // Mumu
              Positioned(
                left: tengah - m / 2 + jalan * (w * .7),
                bottom: 0 + langkah.abs(),
                child: Stack(clipBehavior: Clip.none, children: [
                  MumuHidup(key: widget.mumuKey, size: m, onTap: widget.onMumuTap),
                  if (keranjang > 0)
                    Positioned(
                      right: -8 * km,
                      top: 96 * km,
                      child: Transform.scale(scale: keranjang, child: Emo('keranjang', size: 46 * km)),
                    ),
                ]),
              ),
              // lebah
              Positioned(
                left: lebah.dx,
                top: lebah.dy,
                child: IgnorePointer(child: Transform.scale(scaleX: (t * 14 / 16) % 1 < .6 ? -1 : 1, child: const Emo('lebah', size: 22))),
              ),
              // kupu-kupu
              Positioned(
                left: kupu.dx,
                top: kupu.dy,
                child: IgnorePointer(child: _KupuKupu(kepak: hinggap ? .25 : 1, t: t)),
              ),
            ]);
          },
        ),
      );
    });
  }

  Widget _kerikil(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE6DCCB), Color(0xFFC9BBA3)]),
        ),
      );
}

class _Awan extends StatelessWidget {
  const _Awan();
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 70,
        height: 35,
        child: Stack(children: [
          Positioned(left: 6, top: 14, child: _bulat(40, 22)),
          Positioned(left: 22, top: 4, child: _bulat(36, 28)),
          Positioned(left: 40, top: 16, child: _bulat(30, 18)),
        ]),
      );
  Widget _bulat(double w, double h) =>
      Container(width: w, height: h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(h)));
}

class _Papan extends StatelessWidget {
  final String teks;
  const _Papan({required this.teks});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 66,
        height: 70,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 30, top: 30, child: Container(width: 6, height: 40, color: const Color(0xFF9C6A42))),
          Positioned(
            left: 2,
            top: 8,
            child: Container(
              width: 62,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFC99A68),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF8A5A36), width: 2),
              ),
              child: Text(teks, style: AppText.body(9, color: const Color(0xFFFFF6E2), weight: FontWeight.w900)),
            ),
          ),
          const Positioned(left: 4, top: -2, child: Emo('daun', size: 16)),
        ]),
      );
}

class _Kepik extends StatelessWidget {
  const _Kepik();
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(16, 14), painter: _KepikPainter());
}

class _KepikPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final hitam = Paint()..color = const Color(0xFF33231D);
    canvas.drawCircle(const Offset(8, 3), 3, hitam);
    canvas.drawOval(const Rect.fromLTWH(1, 2, 14, 12), Paint()..color = const Color(0xFFE9402F));
    canvas.drawLine(const Offset(8, 2), const Offset(8, 14), hitam..strokeWidth = 1);
    for (final o in const [Offset(5, 8), Offset(11, 8), Offset(5, 11.5), Offset(11, 11.5)]) {
      canvas.drawCircle(o, 1.3, hitam);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KupuKupu extends StatelessWidget {
  final double kepak;
  final double t;
  const _KupuKupu({required this.kepak, required this.t});
  @override
  Widget build(BuildContext context) {
    final s = .25 + .75 * (.5 + .5 * math.cos(t * math.pi * 2 * (kepak < 1 ? 12 : 60)));
    return CustomPaint(size: const Size(30, 24), painter: _KupuPainter(s));
  }
}

class _KupuPainter extends CustomPainter {
  final double sayap;
  _KupuPainter(this.sayap);
  @override
  void paint(Canvas canvas, Size size) {
    const oranye = Color(0xFFFFB86B), pink = Color(0xFFFF9C94);
    for (final arah in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(15, 12);
      canvas.scale(arah * sayap, 1);
      canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..cubicTo(-7, -12, -15, -10, -13, -3)
            ..cubicTo(-12, 1, -6, 2, 0, 0)
            ..close(),
          Paint()..color = oranye);
      canvas.drawPath(
          Path()
            ..moveTo(0, 1)
            ..cubicTo(-6, 3, -11, 8, -7, 10)
            ..cubicTo(-4, 11, -1, 6, 0, 1)
            ..close(),
          Paint()..color = pink);
      canvas.restore();
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 7, 2, 12), const Radius.circular(1)),
        Paint()..color = const Color(0xFF5A4026));
  }

  @override
  bool shouldRepaint(_KupuPainter old) => old.sayap != sayap;
}

class _AnakJamur extends StatelessWidget {
  final double size;
  final int tunda;
  const _AnakJamur({required this.size, required this.tunda});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 700 + tunda),
        curve: Interval(tunda / (700 + tunda), 1, curve: Curves.elasticOut),
        builder: (_, v, __) => Transform.scale(
          scale: v,
          alignment: Alignment.bottomCenter,
          child: MumuMini(size: size, mood: MumuMood.idle),
        ),
      );
}

class _SemakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 440;
    final semak = Paint()..color = const Color(0xFFCFE3BA).withValues(alpha: .8);
    Path bukit(double x0) => Path()
      ..moveTo(x0 * k, s.height)
      ..cubicTo((x0 + 10) * k, s.height * .56, (x0 + 40) * k, s.height * .5, (x0 + 56) * k, s.height * .73)
      ..cubicTo((x0 + 64) * k, s.height * .37, (x0 + 100) * k, s.height * .37, (x0 + 108) * k, s.height * .7)
      ..cubicTo((x0 + 118) * k, s.height * .5, (x0 + 140) * k, s.height * .53, (x0 + 146) * k, s.height * .8)
      ..lineTo((x0 + 146) * k, s.height)
      ..close();
    canvas.drawPath(bukit(0), semak);
    canvas.drawPath(bukit(294), semak);
    final bunga = Paint()..color = const Color(0xCCFF9C94);
    for (final x in [40.0, 90.0, 340.0, 388.0]) {
      canvas.drawCircle(Offset(x * k, s.height * .58), 3, bunga);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TanahPainter extends CustomPainter {
  final double t;
  _TanahPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 440;
    final pudar = Rect.fromLTWH(0, 0, s.width, s.height);
    canvas.saveLayer(pudar, Paint());
    canvas.drawPath(
      Path()
        ..moveTo(0, 46)
        ..cubicTo(70 * k, 30, 130 * k, 40, 200 * k, 38)
        ..cubicTo(270 * k, 36, 340 * k, 26, s.width, 40)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      Paint()..color = const Color(0xFFDCEBCB),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 56)
        ..cubicTo(90 * k, 46, 170 * k, 54, 240 * k, 50)
        ..cubicTo(320 * k, 46, 380 * k, 44, s.width, 52)
        ..lineTo(s.width, s.height)
        ..lineTo(0, s.height)
        ..close(),
      Paint()..color = const Color(0xFFCBE0B4),
    );
    // memudar ke bawah
    canvas.drawRect(
      pudar,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, .55, 1],
        ).createShader(pudar),
    );
    canvas.restore();

    final rumput = Paint()
      ..color = const Color(0xFF6DBB5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final x in [34.0, 70.0, 300.0, 352.0, 402.0]) {
      final ayun = math.sin((t * 5 + x) * math.pi * 2) * 3;
      final bx = x * k, by = 46.0;
      canvas.drawPath(
          Path()
            ..moveTo(bx, by)
            ..quadraticBezierTo(bx - 2 + ayun, by - 12, bx - 6 + ayun, by - 16)
            ..moveTo(bx + 4, by)
            ..quadraticBezierTo(bx + 4 + ayun, by - 14, bx + 6 + ayun, by - 18)
            ..moveTo(bx + 8, by)
            ..quadraticBezierTo(bx + 10 + ayun, by - 10, bx + 15 + ayun, by - 13),
          rumput);
    }
    for (final f in [
      [110.0, const Color(0xFFFFD25A)],
      [262.0, const Color(0xFFFF9C94)],
      [380.0, Colors.white],
    ]) {
      final x = (f[0] as double) * k;
      final ayun = math.sin((t * 4 + x) * math.pi * 2) * 2;
      final pusat = Offset(x + ayun, 34);
      canvas.drawLine(Offset(x, 46), pusat, Paint()
        ..color = const Color(0xFF5FAE52)
        ..strokeWidth = 2);
      for (var a = 0; a < 5; a++) {
        final r = a * math.pi * 2 / 5;
        canvas.drawCircle(pusat + Offset(math.cos(r) * 4, math.sin(r) * 4), 3.2, Paint()..color = f[1] as Color);
      }
      canvas.drawCircle(pusat, 2.4, Paint()..color = const Color(0xFFF2A23A));
    }
  }

  @override
  bool shouldRepaint(_TanahPainter old) => old.t != t;
}

/// Langit pagi di belakang taman: gradasi langit, matahari bersinar,
/// bukit berlapis di kejauhan, pepohonan kecil, dan burung yang terbang.
class _LangitPainter extends CustomPainter {
  final double t;
  final bool daftar;
  _LangitPainter(this.t, this.daftar);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final semua = Rect.fromLTWH(-30, -60, w + 60, h + 60);

    // 1. langit (pagi cerah saat Masuk, matahari terbit hangat saat Daftar)
    canvas.drawRect(
      semua,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: daftar
              ? const [Color(0xFFF9CDB0), Color(0xFFFCE3CF), Color(0xFFFBF1E2)]
              : const [Color(0xFFB9DFF0), Color(0xFFDDF0EE), Color(0xFFF7F1E2)],
          stops: const [0, .55, 1],
        ).createShader(semua),
    );

    // 2. matahari: cahaya lembut, sinar berputar pelan, bulatan bergradasi
    final r = (h * .085).clamp(16.0, 42.0);
    final pusat = Offset(w * .83, r * 2.3);
    canvas.drawCircle(
      pusat,
      r * 4.2,
      Paint()
        ..shader = RadialGradient(colors: [
          (daftar ? const Color(0xFFFFC27A) : const Color(0xFFFFE9A0)).withValues(alpha: .75),
          (daftar ? const Color(0xFFFFC27A) : const Color(0xFFFFE9A0)).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: pusat, radius: r * 4.2)),
    );
    canvas.save();
    canvas.translate(pusat.dx, pusat.dy);
    canvas.rotate(t * math.pi * 2 / 3);
    final sinar = Paint()..color = const Color(0xFFFFD45C).withValues(alpha: .55);
    for (var i = 0; i < 12; i++) {
      final panjang = i.isEven ? 1.0 : .7;
      final denyut = 1 + .08 * math.sin((t * 14 + i / 12) * math.pi * 2);
      canvas.drawPath(
        Path()
          ..moveTo(-r * .14, -r * 1.25)
          ..lineTo(0, -r * (1.25 + .75 * panjang * denyut))
          ..lineTo(r * .14, -r * 1.25)
          ..close(),
        sinar,
      );
      canvas.rotate(math.pi * 2 / 12);
    }
    canvas.restore();
    canvas.drawCircle(
      pusat,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.3),
          colors: [Color(0xFFFFF3B0), Color(0xFFFFCF3F), Color(0xFFF7A928)],
          stops: [0, .6, 1],
        ).createShader(Rect.fromCircle(center: pusat, radius: r)),
    );

    // 3. burung kecil terbang melintas
    final burung = Paint()
      ..color = const Color(0xFF6F7F73).withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final b in const [
      [0.0, .22, 1.0],
      [.08, .3, .8],
      [.5, .16, .9],
    ]) {
      final u = (t * 2 + b[0]) % 1;
      final x = -20 + u * (w + 40);
      final y = h * b[1] + math.sin(u * math.pi * 4) * 4;
      final kepak = 3 + 2.5 * math.sin((t * 28 + b[0]) * math.pi * 2);
      final k = 6 * b[2];
      canvas.drawPath(
        Path()
          ..moveTo(x - k, y - kepak * .6)
          ..quadraticBezierTo(x - k * .4, y - kepak, x, y)
          ..quadraticBezierTo(x + k * .4, y - kepak, x + k, y - kepak * .6),
        burung,
      );
    }

    // 4. bukit berlapis di kejauhan (makin jauh makin pudar)
    final dasar = h - 40;
    Path bukit(double tinggiBukit, double geser, double gelombang) {
      final p = Path()..moveTo(-30, h);
      p.lineTo(-30, dasar - tinggiBukit * .5);
      const n = 4;
      for (var i = 0; i < n; i++) {
        final x0 = -30 + (w + 60) * i / n;
        final x1 = -30 + (w + 60) * (i + 1) / n;
        final puncak = dasar - tinggiBukit * (.7 + .3 * math.sin(i * 1.7 + geser));
        p.quadraticBezierTo((x0 + x1) / 2, puncak - gelombang, x1, dasar - tinggiBukit * (.45 + .2 * math.cos(i + geser)));
      }
      p.lineTo(w + 30, h);
      p.close();
      return p;
    }

    canvas.drawPath(bukit(h * .42, 0, 18), Paint()..color = daftar ? const Color(0xFFE6E2C6) : const Color(0xFFD5E8D2));
    canvas.drawPath(bukit(h * .30, 2.1, 12), Paint()..color = daftar ? const Color(0xFFD7DDB3) : const Color(0xFFC3DFB5));

    // 5. pepohonan kecil di punggung bukit
    for (final p in const [
      [.08, .30, 1.0],
      [.14, .27, .8],
      [.62, .29, .9],
      [.70, .26, 1.1],
      [.93, .31, .85],
    ]) {
      final x = w * p[0];
      final y = dasar - h * p[1] * .62;
      final k = (h / 236).clamp(1.0, 2.2) * p[2];
      final ayun = math.sin((t * 6 + p[0]) * math.pi * 2) * .8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.5 * k, y, 3 * k, 12 * k), Radius.circular(k)),
        Paint()..color = const Color(0xFF9C7A58),
      );
      final daun = Paint()..color = const Color(0xFF8CC26F);
      canvas.drawCircle(Offset(x + ayun, y - 4 * k), 8 * k, daun);
      canvas.drawCircle(Offset(x - 5 * k + ayun, y), 6 * k, daun);
      canvas.drawCircle(Offset(x + 5 * k + ayun, y), 6 * k, daun);
      canvas.drawCircle(Offset(x - 2 * k + ayun, y - 7 * k), 3.5 * k, Paint()..color = const Color(0xFFA9D88A));
    }

    // 6. kabut tipis di kaki bukit supaya menyatu dengan semak
    final kabut = Rect.fromLTWH(-30, dasar - 30, w + 60, 70);
    canvas.drawRect(
      kabut,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .35)],
        ).createShader(kabut),
    );
  }

  @override
  bool shouldRepaint(_LangitPainter old) => old.t != t || old.daftar != daftar;
}

/// Warna Mumu dipakai juga oleh elemen lain.
const warnaTopi = AppColors.mumuRed;
