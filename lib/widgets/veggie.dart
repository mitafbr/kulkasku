import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/logic.dart';
import '../data/models.dart';
import 'common.dart';

/// Gambar sayur/buah yang tampilannya berubah sesuai status:
/// segar = normal, hampir layu = pucat & lunglai, basi = cokelat, berjamur, dikerubungi lalat.
class VeggieImage extends StatefulWidget {
  final Bahan bahan;
  final double size;
  final bool animasi;
  const VeggieImage(this.bahan, {super.key, this.size = 40, this.animasi = true});

  @override
  State<VeggieImage> createState() => _VeggieImageState();
}

class _VeggieImageState extends State<VeggieImage> with TickerProviderStateMixin {
  AnimationController? _c;

  Status get _s => Hitung.status(widget.bahan);

  @override
  void initState() {
    super.initState();
    _atur();
  }

  @override
  void didUpdateWidget(covariant VeggieImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _atur();
  }

  void _atur() {
    final perlu = widget.animasi && _s == Status.basi;
    if (perlu && _c == null) {
      _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    } else if (!perlu && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final j = widget.bahan.jenis;
    switch (_s) {
      case Status.segar:
        return Emo(j, size: s);
      case Status.layu:
        // gambar "mau layu": warna memudar kekuningan & sedikit terkulai (assets/emoji/<jenis>_layu.webp)
        return SizedBox(
          width: s,
          height: s,
          child: Stack(clipBehavior: Clip.none, children: [
            Emo('${j}_layu', size: s, cadangan: j),
            Positioned(right: s * .02, top: s * .08, child: _Tetes(size: s * .2)),
          ]),
        );
      case Status.basi:
        // gambar "layu/busuk": cokelat, berbercak, dan berjamur (assets/emoji/<jenis>_busuk.webp)
        final c = _c;
        return SizedBox(
          width: s,
          height: s,
          child: Stack(clipBehavior: Clip.none, children: [
            Emo('${j}_busuk', size: s, cadangan: j),
            Positioned.fill(child: CustomPaint(painter: _BauPainter())),
            if (c != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: c,
                  builder: (_, __) => CustomPaint(painter: _LalatPainter(c.value)),
                ),
              ),
          ]),
        );
    }
  }
}

class _Tetes extends StatelessWidget {
  final double size;
  const _Tetes({required this.size});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size * 1.3), painter: _TetesPainter());
}

class _TetesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(s.width / 2, 0)
      ..cubicTo(s.width, s.height * .5, s.width, s.height, s.width / 2, s.height)
      ..cubicTo(0, s.height, 0, s.height * .5, s.width / 2, 0);
    canvas.drawPath(p, Paint()..color = const Color(0xFFBFE6F7));
    canvas.drawCircle(Offset(s.width * .38, s.height * .62), s.width * .14, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Garis bau di atas bahan yang sudah busuk.
class _BauPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final bau = Paint()
      ..color = const Color(0x9988A060)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s.width * .03)
      ..strokeCap = StrokeCap.round;
    for (final x in [.38, .58]) {
      final p = Path()..moveTo(s.width * x, s.height * .12);
      p.quadraticBezierTo(s.width * (x - .06), s.height * .02, s.width * x, -s.height * .08);
      canvas.drawPath(p, bau);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LalatPainter extends CustomPainter {
  final double t;
  _LalatPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < 2; i++) {
      final a = (t + i * .5) * math.pi * 2;
      final o = Offset(s.width * (.5 + .42 * math.cos(a)), s.height * (.2 + .16 * math.sin(a * 2)));
      final r = math.max(1.6, s.width * .045);
      canvas.drawOval(Rect.fromCenter(center: o.translate(-r * .7, -r * .6), width: r * 1.5, height: r), Paint()..color = const Color(0xAAFFFFFF));
      canvas.drawOval(Rect.fromCenter(center: o.translate(r * .7, -r * .6), width: r * 1.5, height: r), Paint()..color = const Color(0xAAFFFFFF));
      canvas.drawCircle(o, r * .8, Paint()..color = const Color(0xFF2B2620));
    }
  }

  @override
  bool shouldRepaint(_LalatPainter old) => old.t != t;
}
