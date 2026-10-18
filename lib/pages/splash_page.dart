import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/katalog.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/transisi_dapur.dart';
import 'auth_page.dart';
import 'shell_page.dart';

/// Animasi pembuka: kulkas terbuka, sayur melompat keluar, lalu muat data.
/// Memakai FutureBuilder untuk memuat katalog dari API (materi Pertemuan 6).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
  late final AnimationController _putar = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  late Future<List<SayurInfo>> _katalog;
  late final Future<bool> _sesi;
  bool _pergi = false;

  @override
  void initState() {
    super.initState();
    _katalog = AppState.i.muatKatalog();
    _sesi = AppState.i.pulihkanSesi();
    _a.forward();
    _a.addStatusListener((s) {
      if (s == AnimationStatus.completed) _lanjut();
    });
  }

  @override
  void dispose() {
    _a.dispose();
    _putar.dispose();
    super.dispose();
  }

  Future<void> _lanjut() async {
    if (_pergi) return;
    _pergi = true;
    bool masuk = false;
    try {
      await _katalog;
      masuk = await _sesi;
    } catch (_) {
      _pergi = false;
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;
    if (masuk) {
      // sudah pernah masuk: langsung animasi "masuk ke dapur"
      Navigator.of(context).pushReplacement(RuteDapur(const ShellPage()));
      return;
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (_, __, ___) => const AuthPage(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(anim), child: child),
      ),
    ));
  }

  double _iv(double a, double b, [Curve c = Curves.easeOut]) =>
      c.transform(((_a.value * 4.5 - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_a.value < 1) _a.value = 1;
          _lanjut();
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -.2), radius: 1.1, colors: [Color(0xFFFFF8E6), AppColors.cream]),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_a, _putar]),
              builder: (context, _) => LayoutBuilder(builder: (context, c) => _isi(c.maxWidth, c.maxHeight)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _isi(double w, double h) {
    final cx = w / 2, cy = h * .4;
    final jatuh = _iv(.15, .95, Curves.elasticOut);
    final pintuB = _iv(1.05, 2.1, Curves.easeOutBack);
    final pintuA = _iv(1.6, 2.6, Curves.easeOutBack);
    final cahaya = _iv(1.05, 2.4);
    final lampu = _a.value * 4.5 > 1.6 ? 1.0 : (_a.value * 4.5 > .95 ? ((_a.value * 4.5 * 12).floor() % 2 == 0 ? 1.0 : .3) : 0.0);
    final judulMulai = 1.7;
    const kata = 'Kulkasku.';
    const slogan = 'KULKAS RAPI · NGGAK ADA YANG KEBUANG';
    final huruf = ((_a.value * 4.5 - 2.4) / .025).clamp(0, slogan.length.toDouble()).floor();
    final pesan = ['Menyalakan kulkas…', 'Menata sayur & buah…', 'Mengecek tanggal layu…', 'Siap!'][(_a.value * 4.5 / 1.15).floor().clamp(0, 3).toInt()];

    const V = [
      ['brokoli', -128.0, -192.0, 50.0],
      ['stroberi', -58.0, -214.0, 40.0],
      ['jagung', 16.0, -222.0, 46.0],
      ['tomat', 92.0, -206.0, 52.0],
      ['bayam', 150.0, -142.0, 60.0],
      ['apel', 160.0, -40.0, 48.0],
      ['wortel', 150.0, 62.0, 52.0],
    ];

    return Stack(clipBehavior: Clip.none, children: [
      // ubin dinding & lantai muncul pelan
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: cy + 112,
        child: Opacity(opacity: _iv(.2, 1.2) * .9, child: CustomPaint(painter: _UbinPainter())),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: cy + 112,
        height: 10,
        child: Opacity(
          opacity: _iv(.3, 1.1),
          child: const DecoratedBox(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE2C9A4), AppColors.cream])),
          ),
        ),
      ),
      // sinar
      Positioned(
        left: cx - 160,
        top: cy - 130,
        child: Opacity(
          opacity: cahaya * .55,
          child: Transform.rotate(angle: _putar.value * math.pi * 2, child: CustomPaint(size: const Size(320, 320), painter: _SinarPainter())),
        ),
      ),
      Positioned(
        left: cx - 150,
        top: cy - 120,
        child: Opacity(
          opacity: cahaya * .8,
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0xBFFFE28C), Color(0x00FFE28C)], stops: [0, .65]),
            ),
          ),
        ),
      ),
      // bayangan kulkas
      Positioned(
        left: cx - 84 + 22,
        top: cy + 104,
        child: Opacity(
          opacity: jatuh.clamp(0.0, 1.0),
          child: Container(
            width: 168,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x4D5A4026), Color(0x005A4026)]),
            ),
          ),
        ),
      ),
      // kulkas
      Positioned(
        left: cx - 78 + 22,
        top: cy - 140 - (1 - jatuh) * 400,
        child: Opacity(
          opacity: jatuh.clamp(0.0, 1.0),
          child: _KulkasSplash(pintuBawah: pintuB, pintuAtas: pintuA, lampu: lampu, bangun: _iv(1.3, 2.0, Curves.elasticOut)),
        ),
      ),
      // sayur melompat keluar
      for (var i = 0; i < V.length; i++)
        Builder(builder: (_) {
          final mulai = 1.25 + i * .12;
          final u = _iv(mulai, mulai + .85, Curves.easeOutBack);
          final dx = (V[i][1] as double) * u;
          final dy = (V[i][2] as double) * u - math.sin(u.clamp(0.0, 1.0) * math.pi) * 70 + (1 - u) * 40;
          final s = V[i][3] as double;
          final menari = _a.value * 4.5 > 2.7 ? math.sin((_a.value * 4.5 - 2.7 - i * .07) * 12) * .2 : 0.0;
          return Positioned(
            left: cx + 22 + dx - s / 2,
            top: cy + dy - s / 2,
            child: Opacity(
              opacity: (u * 3).clamp(0.0, 1.0),
              child: Transform.rotate(angle: menari, child: Transform.scale(scale: .15 + .85 * u.clamp(0.0, 1.0), child: Emo(V[i][0] as String, size: s))),
            ),
          );
        }),
      // judul huruf demi huruf
      Positioned(
        left: 0,
        right: 0,
        top: cy + 128,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < kata.length; i++)
            Builder(builder: (_) {
              final u = _iv(judulMulai + i * .07, judulMulai + i * .07 + .6, Curves.elasticOut);
              final lompat = _a.value * 4.5 > 2.6 ? math.max(0.0, math.sin((_a.value * 4.5 - 2.6 - i * .06) * 8)) * 10 : 0.0;
              return Opacity(
                opacity: u.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -40 * (1 - u) - lompat),
                  child: Transform.rotate(angle: -.2 * (1 - u), child: Text(kata[i], style: AppText.display(54, color: AppColors.leaf, italic: false))),
                ),
              );
            }),
        ]),
      ),
      if (_a.value * 4.5 > 2.3)
        for (final b in const [[-130.0, -6.0, 0.0], [110.0, -20.0, .5], [150.0, 30.0, .9], [-160.0, 40.0, 1.3]])
          Positioned(
            left: cx + b[0],
            top: cy + 128 + b[1],
            child: Opacity(
              opacity: (.5 - .5 * math.cos((_a.value * 4.5 - 2.3 - b[2]) * math.pi * 2 / 1.6)).clamp(0.0, 1.0),
              child: const Emo('kilau', size: 20),
            ),
          ),
      Positioned(
        left: 0,
        right: 0,
        top: cy + 192,
        child: Text(slogan.substring(0, huruf), textAlign: TextAlign.center, style: AppText.label(color: const Color(0xFF5A6650))),
      ),
      // sulur loading + pesan
      Positioned(
        left: 0,
        right: 0,
        bottom: 70,
        child: FutureBuilder<List<SayurInfo>>(
          future: _katalog,
          builder: (context, snap) {
            if (snap.hasError) {
              return Column(children: [
                Text('Gagal memuat data. Cek internet kamu.', style: AppText.body(12, color: AppColors.tomatoDark)),
                TextButton(
                  onPressed: () => setState(() {
                    _katalog = AppState.i.muatKatalog();
                    _lanjut();
                  }),
                  child: const Text('Coba lagi'),
                ),
              ]);
            }
            return Column(children: [
              SizedBox(width: 190, height: 18, child: CustomPaint(painter: _SulurPainter(_iv(.3, 3.3)))),
              const SizedBox(height: 8),
              Text(snap.connectionState == ConnectionState.done ? pesan : 'Mengambil data sayur…',
                  style: AppText.body(12, color: AppColors.muted, weight: FontWeight.w800)),
            ]);
          },
        ),
      ),
      Positioned(
        right: 16,
        top: 12,
        child: Opacity(
          opacity: _iv(1, 1.4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .7), borderRadius: BorderRadius.circular(14)),
            child: Text('Ketuk untuk lewati', style: AppText.body(12, color: AppColors.muted, weight: FontWeight.w800)),
          ),
        ),
      ),
    ]);
  }
}

/// Kulkas krem di animasi pembuka (pintu terbuka 3D, isi lengkap).
class _KulkasSplash extends StatelessWidget {
  final double pintuBawah, pintuAtas, lampu, bangun;
  const _KulkasSplash({required this.pintuBawah, required this.pintuAtas, required this.lampu, required this.bangun});

  static const _krem = LinearGradient(colors: [Color(0xFFE5CB90), Color(0xFFFFF6DA), Color(0xFFE8D198)], stops: [0, .42, 1]);

  Widget _pintu(double v, Widget depan, Widget belakang, BorderRadius r) {
    final sudut = -138 * math.pi / 180 * v;
    final balik = sudut.abs() > math.pi / 2;
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0007)
        ..rotateY(sudut),
      child: balik ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: belakang) : depan,
    );
  }

  Widget _rakPintu(double tinggi, List<String> isi, double ukuran) => Container(
        height: tinggi,
        margin: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: .2), const Color(0xFFD6E8F0).withValues(alpha: .4)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: .95), width: 1.5),
        ),
        alignment: Alignment.bottomCenter,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [for (final n in isi) Emo(n, size: ukuran)]),
      );

  Widget _baris(List<List<Object>> isi, double mulai) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final x in isi)
            Transform.scale(scale: .8 + .2 * bangun, alignment: Alignment.bottomCenter, child: Emo(x[0] as String, size: x[1] as double)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    const gasket = Border.fromBorderSide(BorderSide(color: Color(0xFFD8D3C9), width: 3));
    return SizedBox(
      width: 156,
      height: 256,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          top: -15,
          left: 0,
          right: 0,
          child: Center(child: Text('KULKASKU', style: AppText.body(8, color: const Color(0xFFB08A4C), weight: FontWeight.w900).copyWith(letterSpacing: 2.4))),
        ),
        // freezer
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 80,
          child: Container(
            decoration: const BoxDecoration(gradient: _krem, borderRadius: BorderRadius.vertical(top: Radius.circular(22), bottom: Radius.circular(6))),
            padding: const EdgeInsets.all(7),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(4)),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEEF0EA)]),
                border: gasket,
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 4),
              child: _baris(const [['jagung', 28.0], ['salju', 16.0], ['brokoli', 26.0], ['salju', 12.0]], 1.75),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 80,
          child: _pintu(
            pintuAtas,
            Container(
              decoration: const BoxDecoration(gradient: _krem, borderRadius: BorderRadius.vertical(top: Radius.circular(22), bottom: Radius.circular(6))),
              child: Stack(children: [
                Positioned(left: 12, top: 12, child: Text('❄ freezer', style: AppText.body(9, color: const Color(0xFF9C7B45), weight: FontWeight.w900))),
                Positioned(right: 10, top: 34, child: Container(width: 6, height: 30, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: AppColors.wood))),
              ]),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22), bottom: Radius.circular(6)),
                gradient: const LinearGradient(colors: [Color(0xFFEFE7D6), Color(0xFFFBF7EE), Color(0xFFF1E9D9)]),
                border: Border.all(color: const Color(0xFFD8D3C9), width: 3),
              ),
              child: Column(children: [
                const SizedBox(height: 12),
                _rakPintu(22, ['jagung', 'brokoli'], 18),
                const SizedBox(height: 8),
                _rakPintu(20, ['salju', 'salju'], 13),
              ]),
            ),
            const BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
        // kulkas bawah
        Positioned(
          left: 0,
          right: 0,
          top: 84,
          height: 160,
          child: Container(
            decoration: const BoxDecoration(gradient: _krem, borderRadius: BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(22))),
            padding: const EdgeInsets.all(7),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(16)),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFDF5), Color(0xFFF7EBCB)]),
                border: gasket,
              ),
              child: Stack(children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2B8).withValues(alpha: lampu),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFDC78).withValues(alpha: .85 * lampu), blurRadius: 26, spreadRadius: 8)],
                      ),
                    ),
                  ),
                ),
                Positioned(left: 4, right: 4, top: 10, height: 34, child: _baris(const [['tomat', 30.0], ['apel', 28.0], ['stroberi', 22.0]], 1.3)),
                Positioned(left: 3, right: 3, top: 44, height: 4, child: Container(color: const Color(0xFFE2D8BF))),
                Positioned(left: 4, right: 4, top: 50, height: 36, child: _baris(const [['wortel', 32.0], ['paprika', 26.0], ['timun', 28.0]], 1.45)),
                Positioned(left: 3, right: 3, top: 88, height: 4, child: Container(color: const Color(0xFFE2D8BF))),
                Positioned(
                  left: 4,
                  right: 4,
                  bottom: 4,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFB4DE8C).withValues(alpha: .6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(10)),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Transform.translate(offset: const Offset(0, 8), child: _baris(const [['bayam', 40.0], ['brokoli', 34.0], ['bayam', 36.0]], 1.6)),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 84,
          height: 160,
          child: _pintu(
            pintuBawah,
            Container(
              decoration: const BoxDecoration(gradient: _krem, borderRadius: BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(22))),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(right: 10, top: 12, child: Container(width: 6, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: AppColors.wood))),
                Positioned(
                  left: 14,
                  top: 22,
                  child: Transform.rotate(
                    angle: -.07,
                    child: Container(
                      width: 64,
                      padding: const EdgeInsets.all(5),
                      color: const Color(0xFFFFF5C6),
                      child: Text('Belanja:\n· tahu\n· susu', style: AppText.body(8, color: const Color(0xFF5A4214), weight: FontWeight.w800, height: 1.3)),
                    ),
                  ),
                ),
                Positioned(left: 20, top: 84, child: Transform.rotate(angle: -.2, child: const Emo('tomat', size: 22))),
                Positioned(left: 54, top: 96, child: Transform.rotate(angle: .25, child: const Emo('wortel', size: 22))),
              ]),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(22)),
                gradient: const LinearGradient(colors: [Color(0xFFEFE7D6), Color(0xFFFBF7EE), Color(0xFFF1E9D9)]),
                border: Border.all(color: const Color(0xFFD8D3C9), width: 3),
              ),
              child: Column(children: [
                const SizedBox(height: 10),
                _rakPintu(24, ['stroberi', 'anggur'], 20),
                const SizedBox(height: 20),
                _rakPintu(34, ['jeruk', 'kiwi', 'apel'], 24),
                const SizedBox(height: 14),
                _rakPintu(38, ['pisang', 'mangga'], 28),
              ]),
            ),
            const BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
        ),
        Positioned(left: 14, bottom: 6, child: Container(width: 16, height: 6, color: const Color(0xFF6B6156))),
        Positioned(right: 14, bottom: 6, child: Container(width: 16, height: 6, color: const Color(0xFF6B6156))),
      ]),
    );
  }
}

class _UbinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final garis = Paint()
      ..color = const Color(0x8CD5E5C6)
      ..strokeWidth = 2;
    for (double x = 0; x < s.width; x += 39) {
      canvas.drawLine(Offset(x, 0), Offset(x, s.height), garis);
    }
    for (double y = s.height; y > 0; y -= 39) {
      canvas.drawLine(Offset(0, y), Offset(s.width, y), garis);
    }
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cream, Color(0x00F3EFE7)],
          stops: [0, .4],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SinarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final p = Paint()..color = const Color(0xFFFFE39A);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + math.cos(a - .05) * 48, c.dy + math.sin(a - .05) * 48)
          ..lineTo(c.dx + math.cos(a) * 157, c.dy + math.sin(a) * 157)
          ..lineTo(c.dx + math.cos(a + .05) * 48, c.dy + math.sin(a + .05) * 48)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SulurPainter extends CustomPainter {
  final double v;
  _SulurPainter(this.v);
  @override
  void paint(Canvas canvas, Size s) {
    final jalur = Path()
      ..moveTo(2, 12)
      ..cubicTo(40, 4, 70, 16, 100, 10)
      ..cubicTo(130, 4, 160, 4, 188, 10);
    final kuas = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(jalur, kuas..color = const Color(0xFFE2D8C2));
    final metric = jalur.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * v), kuas..color = const Color(0xFF5FAE52));
    for (var i = 0; i < 5; i++) {
      final pos = (i + 1) / 6;
      if (v < pos) continue;
      final t = metric.getTangentForOffset(metric.length * pos);
      if (t == null) continue;
      final skala = ((v - pos) / .08).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(t.position.dx, t.position.dy);
      canvas.scale(skala);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(-6, -8, 2, -14, 8, -12)
          ..cubicTo(8, -5, 4, -1, 0, 0)
          ..close(),
        Paint()..color = const Color(0xFF5FAE52),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SulurPainter old) => old.v != v;
}
