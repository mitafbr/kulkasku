import 'dart:async';

import 'package:flutter/material.dart';

import '../data/katalog.dart';
import '../data/logic.dart';
import '../data/models.dart';
import '../services/kalender.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mumu.dart';
import '../widgets/veggie.dart';
import 'dialogs.dart';
import 'form_bahan_page.dart';

/// Detail satu sayur/buah: jadwal layu, pengingat, tips simpan, dan ide olah.
class DetailPage extends StatefulWidget {
  final String bahanId;
  const DetailPage({super.key, required this.bahanId});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _geli = 0;
  Timer? _simpanJumlah;

  @override
  void dispose() {
    _simpanJumlah?.cancel();
    super.dispose();
  }

  Future<void> _keluar(Bahan b, String aksi) async {
    final nav = Navigator.of(context);
    try {
      await AppState.i.keluarkan(b, aksi);
      if (!mounted) return;
      if (aksi == 'dipakai') {
        await tampilkanPerayaan(context, b);
      } else {
        toast(context, '${b.nama} dibuang. Kulkas bersih!', ikon: 'sampah');
      }
      nav.maybePop();
    } catch (e) {
      if (mounted) toast(context, 'Gagal: $e', ikon: 'tanya');
    }
  }

  void _ubahJumlah(Bahan b, int arah) {
    final langkah = b.satuan == 'gram' ? 50 : 1;
    setState(() => b.jumlah = (b.jumlah + langkah * arah).clamp(langkah.toDouble(), 99999).toDouble());
    _simpanJumlah?.cancel();
    _simpanJumlah = Timer(const Duration(milliseconds: 700), () => AppState.i.ubahBahan(b.salin()));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.i,
      builder: (context, _) {
        final b = AppState.i.cari(widget.bahanId);
        if (b == null) return const Scaffold(body: SizedBox());
        final info = b.info;
        final st = Hitung.status(b);
        final basi = st == Status.basi;
        final layu = Hitung.tanggalLayu(b);
        final h1 = tambahHari(layu, -1);
        final h0 = hariIni();
        final u = AppState.i.user!;
        final jam = u.jam.replaceAll(':', '.');
        final f = Hitung.kesegaran(b);

        return Scaffold(
          backgroundColor: info.tint,
          body: IsiTengah(maxWidth: 680, child: Stack(children: [
            CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 290,
                    child: Stack(children: [
                      const Positioned(left: 16, top: 12, child: TombolKembali()),
                      Positioned(
                        right: 16,
                        top: 12,
                        child: RoundBtn(
                          semantik: 'Edit data',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FormBahanPage(ubah: b))),
                          child: const Emo('pensil', size: 24),
                        ),
                      ),
                      Positioned(
                        right: 72,
                        top: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(20)),
                          child: Text(_geli == 0 ? 'Ketuk aku!' : 'Hihi, geli! ×$_geli', style: AppText.body(12, weight: FontWeight.w800)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 60,
                        child: Center(
                          child: JellyTap(
                            scale: .85,
                            onTap: () => setState(() => _geli++),
                            semantik: 'Ketuk ${b.nama}',
                            child: Hero(
                              tag: 'bahan-${b.id}',
                              child: basi ? VeggieImage(b, size: 200) : Melayang(jarak: 8, child: VeggieImage(b, size: 200)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 290),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 130),
                  decoration: const BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b.nama, style: AppText.display(38)),
                          const SizedBox(height: 6),
                          Text('${b.kat} · ${tempatLabel[b.tempat]}', style: AppText.body(13, color: AppColors.muted)),
                          const SizedBox(height: 10),
                          StatusChip(st, '${st.label} · ${Hitung.sisaLabel(b)}'),
                        ]),
                      ),
                      FreshRing(nilai: f, warna: st.cincin, size: 78, tebal: 8, label: '${(f * 100).round()}%'),
                    ]),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.line)),
                      child: Row(children: [
                        Expanded(child: Text('Sisa di kulkas', style: AppText.body(14, weight: FontWeight.w800))),
                        _TombolJumlah(teks: '−', onTap: () => _ubahJumlah(b, -1)),
                        SizedBox(width: 92, child: Text(b.jumlahTeks, textAlign: TextAlign.center, style: AppText.body(15, weight: FontWeight.w900))),
                        _TombolJumlah(teks: '+', onTap: () => _ubahJumlah(b, 1)),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: leafRadius(26), border: Border.all(color: AppColors.line)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text('Jadwal & pengingat', style: AppText.body(15, weight: FontWeight.w900))),
                          if (u.kalender)
                            JellyTap(
                              onTap: () => simpanKeKalender(b),
                              semantik: 'Simpan tanggal layu ke kalender',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.lettuce, borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  const Emo('kalender', size: 14),
                                  const SizedBox(width: 4),
                                  Text('+ Kalender HP', style: AppText.body(11, color: AppColors.leaf, weight: FontWeight.w900)),
                                ]),
                              ),
                            ),
                        ]),
                        _baris('keranjang', 'Dibeli', tglHari(b.beli)),
                        _baris('kalender', 'Perkiraan layu', tglHari(layu)),
                        if (!h1.isBefore(h0)) _baris('lonceng', 'Pengingat H-1', '${tglHari(h1)} · $jam'),
                        if (!layu.isBefore(h0)) _baris('jam', 'Pengingat hari-H', '${tglHari(layu)} · $jam'),
                        const SizedBox(height: 6),
                        _GarisWaktu(nilai: 1 - f, jenis: b.jenis, warna: st.cincin),
                        const SizedBox(height: 12),
                        JellyTap(
                          onTap: () async {
                            b.awet += 2;
                            await AppState.i.ubahBahan(b.salin());
                            if (context.mounted) {
                              toast(context, 'Oke! ${b.nama} sekarang layu ${tglHari(Hitung.tanggalLayu(b))}. Pengingat ikut digeser.', ikon: 'kalender');
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.lettuce, borderRadius: BorderRadius.circular(16)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Emo('daun', size: 20),
                              const SizedBox(width: 8),
                              Text(basi ? 'Ternyata masih bagus? Tambah 2 hari' : 'Masih segar? Tambah 2 hari',
                                  style: AppText.body(13.5, color: AppColors.leafDark, weight: FontWeight.w900)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    Text('Tips simpan', style: AppText.body(15, weight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(info.tips, style: AppText.body(14, color: AppColors.muted, weight: FontWeight.w600, height: 1.55)),
                    const SizedBox(height: 18),
                    if (basi)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF3A2F22), borderRadius: leafRadius(24)),
                        child: Row(children: [
                          const MumuMini(size: 54, mood: MumuMood.sedih),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Sudah basi, jangan diolah', style: AppText.body(16, color: Colors.white, weight: FontWeight.w900)),
                              const SizedBox(height: 3),
                              Text('Lewat ${-Hitung.sisaHari(b)} hari dari tanggal layunya. Buang supaya jamurnya nggak menular ke bahan lain.',
                                  style: AppText.body(13, color: Colors.white70, weight: FontWeight.w600, height: 1.4)),
                            ]),
                          ),
                        ]),
                      )
                    else ...[
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Expanded(child: Text('Ide olah cepat', style: AppText.display(26))),
                        const Emo('salad', size: 30),
                      ]),
                      const SizedBox(height: 4),
                      Text('Biar ${b.nama.toLowerCase()} habis sebelum layu.', style: AppText.body(12.5, color: AppColors.muted)),
                      const SizedBox(height: 10),
                      for (var i = 0; i < info.ide.length; i++)
                        Naik(
                          delayMs: i * 70,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: leafRadius(20), border: Border.all(color: AppColors.line)),
                            child: Row(children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: info.tint, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text('${i + 1}', style: AppText.display(18, italic: false)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(info.ide[i].nama, style: AppText.body(14, weight: FontWeight.w800))),
                              Text(info.ide[i].waktu, style: AppText.body(12, color: AppColors.muted)),
                            ]),
                          ),
                        ),
                    ],
                  ]),
                ),
              ),
            ]),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: basi
                    ? ChunkyButton(
                        label: 'Buang, sudah basi',
                        ikon: 'sampah',
                        warna: const Color(0xFF5A4630),
                        bayangan: const Color(0xFF33271A),
                        onTap: () => _keluar(b, 'dibuang'),
                      )
                    : Row(children: [
                        JellyTap(
                          semantik: 'Buang ${b.nama}',
                          onTap: () async {
                            final ok = await konfirmasi(context,
                                judul: 'Buang ${b.nama}?',
                                isi: 'Bahan keluar dari kulkas dan tercatat sebagai “dibuang” di riwayat.',
                                ya: 'Buang',
                                ikon: 'sampah');
                            if (ok) _keluar(b, 'dibuang');
                          },
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.tomatoLight,
                              borderRadius: leafRadius(22),
                              boxShadow: const [BoxShadow(color: Color(0x38D93A2B), offset: Offset(0, 5))],
                            ),
                            alignment: Alignment.center,
                            child: const Emo('sampah', size: 30),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: ChunkyButton(label: 'Sudah dipakai', ikon: 'centang', onTap: () => _keluar(b, 'dipakai'))),
                      ]),
              ),
            ),
          ])),
        );
      },
    );
  }

  Widget _baris(String ikon, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Emo(ikon, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(k, style: AppText.body(13.5, color: AppColors.muted))),
          Text(v, style: AppText.body(14, weight: FontWeight.w900)),
        ]),
      );
}

class _TombolJumlah extends StatelessWidget {
  final String teks;
  final VoidCallback onTap;
  const _TombolJumlah({required this.teks, required this.onTap});
  @override
  Widget build(BuildContext context) => JellyTap(
        onTap: onTap,
        semantik: teks == '+' ? 'Tambah' : 'Kurangi',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.lettuce, borderRadius: leafRadius(16)),
          alignment: Alignment.center,
          child: Text(teks, style: AppText.body(22, color: AppColors.leaf, weight: FontWeight.w900)),
        ),
      );
}

class _GarisWaktu extends StatelessWidget {
  final double nilai;
  final String jenis;
  final Color warna;
  const _GarisWaktu({required this.nilai, required this.jenis, required this.warna});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: LayoutBuilder(
          builder: (context, c) => Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(colors: [Color(0xFFA8D86E), Color(0xFFF2C14E), Color(0xFFE8701A), Color(0xFFD93A2B)]),
                ),
              ),
            ),
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: nilai.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Align(
                alignment: Alignment(-1 + 2 * v, 0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: warna, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: Emo(jenis, size: 18),
                ),
              ),
            ),
            ),
          ]),
        ),
      );
}
