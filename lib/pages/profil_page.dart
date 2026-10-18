import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/logic.dart';
import '../services/suara.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/branch_nav.dart';
import '../widgets/common.dart';
import 'auth_page.dart';
import 'dialogs.dart';
import 'edit_profil_page.dart';
import 'info_pages.dart';

/// Profil bergaya polaroid yang ditempel di pintu kulkas + pengaturan.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  Future<void> _keluar(BuildContext context) async {
    final ok = await konfirmasi(context, judul: 'Keluar dari akun?', isi: 'Datamu tetap aman dan bisa dibuka lagi setelah masuk.', ya: 'Keluar', ikon: 'pintu');
    if (!ok || !context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars(); // tutup notifikasi yang masih tampil
    await AppState.i.keluar();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthPage()), (_) => false);
  }

  Future<void> _hapusAkun(BuildContext context) async {
    final ok = await konfirmasi(
      context,
      judul: 'Hapus akun?',
      isi: 'Akun, isi kulkas, riwayat, catatan, dan foto profil akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
      ya: 'Hapus permanen',
      ikon: 'sampah',
    );
    if (!ok || !context.mounted) return;
    try {
      await AppState.i.hapusAkun();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthPage()), (_) => false);
    } catch (e) {
      if (context.mounted) toast(context, 'Gagal menghapus akun: $e', ikon: 'tanya');
    }
  }

  Future<void> _jam(BuildContext context) async {
    final u = AppState.i.user!;
    final p = u.jam.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(p.first) ?? 7, minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0),
      helpText: 'Jam pengingat',
    );
    if (t == null) return;
    final jam = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    await AppState.i.ubahPengaturan((x) => x.jam = jam);
    if (context.mounted) toast(context, 'Semua pengingat dikirim jam ${jam.replaceAll(':', '.')}', ikon: 'jam');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final s = AppState.i;
        final u = s.user;
        if (u == null) return const SizedBox();
        void bukaEdit() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfilPage()));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
          children: [
            const SafeArea(bottom: false, child: PageHead('Akun & pengaturan', 'Profil.')),
            const SizedBox(height: 14),
            // ---------- pintu kulkas sage dengan polaroid
            Container(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26), bottom: Radius.circular(18)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF9DB582), Color(0xFFC3D5AB), Color(0xFFB4C89A), Color(0xFF98B07D)],
                  stops: [0, .42, .8, 1],
                ),
                boxShadow: [BoxShadow(color: const Color(0xFF283C1E).withValues(alpha: .4), blurRadius: 22, offset: const Offset(0, 12), spreadRadius: -12)],
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  top: -16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text('KULKASKU',
                        style: AppText.body(8, color: const Color(0xFF55703F), weight: FontWeight.w900).copyWith(letterSpacing: 1.8)),
                  ),
                ),
                Positioned(
                  right: -6,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(colors: [AppColors.woodDark, AppColors.woodLight, Color(0xFF8A5A36)]),
                    ),
                  ),
                ),
                Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    JellyTap(
                      onTap: bukaEdit,
                      semantik: 'Edit profil dan foto',
                      child: Transform.rotate(
                        angle: -.07,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 30),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 8))],
                          ),
                          child: Stack(clipBehavior: Clip.none, children: [
                            Container(
                              width: 104,
                              height: 104,
                              color: u.foto == null ? const Color(0xFFDDF0D0) : const Color(0xFFEEEEEE),
                              alignment: Alignment.center,
                              child: u.foto != null
                                  ? SizedBox.expand(child: FotoProfil(u.foto!))
                                  : Emo(u.ava, size: 80),
                            ),
                            const Positioned(top: -22, left: 38, child: Emo('tomat', size: 28)),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -25,
                              child: Text('${u.nama} ♡',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.display(17, color: const Color(0xFF2B2620))),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Transform.rotate(
                          angle: .035,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFDF6),
                              boxShadow: [BoxShadow(color: Color(0x2E1E2814), blurRadius: 12, offset: Offset(0, 6))],
                            ),
                            child: Stack(clipBehavior: Clip.none, children: [
                              Positioned(
                                top: -22,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: -.05,
                                    child: Container(width: 52, height: 16, color: const Color(0xBFFFECAA)),
                                  ),
                                ),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('@${u.username}', style: AppText.body(14, weight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                                Text(u.email, style: AppText.body(11.5, color: AppColors.muted), overflow: TextOverflow.ellipsis),
                                if (u.hp.isNotEmpty) Text(u.hp, style: AppText.body(11.5, color: AppColors.muted)),
                                const SizedBox(height: 8),
                                JellyTap(
                                  onTap: bukaEdit,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.lettuce, borderRadius: BorderRadius.circular(12)),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Emo('pensil', size: 16),
                                      const SizedBox(width: 5),
                                      Text('Edit profil', style: AppText.body(12, color: AppColors.leafDark, weight: FontWeight.w800)),
                                    ]),
                                  ),
                                ),
                              ]),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Row(children: [
                      _Sticky(nilai: s.bahan.length, label: 'Di kulkas', warna: const Color(0xFFFFF3B8), rot: -4, magnet: 'stroberi', fase: 0),
                      const SizedBox(width: 10),
                      _Sticky(nilai: s.dipakai, label: 'Diselamatkan', warna: const Color(0xFFDDF0D0), rot: 3, magnet: 'wortel', fase: .3),
                      const SizedBox(width: 10),
                      _Sticky(nilai: s.dibuang, label: 'Terbuang', warna: const Color(0xFFFBDDD3), rot: -2, magnet: 'apel', fase: .6),
                    ]),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            // ---------- pengaturan
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: leafRadius(26), border: Border.all(color: AppColors.line)),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                _Menu(ikon: 'pensil', label: 'Edit profil & foto', onTap: bukaEdit),
                _Baris(
                  ikon: 'termo',
                  label: 'Suhu kulkasku',
                  sub: 'Ketuk angka untuk mengubah',
                  akhir: Row(mainAxisSize: MainAxisSize.min, children: [
                    _ChipSuhu(teks: formatSuhu(u.suhuKl), warna: AppColors.lettuce, onTap: () => aturSuhu(context, 'kl')),
                    const SizedBox(width: 6),
                    _ChipSuhu(teks: '❄ ${formatSuhu(u.suhuFz)}', warna: const Color(0xFFEEF0F4), onTap: () => aturSuhu(context, 'fz')),
                  ]),
                ),
                _Baris(
                  ikon: 'lonceng',
                  label: 'Notifikasi HP',
                  sub: 'Pengingat H-1 dan hari-H',
                  akhir: Switch(value: u.pengingat, onChanged: (v) => s.ubahPengaturan((p) => p.pengingat = v)),
                ),
                _Baris(
                  ikon: 'jam',
                  label: 'Jam pengingat',
                  sub: 'Semua notifikasi ikut jam ini',
                  akhir: JellyTap(
                    onTap: () => _jam(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                      child: Text(u.jam.replaceAll(':', '.'), style: AppText.body(15, weight: FontWeight.w900)),
                    ),
                  ),
                ),
                _Baris(
                  ikon: 'kalender',
                  label: 'Sinkron Kalender HP',
                  sub: 'Tombol simpan tanggal layu ke Kalender HP',
                  akhir: Switch(value: u.kalender, onChanged: (v) => s.ubahPengaturan((p) => p.kalender = v)),
                ),
                ListenableBuilder(
                  listenable: Suara.i,
                  builder: (context, _) => Column(children: [
                    _Baris(
                      ikon: 'musik',
                      label: 'Lagu latar',
                      sub: 'Musik ceria saat Kulkasku dibuka',
                      akhir: Switch(value: Suara.i.musikAktif, onChanged: Suara.i.aturMusik),
                    ),
                    _Baris(
                      ikon: 'speaker',
                      label: 'Suara klik',
                      sub: 'Bunyi "pop" setiap kali mengetuk',
                      akhir: Switch(value: Suara.i.klikAktif, onChanged: Suara.i.aturKlik),
                    ),
                  ]),
                ),
                _Menu(ikon: 'tanya', label: 'FAQ', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaqPage()))),
                _Menu(ikon: 'buku', label: 'Tentang Kulkasku', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TentangPage()))),
                _Menu(ikon: 'gembok', label: 'Kebijakan Privasi', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivasiPage()))),
              ]),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                s.repo.online ? 'Data tersimpan online (Supabase)' : 'Mode lokal: data tersimpan di perangkat ini',
                style: AppText.body(11.5, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 14),
            ChunkyButton(label: 'Keluar', ikon: 'pintu', warna: AppColors.tomato, bayangan: AppColors.tomatoDark, onTap: () => _keluar(context)),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: () => _hapusAkun(context),
                child: Text('Hapus akun & semua data', style: AppText.body(12.5, color: AppColors.tomatoDark)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Sticky extends StatefulWidget {
  final int nilai;
  final String label;
  final Color warna;
  final double rot;
  final String magnet;
  final double fase;
  const _Sticky({required this.nilai, required this.label, required this.warna, required this.rot, required this.magnet, required this.fase});
  @override
  State<_Sticky> createState() => _StickyState();
}

class _StickyState extends State<_Sticky> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, c) {
          final r = widget.rot * math.pi / 180;
          final goyang = r * (1 - 1.5 * (.5 - .5 * math.cos((_c.value + widget.fase) * math.pi * 2)));
          return Transform.rotate(angle: goyang, alignment: Alignment.topCenter, child: c);
        },
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 9),
            decoration: BoxDecoration(
              color: widget.warna,
              boxShadow: const [BoxShadow(color: Color(0x2E1E2814), blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Column(children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: widget.nilai),
                duration: const Duration(milliseconds: 700),
                builder: (_, v, __) => Text('$v', style: AppText.display(26, color: const Color(0xFF2B2620), italic: false)),
              ),
              Text(widget.label, style: AppText.body(10.5, color: const Color(0xFF5A4A3A), weight: FontWeight.w800)),
            ]),
          ),
          Positioned(top: -10, child: Emo(widget.magnet, size: 20)),
        ]),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final String ikon;
  final String label;
  final VoidCallback onTap;
  const _Menu({required this.ikon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _Ikon(ikon),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.body(15, weight: FontWeight.w800))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ]),
        ),
      );
}

class _Baris extends StatelessWidget {
  final String ikon;
  final String label;
  final String sub;
  final Widget akhir;
  const _Baris({required this.ikon, required this.label, required this.sub, required this.akhir});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(children: [
          _Ikon(ikon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppText.body(15, weight: FontWeight.w800)),
              Text(sub, style: AppText.body(12, color: AppColors.muted, weight: FontWeight.w600)),
            ]),
          ),
          akhir,
        ]),
      );
}

class _Ikon extends StatelessWidget {
  final String nama;
  const _Ikon(this.nama);
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.lettuce, borderRadius: leafRadius(14)),
        alignment: Alignment.center,
        child: Emo(nama, size: 26),
      );
}

class _ChipSuhu extends StatelessWidget {
  final String teks;
  final Color warna;
  final VoidCallback onTap;
  const _ChipSuhu({required this.teks, required this.warna, required this.onTap});
  @override
  Widget build(BuildContext context) => JellyTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(12)),
          child: Text(teks, style: AppText.body(12, weight: FontWeight.w900)),
        ),
      );
}
