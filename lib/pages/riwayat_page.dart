import 'package:flutter/material.dart';

import '../data/katalog.dart';
import '../data/logic.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mumu.dart';

/// Jejak sayur/buah yang sudah keluar dari kulkas.
class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});
  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String _filter = 'semua';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final s = AppState.i;
        final pk = s.dipakai, bg = s.dibuang;
        final total = s.riwayat.length;
        final pct = total == 0 ? 1.0 : pk / total;
        final list = s.riwayat.where((r) => _filter == 'semua' || r.aksi == _filter).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
          children: [
            SafeArea(bottom: false, child: PageHead('Jejak penyelamatan', 'Riwayat.', ikon: const Melayang(child: Emo('buku', size: 44)))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3C9446), Color(0xFF1F5A28)]),
                borderRadius: leafRadius(32),
              ),
              child: Row(children: [
                FreshRing(nilai: pct, warna: AppColors.leafLight, size: 92, tebal: 9, label: '${(pct * 100).round()}%', warnaLabel: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BAHAN TERPAKAI', style: AppText.label(color: AppColors.leafLight, size: 10)),
                    const SizedBox(height: 6),
                    Text('$pk dipakai\n$bg terbuang', style: AppText.display(24, color: Colors.white)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, children: [
              for (final f in const [('semua', 'Semua', 'keranjang'), ('dipakai', 'Dipakai', 'centang'), ('dibuang', 'Dibuang', 'sampah')])
                LeafChip(label: f.$2, ikon: f.$3, aktif: _filter == f.$1, onTap: () => setState(() => _filter = f.$1)),
            ]),
            const SizedBox(height: 14),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  const MumuMini(size: 90),
                  const SizedBox(height: 6),
                  Text('Belum ada riwayat. Mumu menunggu sayur pertamamu!', textAlign: TextAlign.center, style: AppText.body(14, color: AppColors.muted)),
                ]),
              )
            else
              for (var i = 0; i < list.length; i++)
                Naik(
                  delayMs: i.clamp(0, 8).toInt() * 50,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: leafRadius(24), border: Border.all(color: AppColors.line)),
                    child: Row(children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: Katalog.info(list[i].jenis).tint, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Emo(list[i].jenis, size: 38),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(list[i].nama, style: AppText.body(15, weight: FontWeight.w900)),
                          Text(list[i].jumlahTeks, style: AppText.body(12.5, color: AppColors.muted)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: list[i].aksi == 'dipakai' ? AppColors.lettuce : AppColors.tomatoLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(list[i].aksi == 'dipakai' ? 'Dipakai' : 'Dibuang',
                              style: AppText.body(11, color: list[i].aksi == 'dipakai' ? AppColors.leaf : AppColors.tomatoDark, weight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 6),
                        Text(tglHari(list[i].waktu), style: AppText.body(11, color: AppColors.muted)),
                      ]),
                    ]),
                  ),
                ),
          ],
        );
      },
    );
  }
}
