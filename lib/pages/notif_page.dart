import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/logic.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mumu.dart';
import '../widgets/veggie.dart';
import 'detail_page.dart';

/// Jadwal pengingat H-1, hari-H, dan pengingat sayur yang sudah basi.
class NotifPage extends StatefulWidget {
  const NotifPage({super.key});
  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  int _hari = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final s = AppState.i;
        final u = s.user!;
        final jam = u.jam.replaceAll(':', '.');
        final jadwal = Hitung.jadwal(s.bahan);
        final h0 = hariIni();
        final hari = List.generate(14, (i) => tambahHari(h0, i));
        final pilih = hari[_hari];
        final hariIniList = jadwal.where((p) => p.tanggal == pilih).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
          children: [
            SafeArea(
              bottom: false,
              child: PageHead(u.pengingat ? 'Pengingat aktif · jam $jam' : 'Pengingat dimatikan', 'Notifikasi.',
                  ikon: const Melayang(child: Emo('lonceng', size: 44))),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 10),
              _KartuNotifWeb(izin: s.izinNotif, didukung: s.notifDidukung, aktif: u.pengingat),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hari.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = hari[i];
                  final aktif = i == _hari;
                  final titik = jadwal.where((p) => p.tanggal == d).take(3).toList();
                  return JellyTap(
                    onTap: () => setState(() => _hari = i),
                    semantik: tglHari(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 56,
                      decoration: BoxDecoration(
                        color: aktif ? AppColors.leaf : Colors.white,
                        borderRadius: leafRadius(20),
                        border: Border.all(color: aktif ? AppColors.leaf : AppColors.line),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(i == 0 ? 'Hari ini' : hariSingkat(d),
                            style: AppText.body(10, color: aktif ? Colors.white70 : AppColors.muted, weight: FontWeight.w800)),
                        Text('${d.day}', style: AppText.display(22, color: aktif ? Colors.white : AppColors.ink, italic: false)),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (final p in titik)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: p.jenis == 'h1' ? AppColors.carrot : AppColors.tomato,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ]),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(_hari == 0 ? 'Hari ini' : tglHari(pilih), style: AppText.display(26)),
            const SizedBox(height: 10),
            if (hariIniList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  const MumuMini(size: 90),
                  const SizedBox(height: 6),
                  Text('Tidak ada pengingat di hari ini.', style: AppText.body(14, color: AppColors.muted)),
                ]),
              )
            else
              for (var i = 0; i < hariIniList.length; i++)
                Naik(delayMs: i * 50, child: _KartuPengingat(p: hariIniList[i], jam: jam, kalender: u.kalender)),
          ],
        );
      },
    );
  }
}

class _KartuPengingat extends StatelessWidget {
  final Pengingat p;
  final String jam;
  final bool kalender;
  const _KartuPengingat({required this.p, required this.jam, required this.kalender});

  @override
  Widget build(BuildContext context) {
    final (bg, garis) = switch (p.jenis) {
      'h1' => (const Color(0xFFFFF3E4), const Color(0xFFFFE0BF)),
      'lewat' => (const Color(0xFFEFE6D8), const Color(0xFFDDCFB8)),
      _ => (const Color(0xFFFDEDEA), const Color(0xFFF7D2CC)),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: JellyTap(
        scale: .97,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailPage(bahanId: p.bahan.id))),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: leafRadius(26), border: Border.all(color: garis)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: p.bahan.info.tint, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: VeggieImage(p.bahan, size: 38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.judul, style: AppText.body(15, weight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(p.pesan, style: AppText.body(13, color: AppColors.muted, weight: FontWeight.w600, height: 1.35)),
                const SizedBox(height: 6),
                Row(children: [
                  const Emo('jam', size: 14),
                  const SizedBox(width: 4),
                  Text('${tglHari(p.tanggal)} · $jam', style: AppText.body(11, weight: FontWeight.w800)),
                  if (kalender) ...[
                    const SizedBox(width: 6),
                    const Emo('kalender', size: 14),
                    const SizedBox(width: 3),
                    Text('Kalender HP', style: AppText.body(11, weight: FontWeight.w800)),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}


/// Kartu status notifikasi browser (versi web).
class _KartuNotifWeb extends StatelessWidget {
  final String izin;
  final bool didukung;
  final bool aktif;
  const _KartuNotifWeb({required this.izin, required this.didukung, required this.aktif});

  @override
  Widget build(BuildContext context) {
    final nyala = didukung && izin == 'granted' && aktif;
    final String teks;
    if (!didukung) {
      teks = 'Browser ini belum mendukung notifikasi. Pengingat tetap tampil di halaman ini.';
    } else if (izin == 'denied') {
      teks = 'Notifikasi diblokir browser. Klik ikon gembok di samping alamat web → Notifikasi → Izinkan, lalu muat ulang halaman.';
    } else if (!aktif) {
      teks = 'Pengingat sedang dimatikan. Nyalakan lewat Profil → Notifikasi pengingat.';
    } else if (nyala) {
      teks = 'Notifikasi browser aktif. Pengingat muncul selama tab Kulkasku terbuka (boleh di latar belakang). Untuk notifikasi walau aplikasi ditutup, pakai versi APK.';
    } else {
      teks = 'Izinkan notifikasi supaya pengingat H-1 dan hari-H muncul di layar laptop atau HP-mu.';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: nyala ? AppColors.lettuce : AppColors.carrotLight, borderRadius: leafRadius(18)),
      child: Row(children: [
        Emo(nyala ? 'lonceng' : 'tanya', size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(teks, style: AppText.body(12.5, color: nyala ? AppColors.leafDark : AppColors.carrotDark, weight: FontWeight.w700)),
        ),
        if (didukung && izin == 'default' && aktif) ...[
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => AppState.i.aktifkanNotif(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
            child: Text('Izinkan', style: AppText.body(13, color: Colors.white, weight: FontWeight.w800)),
          ),
        ],
      ]),
    );
  }
}
