import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

class NavItem {
  final String id;
  final String label;
  final Widget ikon;
  final int badge;
  const NavItem(this.id, this.label, this.ikon, {this.badge = 0});
}

/// Navbar berbentuk ranting pohon dengan ikon tetesan embun.
class BranchNav extends StatelessWidget {
  final List<NavItem> items;
  final String aktif;
  final ValueChanged<String> onTap;
  const BranchNav({super.key, required this.items, required this.aktif, required this.onTap});

  static const _pos = [Offset(66, 64), Offset(128, 60), Offset(195, 60), Offset(262, 60), Offset(326, 57)];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final k = w / 390;
      final h = 124 * k;
      return SizedBox(
        width: w,
        height: h + 10,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(top: 10, child: CustomPaint(painter: _RantingPainter())),
          for (var i = 0; i < items.length && i < _pos.length; i++)
            Positioned(
              left: _pos[i].dx * k - 34 * k,
              top: 10 + _pos[i].dy * k - 54 * k,
              width: 68 * k,
              height: 100 * k,
              child: _Tetes(
                item: items[i],
                aktif: items[i].id == aktif,
                tambah: items[i].id == 'add',
                skala: k,
                onTap: () => onTap(items[i].id),
              ),
            ),
        ]),
      );
    });
  }
}

class _Tetes extends StatefulWidget {
  final NavItem item;
  final bool aktif;
  final bool tambah;
  final double skala;
  final VoidCallback onTap;
  const _Tetes({required this.item, required this.aktif, required this.tambah, required this.skala, required this.onTap});

  @override
  State<_Tetes> createState() => _TetesState();
}

class _TetesState extends State<_Tetes> with TickerProviderStateMixin {
  late final AnimationController _jelly =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _goyang =
      AnimationController(vsync: this, duration: Duration(milliseconds: 2600 + widget.item.label.length * 90))
        ..repeat();

  @override
  void dispose() {
    _jelly.dispose();
    _goyang.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.skala;
    final r = (widget.tambah ? 24.0 : 21.0) * k;
    return Semantics(
      button: true,
      selected: widget.aktif,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _jelly.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_jelly, _goyang]),
          builder: (_, __) {
            final j = _jelly.value;
            final pantul = j == 0 ? 0.0 : math.exp(-5 * j) * math.sin(j * math.pi * 5);
            final ayun = math.sin(_goyang.value * math.pi * 2) * .05;
            final aktifSkala = widget.aktif ? 1.14 : 1.0;
            return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
              Positioned(
                top: 0,
                child: Transform.rotate(
                  angle: ayun,
                  alignment: Alignment.topCenter,
                  child: Transform.scale(
                    scaleX: aktifSkala * (1 + pantul * .18),
                    scaleY: aktifSkala * (1 - pantul * .18),
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: r * 2.4,
                      height: r * 2.9,
                      child: CustomPaint(
                        painter: _TetesPainter(r, widget.aktif, widget.tambah),
                        child: Padding(
                          padding: EdgeInsets.only(top: r * 0.9),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(width: r * 1.35, height: r * 1.35, child: widget.item.ikon),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.item.badge > 0)
                Positioned(
                  top: r * .55,
                  right: r * .2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.tomato,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.6),
                    ),
                    child: Text('${widget.item.badge}', style: AppText.body(10, color: Colors.white, weight: FontWeight.w900)),
                  ),
                ),
              if (widget.aktif)
                Positioned(
                  top: r * 2.95,
                  child: Text(widget.item.label,
                      style: AppText.body(11.5, color: const Color(0xFF2B2620), weight: FontWeight.w900)),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

class _TetesPainter extends CustomPainter {
  final double r;
  final bool aktif;
  final bool tambah;
  _TetesPainter(this.r, this.aktif, this.tambah);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = r * 1.5 + 2; // pusat lingkaran bawah
    final p = Path()
      ..moveTo(cx, cy - r * 1.5)
      ..cubicTo(cx + r * .42, cy - r * .85, cx + r, cy - r * .45, cx + r, cy + r * .12)
      ..arcToPoint(Offset(cx - r, cy + r * .12), radius: Radius.circular(r), clockwise: true)
      ..cubicTo(cx - r, cy - r * .45, cx - r * .42, cy - r * .85, cx, cy - r * 1.5)
      ..close();
    final warna = tambah
        ? [Colors.white, const Color(0xD9FFE9CF), const Color(0xE6F2A15A)]
        : aktif
            ? [Colors.white, const Color(0xD9DFF8D2), const Color(0xE67CC56A)]
            : [const Color(0xF2FFFFFF), const Color(0xB3E4F6FD), const Color(0xBF8CCBE6)];
    canvas.drawShadow(p, const Color(0xFF2A3A2A), 3, true);
    canvas.drawPath(
      p,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-.28, -.24), radius: .9, colors: warna, stops: const [0, .5, 1])
            .createShader(Rect.fromCircle(center: Offset(cx, cy - r * .3), radius: r * 1.4)),
    );
    canvas.drawPath(
        p,
        Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // kilau
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * .45, cy - r * .2), width: r * .32, height: r * .5),
        Paint()..color = Colors.white.withValues(alpha: .85));
  }

  @override
  bool shouldRepaint(_TetesPainter old) => old.aktif != aktif || old.r != r;
}

class _RantingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 390;
    canvas.save();
    canvas.scale(k, k);
    final batang = Path()
      ..moveTo(-14, 124)
      ..cubicTo(2, 104, 12, 92, 34, 84)
      ..cubicTo(70, 72, 104, 82, 150, 74)
      ..cubicTo(206, 64, 262, 76, 312, 66)
      ..cubicTo(340, 61, 364, 58, 392, 50)
      ..lineTo(394, 58)
      ..cubicTo(368, 68, 344, 72, 316, 78)
      ..cubicTo(266, 90, 210, 80, 156, 90)
      ..cubicTo(108, 98, 74, 90, 46, 100)
      ..cubicTo(30, 106, 22, 116, 18, 124)
      ..close();
    canvas.drawPath(
      batang,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A6A42), Color(0xFF7A4F2D), Color(0xFF4E311B)],
          stops: [0, .45, 1],
        ).createShader(const Rect.fromLTWH(0, 50, 390, 74)),
    );
    final serat = Paint()
      ..color = const Color(0x733F2714)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final s in [
      [44.0, 92.0, 80.0, 87.0],
      [110.0, 86.0, 154.0, 80.0],
      [180.0, 80.0, 226.0, 78.0],
      [246.0, 80.0, 290.0, 73.0],
      [300.0, 74.0, 340.0, 66.0],
    ]) {
      canvas.drawLine(Offset(s[0], s[1]), Offset(s[2], s[3]), serat);
    }
    final daun = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFA9E07C), Color(0xFF3F8F38)])
          .createShader(const Rect.fromLTWH(140, 10, 220, 110));
    final ranting = Paint()
      ..color = const Color(0xFF7A4F2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(150, 76)
          ..cubicTo(156, 64, 154, 52, 162, 42),
        ranting);
    canvas.drawPath(
        Path()
          ..moveTo(162, 42)
          ..cubicTo(148, 38, 142, 26, 148, 16)
          ..cubicTo(160, 20, 166, 30, 162, 42)
          ..close(),
        daun);
    canvas.drawPath(
        Path()
          ..moveTo(292, 70)
          ..cubicTo(300, 62, 306, 54, 318, 52),
        ranting..strokeWidth = 3.5);
    canvas.drawPath(
        Path()
          ..moveTo(318, 52)
          ..cubicTo(322, 38, 336, 34, 346, 40)
          ..cubicTo(340, 52, 330, 56, 318, 52)
          ..close(),
        daun);
    canvas.drawPath(
        Path()
          ..moveTo(98, 84)
          ..cubicTo(88, 92, 86, 104, 94, 112)
          ..cubicTo(102, 104, 104, 94, 98, 84)
          ..close(),
        daun);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ikon profil di navbar: foto pengguna (bulat) atau avatar sayur.
class NavAvatar extends StatelessWidget {
  final String? foto;
  final String ava;
  const NavAvatar({super.key, this.foto, required this.ava});

  @override
  Widget build(BuildContext context) {
    final f = foto;
    if (f != null && f.isNotEmpty) {
      return ClipOval(child: FotoProfil(f, fit: BoxFit.cover));
    }
    return Emo(ava, size: 30);
  }
}

/// Menampilkan foto dari URL (Supabase) atau data URI (mode lokal).
class FotoProfil extends StatelessWidget {
  final String sumber;
  final BoxFit fit;
  const FotoProfil(this.sumber, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (sumber.startsWith('data:')) {
      final data = UriData.parse(sumber);
      return Image.memory(data.contentAsBytes(), fit: fit, gaplessPlayback: true);
    }
    return Image.network(sumber, fit: fit, gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEDE6D8)));
  }
}
