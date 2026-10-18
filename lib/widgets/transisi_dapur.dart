import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';
import 'mumu.dart';

/// Transisi "masuk ke dapur" setelah berhasil Masuk/Daftar:
/// lingkaran krem membesar, Mumu berjalan membawa keranjang ke kulkas,
/// sayur & buah melompat satu per satu ke dalam kulkas, lalu dapur muncul.
class RuteDapur extends PageRouteBuilder<void> {
  RuteDapur(Widget halaman)
      : super(
          transitionDuration: const Duration(milliseconds: 2800),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => halaman,
          transitionsBuilder: (context, anim, _, child) {
            final p = anim.value;
            final ukuran = MediaQuery.sizeOf(context);
            final r = Curves.easeInOutCubic.transform((p / .14).clamp(0.0, 1.0)) * ukuran.longestSide * 1.2;
            final pudar = ((p - .82) / .18).clamp(0.0, 1.0);
            return Stack(children: [
              if (pudar > 0) Opacity(opacity: pudar, child: child),
              if (pudar < 1)
                IgnorePointer(
                  child: Opacity(
                    opacity: 1 - pudar,
                    child: ClipPath(
                      clipper: _Lingkaran(Offset(ukuran.width / 2, ukuran.height / 2), r),
                      child: _AdeganDapur(p: p),
                    ),
                  ),
                ),
            ]);
          },
        );
}

class _Lingkaran extends CustomClipper<Path> {
  final Offset pusat;
  final double r;
  _Lingkaran(this.pusat, this.r);
  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: pusat, radius: r));
  @override
  bool shouldReclip(_Lingkaran old) => old.r != r;
}

class _AdeganDapur extends StatelessWidget {
  final double p;
  const _AdeganDapur({required this.p});

  static const _sayur = ['tomat', 'wortel', 'brokoli', 'apel', 'stroberi'];

  double _iv(double a, double b, [Curve c = Curves.easeInOut]) => c.transform(((p - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBF3E4), Color(0xFFF3EBDD), Color(0xFFE9DCC6)],
          stops: [0, .62, 1],
        ),
      ),
      child: LayoutBuilder(builder: (context, k) {
        final w = k.maxWidth, h = k.maxHeight;
        final skala = (math.min(w, 520.0) / 390).clamp(.85, 1.35);
        final lantai = h * .6;
        final kulkasX = w / 2 + 70 * skala;
        const ukKulkas = 130.0;
        final mumu = 104 * skala;

        // Mumu berjalan dari kiri lalu berhenti di depan kulkas
        final jalan = _iv(.08, .42, Curves.easeOutCubic);
        final mumuX = w / 2 - 190 * skala + jalan * 120 * skala;
        final langkah = jalan < 1 ? (math.sin(p * 70)).abs() * 7 : 0.0;
        final selesai = p > .7;

        // kulkas sedikit memantul setiap ada sayur yang masuk
        var pantul = 0.0;
        for (var i = 0; i < _sayur.length; i++) {
          final mendarat = .42 + i * .07 + .07;
          final d = p - mendarat;
          if (d > 0 && d < .06) pantul = math.max(pantul, math.sin(d / .06 * math.pi));
        }

        return Stack(children: [
          // lantai kayu
          Positioned(
            left: 0,
            right: 0,
            top: lantai,
            bottom: 0,
            child: CustomPaint(painter: _LantaiPainter()),
          ),
          // jendela & matahari pagi
          Positioned(
            left: w / 2 - 210 * skala,
            top: lantai - 250 * skala,
            child: Opacity(opacity: _iv(.05, .2), child: _Jendela(skala: skala)),
          ),
          // kulkas
          Positioned(
            left: kulkasX - ukKulkas * skala / 2,
            top: lantai - ukKulkas * skala * 1.02 - pantul * 6,
            child: Transform.scale(
              scaleX: 1 + pantul * .05,
              scaleY: 1 - pantul * .04,
              alignment: Alignment.bottomCenter,
              child: Opacity(opacity: _iv(.06, .18), child: Emo('kulkas', size: ukKulkas * skala)),
            ),
          ),
          // kilau saat kulkas penuh
          if (selesai)
            for (var i = 0; i < 4; i++)
              Positioned(
                left: kulkasX + math.cos(i * 1.6 + 0.4) * 70 * skala - 10,
                top: lantai - ukKulkas * skala * .6 + math.sin(i * 1.6 + .4) * 60 * skala - 10,
                child: Transform.scale(
                  scale: math.sin(_iv(.7 + i * .02, .86 + i * .02) * math.pi),
                  child: Icon(Icons.auto_awesome, size: 22 * skala, color: const Color(0xFFFFC93C)),
                ),
              ),
          // Mumu + keranjang
          Positioned(
            left: mumuX - mumu / 2,
            top: lantai - mumu * .98 - langkah,
            child: SizedBox(
              width: mumu,
              height: mumu,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: MumuPainter(MumuPose(
                      mood: selesai ? MumuMood.senang : MumuMood.idle,
                      napas: .5 + .5 * math.sin(p * 30),
                      lompat: selesai ? 10 * math.sin(_iv(.72, .86) * math.pi) : 0,
                      pupil: const Offset(.8, -.1),
                      capRot: math.sin(p * 35) * .04 * (1 - jalan),
                    )),
                  ),
                ),
                Positioned(
                  right: -mumu * .18,
                  top: mumu * .5,
                  child: Emo('keranjang', size: mumu * .34),
                ),
              ]),
            ),
          ),
          // sayur melompat dari keranjang ke kulkas satu per satu
          for (var i = 0; i < _sayur.length; i++) _lompatan(i, mumuX + mumu * .4, lantai - mumu * .4, kulkasX, lantai - ukKulkas * skala * .55, skala),
          // tulisan
          Positioned(
            left: 24,
            right: 24,
            top: lantai + 40 * skala,
            child: Opacity(
              opacity: _iv(.1, .22),
              child: Column(children: [
                Text(selesai ? 'Kulkas siap!' : 'Menata sayur di kulkasmu${'.' * (1 + (p * 18).floor() % 3)}',
                    textAlign: TextAlign.center, style: AppText.display(26 * skala, color: AppColors.leafDark)),
                const SizedBox(height: 10),
                // daun-daun kecil sebagai penanda kemajuan
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.scale(
                        scale: Curves.elasticOut.transform(_iv(.2 + i * .1, .3 + i * .1, Curves.linear)),
                        child: Emo(i.isEven ? 'daun' : 'tunas', size: 18 * skala),
                      ),
                    ),
                ]),
              ]),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _lompatan(int i, double x0, double y0, double x1, double y1, double skala) {
    final mulai = .42 + i * .07;
    final u = ((p - mulai) / .08).clamp(0.0, 1.0);
    if (u <= 0 || u >= 1) return const SizedBox.shrink();
    final x = x0 + (x1 - x0) * u;
    final y = y0 + (y1 - y0) * u - math.sin(u * math.pi) * 90 * skala;
    final s = 38 * skala * (1 - .5 * u);
    return Positioned(
      left: x - s / 2,
      top: y - s / 2,
      child: Opacity(
        opacity: u > .85 ? (1 - u) / .15 : 1,
        child: Transform.rotate(angle: u * math.pi * 1.5, child: Emo(_sayur[i], size: s)),
      ),
    );
  }
}

class _Jendela extends StatelessWidget {
  final double skala;
  const _Jendela({required this.skala});
  @override
  Widget build(BuildContext context) => Container(
        width: 120 * skala,
        height: 100 * skala,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14 * skala),
          border: Border.all(color: AppColors.woodLight, width: 6 * skala),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBFE3F0), Color(0xFFEAF5EE)],
          ),
        ),
        child: Stack(children: [
          Positioned(
            right: 14 * skala,
            top: 12 * skala,
            child: Container(
              width: 24 * skala,
              height: 24 * skala,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD45C)),
            ),
          ),
          Center(child: Container(width: 4 * skala, color: AppColors.woodLight)),
          Center(child: Container(height: 4 * skala, color: AppColors.woodLight)),
        ]),
      );
}

class _LantaiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFDCC4A0));
    final garis = Paint()
      ..color = const Color(0xFFC9AE86)
      ..strokeWidth = 2;
    for (var y = 18.0; y < s.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), garis);
    }
    for (var x = 40.0; x < s.width; x += 120) {
      for (var y = 0.0; y < s.height; y += 52) {
        canvas.drawLine(Offset(x + (y / 26 % 2) * 60, y + 18), Offset(x + (y / 26 % 2) * 60, y + 44), garis);
      }
    }
    // bayangan lembut di garis dinding
    final r = Rect.fromLTWH(0, 0, s.width, 18);
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33593F26), Color(0x00593F26)],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
