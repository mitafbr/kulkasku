import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/logic.dart';
import '../theme.dart';

/// Gambar 3D (Fluent Emoji, MIT) dari folder assets/emoji.
class Emo extends StatelessWidget {
  final String nama;
  final double size;

  /// Gambar pengganti kalau [nama] tidak ada (misalnya gambar kondisi layu).
  final String? cadangan;
  const Emo(this.nama, {super.key, this.size = 24, this.cadangan});

  static const _png = {'champ', 'kulkas'};

  static String path(String nama) => 'assets/emoji/$nama.${_png.contains(nama) ? 'png' : 'webp'}';

  @override
  Widget build(BuildContext context) => Image.asset(
        path(nama),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => cadangan == null ? SizedBox(width: size, height: size) : Emo(cadangan!, size: size),
      );
}

/// Tombol yang "kenyal" saat ditekan (efek jelly).
class JellyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semantik;
  const JellyTap({super.key, required this.child, this.onTap, this.scale = 0.93, this.semantik});

  @override
  State<JellyTap> createState() => _JellyTapState();
}

class _JellyTapState extends State<JellyTap> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _nilai(double t) {
    // turun cepat lalu memantul (wobble)
    if (t < .18) return 1 - (1 - widget.scale) * (t / .18);
    final u = (t - .18) / .82;
    return 1 - (1 - widget.scale) * math.exp(-5 * u) * math.cos(u * math.pi * 3);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semantik,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap == null
            ? null
            : () {
                _c.forward(from: 0);
                widget.onTap!();
              },
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final s = _c.isAnimating ? _nilai(_c.value) : 1.0;
            return Transform.scale(scaleX: 2 - s, scaleY: s, child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Cincin persen kesegaran.
class FreshRing extends StatelessWidget {
  final double nilai;
  final Color warna;
  final double size;
  final double tebal;
  final String label;
  final Color? warnaLabel;
  const FreshRing({
    super.key,
    required this.nilai,
    required this.warna,
    this.size = 36,
    this.tebal = 4.5,
    this.label = '',
    this.warnaLabel,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: nilai.clamp(0.04, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, warna, tebal),
          child: Center(
            child: Text(label,
                style: AppText.body(size * .26, color: warnaLabel ?? AppColors.ink, weight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color c;
  final double w;
  _RingPainter(this.v, this.c, this.w);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..color = c.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w);
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.c != c;
}

class StatusChip extends StatelessWidget {
  final Status status;
  final String teks;
  const StatusChip(this.status, this.teks, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: status.muda, borderRadius: BorderRadius.circular(10)),
        child: Text(teks, style: AppText.body(11, color: status.warna, weight: FontWeight.w900)),
      );
}

/// Tombol besar bergaya "chunky" dengan bayangan padat.
class ChunkyButton extends StatelessWidget {
  final String label;
  final String? ikon;
  final VoidCallback? onTap;
  final Color warna;
  final Color bayangan;
  final bool memuat;
  const ChunkyButton({
    super.key,
    required this.label,
    this.ikon,
    this.onTap,
    this.warna = AppColors.leaf,
    this.bayangan = AppColors.leafDark,
    this.memuat = false,
  });

  @override
  Widget build(BuildContext context) {
    return JellyTap(
      onTap: memuat ? null : onTap,
      semantik: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? .55 : 1,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: bayangan, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (memuat)
                const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              else if (ikon != null)
                Emo(ikon!, size: 26),
              const SizedBox(width: 8),
              Text(label, style: AppText.body(16, color: Colors.white, weight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class LeafChip extends StatelessWidget {
  final String label;
  final String? ikon;
  final bool aktif;
  final VoidCallback onTap;
  const LeafChip({super.key, required this.label, this.ikon, required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return JellyTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
        decoration: BoxDecoration(
          color: aktif ? AppColors.leaf : Colors.white,
          borderRadius: leafRadius(20),
          border: Border.all(color: aktif ? AppColors.leaf : AppColors.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (ikon != null) ...[Emo(ikon!, size: 20), const SizedBox(width: 6)],
          Text(label, style: AppText.body(13.5, color: aktif ? Colors.white : AppColors.ink, weight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class RoundBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;
  final Color warna;
  final String? semantik;
  const RoundBtn({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 46,
    this.warna = Colors.white,
    this.semantik,
  });

  @override
  Widget build(BuildContext context) => JellyTap(
        onTap: onTap,
        semantik: semantik,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: warna,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      );
}

class TombolKembali extends StatelessWidget {
  final VoidCallback? onTap;
  const TombolKembali({super.key, this.onTap});
  @override
  Widget build(BuildContext context) => RoundBtn(
        semantik: 'Kembali',
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
      );
}

/// Judul halaman: label kecil + judul serif besar + ikon opsional.
class PageHead extends StatelessWidget {
  final String label;
  final String judul;
  final Widget? ikon;
  const PageHead(this.label, this.judul, {super.key, this.ikon});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label.toUpperCase(), style: AppText.label()),
              const SizedBox(height: 4),
              Text(judul, style: AppText.display(42)),
            ]),
          ),
          if (ikon != null) ikon!,
        ],
      );
}

/// Muncul naik + memudar saat pertama tampil (stagger dengan [delay]).
class Naik extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const Naik({super.key, required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delayMs),
      curve: Interval(delayMs / (520 + delayMs), 1, curve: Curves.easeOutBack),
      builder: (_, t, c) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}

/// Melayang naik-turun pelan (dipakai banyak elemen dekorasi).
class Melayang extends StatefulWidget {
  final Widget child;
  final double jarak;
  final Duration durasi;
  final double fase;
  const Melayang({
    super.key,
    required this.child,
    this.jarak = 6,
    this.durasi = const Duration(milliseconds: 3400),
    this.fase = 0,
  });

  @override
  State<Melayang> createState() => _MelayangState();
}

class _MelayangState extends State<Melayang> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.durasi)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
        animation: _c,
        builder: (_, c) => Transform.translate(
          offset: Offset(0, -widget.jarak * (0.5 - 0.5 * math.cos((_c.value + widget.fase) * math.pi * 2))),
          child: c,
        ),
        child: widget.child,
      ),
      );
}

void toast(BuildContext context, String pesan, {String ikon = 'daun'}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 2600),
      content: Row(children: [
        Emo(ikon, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(pesan, style: AppText.body(14, color: Colors.white))),
      ]),
    ));
}

/// Dialog konfirmasi bergaya Kulkasku.
Future<bool> konfirmasi(BuildContext context,
    {required String judul, required String isi, String ya = 'Ya', String ikon = 'tanya', Color? warnaYa}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Emo(ikon, size: 40),
          const SizedBox(height: 8),
          Text(judul, style: AppText.display(26)),
          const SizedBox(height: 8),
          Text(isi, style: AppText.body(14, color: AppColors.muted, weight: FontWeight.w600, height: 1.45)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Batal', style: AppText.body(14, color: AppColors.leaf))),
            const SizedBox(width: 6),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: warnaYa ?? AppColors.tomato),
              onPressed: () => Navigator.pop(c, true),
              child: Text(ya, style: AppText.body(14, color: Colors.white)),
            ),
          ]),
        ]),
      ),
    ),
  );
  return hasil ?? false;
}

// ===================================================================== responsif

/// Lebar minimum untuk tampilan laptop/PC (landscape). Di bawah ini = tampilan HP.
const double batasLebar = 760;

/// true kalau layar cukup lebar untuk tata letak landscape (laptop, PC, tablet mendatar).
bool layarLebar(BuildContext context) => MediaQuery.sizeOf(context).width >= batasLebar;

/// Membatasi lebar isi halaman dan menaruhnya di tengah (dipakai di layar lebar),
/// supaya formulir dan teks tidak melebar sampai ujung layar laptop.
class IsiTengah extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const IsiTengah({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, k) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(k.maxWidth, maxWidth),
            height: k.maxHeight,
            child: child,
          ),
        ),
      );
}
