import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/logic.dart';
import '../data/models.dart';
import '../theme.dart';
import 'common.dart';
import 'veggie.dart';

/// Dapur interaktif: ruangan + kulkas dua pintu (freezer di atas, kulkas di bawah).
class KitchenScene extends StatefulWidget {
  final List<Bahan> bahan;
  final String? buka; // 'freezer' / 'kulkas' / null
  final String? pilih;
  final String catatan;
  final int suhuKl;
  final int suhuFz;
  final ValueChanged<String> onPintu;
  final ValueChanged<Bahan> onPilih;
  final ValueChanged<Bahan> onDetail;
  final ValueChanged<String> onSuhu; // 'kl' / 'fz'
  final VoidCallback onCatatan;

  const KitchenScene({
    super.key,
    required this.bahan,
    required this.buka,
    required this.pilih,
    required this.catatan,
    required this.suhuKl,
    required this.suhuFz,
    required this.onPintu,
    required this.onPilih,
    required this.onDetail,
    required this.onSuhu,
    required this.onCatatan,
  });

  static const double tinggi = 420;

  @override
  State<KitchenScene> createState() => _KitchenSceneState();
}

class _KitchenSceneState extends State<KitchenScene> with SingleTickerProviderStateMixin {
  late final AnimationController _waktu =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  String? _bicara;
  Offset _posBicara = Offset.zero;

  @override
  void dispose() {
    _waktu.dispose();
    super.dispose();
  }

  void _ngomong(String teks, Offset pos) {
    setState(() {
      _bicara = teks;
      _posBicara = pos;
    });
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted && _bicara == teks) setState(() => _bicara = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      const h = KitchenScene.tinggi;
      final k = math.max(w / 390, h / 420);
      final ox = (w - 390 * k) / 2;
      final oy = h - 420 * k;
      Offset p(double x, double y) => Offset(ox + x * k, oy + y * k);

      Widget prop(String nama, double x, double y, double s, List<String> kata) {
        final pos = p(x, y);
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: _Prop(
            nama: nama,
            size: s * k,
            onTap: () => _ngomong(kata[math.Random().nextInt(kata.length)], pos),
          ),
        );
      }

      return SizedBox(
        height: h,
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waktu,
              builder: (_, __) => CustomPaint(painter: _RuangPainter(k, ox, oy, _waktu.value)),
            ),
          ),
          prop('toples', 24, 114, 36, ['Bumbu dapur aman', 'Tutup rapat ya']),
          prop('garam', 64, 122, 28, ['Secukupnya saja', 'Asin~']),
          prop('toples', 96, 118, 30, ['Gula atau garam?']),
          prop('pot', 132, 104, 46, ['Siram aku ya!', 'Daunku tumbuh']),
          _PotGantung(left: p(182, 0).dx, top: p(182, 0).dy, k: k, onTap: () => _ngomong('Wush, aku berayun!', p(182, 30))),
          prop('keranjang', 14, 238, 58, ['Ayo belanja sayur!', 'Isi aku dengan buah']),
          prop('bawangputih', 70, 262, 28, ['Aku bikin wangi masakan', 'Simpan aku di luar kulkas']),
          prop('bawangmerah', 94, 264, 26, ['Bawang merah siap!']),
          _Teko(left: p(128, 250).dx, top: p(128, 250).dy, k: k, onTap: () => _ngomong('Fiuuuh! Teh hangat?', p(128, 250))),
          prop('jamur', 178, 266, 24, ['Jamur suka tempat kering', 'Hai!']),
          Positioned(
            right: 20,
            bottom: 24,
            child: _Kulkas(
              bahan: widget.bahan,
              buka: widget.buka,
              pilih: widget.pilih,
              catatan: widget.catatan,
              suhuKl: widget.suhuKl,
              suhuFz: widget.suhuFz,
              onPintu: widget.onPintu,
              onPilih: widget.onPilih,
              onDetail: widget.onDetail,
              onSuhu: widget.onSuhu,
              onCatatan: widget.onCatatan,
            ),
          ),
          if (_bicara != null)
            Positioned(
              left: math.max(8.0, _posBicara.dx - 20),
              top: math.max(6.0, _posBicara.dy - 40),
              child: _Gelembung(_bicara!),
            ),
        ]),
      );
    });
  }
}

class _Gelembung extends StatelessWidget {
  final String teks;
  const _Gelembung(this.teks);
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: .6, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (_, s, c) => Transform.scale(scale: s, alignment: Alignment.bottomLeft, child: c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(4)),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Text(teks, style: AppText.body(12, weight: FontWeight.w800)),
        ),
      );
}

class _Prop extends StatelessWidget {
  final String nama;
  final double size;
  final VoidCallback onTap;
  const _Prop({required this.nama, required this.size, required this.onTap});
  @override
  Widget build(BuildContext context) => JellyTap(scale: .8, onTap: onTap, child: Emo(nama, size: size));
}

class _PotGantung extends StatefulWidget {
  final double left, top, k;
  final VoidCallback onTap;
  const _PotGantung({required this.left, required this.top, required this.k, required this.onTap});
  @override
  State<_PotGantung> createState() => _PotGantungState();
}

class _PotGantungState extends State<_PotGantung> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.k;
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, c) => Transform.rotate(
          angle: math.sin(_c.value * math.pi * 2) * .07,
          alignment: Alignment.topCenter,
          child: c,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: 42 * k,
            height: 72 * k,
            child: Column(children: [
              Container(width: 2, height: 30 * k, color: const Color(0xFF9C7046)),
              Emo('pot', size: 42 * k),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Teko extends StatefulWidget {
  final double left, top, k;
  final VoidCallback onTap;
  const _Teko({required this.left, required this.top, required this.k, required this.onTap});
  @override
  State<_Teko> createState() => _TekoState();
}

class _TekoState extends State<_Teko> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  bool _sembur = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.k;
    return Positioned(
      left: widget.left,
      top: widget.top - 30 * k,
      child: SizedBox(
        width: 44 * k,
        height: 74 * k,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            bottom: 44 * k,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(painter: _UapPainter(_c.value, _sembur ? 2.5 : 1)),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: JellyTap(
              scale: .82,
              onTap: () {
                setState(() => _sembur = true);
                widget.onTap();
                Future.delayed(const Duration(milliseconds: 1800), () {
                  if (mounted) setState(() => _sembur = false);
                });
              },
              child: Emo('teko', size: 44 * k),
            ),
          ),
        ]),
      ),
    );
  }
}

class _UapPainter extends CustomPainter {
  final double t;
  final double kuat;
  _UapPainter(this.t, this.kuat);
  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < 3; i++) {
      final u = (t * kuat + i / 3) % 1;
      final x = s.width * (.35 + i * .14);
      final y = s.height * (1 - u);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: (u < .3 ? u / .3 : 1 - (u - .3) / .7) * .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final p = Path()
        ..moveTo(x, y + 10)
        ..quadraticBezierTo(x - 5, y + 5, x, y)
        ..quadraticBezierTo(x + 5, y - 5, x, y - 10);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(_UapPainter old) => true;
}

/// Gambar ruangan dapur (dinding, jendela, rak, meja, lantai).
class _RuangPainter extends CustomPainter {
  final double k, ox, oy, t;
  _RuangPainter(this.k, this.ox, this.oy, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(ox, oy);
    canvas.scale(k, k);
    // dinding
    canvas.drawRect(
      const Rect.fromLTWH(-200, 0, 790, 420),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F0E0), Color(0xFFF1E6D0)],
        ).createShader(const Rect.fromLTWH(0, 0, 390, 420)),
    );
    // ubin
    final ubin = Paint()..color = const Color(0xFFEEF5E6);
    final garisUbin = Paint()
      ..color = const Color(0xFFD5E5C6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (double x = 0; x < 230; x += 20) {
      for (double y = 196; y < 292; y += 20) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(x + .75, y + .75, 18.5, 18.5), const Radius.circular(2.5));
        canvas.drawRRect(r, ubin);
        canvas.drawRRect(r, garisUbin);
      }
    }
    // sinar matahari
    canvas.drawPath(
      Path()
        ..moveTo(40, 52)
        ..lineTo(160, 52)
        ..lineTo(250, 330)
        ..lineTo(30, 330)
        ..close(),
      Paint()
        ..shader = LinearGradient(colors: [const Color(0xFFFFF8DC).withValues(alpha: .55), const Color(0x00FFF8DC)])
            .createShader(const Rect.fromLTWH(30, 52, 220, 278)),
    );
    // jendela
    canvas.save();
    canvas.translate(26, 36);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -6, 136, 110), const Radius.circular(10)),
        Paint()..color = Colors.white);
    final langit = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 124, 98), const Radius.circular(6));
    canvas.drawRRect(
      langit,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA9DCFA), Color(0xFFE6F6FF)],
        ).createShader(const Rect.fromLTWH(0, 0, 124, 98)),
    );
    canvas.save();
    canvas.clipRRect(langit);
    // matahari berdenyut
    final denyut = 1 + .1 * math.sin(t * math.pi * 2 * 7);
    canvas.drawCircle(const Offset(94, 28), 22 * denyut, Paint()..color = const Color(0x66FFD66B));
    canvas.drawCircle(const Offset(94, 28), 10, Paint()..color = const Color(0xFFFFD25A));
    // awan bergerak
    final awan = Paint()..color = Colors.white.withValues(alpha: .95);
    for (final a in [
      [0.0, 40.0, 1.0],
      [0.45, 66.0, .7],
    ]) {
      final x = ((t + a[0]) % 1) * 190 - 40;
      final y = a[1];
      final s = a[2];
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 36 * s, height: 16 * s), awan);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 12 * s, y - 6 * s), width: 24 * s, height: 18 * s), awan);
    }
    // burung
    final bx = ((t * 2) % 1) * 170 - 20;
    final kepak = math.sin(t * math.pi * 2 * 90) * 3;
    canvas.drawPath(
      Path()
        ..moveTo(bx, 24)
        ..quadraticBezierTo(bx + 4, 20 - kepak, bx + 8, 24)
        ..quadraticBezierTo(bx + 12, 20 - kepak, bx + 16, 24),
      Paint()
        ..color = const Color(0xFF3B4A36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(8, 98)
        ..quadraticBezierTo(24, 70, 40, 98)
        ..close()
        ..moveTo(36, 98)
        ..quadraticBezierTo(56, 60, 76, 98)
        ..close(),
      Paint()..color = const Color(0xFF8CC56A),
    );
    canvas.restore();
    canvas.drawRect(const Rect.fromLTWH(59, 0, 6, 98), Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(0, 46, 124, 6), Paint()..color = Colors.white);
    canvas.restore();
    // gorden
    final goyang = math.sin(t * math.pi * 2 * 6) * 3;
    canvas.drawLine(const Offset(14, 26), const Offset(174, 26), Paint()
      ..color = const Color(0xFFB88B5E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    final gorden = Paint()..color = const Color(0xFFF2A37E);
    canvas.drawPath(
        Path()
          ..moveTo(16, 28)
          ..cubicTo(30 + goyang, 60, 22 + goyang, 100, 34 + goyang, 140)
          ..lineTo(16, 140)
          ..close(),
        gorden);
    canvas.drawPath(
        Path()
          ..moveTo(174, 28)
          ..cubicTo(160 - goyang, 60, 168 - goyang, 100, 156 - goyang, 140)
          ..lineTo(174, 140)
          ..close(),
        gorden);
    // rak dinding
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 148, 170, 10), const Radius.circular(3)),
        Paint()..color = const Color(0xFFB98A5C));
    // meja kayu & lemari
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 286, 232, 14), const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE2BC8E), Color(0xFFC79A68)],
        ).createShader(const Rect.fromLTWH(0, 286, 232, 14)),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 300, 224, 98),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9FC48F), Color(0xFF86AE76)],
        ).createShader(const Rect.fromLTWH(0, 300, 224, 98)),
    );
    final pintuLemari = Paint()
      ..color = const Color(0xFF6F9A60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 310, 96, 80), const Radius.circular(6)), pintuLemari);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(116, 310, 98, 80), const Radius.circular(6)), pintuLemari);
    final gagang = Paint()..color = const Color(0xFFE7EFE2);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(88, 344, 6, 18), const Radius.circular(3)), gagang);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(128, 344, 6, 18), const Radius.circular(3)), gagang);
    // lantai
    canvas.drawRect(
      const Rect.fromLTWH(-200, 398, 790, 22),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD9B48A), Color(0xFFC69C6E)],
        ).createShader(const Rect.fromLTWH(0, 398, 390, 22)),
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(300, 398), width: 192, height: 18),
        Paint()..color = const Color(0xFF5A4026).withValues(alpha: .28));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RuangPainter old) => old.t != t || old.k != k;
}

// =====================================================================
//  KULKAS
// =====================================================================
class _Kulkas extends StatelessWidget {
  final List<Bahan> bahan;
  final String? buka;
  final String? pilih;
  final String catatan;
  final int suhuKl, suhuFz;
  final ValueChanged<String> onPintu;
  final ValueChanged<Bahan> onPilih;
  final ValueChanged<Bahan> onDetail;
  final ValueChanged<String> onSuhu;
  final VoidCallback onCatatan;

  const _Kulkas({
    required this.bahan,
    required this.buka,
    required this.pilih,
    required this.catatan,
    required this.suhuKl,
    required this.suhuFz,
    required this.onPintu,
    required this.onPilih,
    required this.onDetail,
    required this.onSuhu,
    required this.onCatatan,
  });

  static const double lebar = 164, tinggi = 330;

  List<Bahan> _di(String t) => bahan.where((b) => b.tempat == t).toList();

  @override
  Widget build(BuildContext context) {
    final fz = _di('freezer'), rak = _di('rak'), laci = _di('laci'), pintu = _di('pintu');
    final half = (rak.length / 2).ceil();
    return SizedBox(
      width: lebar,
      height: tinggi,
      child: Stack(clipBehavior: Clip.none, children: [
        // cahaya saat pintu terbuka
        if (buka != null)
          Positioned(
            left: -120,
            top: -40,
            right: -30,
            bottom: -10,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (_, v, __) => DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      (buka == 'freezer' ? Colors.white : const Color(0xFFFFECAA)).withValues(alpha: .6 * v),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),
          ),
        // badan kulkas
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26), bottom: Radius.circular(16)),
              gradient: const LinearGradient(
                colors: [Color(0xFF98B07D), Color(0xFFBFD1A6), Color(0xFFB2C799), Color(0xFF93AB78)],
                stops: [0, .38, .7, 1],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF28321E).withValues(alpha: .45), blurRadius: 26, offset: const Offset(0, 22), spreadRadius: -14),
              ],
            ),
          ),
        ),
        Positioned(left: 14, bottom: -7, child: _kaki()),
        Positioned(right: 14, bottom: -7, child: _kaki()),
        Positioned(
          top: 4,
          left: 0,
          right: 0,
          child: Center(
              child: Text('KULKASKU',
                  style: AppText.body(8, color: const Color(0xFF55703F), weight: FontWeight.w900).copyWith(letterSpacing: 1.6))),
        ),
        // freezer
        Positioned(
          left: 9,
          right: 9,
          top: 14,
          height: 104,
          child: _Kompartemen(
            freezer: true,
            buka: buka == 'freezer',
            tag: fz.isEmpty ? 'kosong' : '${fz.length} beku',
            label: 'Freezer · ${formatSuhu(suhuFz)} ✎',
            onPintu: () => onPintu('freezer'),
            onSuhu: () => onSuhu('fz'),
            isi: _isiFreezer(fz),
          ),
        ),
        // kulkas
        Positioned(
          left: 9,
          right: 9,
          top: 126,
          bottom: 12,
          child: _Kompartemen(
            freezer: false,
            buka: buka == 'kulkas',
            tag: '${rak.length + laci.length + pintu.length} segar',
            label: 'Kulkas · ${formatSuhu(suhuKl)} ✎',
            onPintu: () => onPintu('kulkas'),
            onSuhu: () => onSuhu('kl'),
            catatan: catatan,
            onCatatan: onCatatan,
            isi: _isiKulkas(rak.sublist(0, half), rak.sublist(half), laci),
            balikPintu: _balikPintu(pintu),
          ),
        ),
      ]),
    );
  }

  Widget _kaki() => Container(
        width: 16,
        height: 9,
        decoration: const BoxDecoration(
          color: Color(0xFF6B5A48),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
        ),
      );

  double _ukuran(int n, double besar, double w) => n == 0 ? besar : math.max(20.0, math.min(besar, w / n - 3));

  Widget _deret(List<Bahan> xs, double besar, double w) {
    final s = _ukuran(xs.length, besar, w);
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 2,
      children: [
        for (var i = 0; i < xs.length; i++)
          _ItemKulkas(
            key: ValueKey(xs[i].id),
            bahan: xs[i],
            size: s,
            dipilih: pilih == xs[i].id,
            urutan: i,
            onTap: () => pilih == xs[i].id ? onDetail(xs[i]) : onPilih(xs[i]),
          ),
      ],
    );
  }

  Widget _isiFreezer(List<Bahan> fz) => Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFCFDF8), Color(0xFFE9EEDF)],
              ),
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
        Positioned(left: 8, right: 8, top: 8, bottom: 22, child: Center(child: _deret(fz, 38, 128))),
        Positioned(
          left: 10,
          right: 10,
          bottom: 6,
          height: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: const LinearGradient(colors: [Colors.white, Color(0xFFD9E2CC)], stops: [.85, 1], tileMode: TileMode.repeated),
              boxShadow: const [BoxShadow(color: Color(0xFFC9D4BA), offset: Offset(0, 2))],
            ),
          ),
        ),
      ]);

  Widget _isiKulkas(List<Bahan> r1, List<Bahan> r2, List<Bahan> laci) => Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDF5), Color(0xFFF5EBD0)],
              ),
              border: Border.all(color: const Color(0xFFD8D3C9), width: 3),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 28,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2B8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                boxShadow: [BoxShadow(color: const Color(0xFFFFDC78).withValues(alpha: .85), blurRadius: 24, spreadRadius: 8)],
              ),
            ),
          ),
        ),
        Positioned(left: 6, right: 6, top: 14, height: 40, child: Align(alignment: Alignment.bottomCenter, child: _deret(r1, 40, 132))),
        const Positioned(left: 4, right: 4, top: 56, height: 4, child: _Kaca()),
        Positioned(left: 6, right: 6, top: 62, height: 42, child: Align(alignment: Alignment.bottomCenter, child: _deret(r2, 40, 132))),
        const Positioned(left: 4, right: 4, top: 106, height: 4, child: _Kaca()),
        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          height: 70,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(12)),
              color: const Color(0xFFB4DE8C).withValues(alpha: .45),
              border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 4),
            child: _deret(laci, 40, 126),
          ),
        ),
      ]);

  Widget _balikPintu(List<Bahan> pintu) {
    Widget rakPintu(List<Bahan> xs) => Container(
          height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: .3), const Color(0xFFDCE8CD).withValues(alpha: .8)],
            ),
            border: const Border(
              left: BorderSide(color: Color(0xCCA0B982), width: 2),
              right: BorderSide(color: Color(0xCCA0B982), width: 2),
              bottom: BorderSide(color: Color(0xCCA0B982), width: 2),
            ),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 3),
          child: _deret(xs, 24, 90),
        );
    return Column(children: [
      const SizedBox(height: 32),
      rakPintu(pintu.take(3).toList()),
      const SizedBox(height: 32),
      rakPintu(pintu.skip(3).take(3).toList()),
    ]);
  }
}

class _Kaca extends StatelessWidget {
  const _Kaca();
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE2D8BF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 2))],
        ),
      );
}

/// Satu kompartemen kulkas: isi di belakang + pintu 3D di depan.
class _Kompartemen extends StatefulWidget {
  final bool freezer;
  final bool buka;
  final String tag;
  final String label;
  final VoidCallback onPintu;
  final VoidCallback onSuhu;
  final Widget isi;
  final Widget? balikPintu;
  final String? catatan;
  final VoidCallback? onCatatan;

  const _Kompartemen({
    required this.freezer,
    required this.buka,
    required this.tag,
    required this.label,
    required this.onPintu,
    required this.onSuhu,
    required this.isi,
    this.balikPintu,
    this.catatan,
    this.onCatatan,
  });

  @override
  State<_Kompartemen> createState() => _KompartemenState();
}

class _KompartemenState extends State<_Kompartemen> with TickerProviderStateMixin {
  late final AnimationController _pintu =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 850), value: widget.buka ? 1 : 0);
  late final AnimationController _kabut = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didUpdateWidget(covariant _Kompartemen old) {
    super.didUpdateWidget(old);
    if (widget.buka != old.buka) {
      if (widget.buka) {
        _pintu.forward();
        if (widget.freezer) _kabut.forward(from: 0);
      } else {
        _pintu.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pintu.dispose();
    _kabut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: widget.isi),
      if (widget.freezer)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _kabut,
              builder: (_, __) => _kabut.isAnimating ? CustomPaint(painter: _KabutPainter(_kabut.value)) : const SizedBox(),
            ),
          ),
        ),
      Positioned(
        left: -3,
        top: -3,
        right: -3,
        bottom: -3,
        child: AnimatedBuilder(
          animation: _pintu,
          builder: (_, __) {
            final v = Curves.easeOutBack.transform(_pintu.value);
            final sudut = -114 * math.pi / 180 * v;
            final belakang = sudut.abs() > math.pi / 2;
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateY(sudut);
            return Transform(
              alignment: Alignment.centerLeft,
              transform: m,
              child: belakang
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: _belakang(),
                    )
                  : _depan(),
            );
          },
        ),
      ),
    ]);
  }

  Widget _belakang() => GestureDetector(
        onTap: widget.onPintu,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFFF7F8F1), Color(0xFFE9EDDF)]),
            border: Border.all(color: const Color(0xFFCBD6BC), width: 3),
          ),
          child: widget.balikPintu ?? const SizedBox.expand(),
        ),
      );

  Widget _depan() {
    return Semantics(
      button: true,
      label: '${widget.buka ? 'Tutup' : 'Buka'} ${widget.freezer ? 'freezer' : 'kulkas'}',
      child: GestureDetector(
        onTap: widget.onPintu,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFA3BA87), Color(0xFFC3D5AB), Color(0xFFB4C89A), Color(0xFF9DB582)],
              stops: [0, .42, .8, 1],
            ),
            border: Border.all(color: const Color(0x2E3C5028)),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(3, 3, 6, 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .6), borderRadius: BorderRadius.circular(9)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Emo(widget.freezer ? 'salju' : 'daun', size: 14),
                  const SizedBox(width: 3),
                  Text(widget.tag, style: AppText.body(10, color: const Color(0xFF3F5A33), weight: FontWeight.w900)),
                ]),
              ),
            ),
            Positioned(
              right: 11,
              top: widget.freezer ? null : 12,
              bottom: widget.freezer ? 12 : null,
              child: Container(
                width: 8,
                height: widget.freezer ? 40 : 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(colors: [AppColors.woodDark, AppColors.woodLight, Color(0xFF8A5A36)], stops: [0, .45, 1]),
                  boxShadow: const [BoxShadow(color: Color(0x2E000000), offset: Offset(1, 2), blurRadius: 2)],
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 6,
              child: GestureDetector(
                onTap: widget.onSuhu,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(widget.label.toUpperCase(),
                      style: AppText.body(9, color: AppColors.sageInk, weight: FontWeight.w800).copyWith(letterSpacing: 1.2)),
                ),
              ),
            ),
            if (widget.catatan != null)
              Positioned(left: 14, top: 40, child: _KertasCatatan(teks: widget.catatan!, onTap: widget.onCatatan!)),
            if (!widget.freezer) ...[
              const Positioned(left: 26, top: 128, child: _Magnet('tomat', -.2)),
              const Positioned(left: 66, top: 138, child: _Magnet('wortel', .25)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Magnet extends StatelessWidget {
  final String nama;
  final double rot;
  const _Magnet(this.nama, this.rot);
  @override
  Widget build(BuildContext context) => JellyTap(
        scale: .75,
        onTap: () {},
        child: Transform.rotate(angle: rot, child: Emo(nama, size: 24)),
      );
}

class _KertasCatatan extends StatefulWidget {
  final String teks;
  final VoidCallback onTap;
  const _KertasCatatan({required this.teks, required this.onTap});
  @override
  State<_KertasCatatan> createState() => _KertasCatatanState();
}

class _KertasCatatanState extends State<_KertasCatatan> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baris = widget.teks.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return Semantics(
      button: true,
      label: 'Edit catatan di pintu kulkas',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, c) => Transform.rotate(
            angle: -0.07 + math.sin(_c.value * math.pi * 2) * .04,
            alignment: Alignment.topCenter,
            child: c,
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 84,
              padding: const EdgeInsets.fromLTRB(7, 8, 7, 9),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF5C6),
                boxShadow: [BoxShadow(color: Color(0x2E000000), blurRadius: 5, offset: Offset(0, 3))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(child: Text('Catatan', style: AppText.body(9.5, color: const Color(0xFF5A4214), weight: FontWeight.w900))),
                  const Emo('pensil', size: 11),
                ]),
                if (baris.isEmpty)
                  Text('ketuk untuk menulis', style: AppText.body(8.5, color: const Color(0x995A4214)).copyWith(fontStyle: FontStyle.italic))
                else
                  for (final b in baris.take(4))
                    Text('· ${b.length > 13 ? '${b.substring(0, 12)}…' : b}',
                        style: AppText.body(8.5, color: const Color(0xFF5A4214), weight: FontWeight.w800, height: 1.35)),
                if (baris.length > 4)
                  Text('+${baris.length - 4} lagi', style: AppText.body(8, color: const Color(0xB35A4214))),
              ]),
            ),
            const Positioned(top: -9, left: 34, child: Emo('stroberi', size: 16)),
          ]),
        ),
      ),
    );
  }
}

class _ItemKulkas extends StatelessWidget {
  final Bahan bahan;
  final double size;
  final bool dipilih;
  final int urutan;
  final VoidCallback onTap;
  const _ItemKulkas({super.key, required this.bahan, required this.size, required this.dipilih, required this.urutan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + urutan * 55),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Transform.scale(scale: v.clamp(0.0, 1.2), alignment: Alignment.bottomCenter, child: c),
      child: Semantics(
        button: true,
        label: '${bahan.nama}, ${Hitung.sisaLabel(bahan)}',
        child: GestureDetector(
          onTap: onTap,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            AnimatedScale(
              scale: dipilih ? 1.25 : 1,
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              alignment: Alignment.bottomCenter,
              child: VeggieImage(bahan, size: size),
            ),
            if (dipilih)
              Positioned(
                bottom: size + 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF22301F), borderRadius: BorderRadius.circular(10)),
                  child: Text('${bahan.nama} · ${Hitung.sisaLabel(bahan)}',
                      style: AppText.body(10, color: Colors.white, weight: FontWeight.w800)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _KabutPainter extends CustomPainter {
  final double t;
  _KabutPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    for (var i = 0; i < 12; i++) {
      final mulai = Offset(rnd.nextDouble() * s.width, s.height * (.4 + rnd.nextDouble() * .6));
      final arah = Offset(-30 - rnd.nextDouble() * 40, 10 + rnd.nextDouble() * 30);
      final u = (t - i * .03).clamp(0.0, 1.0);
      final pos = mulai + arah * u;
      final r = 10 + 16 * u;
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: .9 * (1 - u)), Colors.white.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: pos, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_KabutPainter old) => old.t != t;
}
