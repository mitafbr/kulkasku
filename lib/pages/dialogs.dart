import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/logic.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mumu.dart';

// =====================================================================
//  SUHU KULKAS / FREEZER
// =====================================================================
Future<void> aturSuhu(BuildContext context, String k) async {
  final u = AppState.i.user;
  if (u == null) return;
  final fz = k == 'fz';
  final min = fz ? -24 : 0, max = fz ? -10 : 10;
  var v = fz ? u.suhuFz : u.suhuKl;
  final preset = fz ? const [(-22, 'Super dingin'), (-18, 'Standar'), (-14, 'Hemat listrik')] : const [(2, 'Dingin'), (4, 'Ideal'), (7, 'Kurang dingin')];

  final simpan = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(builder: (c, set) {
      final p = (v - min) / (max - min);
      final warna = fz
          ? (v <= -18 ? const Color(0xFF7FB3D5) : v <= -15 ? const Color(0xFF9CC7B0) : const Color(0xFFE9A23B))
          : (v <= 4 ? const Color(0xFF5FAE52) : v <= 6 ? const Color(0xFFE9A23B) : const Color(0xFFE46A4B));
      final lama = fz ? Hitung.suhuFz : Hitung.suhuKl;
      if (fz) {
        Hitung.suhuFz = v;
      } else {
        Hitung.suhuKl = v;
      }
      final pct = ((Hitung.faktorSuhu(fz ? 'freezer' : 'rak') - 1) * 100).round();
      if (fz) {
        Hitung.suhuFz = lama;
      } else {
        Hitung.suhuKl = lama;
      }
      final saran = fz
          ? (v <= -18 ? 'Pas! Beku aman.' : v <= -15 ? 'Masih oke, sedikit kurang dingin.' : 'Terlalu hangat untuk freezer.')
          : (v <= 1 ? 'Sangat dingin, sayur daun bisa beku.' : v <= 4 ? 'Ideal untuk sayur & buah.' : v <= 6 ? 'Agak hangat, cepat layu.' : 'Terlalu hangat!');
      return Dialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          if (fz) const Positioned.fill(child: _Salju()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Emo('termo', size: 30),
                const SizedBox(width: 8),
                Text('Suhu ${fz ? 'freezer' : 'kulkas'}', style: AppText.display(26)),
              ]),
              const SizedBox(height: 6),
              Text('Tiap kulkas beda. Samakan dengan angka di termometer atau pengatur suhu kulkasmu.',
                  style: AppText.body(12.5, color: AppColors.muted, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                SizedBox(
                  width: 52,
                  height: 190,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: p),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (_, x, __) => CustomPaint(painter: _TermometerPainter(x.clamp(0.0, 1.0), warna)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: AppText.display(46, color: warna, italic: false),
                      child: Text(formatSuhu(v)),
                    ),
                    Row(children: [
                      RoundBtn(size: 34, onTap: () => set(() => v = math.max(min, v - 1)), semantik: 'Turunkan', child: const Icon(Icons.remove, size: 18)),
                      Expanded(
                        child: Slider(
                          value: v.toDouble(),
                          min: min.toDouble(),
                          max: max.toDouble(),
                          divisions: max - min,
                          activeColor: AppColors.leaf,
                          onChanged: (x) => set(() => v = x.round()),
                        ),
                      ),
                      RoundBtn(size: 34, onTap: () => set(() => v = math.min(max, v + 1)), semantik: 'Naikkan', child: const Icon(Icons.add, size: 18)),
                    ]),
                    Text(saran, style: AppText.body(12, color: warna, weight: FontWeight.w800)),
                    Text(pct == 0 ? 'Perkiraan layu normal' : pct > 0 ? 'Tahan ±$pct% lebih lama' : 'Layu ±${-pct}% lebih cepat',
                        style: AppText.body(12, color: AppColors.muted)),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                for (final pr in preset)
                  JellyTap(
                    onTap: () => set(() => v = pr.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(color: v == pr.$1 ? AppColors.leaf : const Color(0xFFF1EBDD), borderRadius: BorderRadius.circular(14)),
                      child: Text('${formatSuhu(pr.$1)} · ${pr.$2}',
                          style: AppText.body(12, color: v == pr.$1 ? Colors.white : AppColors.ink, weight: FontWeight.w800)),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Batal', style: AppText.body(14, color: AppColors.leaf))),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
                  onPressed: () => Navigator.pop(c, true),
                  child: Text('Simpan', style: AppText.body(14, color: Colors.white)),
                ),
              ]),
            ]),
          ),
        ]),
      );
    }),
  );
  if (simpan != true) return;
  try {
    await AppState.i.ubahPengaturan((p) {
      if (fz) {
        p.suhuFz = v;
      } else {
        p.suhuKl = v;
      }
    });
    if (context.mounted) {
      toast(context, 'Suhu ${fz ? 'freezer' : 'kulkas'} ${formatSuhu(v)}. Tanggal layu & pengingat dihitung ulang.', ikon: 'termo');
    }
  } catch (e) {
    if (context.mounted) toast(context, 'Gagal menyimpan: $e', ikon: 'tanya');
  }
}

class _TermometerPainter extends CustomPainter {
  final double p;
  final Color warna;
  _TermometerPainter(this.p, this.warna);
  @override
  void paint(Canvas canvas, Size s) {
    final tabung = RRect.fromRectAndRadius(const Rect.fromLTWH(13, 0, 20, 160), const Radius.circular(12));
    canvas.drawRRect(tabung, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipRRect(tabung);
    final tinggi = 160 * (.14 + p * .86);
    canvas.drawRect(Rect.fromLTWH(13, 160 - tinggi, 20, tinggi), Paint()..color = warna);
    canvas.restore();
    canvas.drawRRect(tabung, Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawCircle(const Offset(23, 168), 20, Paint()..color = warna);
    canvas.drawCircle(const Offset(23, 168), 20, Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(Offset(38, 14.0 + i * 32), Offset(46, 14.0 + i * 32), Paint()
        ..color = const Color(0xFFD6CCB5)
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_TermometerPainter old) => old.p != p || old.warna != warna;
}

class _Salju extends StatefulWidget {
  const _Salju();
  @override
  State<_Salju> createState() => _SaljuState();
}

class _SaljuState extends State<_Salju> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _SaljuPainter(_c.value))),
      );
}

class _SaljuPainter extends CustomPainter {
  final double t;
  _SaljuPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFFE8F1F6);
    for (var i = 0; i < 16; i++) {
      final x = (i * 37 % 100) / 100 * s.width + math.sin((t + i) * math.pi * 2) * 8;
      final y = ((t * (1 + i % 3 * .3) + i / 16) % 1) * s.height;
      canvas.drawCircle(Offset(x, y), 3, p);
    }
  }

  @override
  bool shouldRepaint(_SaljuPainter old) => old.t != t;
}

// =====================================================================
//  CATATAN DI PINTU KULKAS
// =====================================================================
Future<void> editCatatan(BuildContext context) async {
  final s = AppState.i;
  final u = s.user;
  if (u == null) return;
  final ctl = TextEditingController(text: u.catatan);
  final saran = s.bahan.where((b) => Hitung.status(b) != Status.segar).map((b) => b.nama).toSet().toList();

  final simpan = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(builder: (c, set) {
      return Dialog(
        backgroundColor: const Color(0xFFFFF8D6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Transform.rotate(
          angle: -.012,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Emo('stroberi', size: 30),
                const SizedBox(width: 8),
                Text('Catatan kulkas', style: AppText.display(28)),
              ]),
              const SizedBox(height: 6),
              Text('Tulis apa saja: daftar belanja, pengingat, atau pesan untuk keluarga. Satu baris satu catatan.',
                  style: AppText.body(12.5, color: AppColors.muted, weight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: ctl,
                autofocus: true,
                maxLines: 5,
                maxLength: 160,
                style: AppText.body(15, color: const Color(0xFF5A4214), height: 1.6),
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              if (saran.isNotEmpty) ...[
                Text('TAMBAH CEPAT · PERLU DIBELI LAGI', style: AppText.label(size: 10.5)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final n in saran)
                    ActionChip(
                      label: Text('+ $n', style: AppText.body(12)),
                      backgroundColor: Colors.white,
                      onPressed: () => set(() {
                        final t = ctl.text.trimRight();
                        ctl.text = t.isEmpty ? n : '$t\n$n';
                      }),
                    ),
                ]),
              ],
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Batal', style: AppText.body(14, color: AppColors.leaf))),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
                  onPressed: () => Navigator.pop(c, true),
                  child: Text('Tempel', style: AppText.body(14, color: Colors.white)),
                ),
              ]),
            ]),
          ),
        ),
      );
    }),
  );
  final teks = ctl.text;
  ctl.dispose();
  if (simpan != true) return;
  try {
    await s.ubahPengaturan((p) => p.catatan = teks.length > 160 ? teks.substring(0, 160) : teks);
    if (context.mounted) toast(context, 'Catatan ditempel di pintu kulkas', ikon: 'pensil');
  } catch (e) {
    if (context.mounted) toast(context, 'Gagal menyimpan: $e', ikon: 'tanya');
  }
}

// =====================================================================
//  PERAYAAN SAAT SAYUR DIPAKAI
// =====================================================================
Future<void> tampilkanPerayaan(BuildContext context, Bahan b) async {
  final nav = Navigator.of(context);
  var terbuka = true;
  Future.delayed(const Duration(milliseconds: 1900), () {
    if (terbuka && nav.canPop()) nav.pop();
  });
  await showDialog<void>(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        const Positioned.fill(child: _Konfeti()),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              const MumuMini(size: 86, mood: MumuMood.senang),
              Melayang(child: Emo(b.jenis, size: 96)),
            ]),
            const SizedBox(height: 6),
            Text('Mantap!', style: AppText.display(34, color: AppColors.leaf)),
            const SizedBox(height: 6),
            Text('${b.nama} berhasil diselamatkan sebelum layu.',
                textAlign: TextAlign.center, style: AppText.body(15, color: AppColors.muted)),
          ]),
        ),
      ]),
    ),
  );
  terbuka = false;
}

class _Konfeti extends StatefulWidget {
  const _Konfeti();
  @override
  State<_Konfeti> createState() => _KonfetiState();
}

class _KonfetiState extends State<_Konfeti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _KonfetiPainter(_c.value))));
}

class _KonfetiPainter extends CustomPainter {
  final double t;
  _KonfetiPainter(this.t);
  static const _warna = [Color(0xFFA8D86E), Color(0xFFE8701A), Color(0xFFD93A2B), Color(0xFFF2C14E), Color(0xFF2F7D3A)];
  @override
  void paint(Canvas canvas, Size s) {
    for (var i = 0; i < 22; i++) {
      final a = (math.sin(i * 91.7) + 1) / 2;
      final mulai = ((math.sin(i * 37.1) + 1) / 2) * .3;
      final p = ((t - mulai) / .7).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      canvas.save();
      canvas.translate(a * s.width + math.sin(p * 6 + i) * 18, -20 + p * (s.height + 40));
      canvas.rotate(p * 8 + i);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -3, 10, 6), const Radius.circular(2)), Paint()..color = _warna[i % 5]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_KonfetiPainter old) => old.t != t;
}
