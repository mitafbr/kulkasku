import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/branch_nav.dart';
import '../widgets/common.dart';
import '../widgets/mumu.dart';
import 'form_bahan_page.dart';
import 'home_page.dart';
import 'notif_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

/// Kerangka utama setelah masuk.
/// - HP: halaman aktif + navbar ranting di bawah.
/// - Laptop/PC (layar lebar): menu ranting di samping kiri + halaman di kanan.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  /// Pindah tab dari halaman mana pun: ShellPage.of(context)?.pindah('notif').
  static ShellPageState? of(BuildContext context) => context.findAncestorStateOfType<ShellPageState>();

  @override
  State<ShellPage> createState() => ShellPageState();
}

class ShellPageState extends State<ShellPage> {
  String tab = 'kulkas';

  void pindah(String id) {
    if (id == 'add') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FormBahanPage()));
      return;
    }
    setState(() => tab = id);
  }

  Widget _halaman(bool lebar) {
    final Widget h = switch (tab) {
      'notif' => const NotifPage(),
      'riwayat' => const RiwayatPage(),
      'profil' => const ProfilPage(),
      _ => const HomePage(),
    };
    // Beranda punya tata letak lebar sendiri; halaman lain cukup ditaruh di tengah.
    final isi = (lebar && tab != 'kulkas') ? IsiTengah(maxWidth: 820, child: h) : h;
    return KeyedSubtree(key: ValueKey(tab), child: isi);
  }

  List<NavItem> _menu(AppState s) {
    final u = s.user;
    return [
      const NavItem('kulkas', 'Kulkas', Emo('kulkas', size: 30)),
      NavItem('notif', 'Notifikasi', const Emo('lonceng', size: 30), badge: s.perluPerhatian),
      const NavItem('add', 'Tambah', Emo('tunas', size: 32)),
      const NavItem('riwayat', 'Riwayat', Emo('buku', size: 30)),
      NavItem('profil', 'Profil', NavAvatar(foto: u?.foto, ava: u?.ava ?? 'brokoli')),
    ];
  }

  Widget _konten(bool lebar) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: _halaman(lebar),
      );

  @override
  Widget build(BuildContext context) {
    final lebar = layarLebar(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListenableBuilder(
        listenable: AppState.i,
        builder: (context, _) {
          final s = AppState.i;
          if (lebar) {
            return Row(children: [
              _MenuSamping(aktif: tab, items: _menu(s), onTap: pindah),
              Expanded(child: _konten(true)),
            ]);
          }
          return Stack(children: [
            Positioned.fill(child: _konten(false)),
            // kabut di belakang navbar supaya konten tidak bertabrakan
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.cream.withValues(alpha: 0), AppColors.cream.withValues(alpha: .95)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: BranchNav(aktif: tab, onTap: pindah, items: _menu(s)),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ===================================================================== menu samping (laptop/PC)

class _MenuSamping extends StatelessWidget {
  final String aktif;
  final List<NavItem> items;
  final ValueChanged<String> onTap;
  const _MenuSamping({required this.aktif, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tambah = items.firstWhere((e) => e.id == 'add');
    final lain = items.where((e) => e.id != 'add').toList();
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F2),
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Stack(children: [
        // ranting kayu yang menjalar di sisi kiri menu
        const Positioned(left: 0, top: 0, bottom: 0, width: 40, child: CustomPaint(painter: _RantingTegak())),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, 24, 18, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const MumuMini(size: 52),
                const SizedBox(width: 6),
                Expanded(child: Text('Kulkasku.', style: AppText.display(30, color: AppColors.leaf))),
              ]),
              const SizedBox(height: 4),
              Text('Sayur & buah aman sebelum layu', style: AppText.body(11.5, color: AppColors.muted)),
              const SizedBox(height: 24),
              _TombolTambah(onTap: () => onTap(tambah.id)),
              const SizedBox(height: 20),
              for (var i = 0; i < lain.length; i++)
                Naik(
                  delayMs: i * 60,
                  child: _ItemMenu(item: lain[i], aktif: lain[i].id == aktif, onTap: () => onTap(lain[i].id)),
                ),
              const Spacer(),
              Text('© 2026 Mita · Kulkasku', style: AppText.body(11, color: AppColors.muted, weight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _TombolTambah extends StatelessWidget {
  final VoidCallback onTap;
  const _TombolTambah({required this.onTap});
  @override
  Widget build(BuildContext context) => ChunkyButton(
        label: 'Tambah sayur',
        ikon: 'tunas',
        warna: AppColors.leaf,
        bayangan: AppColors.leafDark,
        onTap: onTap,
      );
}

class _ItemMenu extends StatefulWidget {
  final NavItem item;
  final bool aktif;
  final VoidCallback onTap;
  const _ItemMenu({required this.item, required this.aktif, required this.onTap});
  @override
  State<_ItemMenu> createState() => _ItemMenuState();
}

class _ItemMenuState extends State<_ItemMenu> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final a = widget.aktif;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: JellyTap(
          onTap: widget.onTap,
          semantik: widget.item.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: a ? AppColors.lettuce : (_hover ? const Color(0xFFF1EDE2) : Colors.transparent),
              borderRadius: leafRadius(18),
            ),
            child: Row(children: [
              AnimatedScale(
                scale: a || _hover ? 1.12 : 1,
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                child: SizedBox(width: 32, height: 32, child: Center(child: widget.item.ikon)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.item.label,
                    style: AppText.body(15, color: a ? AppColors.leafDark : AppColors.ink, weight: a ? FontWeight.w900 : FontWeight.w700)),
              ),
              if (widget.item.badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.mumuRed, borderRadius: BorderRadius.circular(10)),
                  child: Text('${widget.item.badge}', style: AppText.body(12, color: Colors.white, weight: FontWeight.w900)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Ranting kayu tegak dengan daun-daun kecil (versi samping dari navbar ranting).
class _RantingTegak extends CustomPainter {
  const _RantingTegak();
  @override
  void paint(Canvas canvas, Size s) {
    final batang = Path()..moveTo(18, 0);
    var y = 0.0;
    while (y < s.height) {
      batang.quadraticBezierTo(26, y + 60, 18, y + 120);
      batang.quadraticBezierTo(10, y + 180, 18, y + 240);
      y += 240;
    }
    canvas.drawPath(
      batang,
      Paint()
        ..color = AppColors.wood
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final daun = [const Color(0xFF7CC765), const Color(0xFF5FAE52), const Color(0xFF6DBB5A)];
    var i = 0;
    for (var yy = 50.0; yy < s.height; yy += 90) {
      final kanan = i.isEven;
      canvas.save();
      canvas.translate(19, yy);
      canvas.rotate((kanan ? -.5 : .5 + math.pi));
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(5, -9, 16, -9, 18, -3)
          ..cubicTo(12, 3, 5, 3, 0, 0)
          ..close(),
        Paint()..color = daun[i % 3],
      );
      canvas.restore();
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
