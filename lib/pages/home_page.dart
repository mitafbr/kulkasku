import 'package:flutter/material.dart';

import '../data/katalog.dart';
import '../data/logic.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/branch_nav.dart';
import '../widgets/common.dart';
import '../widgets/kitchen.dart';
import '../widgets/mumu.dart';
import '../widgets/veggie.dart';
import 'detail_page.dart';
import 'dialogs.dart';
import 'shell_page.dart';

/// Beranda: dapur dengan kulkas yang bisa dibuka + daftar isi kulkas.
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _buka;
  String? _pilih;
  String _kategori = 'Semua';
  String _cari = '';

  AppState get s => AppState.i;

  void _detail(Bahan b) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailPage(bahanId: b.id)));
  }

  Future<void> _pakai(Bahan b, String aksi) async {
    try {
      await s.keluarkan(b, aksi);
      if (!mounted) return;
      if (aksi == 'dipakai') {
        await tampilkanPerayaan(context, b);
      } else {
        toast(context, '${b.nama} yang basi sudah dibuang. Kulkas bersih!', ikon: 'sampah');
      }
    } catch (e) {
      if (mounted) toast(context, 'Gagal: $e', ikon: 'tanya');
    }
  }

  Future<void> _buangBasi() async {
    final n = await s.buangSemuaBasi();
    if (mounted && n > 0) toast(context, '$n bahan basi dibuang. Kulkas bersih lagi!', ikon: 'sampah');
  }

  @override
  Widget build(BuildContext context) {
    final lebar = layarLebar(context);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final u = s.user;
        if (u == null) return const SizedBox();
        final q = _cari.toLowerCase();
        final list = s.urut.where((b) => (_kategori == 'Semua' || b.kat == _kategori) && (q.isEmpty || b.nama.toLowerCase().contains(q))).toList();
        final basi = s.bahan.where((b) => Hitung.status(b) == Status.basi).toList();
        final now = DateTime.now();

        // ---------- bagian-bagian halaman
        final kepala = <Widget>[
          SafeArea(
            bottom: false,
            child: Row(children: [
              Expanded(child: Text('${namaHari(now).toUpperCase()}, ${tgl(now).toUpperCase()}', style: AppText.label())),
              JellyTap(
                onTap: () => ShellPage.of(context)?.pindah('notif'),
                semantik: 'Notifikasi',
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Emo('lonceng', size: 22),
                    const SizedBox(width: 4),
                    Text('${s.perluPerhatian}', style: AppText.body(13, weight: FontWeight.w900)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              JellyTap(
                onTap: () => ShellPage.of(context)?.pindah('profil'),
                semantik: 'Profil',
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: NavAvatar(foto: u.foto, ava: u.ava),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Text('Kulkasku.', style: AppText.display(46, color: AppColors.leaf)),
          const SizedBox(height: 6),
          Text(
            'Halo, ${u.nama}! Ada ${s.bahan.length} sayur & buah di kulkas, ${s.hitung(Status.layu)} minta segera dimasak.',
            style: AppText.body(14, color: AppColors.muted, height: 1.35),
          ),
          if (basi.isNotEmpty) ...[
            const SizedBox(height: 14),
            Naik(child: _KartuBasi(basi: basi, onBuang: _buangBasi, onDetail: _detail)),
          ],
        ];

        final dapur = <Widget>[
          const SizedBox(height: 10),
          // dapur dibuat selebar kolomnya
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: KitchenScene.tinggi,
              child: OverflowBox(
                minWidth: c.maxWidth + 40,
                maxWidth: c.maxWidth + 40,
                child: RepaintBoundary(
                  child: KitchenScene(
                    bahan: s.bahan,
                    buka: _buka,
                    pilih: _pilih,
                    catatan: u.catatan,
                    suhuKl: u.suhuKl,
                    suhuFz: u.suhuFz,
                    onPintu: (c) => setState(() {
                      _buka = _buka == c ? null : c;
                      _pilih = null;
                    }),
                    onPilih: (b) => setState(() => _pilih = b.id),
                    onDetail: _detail,
                    onSuhu: (k) => aturSuhu(context, k),
                    onCatatan: () => editCatatan(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buka == null
                ? const _KartuPetunjuk(key: ValueKey('petunjuk'))
                : _PanelKompartemen(
                    key: ValueKey(_buka),
                    freezer: _buka == 'freezer',
                    onTutup: () => setState(() => _buka = null),
                    onDetail: _detail,
                    onPakai: _pakai,
                  ),
          ),
        ];

        final daftar = <Widget>[
          Row(children: [
            for (final st in Status.values) ...[
              Expanded(child: _KotakHitung(status: st, jumlah: s.hitung(st))),
              if (st != Status.basi) const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _cari = v),
            decoration: const InputDecoration(
              hintText: 'Cari sayur atau buah…',
              prefixIcon: Padding(padding: EdgeInsets.all(10), child: Emo('kaca', size: 22)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in const [('Semua', 'keranjang'), ('Sayur', 'brokoli'), ('Buah', 'apel'), ('Lainnya', 'telur')])
              LeafChip(label: k.$1, ikon: k.$2, aktif: _kategori == k.$1, onTap: () => setState(() => _kategori = k.$1)),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Text('Isi kulkas', style: AppText.display(28))),
            Text('paling cepat layu di atas', style: AppText.body(12, color: AppColors.muted)),
          ]),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(children: [
                MumuMini(size: 110, mood: q.isNotEmpty ? MumuMood.tanya : MumuMood.idle),
                const SizedBox(height: 6),
                Text(q.isNotEmpty ? 'Nggak ketemu, nih.' : 'Kulkasnya kosong.', style: AppText.display(26)),
                const SizedBox(height: 4),
                Text(q.isNotEmpty ? 'Coba kata kunci lain.' : (lebar ? 'Tambah lewat tombol "Tambah sayur" di menu kiri.' : 'Tambah lewat tetesan tengah di navbar.'),
                    style: AppText.body(13, color: AppColors.muted)),
              ]),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: lebar
                  ? const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 230,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 222,
                    )
                  : const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 222,
                    ),
              itemBuilder: (_, i) => Naik(
                delayMs: i.clamp(0, 8).toInt() * 50,
                child: _KartuBahan(bahan: list[i], onDetail: () => _detail(list[i]), onPakai: _pakai),
              ),
            ),
        ];

        // ---------- laptop/PC: dapur di kiri, daftar isi kulkas di kanan
        if (lebar) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 480,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
                children: [...kepala, ...dapur],
              ),
            ),
            Container(width: 1, color: AppColors.line),
            Expanded(
              child: RefreshIndicator(
                onRefresh: s.muatData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
                  children: [
                    SafeArea(bottom: false, child: Text('RINGKASAN KULKAS', style: AppText.label())),
                    const SizedBox(height: 10),
                    ...daftar,
                  ],
                ),
              ),
            ),
          ]);
        }

        // ---------- HP: satu kolom
        return RefreshIndicator(
          onRefresh: s.muatData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
            children: [...kepala, ...dapur, const SizedBox(height: 14), ...daftar],
          ),
        );
      },
    );
  }
}

class _KartuBasi extends StatelessWidget {
  final List<Bahan> basi;
  final VoidCallback onBuang;
  final ValueChanged<Bahan> onDetail;
  const _KartuBasi({required this.basi, required this.onBuang, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF3A2F22), borderRadius: leafRadius(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const MumuMini(size: 56, mood: MumuMood.sedih),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${basi.length} bahan sudah basi', style: AppText.body(16, color: Colors.white, weight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text('Masih di kulkas sejak lewat tanggalnya. Buang supaya nggak menular ke yang lain.',
                  style: AppText.body(12.5, color: Colors.white70, weight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final b in basi)
            GestureDetector(
              onTap: () => onDetail(b),
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  VeggieImage(b, size: 22, animasi: false),
                  const SizedBox(width: 6),
                  Text('${b.nama} · ${Hitung.sisaLabel(b).toLowerCase()}', style: AppText.body(12, color: Colors.white)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        _Berdenyut(
          child: ChunkyButton(
            label: 'Buang semua yang basi',
            ikon: 'sampah',
            warna: const Color(0xFFC9A46C),
            bayangan: const Color(0xFF8A6A3E),
            onTap: onBuang,
          ),
        ),
      ]),
    );
  }
}

class _Berdenyut extends StatefulWidget {
  final Widget child;
  const _Berdenyut({required this.child});
  @override
  State<_Berdenyut> createState() => _BerdenyutState();
}

class _BerdenyutState extends State<_Berdenyut> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: AppColors.tomatoDark.withValues(alpha: .35 * (1 - _c.value)), spreadRadius: 10 * _c.value)],
          ),
          child: c,
        ),
        child: widget.child,
      );
}

class _KartuPetunjuk extends StatelessWidget {
  const _KartuPetunjuk({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: leafRadius(24),
          border: Border.all(color: AppColors.line, width: 1.4),
        ),
        child: Row(children: [
          const Melayang(child: Emo('kulkas', size: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ketuk pintu atas untuk melihat isi freezer, atau pintu bawah untuk isi kulkas. Ketuk sayurnya sekali untuk melihat nama, dua kali untuk membuka detail.',
              style: AppText.body(13, color: AppColors.ink, weight: FontWeight.w600, height: 1.45),
            ),
          ),
        ]),
      );
}

class _PanelKompartemen extends StatelessWidget {
  final bool freezer;
  final VoidCallback onTutup;
  final ValueChanged<Bahan> onDetail;
  final Future<void> Function(Bahan, String) onPakai;
  const _PanelKompartemen({super.key, required this.freezer, required this.onTutup, required this.onDetail, required this.onPakai});

  @override
  Widget build(BuildContext context) {
    final s = AppState.i;
    final u = s.user!;
    final grup = freezer ? const [('Rak freezer', 'freezer')] : const [('Rak', 'rak'), ('Laci sayur', 'laci'), ('Rak pintu', 'pintu')];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: leafRadius(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: freezer ? const [Color(0xFFFBFCF6), Color(0xFFE6ECDA)] : const [Color(0xFFEAF5DF), Color(0xFFD6EBC4)],
        ),
        border: Border.all(color: freezer ? const Color(0xFFD3DCC4) : const Color(0xFFC5DDB0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Emo(freezer ? 'salju' : 'daun', size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(freezer ? 'Freezer' : 'Kulkas', style: AppText.display(30)),
              Text(freezer ? 'Beku tahan ±3× lebih lama dari kulkas' : 'Sayur & buah segar, cek tiap hari',
                  style: AppText.body(12, color: AppColors.muted)),
            ]),
          ),
          JellyTap(
            onTap: () => aturSuhu(context, freezer ? 'fz' : 'kl'),
            semantik: 'Atur suhu',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .7), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Emo('termo', size: 14),
                const SizedBox(width: 3),
                Text(formatSuhu(freezer ? u.suhuFz : u.suhuKl), style: AppText.body(12, weight: FontWeight.w900)),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          RoundBtn(size: 38, onTap: onTutup, semantik: 'Tutup', child: const Icon(Icons.close_rounded, size: 20)),
        ]),
        for (final g in grup) ...[
          const SizedBox(height: 12),
          Text('${g.$1.toUpperCase()} · ${s.di(g.$2).length}', style: AppText.label(color: AppColors.ink.withValues(alpha: .7))),
          const SizedBox(height: 6),
          if (s.di(g.$2).isEmpty)
            Text('Kosong. Tekan Tambah untuk mengisi.', style: AppText.body(13, color: AppColors.muted))
          else
            for (final b in (s.di(g.$2)..sort((a, b) => Hitung.sisaHari(a).compareTo(Hitung.sisaHari(b)))))
              _BarisPanel(bahan: b, freezer: freezer, onDetail: onDetail, onPakai: onPakai),
        ],
      ]),
    );
  }
}

class _BarisPanel extends StatelessWidget {
  final Bahan bahan;
  final bool freezer;
  final ValueChanged<Bahan> onDetail;
  final Future<void> Function(Bahan, String) onPakai;
  const _BarisPanel({required this.bahan, required this.freezer, required this.onDetail, required this.onPakai});

  @override
  Widget build(BuildContext context) {
    final st = Hitung.status(bahan);
    final basi = st == Status.basi;
    final layu = Hitung.tanggalLayu(bahan);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: leafRadius(18)),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onDetail(bahan),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: freezer ? Colors.white : bahan.info.tint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: VeggieImage(bahan, size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bahan.nama, style: AppText.body(14.5, weight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                  Text(
                    basi
                        ? 'Basi sejak ${tglHari(layu)} · buang ya'
                        : freezer
                            ? 'Beku sampai ${tglHari(layu)}'
                            : '${bahan.jumlahTeks} · layu ${tglHari(layu)}',
                    style: AppText.body(12, color: AppColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            ]),
          ),
        ),
        StatusChip(st, freezer && !basi ? '${Hitung.sisaHari(bahan)} hari' : st.label),
        const SizedBox(width: 6),
        JellyTap(
          onTap: () => onPakai(bahan, basi ? 'dibuang' : 'dipakai'),
          semantik: basi ? 'Buang ${bahan.nama}' : 'Tandai ${bahan.nama} sudah dipakai',
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: basi ? const Color(0xFFE9DFCF) : AppColors.lettuce, borderRadius: leafRadius(12)),
            alignment: Alignment.center,
            child: Emo(basi ? 'sampah' : 'centang', size: 22),
          ),
        ),
      ]),
    );
  }
}

class _KotakHitung extends StatelessWidget {
  final Status status;
  final int jumlah;
  const _KotakHitung({required this.status, required this.jumlah});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(color: status.muda, borderRadius: leafRadius(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: jumlah),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('$v', style: AppText.display(32, color: status.warna, italic: false)),
          ),
          Text(status.label, style: AppText.body(12, color: status.warna, weight: FontWeight.w800)),
        ]),
      );
}

class _KartuBahan extends StatelessWidget {
  final Bahan bahan;
  final VoidCallback onDetail;
  final Future<void> Function(Bahan, String) onPakai;
  const _KartuBahan({required this.bahan, required this.onDetail, required this.onPakai});

  @override
  Widget build(BuildContext context) {
    final st = Hitung.status(bahan);
    final basi = st == Status.basi;
    final freezer = bahan.tempat == 'freezer';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: leafRadius(28),
        boxShadow: const [BoxShadow(color: Color(0x142F7D3A), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        JellyTap(
          onTap: onDetail,
          semantik: 'Detail ${bahan.nama}',
          child: Container(
            height: 112,
            decoration: BoxDecoration(
              borderRadius: leafRadius(22),
              color: freezer ? null : bahan.info.tint,
              gradient: freezer
                  ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFCFDF8), Color(0xFFE6ECDA)])
                  : null,
            ),
            child: Stack(children: [
              Center(child: Hero(tag: 'bahan-${bahan.id}', child: VeggieImage(bahan, size: 80))),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(3, 3, 6, 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .75), borderRadius: BorderRadius.circular(9)),
                  child: Row(children: [
                    Emo(freezer ? 'salju' : 'daun', size: 14),
                    const SizedBox(width: 3),
                    Text(tempatLabel[bahan.tempat] ?? bahan.tempat, style: AppText.body(10, weight: FontWeight.w900)),
                  ]),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: FreshRing(
                    nilai: Hitung.kesegaran(bahan),
                    warna: st.cincin,
                    label: Hitung.sisaHari(bahan) <= 0 ? '!' : '${Hitung.sisaHari(bahan)}h',
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(bahan.nama, style: AppText.body(15, weight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('Layu ${tglHari(Hitung.tanggalLayu(bahan))}', style: AppText.body(12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Row(children: [
          StatusChip(st, st.label),
          const Spacer(),
          JellyTap(
            onTap: () => onPakai(bahan, basi ? 'dibuang' : 'dipakai'),
            semantik: basi ? 'Buang ${bahan.nama}' : 'Tandai ${bahan.nama} sudah dipakai',
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: basi ? const Color(0xFFE9DFCF) : AppColors.lettuce, borderRadius: leafRadius(12)),
              alignment: Alignment.center,
              child: Emo(basi ? 'sampah' : 'centang', size: 22),
            ),
          ),
        ]),
      ]),
    );
  }
}
